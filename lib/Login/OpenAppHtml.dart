
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../Util/PhoneUtil.dart';
import '../util/QuickAlertShow.dart';
import '../webapi/WebUtil.dart';

class AppLauncher {
  static Future<void> handleAddChat(BuildContext context, String userId, Function(String) state) async {
    final addChatUrl = "freepay://freechat/startpage?user=$userId";
    const timeout = Duration(seconds: 3);
    final startTime = DateTime.now().millisecondsSinceEpoch;
    // 标记是否已显示提示框，避免重复
    bool hasShownPrompt = false;
    Future<void> showPrompt() async {
      if (!hasShownPrompt && context.mounted) {
        hasShownPrompt = true;
        final value = await QuickAlertShow.showinfo(context, "fChat APP", "需要在fChat环境下打开,继续跳转到下载页面");
        if (value == "ok") {
          WebUtil.openfchatweb();
        } else {
          state("err");
        }
      }
    }
    try {
      bool launched=false;
      Timer(timeout, () {  // 如果 launched 为 true，启动 3 秒延时检查
        if (DateTime.now().millisecondsSinceEpoch - startTime < 3100 && context.mounted) {
          if(!launched) {
            showPrompt();
          }
        }
      });
      // 尝试打开 App 使用 DOM 操作
      PhoneUtil.applog("准备开始唤起app$addChatUrl");
      launched = await _tryLaunchApp(addChatUrl);
      PhoneUtil.applog("打开app的返回结果$launched");
      if (!launched) {
        await showPrompt();
        return; // 避免重复触发延时逻辑
      }
    } catch (e) {
      print('Error launching URL: $e');
      await showPrompt();
    }
  }

  static Future<bool> _tryLaunchApp(String url) async {
    try {
      final iframe = html.IFrameElement()
        ..style.display = 'none'
        ..src = url;
      // 监听 iframe 的错误事件
      final completer = Completer<bool>();
      iframe.onError.listen((event) {
        PhoneUtil.applog('Iframe error: ${event.type}');
        completer.complete(false);
      });
      html.document.body?.append(iframe);
      Timer(const Duration(seconds: 3), () {
        try {
          iframe.remove();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        } catch (e) {
          PhoneUtil.applog('Error removing iframe: $e');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });
      return await completer.future;
    } catch (e) {
      print('Error creating iframe: $e');
      return false;
    }
  }
}



