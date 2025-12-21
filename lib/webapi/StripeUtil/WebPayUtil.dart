import 'package:dio/dio.dart';
import 'package:fchatapi/webapi/PayHtmlObj.dart';

import '../../Util/JsonUtil.dart';
import '../../Util/PhoneUtil.dart';
import '../../util/DateUtil.dart';
import '../../util/UserObj.dart';
import '../Bank/MoneyApi.dart';
import '../HttpWebApi.dart';
import '../WebCommand.dart';
import 'CookieStorage.dart';

class WebPayUtil{

   static bool isLocCard(){  //判断本地是否保存信用卡
     String? cardinfo=CookieStorage.getCookie("fchat.card");
     if(cardinfo==null) return false;
     return true;
   }
   static void delCard(){  //判断本地是否保存信用卡
     CookieStorage.deleteFromStorage("fchat.card");
   }


   static Future<bool> isQuery_payID(String payid) async {
       Map map={};
       map.putIfAbsent("payid", ()=> payid);
       map.putIfAbsent("userid", ()=> UserObj.userid);
       Map<String,dynamic>sendmap=getDataMap(map,WebCommand.payidQuery);
       String rec=await httpFchatserver(sendmap);
       RecObj robj=RecObj(rec);
      // PhoneUtil.applog("返回查询支付流水单状态$rec");
       if(robj.json.containsKey(payid) && robj.json.containsKey("status")){
          return robj.json["status"];
       }
       return false;
   }

   static Future<VerifyPayObj> isverifyPay(String? sessionId,String? payid) async {
     //b必须有一个不能是null
     VerifyPayObj verifyPayObj=VerifyPayObj();
     if (sessionId == null && payid == null) {
        return verifyPayObj;
     }
     sessionId ?? "";
     payid ?? "";
     Map map={};
     map.putIfAbsent("payid", ()=> payid);
     map.putIfAbsent("sessionid", ()=> sessionId);
     Map<String,dynamic>sendmap=getDataMap(map,WebCommand.verifyPay);
     String rec=await httpFchatserver(sendmap);
     RecObj robj=RecObj(rec);

     if(robj.json.containsKey("payrec")) {
       String payrec = robj.json["payrec"];
       Map paymap=JsonUtil.strtoMap(payrec);
       if(paymap.containsKey("payment_intent")){
         verifyPayObj.paymentIntentId=paymap["payment_intent"];
         //PhoneUtil.applog("stripe 订单id ${verifyPayObj.paymentIntentId}");
       }
       if(robj.json.containsKey("bank")) {
         Map bank = robj.json["bank"];
         //PhoneUtil.applog("支付流水单银行信息$bank");
         verifyPayObj.bank=bank["name"];
       }else{
         verifyPayObj.detectPaymentProvider(paymap);
       }
      /* if(verifyPayObj.bank=="stripe"){
         PhoneUtil.applog("支付机构的回调信息，在这里获取id${robj.json}");
       }*/
       if (robj.json.containsKey("payid")) {
         if (payid!.isEmpty) payid = robj.json["payid"];
       } else {
         return verifyPayObj;
       }
     }
     verifyPayObj.payid=payid!;
     verifyPayObj.ispay=false;
     if(robj.json.containsKey("status")){
       verifyPayObj.ispay= robj.json["status"];
     }
     return verifyPayObj;
   }
   //通过payid 返回支付对象
   static Future<PayHtmlObj> getPayHtmlObj(String payid) async {
     Map map={};
     map.putIfAbsent("payid", ()=> payid);
     map.putIfAbsent("userid", ()=> UserObj.userid);
     Map<String,dynamic>sendmap=getDataMap(map,WebCommand.payidQuery);
     String rec=await httpFchatserver(sendmap);
     RecObj robj=RecObj(rec);
    // PhoneUtil.applog("返回查询支付流水单状态$rec");
     return PayHtmlObj.fromJson(robj.json);
   }

   static readstripekey() async {
     Map<String,dynamic>sendmap=getDataMap({},WebCommand.readstripekey);
     String rec=await httpFchatserver(sendmap);
     RecObj robj=RecObj(rec);
    // PhoneUtil.applog("读取stripe key 参数${robj.data}");
     return robj.data;
   }

   static Future<Map> getWebcreateWebPaymentIntent(PayHtmlObj pobj) async {
     Map map={};
     map.putIfAbsent("amount",()=> JsonUtil.getmoneyint(pobj.money));
     map.putIfAbsent("currency", ()=> "usd");
     Map<String,dynamic>sendmap= getDataMap(map,WebCommand.createWebPaymentIntent);
     //这里是否有bug
     String rec=await httpFchatserver(sendmap);
     RecObj robj=RecObj(rec);
     PhoneUtil.applog("返回web 调用支付申请${robj.json}");
     return robj.json;
   }

   static Map<String, dynamic> getDataMap(Map sendmap,String command) {
     Map<String, dynamic> map = {};
     map.putIfAbsent("userid", () => UserObj.userid);
     map.putIfAbsent("command", () => command);
     String data=JsonUtil.maptostr(sendmap);
     data=JsonUtil.setbase64(data);
     map.putIfAbsent("data", ()=>data);
     return map;
   }

