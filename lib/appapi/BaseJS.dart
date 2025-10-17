import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import '../util/PhoneUtil.dart';

class BaseJSObj {
  static final StreamController<String> _fchatstreamobj = StreamController.broadcast();

  static void apiRecdatainit() {
    html.window.onMessage.listen((event) {
      final message = event.data;
      try {
        _fchatstreamobj.add(message["data"]);
      } catch (e) {
        PhoneUtil.applog("Fchat api err $e, message$message");
      }
    });
  }

  static Future<StreamSubscription<String>> sendtoFChat(
      String json, void Function(String recdata) fchatrec) async {
    await js.context.callMethod("sendtoFChat", [json]);
    // 返回一个订阅对象，调用者可以手动管理
    return _fchatstreamobj.stream.listen((value) {
      fchatrec(value);
    });
  }
}



class BaseJS {
  // 单例实例
  static final BaseJS _instance = BaseJS._internal();
  factory BaseJS() => _instance;
  BaseJS._internal();

  // 广播流控制器
  final StreamController<String> _fchatStream = StreamController<String>.broadcast();
  bool _isInitialized = false;
  // 订阅池，用于跟踪和管理订阅
  final Map<String, StreamSubscription<String>> _subscriptions = {};

  // 初始化消息监听
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    html.window.onMessage.listen((event) {
      final message = event.data;
      try {
        if (message != null && message.containsKey('data') && message['data'] is String) {
          _fchatStream.add(message['data']);
          //PhoneUtil.applog('BaseJS received message data: ${message['data']}');
        } else {
          //PhoneUtil.applog('BaseJS invalid message format: $message');
        }
      } catch (e) {
        PhoneUtil.applog('BaseJS error: $e, message: $message');
      }
    });
    PhoneUtil.applog('BaseJS initialized');
  }

  // 发送消息并返回订阅，关联 actionid
  Future<StreamSubscription<String>> sendFChat({
    required String json,
    required String actionid,
    required void Function(String recdata) onReceive,
  }) async {
    try {
      await js.context.callMethod('sendtoFChat', [json]);
      //PhoneUtil.applog('BaseJS sent message: $json');
      // 取消之前的订阅（如果存在）
      _subscriptions[actionid]?.cancel();
      _subscriptions.remove(actionid);

      // 创建新订阅
      final subscription = _fchatStream.stream.listen((value) {
        //PhoneUtil.applog('BaseJS stream received for actionid $actionid: $value');
        onReceive(value);
      });

      // 保存订阅
      _subscriptions[actionid] = subscription;
      //PhoneUtil.applog('BaseJS active subscriptions: ${_subscriptions.length}');

      // 在订阅完成或取消时清理
      subscription.onDone(() {
        _subscriptions.remove(actionid);
        //PhoneUtil.applog('BaseJS subscription removed for actionid $actionid, remaining: ${_subscriptions.length}');
      });

      return subscription;
    } catch (e) {
      PhoneUtil.applog('BaseJS failed to send message: $e');
      rethrow;
    }
  }

  // 清理特定 actionid 的订阅
  void cancelSubscription(String actionid) {
    _subscriptions[actionid]?.cancel();
    _subscriptions.remove(actionid);
    PhoneUtil.applog('BaseJS subscription cancelled for actionid $actionid, remaining: ${_subscriptions.length}');
  }

  // 清理所有订阅
  void cancelAllSubscriptions() {
    _subscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
    PhoneUtil.applog('BaseJS all subscriptions cancelled');
  }

  // 清理资源
  void dispose() {
    cancelAllSubscriptions();
    _fchatStream.close();
    PhoneUtil.applog('BaseJS disposed');
  }
}