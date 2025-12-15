import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../../Util/PhoneUtil.dart';

class WebStripePayment {
  static const String PUBLISHABLE_KEY = 'pk_test_YOUR_KEY'; // ⚠️ 替换为您的 Stripe 可发布密钥

  /// Web 平台使用 Stripe.js 完成支付
  static Future<bool> processWebPayment({
    required String clientSecret,
    required String merchantName,
  }) async {
    try {
      PhoneUtil.applog("🌐 Web 支付流程开始");

      // 检查 Stripe.js 是否加载
      if (js.context['Stripe'] == null) {
        PhoneUtil.applog("❌ Stripe.js 未加载，请确保在 index.html 中添加了 <script src='https://js.stripe.com/v3/'></script>");
        return false;
      }

      // 调用 JavaScript 处理支付
      final result = await _callStripeJS(clientSecret, merchantName);

      PhoneUtil.applog("✅ Web 支付完成: $result");
      return result;

    } catch (e) {
      PhoneUtil.applog("❌ Web 支付异常: $e");
      return false;
    }
  }

  /// 通过 JS 互操作调用 Stripe Payment Request API
  static Future<bool> _callStripeJS(String clientSecret, String merchantName) async {
    try {
      // 创建 Promise 包装器
      final completer = Completer<bool>();

      // 注入 JavaScript 代码
      js.context.callMethod('eval', ['''
        (async function() {
          try {
            // 初始化 Stripe
            const stripe = Stripe('$PUBLISHABLE_KEY');
            
            // 创建 Payment Request (支持 Google Pay / Apple Pay)
            const paymentRequest = stripe.paymentRequest({
              country: 'US',
              currency: 'usd',
              total: {
                label: '$merchantName',
                amount: 1000, // 这个会被后续覆盖
              },
              requestPayerName: true,
              requestPayerEmail: true,
            });

            // 检查是否可以使用 Google Pay / Apple Pay
            const result = await paymentRequest.canMakePayment();
            
            if (!result) {
              window.stripePaymentResult = { success: false, error: 'Google Pay/Apple Pay 不可用' };
              return;
            }

            console.log('✅ 检测到支付方式:', result);

            // 监听支付方法选择
            paymentRequest.on('paymentmethod', async (ev) => {
              try {
                // 使用 client_secret 确认支付
                const {error: confirmError} = await stripe.confirmCardPayment(
                  '$clientSecret',
                  {payment_method: ev.paymentMethod.id},
                  {handleActions: false}
                );

                if (confirmError) {
                  ev.complete('fail');
                  window.stripePaymentResult = { success: false, error: confirmError.message };
                } else {
                  ev.complete('success');
                  window.stripePaymentResult = { success: true };
                }
              } catch (err) {
                ev.complete('fail');
                window.stripePaymentResult = { success: false, error: err.message };
              }
            });

            // 显示支付界面
            paymentRequest.show();

          } catch (error) {
            console.error('Stripe 支付错误:', error);
            window.stripePaymentResult = { success: false, error: error.message };
          }
        })();
      ''']);

      // 轮询等待结果（最多 60 秒）
      int attempts = 0;
      while (attempts < 120) { // 120 * 500ms = 60秒
        await Future.delayed(Duration(milliseconds: 500));

        final result = js.context['stripePaymentResult'];
        if (result != null) {
          final success = js.context['stripePaymentResult']['success'];
          js.context.deleteProperty('stripePaymentResult'); // 清理
          return success == true;
        }

        attempts++;
      }

      PhoneUtil.applog("⏱️ 支付超时");
      return false;

    } catch (e) {
      PhoneUtil.applog("❌ JS 调用异常: $e");
      return false;
    }
  }
}