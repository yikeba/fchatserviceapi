import 'package:fchatapi/Login/OpenAppHtml.dart';
import 'package:fchatapi/Util/PhoneUtil.dart';
import 'package:fchatapi/util/QuickAlertShow.dart';
import 'package:fchatapi/util/Tools.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../FChatApiSdk.dart';
import '../Util/JsonUtil.dart';
import '../webapi/WebUtil.dart';
import 'FChatApiObj.dart';

class OpenUser{
  static String addchathtml="";
  ApiObj? aobj;
  String userid="";
  String name="";
  String type="";
  String action="open";
  BuildContext context;
  OpenUser(this.context,this.userid,this.name);
  openuser(void Function(String recdata) state){
    aobj?.dispose();
    if(userid.isEmpty) return;
    if (FChatApiSdk.isFchatBrower) {
      this.userid = userid;
      this.type = type;
      aobj = ApiObj(ApiName.openUser, (value) {
        state(value);
      });
      aobj!.setData(toString());
    }else{
    /*  QuickAlertShow.showinfo(context, "fChat APP", "需要在fChat环境下打开,继续跳转到下载页面").then((value){
         if(value=="ok"){
           WebUtil.openfchatweb();
         }else{
           state("err");
         }
      });*/

    }
  }

  close(void Function(String recdata) state){
    aobj?.dispose();
    if (FChatApiSdk.isFchatBrower) {
      aobj = ApiObj(ApiName.openUser, (value) {
        state(value);
      });
      action = "close";
      aobj!.setData(toString());
    }else{
      AppLauncher.handleAddChat(context, userid, (value){
        state(value);
      });
    }
  }

  _getJson(){
    if(type.isEmpty) type="user";
    Map map={};
    map.putIfAbsent("userid", ()=> userid);
    map.putIfAbsent("type", ()=> type);
    map.putIfAbsent("action", ()=>action);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }
}