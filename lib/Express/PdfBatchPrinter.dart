import 'dart:convert';
import 'package:fchatapi/webapi/PrintSet.dart';
import 'package:http/http.dart' as http;

class PdfBatchPrinter {

  PdfBatchPrinter();
  /// 向本地打印服务发送PDF URL
  Future<bool> sendPrintRequest(String pdfUrl) async {
    final uri = Uri.parse('http://127.0.0.1:${PrintSet.printPort}');
    try {
      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': pdfUrl}),
      )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        print("✅ 打印任务已发送成功");
        return true;
      } else {
        print("⚠️ 打印服务返回错误: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ 无法连接打印服务 (http://127.0.0.1:${PrintSet.printPort}): $e");
      return false;
    }
  }

}
