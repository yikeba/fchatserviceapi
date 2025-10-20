import 'package:fchatapi/webapi/PushOrder/PushOrderObj.dart';

import '../../Util/PhoneUtil.dart';
import '../HttpWebApi.dart';
import '../StripeUtil/WebPayUtil.dart';
import '../WebCommand.dart';

class PushUtil{


  static Future<Map> creatPushOrder(PushOrderObj pushorder) async {
    Map map=pushorder.toJson();
    Map<String, dynamic>sendmap = WebPayUtil.getDataMap(
        map, WebCommand.pushOrder);
    String rec = await WebPayUtil.httpFchatserver(sendmap);
    RecObj recobj = RecObj(rec);
    PhoneUtil.applog("push 推送返回${recobj.json}");
    return recobj.json;
  }


}