   static Future<String> httpFchatserver(Map<String,dynamic> map) async {
     FormData formData = FormData.fromMap(map);
     String url = HttpWebApi.geturl();
     String authHeader = 'Bearer ${UserObj.servertoken}'; // 设置 Bearer Token
     try {
       Dio dio = Dio();
       Future<Response> res = dio.post(
         url,
         options: Options(
           sendTimeout: const Duration(minutes: 10),
           receiveTimeout: const Duration(minutes:  10),
           method: "POST",
           headers: {
             'Content-Type': 'multipart/form-data',
             "Authorization": authHeader
           },
         ),
         data: formData,
         onReceiveProgress: (int received, int total) {

         },
       );
       return res.then((value) {
         try {
           if (value.statusCode == 200) {
             return value.data.toString();
           } else {
             PhoneUtil.applog("返回类型：${value.data}");
           }
         } catch (e) {
           PhoneUtil.applog("返回错误value 错误$e");
         }
         return "err";
       });
     } on DioError catch (dioError) {
       print("识别到 DioError catch: ${dioError.message}");

     }
     return "err";
   }


}

class VerifyPayObj{
   String payid="";
   bool ispay=false;
   String bank="";
   String paymentIntentId="";  //stripe订单的id
   String status="";  //stripe 状态字符串
   StripeOrderStatus? orderStatus;
   /// 判断支付回调所属机构：ABA PayWay 或 Stripe
   ///
   /// [payrec] 订单表中 payrec 字段的原始字符串（JSON 或拼接格式）
   /// 返回 'aba' | 'stripe' | 'unknown'
   String detectPaymentProvider(Map data) {
     if (data == null || data.isEmpty) {
       bank='null';
       return 'null';
     }
     // === ABA PayWay 判断 ===
     if (data.containsKey('apv') &&
         data.containsKey('tran_id') &&
         data['payment_status'] == 'APPROVED' &&
         data['status'] == 0) { // status 可能是 int 0 或 string "0"，Dart 会自动相等
       bank='aba';
       //PhoneUtil.applog("aba 支付金额$data");
       final withdrawalOrder = WithdrawalOrder.fromBankPayment(data);
       orderStatus= StripeOrderStatus(
           paid: true,
           available: withdrawalOrder.canWithdraw,
           availableOn: withdrawalOrder.withdrawAvailableTimestampMs,
           net: withdrawalOrder.getMoney(),
           fee: 0,
           currency: "USD",
           statusMessage: data['payment_status'],
           remainingSeconds: 0);
       orderStatus!.bank=bank;
       return 'aba';
     }
     // === Stripe 判断（特征最明显，先判）===
     if ((data['object'] == 'checkout.session'
         || data['object'] == 'payment_intent') &&
         ( data['status'] == 'complete') || data["status"]=="succeeded") {
       bank='stripe';
       status= data["status"];
       return 'stripe';
     }
     PhoneUtil.applog("fChat Pay支付验证状态$data");
     Map dcobj=data["dcobj"];
     orderStatus= StripeOrderStatus(
         paid: true,
         available: true,
         availableOn: DateUtil.getUTCint(),
         net: JsonUtil.getmoneyint(data["money"]),
         fee: 0,
         currency: dcobj["currency"],
         statusMessage: "fChat Pay",
         remainingSeconds: 0);
     bank='fChat Pay';
     orderStatus!.bank=bank;
     return 'fChat Pay';
   }
}


class WithdrawalOrder {
  final double amount;
  final String tranId;
  final int paymentTimestampMs;      // 支付时间戳
  final int withdrawAvailableTimestampMs;  // 延后一天时间戳
  final bool canWithdraw;            // 当前是否可提现
  final String paymentDatetime;
  int money=0;
  WithdrawalOrder({
    required this.amount,
    required this.tranId,
    required this.paymentTimestampMs,
    required this.withdrawAvailableTimestampMs,
    required this.canWithdraw,
    required this.paymentDatetime,
  });

  /// 从银行支付反馈 Map 转换生成提现订单
  factory WithdrawalOrder.fromBankPayment(Map payment) {
    final String dtStr = payment['datetime'];
    final DateTime paymentDt = DateTime.parse(dtStr.replaceAll(' ', 'T')); // 处理格式
    final int paymentTs = paymentDt.millisecondsSinceEpoch;

    final int delayMs = 1440 * 60 * 1000; // 1天
    final int availableTs = paymentTs + delayMs;
    // 当前时间（这里用 DateTime.now()，实际运行时自动获取）
    final bool canWithdrawNow = DateTime.now().millisecondsSinceEpoch > availableTs;

    return WithdrawalOrder(
      amount: (payment['amount'] as num).toDouble(),
      tranId: payment['tran_id'] as String,
      paymentTimestampMs: paymentTs,
      withdrawAvailableTimestampMs: availableTs,
      canWithdraw: canWithdrawNow,
      paymentDatetime: dtStr,
    );
  }

  int getMoney(){
    return JsonUtil.getmoneyint(amount.toString());
  }

  @override
  String toString() {
    return '''
提现订单:
  订单ID: $tranId
  金额: \$${amount.toStringAsFixed(2)}
  支付时间: $paymentDatetime (时间戳: $paymentTimestampMs)
  可提现时间: ${DateTime.fromMillisecondsSinceEpoch(withdrawAvailableTimestampMs)} (时间戳: $withdrawAvailableTimestampMs)
  当前状态: ${canWithdraw ? '可提现' : '等待延后一天'}
''';
  }
}