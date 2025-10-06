import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class OpenUser{
  ApiObj? aobj;
  String userid="";
  String type="";
  openuser(String userid, String type,void Function(String recdata) state){
    if(userid.isEmpty) return;
    this.userid=userid;
    this.type=type;
    aobj=ApiObj(ApiName.openUser,(value){
      state(value);
    });
    aobj!.setData(toString());
  }

  _getJson(){
    if(type.isEmpty) type="user";
    Map map={};
    map.putIfAbsent("userid", ()=> userid);
    map.putIfAbsent("type", ()=> type);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }
}