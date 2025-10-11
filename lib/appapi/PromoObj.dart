
import 'package:fchatapi/Util/JsonUtil.dart';

import '../Util/PhoneUtil.dart';
import 'FChatApiObj.dart';

class PromoApi{
  ApiObj? aobj;
  PromObj? promObj;
  receive(void Function(String recdata) state){
    aobj=ApiObj(ApiName.promoreceive,(value){

      state(value);
    });
    aobj!.setData("");
  }

  //返回优惠券对象
  receiveObj(void Function(PromObj prom) state){
    aobj=ApiObj(ApiName.promoreceive,(value){
      PromObj p=PromObj.fromString(value);
      state(p);
    });
    aobj!.setData("");
  }

  del(void Function(String recdata) state){
    if(promObj==null){
      state("err");
      return;
    }
    aobj=ApiObj(ApiName.promodel,(value){
      state(value);
    });
    aobj!.setData(toString());
  }

  toJson(){
    Map map={};
    map.putIfAbsent("id", ()=> promObj!.id);
  }

  @override
  String toString() {
    return JsonUtil.maptostr(toJson());
  }

}


class PromObj {
  String id="";        // 优惠券id
  String title="";     // 优惠券名称
  String name="";      // 优惠券对象标签
  String label="";
  String text="";
  String link="";
  String details="";
  String verify="";
  String image="";
  PromoType? promotype;
  bool isActive=false;    // 是否可用
  String merchantid="";
  int endTime;
  String filename="";
  PromObj({
    required this.id,
    required this.name,
    required this.title,
    required this.label,
    required this.promotype,
    required this.text,
    required this.link,
    required this.details,
    required this.verify,
    required this.endTime,
    required this.merchantid,
    required this.image,
    this.isActive = false,
  });

  factory PromObj.fromString(String data) {
    Map<String, dynamic> map=JsonUtil.strtoMap(data);
    if(map.containsKey("image")){
      String base64=map["image"];
      PhoneUtil.applog("读取到优惠券图片大小${base64.length}");
    }
    return PromObj.fromJson(map);
  }

  factory PromObj.fromJson(Map<String, dynamic> json) {
    return PromObj(
      id: (json['id'] ?? '').toString(),
      link: (json['url'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? 'NewUser').toString(),
      title: (json['title'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      verify:(json['verify'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      merchantid:(json['merchantId'] ?? '').toString(),
      endTime: int.tryParse((json['endTime'] ?? '0').toString()) ?? 0, // 修复：安全解析为 int，默认 0
      promotype: PromoType.values.firstWhere(
            (e) => e.name.toLowerCase() == (json['promotype'] ?? '').toString().toLowerCase(),
        orElse: () => PromoType.free,
      ),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': link,  // 注意：fromJson 用 'url' 对应 link
      'name': name,
      'label': label,
      'title': title,
      'text': text,
      'image':image,
      'details': details,
      'verify': verify,
      'merchantId': merchantid,  // 注意：fromJson 用 'merchantId' 对应 merchantid
      'endTime': endTime,
      'promotype': promotype!.name,  // 枚举名作为字符串
      'isActive': isActive,
    };
  }

}


enum PromoType {
  free,   //免费优惠券
  paid, //销售优惠券
  conditional, //条件优惠券
  engagement, //互动参与优惠券
  loyalty, //忠诚，权益优惠券
}
