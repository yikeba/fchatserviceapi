import 'dart:convert';

import 'package:fchatapi/FChatApiSdk.dart';
import 'package:fchatapi/appapi/BaseJS.dart';
import 'package:fchatapi/appapi/GpsApi.dart';
import 'package:fchatapi/appapi/NotificationApi.dart';
import 'package:fchatapi/appapi/TranslateApi.dart';
import 'package:http/http.dart' as http;
import 'package:fchatapi/appapi/PayObj.dart';
import 'package:fchatapi/appapi/PrintOrderApi.dart';
import 'package:fchatapi/appapi/PromoObj.dart';
import 'package:fchatapi/appapi/ScanApi.dart';
import 'package:fchatapi/util/PhoneUtil.dart';
import 'package:fchatapi/util/Tools.dart';
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

import 'WebApp/WebPage/ShortUrl.dart';

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
    FChatBridge.init();
    FChatBridge.onMessage.listen((msg) {
      PhoneUtil.applog("💬 来自 fChat app JS 的消息: $msg");
    });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12.0, // 按钮之间的水平间距
          runSpacing: 12.0, // 行之间的垂直间距
          alignment: WrapAlignment.start,
          children: [
            _buildButton('选择文件', pickFile),
            _buildButton('选择图片', pickImage),
            _buildButton('读取目录', readmd),

            _buildButton('读取列表', readmdthb),
            _buildButton('列表信息', readmdthbinfo),
            _buildButton('删除文件', delfile),

            _buildButton('App支付', paytest),
            _buildButton('网页支付', webpaytest),
            _buildButton('扫二维码', scanQr),

            _buildButton('获取GPS', () => getgps("gps")),
            _buildButton('获取地图', () => getgps("map")),
            _buildButton('web地图', () => getgps("map")),

            _buildButton('获取优惠', getPromo),

            _buildButton('打印订单', creatPrintOrderObjDemo),
            _buildButton('消息推送', creatpushDemo),
            _buildButton('短连接', creatShortUrl),
            _buildButton('翻译数据', readTra),
            _buildButton('打开grab', openGrabFromWeb)
          ],
        ),
      ),
    );
  }

  readTra(){
     TranslateApi("").read((value){
        PhoneUtil.applog("读取app翻译数据,返回$value");
     });
  }

  creatShortUrl() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) {
      return const ShortLinkGenerator();
    }));
  }

  // 🔍 反向地理编码 - 免费版（无需API Key）
  Future<String> _reverseGeocode(String lat, String lng) async {
    try {
      // 使用免费的 Nominatim 服务
      final url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=zh";

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'MyApp/1.0'}, // Nominatim 必须有 User-Agent
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      print("地理编码失败: $e");
    }

    // ❌ 失败时返回你的预定义地址
    if (lat == "11.3588653") {
      return "奥林匹克体育场, 金边, 柬埔寨";
    } else if (lat == "11.521379") {
      return "金边市中心, 金边, 柬埔寨";
    }

    return "未知位置";
  }


  Future<void> openGrabFromWeb() async {
    const pickupLat = "11.521379";
    const pickupLng = "104.912914";
    const destLat = "11.3588653";
    const destLng = "104.9309222";

    const grabUrl = "grab://open?screenType=BOOKING&pickup=$pickupLat,$pickupLng&dropoff=$destLat,$destLng";
    const grabIOSUrl = grabUrl;
    const grabWebsite = "https://www.grab.com/";

    final userAgent = html.window.navigator.userAgent.toLowerCase();
    String address= await _reverseGeocode(destLat,destLng);
    Tools.showSnackbar(context, "定位地址$address");
    Tools.Copytext(context, address);

    if (userAgent.contains("android")) {
      // ✅ Android 尝试直接打开 Grab
      html.window.location.href = grabUrl;
    } else if (userAgent.contains("iphone") ||
        userAgent.contains("ipad") ||
        userAgent.contains("macintosh")) {
      // 🍎 iOS 受限，只能跳 App Store
      html.window.location.href = grabIOSUrl;
    } else {
      // 💻 其他平台跳 Grab 官网
      html.window.location.href = grabWebsite;
    }
  }


// 抽取按钮的公共方法
  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 3 - 12, // 3列布局，减去padding和spacing
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
  static Future<void> creatPrintOrderObjDemo() async {
    // 英文订单(支持，中文，日文，英文)
    PrintOrderObj neworder=PrintOrderObj(
      title: "Test Order",
      items: ["Milk x2  \$4.00", "Bread x1  \$2.50"],
      total: "total: \$6.50",
      message: "Please provide an extra set of tableware", // 无留言
      logoBase64: "",   //图片base64
      qrLink: "fchat.us/app/fchat?downapp", // 无二维码
      languageType: PrintLanguageType.en,
    );
    PrintOrderApi(neworder).print((value){
      print("app打印端返回$value");
    });

  }

  static Future<void> creatpushDemo() async {
    PrintOrderObj neworder=PrintOrderObj(
      title: "Test Order",
      items: ["牛奶 x2  \$4.00", "Bread x1  \$2.50"],
      total: "total: \$6.50",
      message: "Please provide an extra set of tableware,明天会更好", // 无留言
      logoBase64: "",   //图片base64
      qrLink: "https://fchat.us/app/fchat?downapp", // 无二维码
      languageType: PrintLanguageType.en,
    );
    List<String> userarr=['1564043'];
    PushOrderObj pushOrderObj=PushOrderObj(
      "4765223",
      userarr,
      '熊猫餐厅订单通知',
      '你的咖啡与商务套餐已经制作完毕，编号801,用餐愉快',
      Tools.generateRandomString(20),    //实际支付订单id
      "app json merchant data--json data",     //商户或用户的自行业务逻辑数据（建议不超过1k）
    );
    pushOrderObj.tts="你有一个新的订单，李先生外卖功夫熊猫套餐，10美元，咖啡商务套餐请及时处理";  //自定义语音提示播放(可选)
    pushOrderObj.printOrder=neworder;   //自定义打印小票（可选）
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
    }else {
      GpsApi().getMapgps((value) {
        PhoneUtil.applog("获取地图显示，返gps$value");
      });
    }
  /*  GpsApi().showMapgps(11.34234,105.3432,(value) {
      PhoneUtil.applog("获取地图显示，返gps$value");
    });*/
  }

  sendnotification(String title,String body){
    if(FChatApiSdk.isFchatBrower) {
      NotificationApi(title, body).send((value) {
        PhoneUtil.applog("返回通知是否成功：$value");
      });
    }else{
      Tools.showSnackbar(context, "需要在app 环境下执行发送通知");
    }
  }

  gettraanslate(String str){
    //这个翻译是启用app的第二代翻译类，所有翻译将放到服务器进行缓存，当新客户需要翻译就是app直接返回结果
    //同步效果会好于第一代翻译
    if(FChatApiSdk.isFchatBrower) {
      TranslateApi(str).send((value) {
        PhoneUtil.applog("返回翻译结果：$value");
      });
    }else{
      Tools.showSnackbar(context, "需要在app 环境下完成翻译");
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