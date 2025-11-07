import 'package:fchatapi/webapi/ChatUserobj.dart';

import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class FChatUserInfo{
  ApiObj? aobj;

  getUserInfo(void Function(ChatUserobj user) fchatsend){
    aobj?.dispose();
    aobj=ApiObj(ApiName.userinfo,(value){
      Map map=JsonUtil.strtoMap(value);
      ChatUserobj user=ChatUserobj.withNameAndAge(map);
      //PhoneUtil.applog("app发送参数：$map");
      //PhoneUtil.applog("读取app 使用账户信息${user.toString()}");
      fchatsend(user);
    });
    aobj!.setData("{}");
  }
}