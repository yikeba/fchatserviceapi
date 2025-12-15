import 'dart:html' as html;
import 'dart:js';
import 'dart:async';

class ApplePayWebInjector {
  static const String _injectorId = 'applepay-stripe-script';
  static const String _stripeJsId = 'stripe-js-v3';

  // Apple Pay 配置
  static const String MERCHANT_ID = 'merchant.fchat.village';
  static const String DOMAIN_NAME = 'fchat.win';
  static const String STRIPE_PUBLISHABLE_KEY = 'pk_live_51Qi91LLARWDrZ1N9qJaZOE5wvlTa6RMHicmQ3JHs9tgARMEIQRQvTxTkGrabgx8gegyEiROLLHRAJPwDEfVywOot0043AXsuQ0';

  // 防止重复加载的标志
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;

  // ------------------------- Apple Pay JS 逻辑 -------------------------

  static String get _customJsLogic {
    return '''
      (function() {
        'use strict';
        
        // 防止重复初始化
        if (window.ApplePayHandler) {
          console.log('⚠️ [Apple Pay] Handler 已存在');
          return;
        }

        window.ApplePayHandler = {
          stripeInstance: null,
          clientSecret: null,

          init: function(publishableKey, 
              totalAmount, 
              currency, 
              country, 
              containerId, 
              successCallback, 
              failureCallback,
              currentClientSecret,
              merchantName) {
              
              console.log('🍎 [Apple Pay] 初始化...', {
                  amount: totalAmount,
                  currency: currency,
                  country: country,
                  container: containerId
              });

              // 检查 Stripe
              if (typeof Stripe === 'undefined') {
                  console.error('❌ [Apple Pay] Stripe.js 未加载');
                  failureCallback('Stripe.js not loaded');
                  return;
              }
              
              // 初始化 Stripe（只初始化一次）
              if (!this.stripeInstance) {
                  try {
                      this.stripeInstance = Stripe(publishableKey);
                      console.log('✅ [Apple Pay] Stripe 实例创建成功');
                  } catch (e) {
                      console.error('❌ [Apple Pay] Stripe 初始化失败:', e);
                      failureCallback('Stripe init failed: ' + e.message);
                      return;
                  }
              }
              
              this.clientSecret = currentClientSecret;

              // 检查容器
              const container = document.getElementById(containerId);
              if (!container) {
                  console.error('❌ [Apple Pay] 容器未找到:', containerId);
                  failureCallback('Container not found');
                  return;
              }

              // 创建 Payment Request
              const paymentRequest = this.stripeInstance.paymentRequest({
                  country: country.toUpperCase(),
                  currency: currency.toLowerCase(),
                  total: {
                      label: merchantName || 'Payment',
                      amount: totalAmount, 
                  },
                  requestPayerName: true,
                  requestPayerEmail: true,
              });

              console.log('✅ [Apple Pay] Payment Request 创建完成');

              // 检查可用性
              const self = this;
              paymentRequest.canMakePayment().then(function(result) {
                  console.log('🔍 [Apple Pay] 可用性:', result);
                  
                  if (result) {
                      console.log('✅ [Apple Pay] 可用，创建按钮');
                      
                      const elements = self.stripeInstance.elements();
                      const prButton = elements.create('paymentRequestButton', {
                          paymentRequest: paymentRequest,
                          style: {
                              paymentRequestButton: { 
                                  type: 'buy',
                                  theme: 'dark',
                                  height: '48px'
                              },
                          },
                      });

                      container.innerHTML = '';
                      prButton.mount('#' + containerId);
                      console.log('✅ [Apple Pay] 按钮已挂载');

                      // 支付事件
                      paymentRequest.on('paymentmethod', async function(ev) {
                          console.log('💳 [Apple Pay] 用户授权，PaymentMethod:', ev.paymentMethod.id);

                          try {
                              const {paymentIntent, error: confirmError} = 
                                  await self.stripeInstance.confirmCardPayment(
                                      self.clientSecret,
                                      { payment_method: ev.paymentMethod.id },
                                      { handleActions: false }
                                  );

                              if (confirmError) {
                                  console.error('❌ [Apple Pay] 确认失败:', confirmError);
                                  ev.complete('fail');
                                  failureCallback(confirmError.message || 'Payment failed');
                              } else {
                                  console.log('✅ [Apple Pay] 状态:', paymentIntent.status);
                                  
                                  if (paymentIntent.status === 'requires_action') {
                                      console.log('⚠️ [Apple Pay] 需要额外验证');
                                      const {error: actionError} = 
                                          await self.stripeInstance.confirmCardPayment(self.clientSecret);
                                      
                                      if (actionError) {
                                          console.error('❌ [Apple Pay] 验证失败:', actionError);
                                          ev.complete('fail');
                                          failureCallback(actionError.message);
                                      } else {
                                          console.log('🎉 [Apple Pay] 支付成功');
                                          ev.complete('success');
                                          successCallback(paymentIntent.id);
                                      }
                                  } else if (paymentIntent.status === 'succeeded') {
                                      console.log('🎉 [Apple Pay] 支付成功');
                                      ev.complete('success');
                                      successCallback(paymentIntent.id);
                                  } else {
                                      console.warn('⚠️ [Apple Pay] 未知状态:', paymentIntent.status);
                                      ev.complete('fail');
                                      failureCallback('Unexpected status: ' + paymentIntent.status);
                                  }
                              }
                          } catch (err) {
                              console.error('💥 [Apple Pay] 异常:', err);
                              ev.complete('fail');
                              failureCallback(err.message || 'Error');
                          }
                      });

                      paymentRequest.on('cancel', function() {
                          console.log('🚫 [Apple Pay] 用户取消');
                      });

                  } else {
                      console.warn('❌ [Apple Pay] 不可用');
                      container.innerHTML = '<div style="padding:12px;text-align:center;color:#999;font-size:13px;">此设备不支持 Apple Pay</div>';
                      failureCallback('Apple Pay not available');
                  }
              }).catch(function(err) {
                  console.error('❌ [Apple Pay] 检查失败:', err);
                  failureCallback('Check failed: ' + err.message);
              });
          },

          check: function(publishableKey, callback) {
              console.log('🔍 [Apple Pay] 快速检查可用性');
              
              if (typeof Stripe === 'undefined') {
                  console.error('❌ [Apple Pay] Stripe.js 未加载');
                  callback(false);
                  return;
              }

              if (!this.stripeInstance) {
                  try {
                      this.stripeInstance = Stripe(publishableKey);
                  } catch (e) {
                      console.error('❌ [Apple Pay] 初始化失败:', e);
                      callback(false);
                      return;
                  }
              }

              const pr = this.stripeInstance.paymentRequest({
                  country: 'US',
                  currency: 'usd',
                  total: { label: 'Test', amount: 100 },
              });

              pr.canMakePayment().then(function(result) {
                  const ok = result !== null && result !== false;
                  console.log(ok ? '✅ [Apple Pay] 可用' : '❌ [Apple Pay] 不可用');
                  callback(ok);
              }).catch(function() {
                  console.error('❌ [Apple Pay] 检查失败');
                  callback(false);
              });
          }
        };

        // 向后兼容
        window.initApplePayStripe = function() {
          return window.ApplePayHandler.init.apply(window.ApplePayHandler, arguments);
        };
        window.checkApplePayAvailable = function() {
          return window.ApplePayHandler.check.apply(window.ApplePayHandler, arguments);
        };

        console.log('✅ [Apple Pay] Handler 已就绪');
      })();
    ''';
  }

