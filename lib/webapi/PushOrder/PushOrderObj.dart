import 'PrintObj.dart';

class PushOrderObj {
  PrintOrderObj? printOrder;  // 可选
  String? tts;                // 可选
  String recuserid;           // 必须 接受push 服务号/客户id，会限制为至少userobj.userid或客户id
  String senduserid;          //必须  发送push 服务号/客户id，会限制为至少userobj.userid或客户id
  String data;                // 必须
  String payid;               // 必须 payid 验证是否有支付订单，没有支付订单或支付订单验证失败push 无效
  //同一个payid 支付订单最多支持push 5次，超过5次返回失败
  String title;
  String body;
  PushOrderObj(this.senduserid,this.recuserid, this.title,this.body,this.payid, this.data, {this.tts, this.printOrder});

  factory PushOrderObj.fromJson(Map<String, dynamic> json) {
    return PushOrderObj(
      json['senduserid'] ?? '',
      json['recuserid'] ?? '',
      json['title'] ?? "",
      json['body'] ?? "",
      json['payid'] ?? '',
      json['data'] ?? '',
      tts: json['tts'],
      printOrder: json['printOrder'] != null
          ? PrintOrderObj.fromJson(json['printOrder'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'senduserid': senduserid,
      'recuserid': recuserid,
      'payid': payid,
      'title':title,
      'body':body,
      'data': data,
    };
    if (tts != null) json['tts'] = tts;
    if (printOrder != null) json['printOrder'] = printOrder!.toJson();
    return json;
  }
}
