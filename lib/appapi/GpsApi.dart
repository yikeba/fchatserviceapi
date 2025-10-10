import 'FChatApiObj.dart';

class GpsApi{
  ApiObj? aobj;
  getgps(void Function(String recdata) state){
    aobj=ApiObj(ApiName.gps,(value){
      state(value);
    });
    aobj!.setData("");
  }

  getMapgps(void Function(String recdata) state){
    aobj=ApiObj(ApiName.map,(value){
      state(value);
    });
    aobj!.setData("");
  }
}