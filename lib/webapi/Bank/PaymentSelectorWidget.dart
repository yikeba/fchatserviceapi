import 'package:fchatapi/webapi/PayHtmlObj.dart';
import 'package:fchatapi/webapi/WebUtil.dart';
import 'package:flutter/material.dart';

import '../../Util/PhoneUtil.dart';
import '../ApplePay/ApplePay.dart';

class PaymentSelectorWidget extends StatelessWidget {
  final Future<bool> Function()? onApplePay;
  final Future<bool> Function()? onGooglePay;
  final PayHtmlObj pobj;
  const PaymentSelectorWidget({
    super.key,
    required this.pobj,
    this.onApplePay,
    this.onGooglePay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //_buildApplePayButton(context),
        const SizedBox(height: 8),
        _buildGooglePayButton(context),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildApplePayButton(BuildContext context) {
    return  ApplePayButtonWidget(
      pobj: pobj,
      onSuccess: (paymentIntentId) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('支付成功！')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        //这里处理支付，需要增加
      },
      onFailure: (error) {
        print('❌ 支付失败回调: $error');

        // 显示失败提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('支付失败: $error')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      },
    );
  }


  Widget _oldbuildApplePayButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        PhoneUtil.applog("PayButton 开始呼叫Apple Pay"); // 保留您的日志
        if (onApplePay == null) return;
        bool ok = await onApplePay!.call();
        if (!ok) _showError(context, "当前设备不支持 Apple Pay");
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, color: Colors.white, size: 26),
            // **修改点 1: 增加 Apple Pay 图标与文字之间的间距 (从 8 增加到 12)**
            SizedBox(width: 12),
            Text(
              "Pay",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGooglePayButton(BuildContext context) {
    if(WebUtil.isSafari()){  //苹果浏览器不支持google pay 支付
      return const SizedBox.shrink();
    }
    return  InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          PhoneUtil.applog("PayButton 呼叫 Google Pay");
          if (onGooglePay == null) return;
          final ok = await onGooglePay!.call();
          if (!ok) {
            _showError(context, "当前设备不支持 Google Pay 或支付失败");
          }
        },
        child: Center(
          child: Image.asset(
            "assets/pay/googlepay.png",
            height: 28, // 官方推荐 Logo 高度区间
            fit: BoxFit.contain,
            package: "fchatapi",
            semanticLabel: "Google Pay",
          ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}