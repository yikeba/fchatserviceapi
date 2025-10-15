
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
/// PDF 批量打印工具类（Flutter Web）
class PdfBatchPrinter {
  /// 打印多个 PDF 链接（一次最多20个）
  static Future<void> printBatch(List<String> urls) async {
    if (urls.isEmpty) {
      print("没有需要打印的PDF。");
      return;
    }

    // 限制最大数量
    final limitedUrls = urls.take(20).toList();
    print("开始打印 ${limitedUrls.length} 个 PDF 文件...");

    for (int i = 0; i < limitedUrls.length; i++) {
      final url = limitedUrls[i];
      print("准备打印第 ${i + 1}/${limitedUrls.length} 个：$url");

      await _printSinglePdf(url);

      // 等待2秒，避免浏览器阻塞或打印冲突
      await Future.delayed(const Duration(seconds: 2));
    }

    print("✅ 所有PDF已提交打印任务。");
  }

  /// 打印单个 PDF 链接
  static Future<void> _printSinglePdf(String url) async {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.display = 'none';

    html.document.body?.append(iframe);
    await iframe.onLoad.first;
    final dynamic win = iframe.contentWindow;
    win?.focus();
    win?.print();

    // 打印完成后延迟删除 iframe，避免崩溃
    Future.delayed(const Duration(seconds: 3), () {
      iframe.remove();
    });
  }

  static Future<void> openPdfFromUrl(String pdfUrl) async {
    try {
      // 下载 PDF 内容
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // 生成 Blob 对象
        final blob = html.Blob([bytes], 'application/pdf');

        // 生成临时 URL
        final url = html.Url.createObjectUrlFromBlob(blob);

        // 打开新标签页预览 PDF
        html.window.open(url, '_blank');

        // 延迟释放 URL
        Future.delayed(const Duration(seconds: 5), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        print('下载 PDF 失败: ${response.statusCode}');
      }
    } catch (e) {
      print('打开 PDF 出错: $e');
    }
  }

}





