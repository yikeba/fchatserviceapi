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