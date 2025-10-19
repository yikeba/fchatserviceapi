
import '../../util/MediaUtil.dart';

enum PrintLanguageType {
    cn,
    en,
    ja,
}

class PrintOrderObj {
    final String title;
    final List<String> items;
    final String total;
    final String message;
    final String? logoBase64;
    final String? qrLink;
    final PrintLanguageType languageType;

    PrintOrderObj({
        required this.title,
        required this.items,
        required this.total,
        this.message = '',
        String? logoBase64,
        this.qrLink,
        this.languageType = PrintLanguageType.cn,
    }) : logoBase64 = _compressLogoBase64(logoBase64);

    /// 压缩 logoBase64 如果超过 2KB
    static String? _compressLogoBase64(String? logoBase64) {
        if (logoBase64 != null && logoBase64.length > 2048) {
            final zipped = MediaUtil.getBase64zip(logoBase64);
            return zipped ?? logoBase64; // 压缩失败返回原 logoBase64
        }
        return logoBase64;
    }

    /// ================================
    /// JSON 序列化
    /// ================================
    Map<String, dynamic> toJson() {

        return {
            'title': title,
            'items': items,
            'total': total,
            'message': message,
            'logoBase64': logoBase64,
            'qrLink': qrLink,
            'languageType': languageType.name,
        };
    }

    /// ================================
    /// JSON 反序列化
    /// ================================
    static PrintOrderObj fromJson(Map<String, dynamic> json) {
        final language = _parseLanguageType(json['languageType']);
        final items = (json['items'] as List?)?.cast<String>() ?? [];

        return PrintOrderObj(
            title: json['title']?.toString() ?? '',
            items: items,
            total: json['total']?.toString() ?? '',
            message: json['message']?.toString() ?? '',
            logoBase64: json['logoBase64']?.toString(),
            qrLink: json['qrLink']?.toString(),
            languageType: language,
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
}