import 'package:fchatapi/webapi/PushOrder/PrintObj.dart';

import 'FChatApiObj.dart';

class PrintOrderApi{
  PrintOrderObj printOrderObj;
  PrintOrderApi(this.printOrderObj);
  ApiObj? aobj;
  print(void Function(String recdata) state){
    aobj?.dispose();
    aobj=ApiObj(ApiName.printOrder,(value){
      state(value);
    });
    aobj!.setData(printOrderObj.toString());
  }





}