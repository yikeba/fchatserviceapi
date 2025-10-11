
import 'package:fchatapi/Util/JsonUtil.dart';

import 'FChatApiObj.dart';

class PromoApi{
  ApiObj? aobj;
  String promoid="";
  receive(void Function(String recdata) state){
    aobj=ApiObj(ApiName.promoreceive,(value){
      state(value);
    });
    aobj!.setData("");
  }

  del(void Function(String recdata) state){
    if(promoid.isEmpty){
      state("err");
      return;
    }
    aobj=ApiObj(ApiName.promoreceive,(value){
      state(value);
    });
    aobj!.setData(toString());
  }

  toJson(){
    Map map={};
    map.putIfAbsent("id", ()=> promoid);
  }

  @override
  String toString() {
    return JsonUtil.maptostr(toJson());
  }

}