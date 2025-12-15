import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;
import 'dart:async';

import '../StripeUtil/WebPayUtil.dart';
import 'ApplePayWebInjector.dart';

// 导入你的 ApplePayWebInjector

class ApplePayButtonWidget extends StatefulWidget {
  final dynamic pobj; // 你的支付对象
  final String currency; // 货币
  final String merchantName; // 商户名
  final Function(String paymentIntentId) onSuccess;
  final Function(String error) onFailure;

  const ApplePayButtonWidget({
    Key? key,
    required this.pobj,
    this.currency = 'USD',
    this.merchantName = 'FChat Store',
    required this.onSuccess,
    required this.onFailure,
  }) : super(key: key);

  @override
  State<ApplePayButtonWidget> createState() => _ApplePayButtonWidgetState();
}

class _ApplePayButtonWidgetState extends State<ApplePayButtonWidget> {
  final String _containerId = 'applepay-${DateTime.now().millisecondsSinceEpoch}';
  late final String _viewType;

  bool _isLoading = true;
  bool _isAvailable = false;
  bool _buttonCreated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'applepay-view-$_containerId';
    _init();
  }

  Future<void> _init() async {
    try {
      print('🍎 [Widget] 初始化开始');
      // 1. 初始化 ApplePayWebInjector
      await ApplePayWebInjector.initialize();
      // 2. 注册视图
      _registerView();
      // 3. 检查可用性
      await _checkAvailable();
      setState(() => _isLoading = false);
      // 4. 如果可用，创建按钮
      if (_isAvailable && !_buttonCreated) {
        await Future.delayed(Duration(milliseconds: 300));
        await _createButton();
      }

    } catch (e, stack) {
      print('❌ [Widget] 初始化失败: $e');
      print('Stack: $stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _registerView() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
          (int viewId) => html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '48px',
    );
    print('✅ [Widget] 视图已注册: $_containerId');
  }

  Future<void> _checkAvailable() async {
    final completer = Completer<bool>();
    try {
      print('🔍 [Widget] 检查可用性');

      js.context.callMethod('checkApplePayAvailable', [
        ApplePayWebInjector.STRIPE_PUBLISHABLE_KEY,
        js.allowInterop((bool ok) {
          if (!completer.isCompleted) completer.complete(ok);
        }),
      ]);

      _isAvailable = await completer.future.timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ [Widget] 检查超时');
          return false;
        },
      );

      print(_isAvailable ? '✅ [Widget] 可用' : '❌ [Widget] 不可用');

    } catch (e) {
      print('❌ [Widget] 检查失败: $e');
      _isAvailable = false;
    }
  }

  Future<void> _createButton() async {
    if (_buttonCreated) return;
    try {
      print('💳 [Widget] 创建按钮');

      // 获取 Payment Intent
      final pi = await WebPayUtil.getWebcreateWebPaymentIntent(widget.pobj);
      if (pi == null) throw Exception('Payment Intent is null');

      final secret = pi['client_secret'] as String?;
      if (secret == null || secret.isEmpty) {
        throw Exception('Invalid client_secret');
      }

      print('✅ [Widget] Client Secret: ${secret.substring(0, 20)}...');

      // 调用 JS
      final cents = widget.pobj;
      final country = _getCountry(widget.currency);

      print('🎬 [Widget] 调用 initApplePayStripe');

      js.context.callMethod('initApplePayStripe', [
        ApplePayWebInjector.STRIPE_PUBLISHABLE_KEY,
        cents,
        widget.currency.toLowerCase(),
        country,
        _containerId,
        js.allowInterop(_onSuccess),
        js.allowInterop(_onFailure),
        secret,
        widget.merchantName,
      ]);

      _buttonCreated = true;
      print('✅ [Widget] 按钮创建完成');

    } catch (e, stack) {
      print('❌ [Widget] 创建按钮失败: $e');
      print('Stack: $stack');
      _onFailure('创建失败: $e');
    }
  }

  void _onSuccess(String piId) {
    print('🎉 [Widget] 支付成功: $piId');
    widget.onSuccess(piId);
  }

  void _onFailure(String err) {
    print('❌ [Widget] 失败: $err');
    if (err.toLowerCase().contains('not available')) {
      setState(() => _isAvailable = false);
    } else {
      widget.onFailure(err);
    }
  }

  String _getCountry(String curr) {
    const map = {
      'USD': 'US', 'CNY': 'CN', 'EUR': 'FR', 'GBP': 'GB',
      'JPY': 'JP', 'KHR': 'KH', 'SGD': 'SG',
    };
    return map[curr.toUpperCase()] ?? 'US';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null) {
      return const SizedBox.shrink(); // 不显示
    }

    if (!_isAvailable) {
      return const SizedBox.shrink(); // 不显示
    }

    return SizedBox(
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

// ============== 使用示例 ==============

class CheckoutPage extends StatelessWidget {
  final dynamic pobj;

  const CheckoutPage({Key? key, required this.pobj}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('支付')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 订单信息
            Text('订单金额: \$99.99', style: TextStyle(fontSize: 20)),

            SizedBox(height: 40),

            // Apple Pay 按钮
            ApplePayButtonWidget(
              pobj: pobj,
              currency: 'USD',
              merchantName: 'FChat Store',
              onSuccess: (piId) {
                print('支付成功: $piId');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('支付成功！'), backgroundColor: Colors.green),
                );
                // 跳转到成功页面
              },
              onFailure: (err) {
                print('支付失败: $err');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('支付失败: $err'), backgroundColor: Colors.red),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}