import '../Util/JsonUtil.dart';
import '../Util/PhoneUtil.dart';
import 'FChatApiObj.dart';

class Loginfchat{
  ApiObj? aobj;
  static PushObj? pushobj;
  send(void Function(String recdata) fchatsend){
    aobj?.dispose();
    aobj=ApiObj(ApiName.system,(value){
      fchatsend(value);
      Map recmap=JsonUtil.strtoMap(value);
      if(recmap.containsKey("push")){
        pushobj=PushObj.fromJson(recmap["push"]);
        PhoneUtil.applog("获取pushobj 推送参数${pushobj!.toJson()}");
      }
    });
    aobj!.setData("{}");
  }
}


class PushObj {
  // 定义属性
  String? token;
  String? os;
  String? userid;
  String? package;

  // 构造函数
  PushObj({
    this.token,
    this.os,
    this.userid,
    this.package,
  });

  // 从JSON解析对象
  factory PushObj.fromJson(Map<String, dynamic> json) {
    return PushObj(
      token: json['token'] as String?,
      os: json['os'] as String?,
      userid: json['userid'] as String?,
      package: json['package'] as String?,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    // 原始代码中的 map.putIfAbsent 逻辑
    final Map<String, dynamic> map = {};
    map.putIfAbsent("token", () => token);
    map.putIfAbsent("os", () => os );
    map.putIfAbsent("userid", () => userid );
    map.putIfAbsent("package", () => package );
    // 清理空值（可选，根据需求）
    return map..removeWhere((key, value) => value == null);
  }
}

