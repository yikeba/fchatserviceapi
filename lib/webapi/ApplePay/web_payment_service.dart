@JS()
library stripe_js_interop;

import 'package:js/js.dart';

// 假设这些函数已在您的 JS 脚本中定义 (见 Step 3)
@JS('initApplePayStripe')
external void initApplePayStripe(
    String publishableKey,
    int totalAmount,
    String currency,
    String country,
    String containerId,
    // Dart 回调函数需要使用 allowInterop 包装
    Function onSuccess,
    Function onFailure, String clientSecret,
    );

// 示例：包装 Dart 回调函数
typedef PaymentSuccessCallback = void Function(String paymentIntentId);
typedef PaymentFailureCallback = void Function(String errorMessage);

// 您的主逻辑中调用：
void setupApplePay(
    String pubKey,
    int amount,
    PaymentSuccessCallback onSuccess,
    PaymentFailureCallback onFailure,
    String clientSecret // 假设 clientSecret 已从后端获取
    ) {
  initApplePayStripe(
    pubKey,
    amount,
    'USD',
    'US',
    'apple-pay-container', // 您的 HTML 容器 ID
    allowInterop((paymentIntentId) {
      onSuccess(paymentIntentId);
    }),
    allowInterop((errorMessage) {
      onFailure(errorMessage);
    }),
    clientSecret, // 传递 clientSecret 给 JS
  );
}