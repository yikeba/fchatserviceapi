import 'package:fchatapi/appapi/FChatApiObj.dart';
import 'package:fchatapi/util/JsonUtil.dart';
import 'package:fchatapi/util/PhoneUtil.dart';
import 'package:fchatapi/util/UserObj.dart';
import 'dart:html' as html;

import '../Util/Tools.dart';
import '../util/DateUtil.dart';

class PayObj{
  String amount="";
  String paytext="";
  int moneyint=0;
  ApiObj? aobj;
  String payurl="";
  String _payid="";
  String _order="";
  PayObj({String order=""}){
    _payid=Tools.generateRandomString(10)+DateUtil.getUTCint().toRadixString(32);
    _order=order;
  }
  pay(void Function(String recdata) fchatpay){
    aobj?.dispose();
    if(amount.isEmpty) return;
    moneyint=JsonUtil.getmoneyint(amount);
    PhoneUtil.applog("支付金额转换为:$moneyint");
    if(moneyint<0) return ;
    PhoneUtil.applog("开始进行app支付调起");
    aobj=ApiObj(ApiName.pay,(value){
      if(value=="err"){
         PhoneUtil.applog("环境不在FChat,吊起本地app");
         _startpay();
      }
      fchatpay(value);
    });
    aobj!.setData(toString());
  }

  void _startpay(){
    String base64=aobj!.toString();
    base64=JsonUtil.setbase64(base64);
    PhoneUtil.applog("获得app唤起支付参数$base64");
    base64=Uri.decodeComponent(base64);
    String url="freepay://freechat/startpage?pay=";
    url=url+base64;
    html.window.location.href=url;
  }

  getPayid()=> _payid;

  _getJson(){
    Map map={};
    map.putIfAbsent("amount", ()=> amount);
    map.putIfAbsent("money", ()=>moneyint);
    map.putIfAbsent("paytext", ()=> paytext);
    map.putIfAbsent("recuser", ()=>UserObj.userid);
    map.putIfAbsent("payurl", ()=> payurl);
    map.putIfAbsent("payid", ()=> _payid);
    if(_order.isNotEmpty)map.putIfAbsent("order", ()=> _order);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }

}


