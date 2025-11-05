import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:fchatapi/Util/JsonUtil.dart';
import 'package:image/image.dart' as img;

enum PrintLanguageType {
    cn,
    en,
    ja,
}

enum OrderType {
    dineIn, // 堂食
    takeout, // 外卖
}

class PrintOrderObj {
    final String title;
    final List<String> items;
    final String total;
    final String message;
    final String? logoBase64;
    final String? qrLink;
    final PrintLanguageType languageType;

    // 新增字段
    final OrderType orderType;
    final String? takeoutAddress; // 外卖地址
    final String orderId; // 订单编号
    final String dateTime; // 日期时间
    final String? storeName; // 店名
    final String? storeAddress; // 门店地址
    final String? tableNumber; // 桌号 (堂食)
    final String? customerName; // 顾客姓名
    final String? phoneNumber; // 电话
    final String paymentMethod; // 支付方式
    final String? taxAmount; // 税费
    final String? discount; // 折扣
    final String? serverName; // 服务员
    final String? thanksMessage; // 感谢语

    PrintOrderObj({
        required this.title,
        required this.items,
        required this.total,
        this.message = '',
        this.logoBase64,
        this.qrLink,
        this.languageType = PrintLanguageType.cn,
        // 新增默认值
        required this.orderType,
        this.takeoutAddress,
        required this.orderId,
        required this.dateTime,
        this.storeName,
        this.storeAddress,
        this.tableNumber,
        this.customerName,
        this.phoneNumber,
        required this.paymentMethod,
        this.taxAmount,
        this.discount,
        this.serverName,
        this.thanksMessage = '感谢光临！',
    });

    /// ================================
    /// 生成打印字节（扩展调用新方法）
    /// ================================
    Future<List<int>> generateBytes() async {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        bytes += await _printLogo(generator);
        bytes += _printStoreInfo(generator); // 新增：店信息
        bytes += _printOrderInfo(generator); // 新增：订单基本信息
        bytes += _printTitle(generator);
        bytes += _printItems(generator);
        bytes += _printDiscount(generator); // 新增：折扣
        bytes += _printTax(generator); // 新增：税费
        bytes += _printTotal(generator);
        bytes += _printPayment(generator); // 新增：支付
        bytes += _printMessage(generator);
        bytes += _printQrCode(generator);
        bytes += _printThanks(generator); // 新增：感谢语
        bytes += _printFooter(generator);

        return bytes;
    }

