
import 'FChatApiObj.dart';

class Scanapi{
  ApiObj? aobj;
  scan(void Function(String recdata) state){
    aobj?.dispose();
    aobj=ApiObj(ApiName.scan,(value){
      state(value);
    });
    aobj!.setData("");
  }



}