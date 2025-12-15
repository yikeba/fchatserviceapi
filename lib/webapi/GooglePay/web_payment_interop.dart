// web_payment_interop.dart - 修正后的版本 (移除 PaymentHandler 类和实例导出)

import 'dart:js_interop';
import 'package:flutter/foundation.dart';

// ----------------------------------------------------------------
// A. Dart 调用 JS 的函数 (External Functions) - 保持不变
// ----------------------------------------------------------------

@JS('launchGooglePay')
external void launchGooglePayJS(double totalPrice, String currencyCode);

@JS('launchApplePay')
external void launchApplePayJS(double totalPrice, String currencyCode, String countryCode);

@JS('isApplePayAvailable')
external bool isApplePayAvailableJS();


// ----------------------------------------------------------------
// B. JS 调用 Dart 的回调：新的全局函数导出 (代替 PaymentHandler 类)
// ----------------------------------------------------------------

// 1. 定义 Dart 内部使用的回调逻辑
void _handleSuccess(String paymentData, String provider) {
  debugPrint('Payment Success via $provider: $paymentData');
  //这里收到支付token 发送stripe 进行支付处理


}

void _handleError(String errorMessage) {
  debugPrint('Payment Error: $errorMessage');
  // TODO: 这里是您显示错误信息的地方
}


// 2. 声明 JS 全局函数：用于设置回调 (Callback Setters)
// 我们将 Dart 函数包装成 JSAny后，通过这些 setter 传递给 JS
@JS('setPaymentSuccessCallback')
external set _setSuccessCallback(JSAny callback);

@JS('setPaymentErrorCallback')
external set _setErrorCallback(JSAny callback);


/// 负责初始化 Dart/JS 桥接
/// 作用：将 Dart 的回调逻辑（_handleSuccess, _handleError）导出到 JS 全局。
void initializePaymentInterop() {
  // 重点：将 Dart 函数包装成 JS 可调用的函数 (.toJS)
  final successCallback = ((String data, String provider) {
    _handleSuccess(data, provider);
  }).toJS;

  final errorCallback = ((String message) {
    _handleError(message);
  }).toJS;

  // 重点：通过 setter 导出这些包装后的函数
  _setSuccessCallback = successCallback;
  _setErrorCallback = errorCallback;
}