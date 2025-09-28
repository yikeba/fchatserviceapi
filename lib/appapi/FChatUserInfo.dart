import 'FChatApiObj.dart';

class FChatUserInfo{
  ApiObj? aobj;

  getUserInfo(void Function(String recdata) fchatsend){
    aobj=ApiObj(ApiName.userinfo,(value){
      fchatsend(value);
    });
    aobj!.setData("{}");
  }
}