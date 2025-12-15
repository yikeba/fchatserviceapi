// GooglePayWebInjector.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class GooglePayWebInjector {
  // ------------------------- 商户配置 -------------------------

  // 仅用于 RELEASE
  static const String GOOGLE_MERCHANT_ID = 'BCR2DN7TVGRMHWSK';

  static const String GATEWAY_NAME = 'stripe';

  // ⚠️ Web + Stripe：通常不需要 gatewayMerchantId
  // 如无特殊要求，生产也可以不传
  static const String GATEWAY_MERCHANT_ID = '';

  // ------------------------- Script -------------------------

  static const String _googlePayScriptUrl =
      'https://pay.google.com/gp/p/js/pay.js';
  static const String _injectorId = 'gpay-injector-script';

  // ------------------------- JS 注入 -------------------------

  static String get _customJsLogic {
    final bool isRelease = kReleaseMode;

    final String environment = isRelease ? 'PRODUCTION' : 'TEST';

    /// merchantInfo：debug 不带 merchantId
    final String merchantInfoJs = isRelease
        ? '''
          merchantInfo: {
            merchantId: '$GOOGLE_MERCHANT_ID',
            merchantName: 'Your Flutter Store'
          },
        '''
        : '''
          merchantInfo: {
            merchantName: 'Test Flutter Store'
          },
        ''';

    /// tokenization：debug 不带 gatewayMerchantId
    final String tokenizationJs = isRelease &&
        GATEWAY_MERCHANT_ID.isNotEmpty
        ? '''
          tokenizationSpecification: {
            type: 'PAYMENT_GATEWAY',
            parameters: {
              gateway: '$GATEWAY_NAME',
              gatewayMerchantId: '$GATEWAY_MERCHANT_ID'
            }
          }
        '''
        : '''
          tokenizationSpecification: {
            type: 'PAYMENT_GATEWAY',
            parameters: {
              gateway: '$GATEWAY_NAME'
            }
          }
        ''';

    return '''
      // ==================== Google Pay Config ====================

      function getGooglePaymentsClient() {
        return new google.payments.api.PaymentsClient({
          environment: '$environment'
        });
      }

      function getGooglePayRequest(totalPrice, currencyCode) {
        return {
          apiVersion: 2,
          apiVersionMinor: 0,

          $merchantInfoJs

          allowedPaymentMethods: [{
            type: 'CARD',
            parameters: {
              allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
              allowedCardNetworks: ['VISA', 'MASTERCARD']
            },
            $tokenizationJs
          }],

          transactionInfo: {
            totalPriceStatus: 'FINAL',
            totalPrice: totalPrice.toString(),
            currencyCode: currencyCode
          }
        };
      }

      window.launchGooglePay = function(totalPrice, currencyCode) {
        const client = getGooglePaymentsClient();
        const request = getGooglePayRequest(totalPrice, currencyCode);

        client.loadPaymentData(request)
          .then(function(paymentData) {

            const token =
              paymentData.paymentMethodData &&
              paymentData.paymentMethodData.tokenizationData &&
              paymentData.paymentMethodData.tokenizationData.token;

            if (!token) {
              if (window._onPaymentError) {
                window._onPaymentError('Google Pay token missing');
              }
              return;
            }

            if (window._onPaymentSuccess) {
              window._onPaymentSuccess(token, 'GooglePay');
            }
          })
          .catch(function(err) {
            if (window._onPaymentError) {
              window._onPaymentError(
                err && err.message ? err.message : 'Google Pay Error'
              );
            }
          });
      };
    ''';
  }

  // ------------------------- 注入 -------------------------

  static void injectScripts() {
    if (html.document.getElementById(_injectorId) != null) return;

    final gpayScript = html.ScriptElement()
      ..src = _googlePayScriptUrl
      ..async = true;

    final customScript = html.ScriptElement()
      ..id = _injectorId
      ..text = _customJsLogic;

    html.document.head!.children.add(gpayScript);
    html.document.head!.children.add(customScript);

    debugPrint(
      'Google Pay injected (${kReleaseMode ? 'PRODUCTION' : 'TEST'})',
    );
  }
}
