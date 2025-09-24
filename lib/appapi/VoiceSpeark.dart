import '../Util/JsonUtil.dart';
import '../Util/PhoneUtil.dart';
import 'FChatApiObj.dart';
//调用app voice tts 进行语音播报
class Voicespeark{
  ApiObj? aobj;
  String text="";
  speark(String text,void Function(String recdata) fchatvoice){
    if(text.isEmpty) return;
    this.text=text;
    aobj=ApiObj(ApiName.voice,(value){
      if(value=="err")return;
      fchatvoice(value);
    });
    aobj!.setData(toString());
  }

  _getJson(){
    Map map={};
    map.putIfAbsent("voice", ()=> text);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }

}


