import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../Util/UIxml.dart';

class Chatmeqrlink extends StatefulWidget {
  final String qrdata;
  final String showstr;
  final double size; // 控制二维码大小参数，默认350（适中）

  const Chatmeqrlink({
    super.key,
    required this.qrdata,
    required this.showstr,
    this.size = 350.0, // 默认350，平衡尺寸与空白
  });

  @override
  _meQR createState() => _meQR();
}

class _meQR extends State<Chatmeqrlink> {
  GlobalKey globalKey = GlobalKey();
  String name = "";
  String linkurl = "";
  String linkid = "";
  ImageProvider? circularImage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {});
  }

  @override
  Widget build(BuildContext context) {
    // 根据size计算嵌入图片大小（比例降到0.15，更小不干扰，且默认居中）
    final embeddedSize = Size(widget.size * 0.15, widget.size * 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 15),
        // Stack 用于头像悬浮在二维码卡片上方
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 二维码卡片
            Container(
              width: widget.size + 40, // 减小宽度，减少整体空白（+左右padding*2）
              margin: const EdgeInsets.only(top: 40), // 留出头像空间
              padding: EdgeInsets.all(widget.size * 0.06), // 外padding减小到0.06（~21px for 350），控制安静区
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(widget.size * 0.12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: widget.size * 0.06,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(widget.size * 0.03), // 内padding减小到0.06
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.size * 0.08),
                  border: Border.all(
                    color: Colors.white,
                    width: widget.size * 0.01, // 边框宽度减小到0.02（~7px），减少空白
                  ),
                ),
                child: QrImageView(
                  data: widget.qrdata,
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                  size: widget.size,
                  gapless: true,
                 /* embeddedImage: _getimage(),
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: embeddedSize, // 缩小到0.15比例，默认居中（qr_flutter内置逻辑）
                  ),*/
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size * 0.1),
        Text(
          widget.showstr,
          style: TextStyle(
            fontSize: widget.size * 0.08,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: widget.size * 0.1),
      ],
    );
  }

  _getimage() {
    return const AssetImage("packages/fchatapi/assets/img/free.png"); // fallback
  }
}