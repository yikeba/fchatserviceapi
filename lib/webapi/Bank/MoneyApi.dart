import '../../Util/PhoneUtil.dart';
import '../HttpWebApi.dart';
import '../StripeUtil/WebPayUtil.dart';
import '../WebCommand.dart';
import 'package:intl/intl.dart'; // 用于格式化日期和金额，可选


class MoneyApi{
  //订单资金读取
  static Future<Map> ordermoney() async {
    Map map={};
    map.putIfAbsent("action", ()=> "order");
    Map<String,dynamic>sendmap=WebPayUtil.getDataMap(map,WebCommand.moneymanagement);
    String rec=await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj=RecObj(rec);
    return robj.json;

  }

  static Future<Map> isSettlement(String payid) async {
    Map map={};
    map.putIfAbsent("action", ()=> "payorder");
    map.putIfAbsent("payid", ()=> payid);
    Map<String,dynamic>sendmap=WebPayUtil.getDataMap(map,WebCommand.moneymanagement);
    String rec=await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj=RecObj(rec);
    return robj.json;

  }

  static Future<Map> insterSettlement(String payid) async {
    Map map={};
    map.putIfAbsent("action", ()=> "insert");
    map.putIfAbsent("payid", ()=> payid);
    Map<String,dynamic>sendmap=WebPayUtil.getDataMap(map,WebCommand.moneymanagement);
    String rec=await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj=RecObj(rec);
    return robj.json;

  }

  static Future<StripeOrderStatus> selectStripeID(String paymentIntentId) async {
    Map map={};
    map.putIfAbsent("action", ()=> "select");
    map.putIfAbsent("paymentIntentId", ()=> paymentIntentId);
    Map<String,dynamic>sendmap=WebPayUtil.getDataMap(map,WebCommand.moneymanagement);
    String rec=await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj=RecObj(rec);
    return StripeOrderStatus.fromMap(robj.json);

  }

  //对支付订单进行提现操作
  static Future<String> cashPayID(String payid) async {
    Map map={};
    map.putIfAbsent("action", ()=> "cash");
    map.putIfAbsent("payid", ()=> payid);
    Map<String,dynamic>sendmap=WebPayUtil.getDataMap(map,WebCommand.moneymanagement);
    String rec=await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj=RecObj(rec);
    return robj.data;

  }

}


class StripeOrderStatus {
  final bool paid;
  final bool available;
  final int availableOn; // Unix 时间戳（秒）
  final int net; // 实际到手金额（单位：分）
  final int fee; // 手续费（单位：分）
  final String currency;
  final String statusMessage;
  final int remainingSeconds;
  String bank="stripe";
  StripeOrderStatus({
    required this.paid,
    required this.available,
    required this.availableOn,
    required this.net,
    required this.fee,
    required this.currency,
    required this.statusMessage,
    required this.remainingSeconds,
  });

  static int _safeAvailableOnToMs(dynamic availableOnRaw) {
    if (availableOnRaw == null) return 0;

    final int value = availableOnRaw is int ? availableOnRaw : int.tryParse(availableOnRaw.toString()) ?? 0;
    // 判断位数：如果已经是 13 位（毫秒级），直接返回
    // 13 位时间戳大致范围：1000000000000 ~ 9999999999999
    // 10 位时间戳大致范围：1000000000 ~ 9999999999
    if (value > 99999999999) { // 大于 10 位最大值（9999999999）的 10 倍，即一定是毫秒
      return value;
    }
    // 否则认为是秒级，转换为毫秒
    return value * 1000;
  }

  /// 从 Map（通常是 JSON）解析构造对象
  factory StripeOrderStatus.fromMap(Map map) {
    final int availableOnMs = _safeAvailableOnToMs(map['availableOn']);
    return StripeOrderStatus(
      paid: map['paid'] as bool? ?? false,
      available: map['available'] as bool? ?? false,
      availableOn: availableOnMs,
      net: map['net'] as int? ?? 0,
      fee: map['fee'] as int? ?? 0,
      currency: (map['currency'] as String?)?.toUpperCase() ?? 'USD',
      statusMessage: map['statusMessage'] as String? ?? '',
      remainingSeconds: map['remainingSeconds'] as int? ?? 0,
    );
  }

  /// 是否已经支付成功
  bool get isPaid => paid;

  /// 是否已经到账到 Stripe 余额（可用余额）
  bool get isAvailable => available;

  /// 是否资金已完全可用（可用于提现）
  bool get isFundsAvailableForPayout =>
      available && remainingSeconds == 0;

  /// 到账时间（DateTime）
  DateTime get availableDate =>
      DateTime.fromMillisecondsSinceEpoch(availableOn, isUtc: true);

  /// 格式化的到账时间字符串（如：2025-12-06 16:00）
  String get formattedAvailableDate =>
      DateFormat('yyyy-MM-dd HH:mm').format(availableDate.toLocal());

  /// 手续费（格式化，如 $1.08）
  String get formattedFee =>
      _formatAmount(fee, currency);

  /// 实际到手金额（格式化，如 $18.82）
  String get formattedNetAmount =>
      _formatAmount(net, currency);

  /// 总金额（net + fee）
  int get totalAmount => net + fee;
  String get formattedTotalAmount =>
      _formatAmount(totalAmount, currency);

  /// 当前订单状态描述（适合直接显示给用户或商户）
  String get statusDescription {
    if (!paid) return '未支付';
    if (!available) return '支付成功，等待资金到账';
    if (remainingSeconds > 0) return '支付成功，资金结算中';
    return '已到账，可提现';
  }

  /// 通道手续费率（例如：5.4%）
  String get feeRate {
    if (totalAmount == 0) return '0%';
    final rate = (fee / totalAmount) * 100;
    return '${rate.toStringAsFixed(2)}%';
  }

  /// 辅助方法：金额格式化
  String _formatAmount(int amountInCents, String curr) {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: _getCurrencySymbol(curr),
      decimalDigits: 2,
    );
    return format.format(amountInCents / 100);
  }

  String _getCurrencySymbol(String curr) {
    switch (curr.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CNY':
        return '¥';
      default:
        return '$curr ';
    }
  }

  /// 可选：toString 方便调试
  @override
  String toString() {
    return '''
StripeOrderStatus:
  状态: $statusDescription
  支付: ${paid ? '成功' : '失败'}
  到账: ${available ? '已到账 ($formattedAvailableDate)' : '未到账'}
  总金额: $formattedTotalAmount
  手续费: $formattedFee ($feeRate)
  到手金额: $formattedNetAmount
  消息: $statusMessage
''';
  }
}