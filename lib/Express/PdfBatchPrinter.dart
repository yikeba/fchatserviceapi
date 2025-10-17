import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:js' as js;

class PdfBatchPrinter {
  /// 批量打印多个 PDF（支持UI进度）
  static Future<void> printBatch(
      BuildContext context,
      List<String> urls, {
        void Function(String message)? onProgress,
      }) async {
    if (urls.isEmpty) {
      print("没有需要打印的PDF。");
      return;
    }

    final limitedUrls = urls.take(20).toList();
    print("开始打印 ${limitedUrls.length} 个 PDF 文件...");

    for (int i = 0; i < limitedUrls.length; i++) {
      final url = limitedUrls[i];
      final msg = "正在打印第 ${i + 1}/${limitedUrls.length} 个文件...";
      print(msg);
      onProgress?.call(msg);

      _showLoadingDialog(context, msg);

      await _printSinglePdf(url);

      // 关闭等待框
      Navigator.of(context, rootNavigator: true).pop();

      await Future.delayed(const Duration(seconds: 1));
    }

    print("✅ 所有PDF已打印完成。");
    onProgress?.call("✅ 所有PDF已打印完成");
  }

  static void printDirectly(String pdfUrl) {
    // 打开一个新窗口显示 PDF（必须同步执行）
    final newWindow = html.window.open(pdfUrl, '_blank');

    // 延迟 1 秒等待 PDF 加载（根据文件大小可调整）
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 使用 JS 调用打印（必须直接操作新窗口）
        js.context.callMethod('eval', [
          'var w = window.open("$pdfUrl"); setTimeout(() => { w.print(); }, 1000);'
        ]);
      } catch (e) {
        print("打印调用失败: $e");
      }
    });
  }

  /// 打印单个 PDF（解决 .focus/.print 报红问题）
  static Future<void> _printSinglePdf(String url) async {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.display = 'none';

    html.document.body?.append(iframe);

    await iframe.onLoad.first;

    final win = iframe.contentWindow;
    if (win != null) {
      // 通过 JS 调用 focus() 与 print()
      await js_util.promiseToFuture(js_util.callMethod(win, 'focus', []));
      await js_util.promiseToFuture(js_util.callMethod(win, 'print', []));
    }

    // 延迟删除 iframe
    Future.delayed(const Duration(seconds: 3), () {
      iframe.remove();
    });
  }

  /// 显示加载框
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Flexible(child: Text(message, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}


class PdfPrinter {
  static void printDirectly(String pdfUrl) {
    // 打开一个新窗口显示 PDF（必须同步执行）
    final newWindow = html.window.open(pdfUrl, '_blank');

    // 延迟 1 秒等待 PDF 加载（根据文件大小可调整）
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 使用 JS 调用打印（必须直接操作新窗口）
        js.context.callMethod('eval', [
          'var w = window.open("$pdfUrl"); setTimeout(() => { w.print(); }, 1000);'
        ]);
      } catch (e) {
        print("打印调用失败: $e");
      }
    });
  }
}