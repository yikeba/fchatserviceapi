
import 'package:fchatapi/Util/JsonUtil.dart';

import 'FChatApiObj.dart';

class PromoApp{
  ApiObj? aobj;
  receive(void Function(String recdata) state){
    aobj=ApiObj(ApiName.promoreceive,(value){
      state(value);
    });
    aobj!.setData("");
  }

  send(Map<String,dynamic> map,void Function(String recdata) state){
    if(map.isEmpty) return;
    aobj=ApiObj(ApiName.promoreceive,(value){
      state(value);
    });
    aobj!.setData(JsonUtil.maptostr(map));
  }


}