    /// ================================
    /// Unicode 检测帮助函数
    /// - Chinese: CJK Unified Ideographs ranges
    /// - Japanese: Hiragana + Katakana (若含平假名/片假名视为日文)
    /// ================================
    static bool _hasChinese(String? s) {
        if (s == null || s.isEmpty) return false;
        final chineseRegex =
        RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]'); // 常用汉字范围
        return chineseRegex.hasMatch(s);
    }

    static bool _hasJapanese(String? s) {
        if (s == null || s.isEmpty) return false;
        // 包含平假名或片假名视为日文；日语也可能包含汉字但平/片假名更能区分
        final japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]');
        return japaneseRegex.hasMatch(s);
    }

    /// 根据单条文本决定是否使用 CJK 支持以及 codeTable（优先检测文本，其次回退到 languageType）
    Map<String, dynamic> _decideTextEncoding(String text) {
        final bool hasJa = _hasJapanese(text);
        final bool hasCn = _hasChinese(text);

        bool containsCJK;
        String? codeTable;

        if (hasJa) {
            containsCJK = true;
            codeTable = 'CP932 ';
        } else if (hasCn) {
            containsCJK = true;
            codeTable = null;
        } else {
            // 回退：如果文本本身没有 CJK，则使用 languageType 作为回退设置
            switch (languageType) {
                case PrintLanguageType.ja:
                    containsCJK = true;
                    codeTable = 'CP932';
                    break;
                case PrintLanguageType.cn:
                    containsCJK = true;
                    codeTable = null;
                    break;
                default:
                    containsCJK = false;
                    codeTable = null;
            }
        }

        return {
            'containsCJK': containsCJK,
            'codeTable': codeTable,
        };
    }

    /// 打印Logo
    Future<List<int>> _printLogo(Generator generator) async {
        List<int> bytes = [];
        if (logoBase64 != null && logoBase64!.isNotEmpty) {
            try {
                final decodedBytes = base64Decode(logoBase64!);
                final logoImage = img.decodeImage(decodedBytes);
                if (logoImage != null) {
                    bytes += generator.image(logoImage, align: PosAlign.center);
                    bytes += generator.feed(1);
                }
            } catch (e) {
                print("加载Logo失败: $e");
            }
        }
        return bytes;
    }

    // 新增：打印店信息
    List<int> _printStoreInfo(Generator generator) {
        List<int> bytes = [];
        if (storeName != null || storeAddress != null) {
            if (storeName != null) {
                final enc = _decideTextEncoding(storeName!);
                bytes += generator.text(storeName!,
                    styles: PosStyles(
                        align: PosAlign.center,
                        bold: true,
                        codeTable: enc['codeTable'] as String?,
                    ),
                    containsChinese: enc['containsCJK'] as bool,
                );
            }
            if (storeAddress != null) {
                final enc = _decideTextEncoding(storeAddress!);
                bytes += generator.text(storeAddress!,
                    styles: PosStyles(
                        align: PosAlign.center,
                        codeTable: enc['codeTable'] as String?,
                    ),
                    containsChinese: enc['containsCJK'] as bool,
                );
            }
            bytes += generator.feed(1);
        }
        return bytes;
    }

    // 新增：打印订单基本信息（类型、ID、时间、地址等）
    List<int> _printOrderInfo(Generator generator) {
        List<int> bytes = [];
        final typeText = orderType == OrderType.dineIn ? '堂食' : '外卖';
        final encType = _decideTextEncoding('订单类型: $typeText');
        bytes += generator.text('订单类型: $typeText',
            styles: PosStyles(
                codeTable: encType['codeTable'] as String?,
            ),
            containsChinese: encType['containsCJK'] as bool,
        );

        // 订单ID 和 时间
        final idTimeText = '订单号: $orderId | 时间: $dateTime';
        final encIdTime = _decideTextEncoding(idTimeText);
        bytes += generator.text(idTimeText,
            styles: PosStyles(
                codeTable: encIdTime['codeTable'] as String?,
            ),
            containsChinese: encIdTime['containsCJK'] as bool,
        );

        // 堂食：桌号
        if (orderType == OrderType.dineIn && tableNumber != null) {
            final tableText = '桌号: $tableNumber';
            final encTable = _decideTextEncoding(tableText);
            bytes += generator.text(tableText,
                styles: PosStyles(
                    codeTable: encTable['codeTable'] as String?,
                ),
                containsChinese: encTable['containsCJK'] as bool,
            );
        }

        // 外卖：姓名、地址、电话
        if (orderType == OrderType.takeout) {
            if (customerName != null) {
                final custText = '收货人: $customerName';
                final encCust = _decideTextEncoding(custText);
                bytes += generator.text(custText,
                    styles: PosStyles(
                        codeTable: encCust['codeTable'] as String?,
                    ),
                    containsChinese: encCust['containsCJK'] as bool,
                );
            }
            if (takeoutAddress != null) {
                final addrText = '地址: $takeoutAddress';
                final encAddr = _decideTextEncoding(addrText);
                bytes += generator.text(addrText,
                    styles: PosStyles(
                        codeTable: encAddr['codeTable'] as String?,
                    ),
                    containsChinese: encAddr['containsCJK'] as bool,
                );
            }
            if (phoneNumber != null) {
                final phoneText = '电话: $phoneNumber';
                final encPhone = _decideTextEncoding(phoneText);
                bytes += generator.text(phoneText,
                    styles: PosStyles(
                        codeTable: encPhone['codeTable'] as String?,
                    ),
                    containsChinese: encPhone['containsCJK'] as bool,
                );
            }
        }

        bytes += generator.hr(ch: '-');
        return bytes;
    }

    /// 打印标题（按 title 文本自动判断）
    List<int> _printTitle(Generator generator) {
        List<int> bytes = [];
        final enc = _decideTextEncoding(title);
        bytes += generator.text(
            title,
            styles: PosStyles(
                align: PosAlign.center,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                bold: true,
                // codeTable 传入如果为 null 则不设置
                codeTable: enc['codeTable'] as String?,
            ),
            containsChinese: enc['containsCJK'] as bool,
        );
        bytes += generator.hr(ch: '=');
        return bytes;
    }

    /// 打印商品项（每项按项文本自动判断）
    List<int> _printItems(Generator generator) {
        List<int> bytes = [];
        for (var item in items) {
            final enc = _decideTextEncoding(item);
            bytes += generator.text(
                item,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        bytes += generator.hr(ch: '=');
        return bytes;
    }

    // 新增：打印折扣
    List<int> _printDiscount(Generator generator) {
        List<int> bytes = [];
        if (discount != null && discount!.isNotEmpty) {
            final enc = _decideTextEncoding(discount!);
            bytes += generator.text(discount!,
                styles: PosStyles(
                    bold: true,
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    // 新增：打印税费
    List<int> _printTax(Generator generator) {
        List<int> bytes = [];
        if (taxAmount != null && taxAmount!.isNotEmpty) {
            final enc = _decideTextEncoding(taxAmount!);
            bytes += generator.text(taxAmount!,
                styles: PosStyles(
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    /// 打印总金额（按 total 文本自动判断）
    List<int> _printTotal(Generator generator) {
        List<int> bytes = [];
        if (total.isNotEmpty) {
            final enc = _decideTextEncoding(total);
            bytes += generator.text(
                total,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    bold: true,
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    // 新增：打印支付方式
    List<int> _printPayment(Generator generator) {
        List<int> bytes = [];
        if (paymentMethod.isNotEmpty && serverName != null) {
            final display = '支付: $paymentMethod | 服务员: $serverName';
            final enc = _decideTextEncoding(display);
            bytes += generator.text(display,
                styles: PosStyles(
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        } else {
            final display = '支付: $paymentMethod';
            final enc = _decideTextEncoding(display);
            bytes += generator.text(display,
                styles: PosStyles(
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    /// 打印留言（按 message 文本自动判断）
    List<int> _printMessage(Generator generator) {
        List<int> bytes = [];
        if (message.isNotEmpty) {
            bytes += generator.feed(1);
            final display = 'message: $message';
            final enc = _decideTextEncoding(display);
            bytes += generator.text(
                display,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    /// 打印二维码
    List<int> _printQrCode(Generator generator) {
        List<int> bytes = [];
        if (qrLink != null && qrLink!.isNotEmpty) {
            bytes += generator.feed(1);
            bytes += generator.qrcode(qrLink!, size: QRSize.size4, align: PosAlign.center);
        }
        return bytes;
    }

    // 新增：打印感谢语
    List<int> _printThanks(Generator generator) {
        List<int> bytes = [];
        if (thanksMessage != null && thanksMessage!.isNotEmpty) {
            bytes += generator.feed(1);
            final enc = _decideTextEncoding(thanksMessage!);
            bytes += generator.text(thanksMessage!,
                styles: PosStyles(
                    align: PosAlign.center,
                    bold: true,
                    codeTable: enc['codeTable'] as String?,
                ),
                containsChinese: enc['containsCJK'] as bool,
            );
        }
        return bytes;
    }

    /// 打印结尾
    List<int> _printFooter(Generator generator) {
        List<int> bytes = [];
        bytes += generator.feed(2);
        bytes += generator.cut();
        return bytes;
    }

    @override
    toString(){
       return JsonUtil.maptostr(toJson()) ;
    }

    /// ================================
    /// JSON 序列化
    /// ================================
    Map<String, dynamic> toJson() {
        return {
            // 原有字段
            'title': title,
            'items': items,
            'total': total,
            'message': message,
            'logoBase64': logoBase64,
            'qrLink': qrLink,
            'languageType': languageType.name,
            // 新增
            'orderType': orderType.name,
            'takeoutAddress': takeoutAddress,
            'orderId': orderId,
            'dateTime': dateTime,
            'storeName': storeName,
            'storeAddress': storeAddress,
            'tableNumber': tableNumber,
            'customerName': customerName,
            'phoneNumber': phoneNumber,
            'paymentMethod': paymentMethod,
            'taxAmount': taxAmount,
            'discount': discount,
            'serverName': serverName,
            'thanksMessage': thanksMessage,
        };
    }

    static PrintOrderObj fromJson(Map<String, dynamic> json) {
        final language = _parseLanguageType(json['languageType']);
        final orderType = _parseOrderType(json['orderType']);
        final items = (json['items'] as List?)?.cast<String>() ?? [];

        return PrintOrderObj(
            title: json['title']?.toString() ?? '',
            items: items,
            total: json['total']?.toString() ?? '0.00',
            message: json['message']?.toString() ?? '',
            logoBase64: json['logoBase64']?.toString(),
            qrLink: json['qrLink']?.toString(),
            languageType: language,
            // 新增
            orderType: orderType,
            takeoutAddress: json['takeoutAddress']?.toString(),
            orderId: json['orderId']?.toString() ?? '',
            dateTime: json['dateTime']?.toString() ?? '',
            storeName: json['storeName']?.toString(),
            storeAddress: json['storeAddress']?.toString(),
            tableNumber: json['tableNumber']?.toString(),
            customerName: json['customerName']?.toString(),
            phoneNumber: json['phoneNumber']?.toString(),
            paymentMethod: json['paymentMethod']?.toString() ?? '',
            taxAmount: json['taxAmount']?.toString(),
            discount: json['discount']?.toString(),
            serverName: json['serverName']?.toString(),
            thanksMessage: json['thanksMessage']?.toString() ?? '感谢光临！',
        );
    }

    /// ================================
    /// 语言类型解析
    /// ================================
    static PrintLanguageType _parseLanguageType(dynamic value) {
        if (value == null) return PrintLanguageType.cn;
        final str = value.toString().toLowerCase();
        return switch (str) {
            'en' => PrintLanguageType.en,
            'ja' => PrintLanguageType.ja,
            _ => PrintLanguageType.cn,
        };
    }

    // 新增：订单类型解析
    static OrderType _parseOrderType(dynamic value) {
        if (value == null) return OrderType.dineIn;
        final str = value.toString().toLowerCase();
        return switch (str) {
            'takeout' => OrderType.takeout,
            _ => OrderType.dineIn,
        };
    }
}