  /// 完整初始化（推荐使用这个方法）
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ [Apple Pay] 已初始化，跳过');
      return;
    }

    if (_initCompleter != null) {
      print('⏳ [Apple Pay] 正在初始化，等待...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      print('🚀 [Apple Pay] 开始初始化');

      // 1. 加载 Stripe.js
      await _loadStripeJs();

      // 2. 等待 Stripe.js 完全加载
      await _waitForStripe();

      // 3. 注入自定义脚本
      _injectCustomScript();

      _isInitialized = true;
      _initCompleter!.complete();
      print('✅ [Apple Pay] 初始化完成');

    } catch (e) {
      print('❌ [Apple Pay] 初始化失败: $e');
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// 加载 Stripe.js
  static Future<void> _loadStripeJs() async {
    // 检查是否已存在
    if (html.document.getElementById(_stripeJsId) != null) {
      print('✅ [Apple Pay] Stripe.js 标签已存在');
      return;
    }

    // 检查全局对象
    try {
      if (context['Stripe'] != null) {
        print('✅ [Apple Pay] Stripe 全局对象已存在');
        return;
      }
    } catch (_) {}

    print('⏳ [Apple Pay] 加载 Stripe.js');

    final completer = Completer<void>();

    final script = html.ScriptElement()
      ..src = 'https://js.stripe.com/v3/'
      ..id = _stripeJsId
      ..async = true;

    script.onLoad.listen((_) {
      print('✅ [Apple Pay] Stripe.js 加载完成');
      completer.complete();
    });

    script.onError.listen((_) {
      print('❌ [Apple Pay] Stripe.js 加载失败');
      completer.completeError('Failed to load Stripe.js');
    });

    html.document.head!.children.add(script);

    await completer.future.timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('⏱️ [Apple Pay] Stripe.js 加载超时');
        throw TimeoutException('Stripe.js load timeout');
      },
    );
  }

  /// 等待 Stripe 对象可用
  static Future<void> _waitForStripe() async {
    print('⏳ [Apple Pay] 等待 Stripe 对象...');

    for (int i = 0; i < 20; i++) {
      try {
        if (context['Stripe'] != null) {
          print('✅ [Apple Pay] Stripe 对象已就绪');
          return;
        }
      } catch (_) {}

      await Future.delayed(Duration(milliseconds: 100));
    }

    throw Exception('Stripe object not available after 2 seconds');
  }

  /// 注入自定义脚本
  static void _injectCustomScript() {
    if (html.document.getElementById(_injectorId) != null) {
      print('⚠️ [Apple Pay] 自定义脚本已存在');
      return;
    }

    print('📝 [Apple Pay] 注入自定义脚本');

    final script = html.ScriptElement()
      ..text = _customJsLogic
      ..id = _injectorId
      ..type = 'text/javascript';

    html.document.head!.children.add(script);

    print('✅ [Apple Pay] 自定义脚本注入完成');
  }

  /// 兼容旧的调用方式
  @Deprecated('Use initialize() instead')
  static void ensureStripeJs() {
    if (html.document.getElementById(_stripeJsId) == null) {
      _loadStripeJs();
    }
  }

  @Deprecated('Use initialize() instead')
  static void injectScripts() {
    if (html.document.getElementById(_injectorId) == null) {
      _injectCustomScript();
    }
  }
}