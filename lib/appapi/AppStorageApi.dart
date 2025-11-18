import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class AppStorageApi {
  ApiObj? aobj;
  String md;
  String name;
  String data="";

  AppStorageApi(this.md,this.name,this.data);

  save(void Function(String recdata) fchatsend){
    aobj?.dispose();
    if(data.isEmpty) {
      return;
    }
    aobj=ApiObj(ApiName.localstorage,(value){
      fchatsend(value);
    });
    aobj!.setData(toString());
  }

  read(void Function(String recdata) fchatsend){
    aobj?.dispose();
    aobj=ApiObj(ApiName.readstorage,(value){
      fchatsend(value);
    });
    aobj!.setData(toString());
  }

  toJson(){
    Map map={};
    map.putIfAbsent("md", ()=> md);
    map.putIfAbsent("name", ()=> name);
    map.putIfAbsent("data", ()=> data);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(toJson());
  }


}