import 'package:fchatapi/webapi/PushOrder/PrintObj.dart';

import '../Util/JsonUtil.dart';
import '../Util/PhoneUtil.dart';
import 'FChatApiObj.dart';

class PrintOrderApi{
  PrintOrderObj printOrderObj;
  PrintOrderApi(this.printOrderObj);
  ApiObj? aobj;
  print(void Function(PrintStatus state) state){
    aobj?.dispose();
    aobj=ApiObj(ApiName.printOrder,(value){
      Map map=JsonUtil.strtoMap(value);
      PhoneUtil.applog("打印返回内容$value");
      if(map.containsKey("status")){
        if(map["status"]=="Complete"){
           state(PrintStatus.Complete);
           return;
        }
      }
      state(PrintStatus.err);
    });
    aobj!.setData(printOrderObj.toString());
  }

}

enum PrintStatus {
  Complete,
  err
}