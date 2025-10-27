import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class NotificationApi{

  //从app获取可以下载的端口和ip
  ApiObj? _aobj;
  String title;
  String body;

  NotificationApi(this.title,this.body);
  send(void Function(String recdata) fchatsend){
    _aobj?.dispose();
    _aobj=ApiObj(ApiName.notification,(value){
      fchatsend(value);
    });
    _aobj!.setData(toString());
  }

  _getJson(){
    Map map={};
    map.putIfAbsent("title", ()=> title);
    map.putIfAbsent("body", ()=> body);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }
}