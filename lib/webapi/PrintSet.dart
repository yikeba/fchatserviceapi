import 'package:fchatapi/util/Translate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrintSet{
  static int printPort=29999;



  static Future<void> showPrintPortDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(text: printPort.toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Translate.show("打印设置")),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
                LengthLimitingTextInputFormatter(5), // 限制最多5位
              ],
              decoration: InputDecoration(
                labelText: Translate.show("打印端口"),
                hintText: Translate.show("请输入 10000 - 65530 之间的端口号"),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Translate.show("端口不能为空");
                }
                final port = int.tryParse(value);
                if (port == null) {
                  return Translate.show("请输入数字");
                }
                if (port < 10000 || port > 65530) {
                  return Translate.show("端口号必须在 10000 - 65530 之间");
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translate.show("取消")),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  printPort = int.parse(controller.text);
                  Navigator.pop(context, printPort); // 返回输入的端口号
                }
              },
              child:  Text(Translate.show("确定")),
            ),
          ],
        );
      },
    );
  }


}