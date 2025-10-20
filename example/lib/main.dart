import 'package:fchatapi/FChatApiSdk.dart';
import 'package:fchatapi/appapi/GpsApi.dart';
import 'package:fchatapi/appapi/LoginFChat.dart';
import 'package:fchatapi/appapi/PayObj.dart';
import 'package:fchatapi/appapi/PromoObj.dart';
import 'package:fchatapi/appapi/ScanApi.dart';
import 'package:fchatapi/util/PhoneUtil.dart';
import 'package:fchatapi/webapi/FileObj.dart';
import 'package:fchatapi/webapi/PushOrder/PrintObj.dart';
import 'package:fchatapi/webapi/PushOrder/PushOrderObj.dart';
import 'package:fchatapi/webapi/PushOrder/PushUtil.dart';
import 'package:fchatapi/webapi/StripeUtil/WebPayUtil.dart';
import 'package:fchatapi/webapi/WebUItools.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:universal_html/html.dart' as html;

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    initload();
  }

  String userid="";
  String token = "";
  initload() {
    userid = dotenv.get('userid');
    token = dotenv.get('token');
    FChatApiSdk.init(userid, token, (webstate) {
      PhoneUtil.applog("fchat web api 返回状态$webstate");
    }, (appstate) {
      PhoneUtil.applog("app login  返回状态$appstate");
    });
  }

  String? selectedFileName;
  String? selectedFilePath;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      if (kIsWeb) {
        final fileBytes = result.files.first.bytes;
        html.File file = result.files.first.bytes != null
            ? html.File([result.files.first.bytes!], result.files.first.name)
            : result.files.first as html.File;
        FChatApiSdk.fileobj.filemd=FileMD.video;
        FChatApiSdk.fileobj.writeFile(file, (value) {
          print("File 上传访问状态: $value");
        });
        print('本地 File Name: $selectedFileName');
        print('本地 File Size: ${fileBytes?.length} bytes');
      } else {
        print('File Path: $selectedFilePath');
      }

    } else {
      setState(() {
        selectedFileName = null;
        selectedFilePath = null;
      });
    }
  }

  Future<void> readmd() async {
    FChatApiSdk.filearrobj.readMD((value) {
      print("读取文件目录返回文件对象数量:${value.length}");
    }, md: "assetsmd");
  }

  Future<void> delfile() async {
    FChatApiSdk.filearrobj.readMDthb((value) {
      for (String str in value) {
        String name=str.replaceAll("$userid/", "");
        print("删除指定文件名称路径:$name");
        FChatApiSdk.fileobj.delFile(name, (data) {
          print("指定文件删除完毕$name,状态$data");
        });
        break;
      }
    }, md: "assetsmd");
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> readmdthb() async {
    int index = 0;
    int endindex = 0;
    _showLoadingDialog();
    FChatApiSdk.filearrobj.readMDthb((value) {
      for (String str in value) {
        index++;
        print("读取服务器原始路径:$str");
        String name=str.replaceAll("$userid/", "");
        print("读取文件明显名称:$name");
        FChatApiSdk.fileobj.readFile(name, (data) {
          PhoneUtil.applog("读取指定文件内容:${data}");
          endindex++;
          if (endindex == index) {
            Navigator.of(context).pop();
          }
        });
      }
    }, md: "assetsmd");
  }

  Future<void> readmdthbinfo() async {
    _showLoadingDialog();
    FChatApiSdk.filearrobj.readMDthb((value) {
      for (String str in value) {
        String name=str.replaceAll("$userid/", "");
        print("读取文件明显名称:$name");
      }
      Navigator.of(context).pop();
    }, md: "assetsmd");
  }

  Future<void> pickImage() async {
    try {
      final pickedImage = await ImagePickerWeb.getImageAsFile();
      String? _fileName;
      if (pickedImage != null) {
        FChatApiSdk.fileobj.filemd=FileMD.image;
        FChatApiSdk.fileobj.writeFile(pickedImage, (value) {
          print("File 上传访问状态: $value");
        });
        setState(() {
          _fileName = pickedImage.name;
        });
        print("File Name: $_fileName");
        print("Image Size: ${pickedImage.size} bytes");
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  paytest(){
    PayObj pay=PayObj();
    pay.amount="0.05";
    pay.paytext="测试支付";
    pay.pay((value){
       print("app 支付返回结果$value");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FChat Api'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("选择Pick a File"),
            ),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("选择图片文件"),
            ),
            ElevatedButton(
              onPressed: readmd,
              child: const Text("读取文件目录"),
            ),
            ElevatedButton(
              onPressed: readmdthb,
              child: const Text("读取文件列表"),
            ),
            ElevatedButton(
              onPressed: readmdthbinfo,
              child: const Text("读取文件列表信息"),
            ),
            ElevatedButton(
              onPressed: delfile,
              child: const Text("删除文件"),
            ),
            ElevatedButton(
              onPressed: paytest,
              child: const Text("app支付"),
            ),
            ElevatedButton(
              onPressed: webpaytest,
              child: const Text("网页支付"),
            ),
            ElevatedButton(
              onPressed: scanQr,
              child: const Text("扫二维码"),
            ),
            ElevatedButton(
              onPressed: (){
                getgps("gps");
              },
              child: const Text("获取gps"),
            ),
            ElevatedButton(
              onPressed: (){
                getgps("map");
              },
              child: const Text("获取地图"),
            ),
            ElevatedButton(
              onPressed: getPromo,
              child: const Text("获取优惠"),
            ),
            const ElevatedButton(
              onPressed: creatPrintOrderObjDemo,
              child: Text("创建打印小票订单"),
            ),
            const ElevatedButton(
              onPressed: creatpushDemo,
              child: Text("创建消息推送机制"),
            ),
          ],
        ),
      ),
    );
  }
  static Future<PrintOrderObj> creatPrintOrderObjDemo() async {
    // 英文订单(支持，中文，日文，英文)
    return PrintOrderObj(
      title: "Test Order",
      items: ["Milk x2  \$4.00", "Bread x1  \$2.50"],
      total: "total: \$6.50",
      message: "Please provide an extra set of tableware", // 无留言
      logoBase64: "",   //图片base64
      qrLink: "fchat.us/app/fchat?downapp", // 无二维码
      languageType: PrintLanguageType.en,
    );
  }

  static Future<void> creatpushDemo() async {
      PrintOrderObj printobj=await creatPrintOrderObjDemo();
      PushOrderObj pushOrderObj=PushOrderObj(
         "4765223",
         "4444444",
         "payid",    //实际支付订单id
         "data",     //商户或用户的自行业务逻辑数据（建议不超过1k）
      );
      pushOrderObj.tts="你有一个新的订单，请及时处理";  //自定义语音提示播放(可选)
      pushOrderObj.printOrder=printobj;   //自定义打印小票（可选）
      PushUtil.creatPushOrder(pushOrderObj);  //创建并发送

  }



  getPromo(){
    PromoApi().receive((value){
      PhoneUtil.applog("获得服务号发行的优惠券 str:$value");
    });
    PromoApi().receiveObj((proobj){
      if(proobj==null){
        PhoneUtil.applog("获得优惠券错误null");
        return;
      }
      PhoneUtil.applog("获得服务号发行的优惠券${proobj.toJson()}");
      PromoApi papi=PromoApi();
      papi.promObj=proobj;
      papi.del((state){  //删除优惠券（核销优惠券）

      });

    });

  }
  getgps(String type){
    if(type=="gps") {
      GpsApi().getgps((value) {
        PhoneUtil.applog("获取客户gps位置$value");
      });
    }else{
      GpsApi().getMapgps((value) {
        PhoneUtil.applog("获取地图显示，返gps$value");
      });
    }
  }

  scanQr(){
    Scanapi().scan((value){
       PhoneUtil.applog("扫码返回内容$value");
    });
  }
  webpaytest(){
     if(WebPayUtil.isLocCard()){
       WebUItools.opencardlist(context,null,null);
     }else {
       WebUItools.openWebpay(context,null,null);
     }
  }
}