import 'package:fchatapi/Util/PhoneUtil.dart';
import 'package:fchatapi/util/Translate.dart';

import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class TranslateApi{
  //从app获取可以下载的端口和ip
  ApiObj? _aobj;
  String text;
  TranslateApi(this.text);
  send(void Function(String recdata) fchatsend){
    _aobj?.dispose();
    _aobj=ApiObj(ApiName.translate,(value){
      fchatsend(value);
    });
    _aobj!.setData(toString());
  }

  read(void Function(String recdata) fchatsend){
    _aobj?.dispose();
    _aobj=ApiObj(ApiName.readtranslate,(value){
      Map rec=JsonUtil.strtoMap(value);
      PhoneUtil.applog("读取app翻译记录${rec.length},数据key${rec.keys.first}");
      if(rec.containsKey("tra")){
         String trastr=rec["tra"];
         List tralist=JsonUtil.strotList(trastr);
         Translate.translateList.addAll(tralist);
         PhoneUtil.applog("读取app翻译记录${tralist.length}");
      }
      fchatsend("ok");
    });
    _aobj!.setData("");
  }

  _getJson(){
    Map map={};
    map.putIfAbsent("text", ()=> text);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }
}