
import 'FChatApiObj.dart';

class PromoApi{
  ApiObj? aobj;
  receive(void Function(String recdata) state){
    aobj=ApiObj(ApiName.promoreceive,(value){
      state(value);
    });
    aobj!.setData("");
  }


}