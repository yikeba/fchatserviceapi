import 'dart:async';
import 'package:fchatapi/util/JsonUtil.dart';
import 'package:fchatapi/util/SignUtil.dart';
import 'package:fchatapi/util/Tools.dart';
import 'package:fchatapi/util/UserObj.dart';
import 'package:fchatapi/appapi/BaseJS.dart';

import '../Util/PhoneUtil.dart';

enum ApiName {
  system,
  userinfo,
  pay,
  gps,
  map,
  showmap,
  localstorage,
  readstorage,
  delstorage,
  sendurl,
  order,
  voice,
  openUser,
  scan,
  promoreceive,
  promodel,
  appport,
  printOrder,
  notification,
  translate,
  readtranslate,
}

class ApiObj {
  final ApiName apiname;
  final String actionid;
  String data = '';
  String sign = '';
  final void Function(String)? recData;
  final BaseJS _bjs = BaseJS();
  StreamSubscription<String>? _subscription;

  ApiObj(this.apiname, this.recData) : actionid = Tools.generateRandomString(70) {
    _bjs.init();
  }

  Future<void> setData(String data) async {
    this.data = JsonUtil.getbase64(data);
    this.sign = SignUtil.hmacSHA512(this.data, UserObj.token);
    // 取消之前的订阅
    await _subscription?.cancel();
    // 发送消息并保存订阅
    PhoneUtil.applog("setdata to fChat app ${toString()}");
    _subscription = await _bjs.sendFChat(
      json: toString(),
      actionid: actionid,
      onReceive: recaction,
    );
  }

  void recaction(String value) {
    if (value == 'err') {
      recData?.call('err');
      _subscription?.cancel();
      return;
    }

    try {
      final recmap = JsonUtil.strtoMap(value);
      final code = recmap['code'] as int? ?? -1;
      final fsign = recmap['sign'] as String? ?? '';
      final fdata = recmap['data'] as String? ?? '';
      final fid = recmap['id'] as String? ?? '';

      //PhoneUtil.applog('ApiObj received data for actionid $actionid: $recmap');

      if (fid == actionid && code == 200) {
        final isValid = SignUtil.verifysha512(fdata, UserObj.token, fsign);
        if (isValid) {
          final vdata = JsonUtil.getbase64(fdata);
          recData?.call(vdata);
          _subscription?.cancel(); // 成功后取消订阅
        } else {
          //PhoneUtil.applog('Signature verification failed: $fsign');
          recData?.call('err');
          _subscription?.cancel();
        }
      } else {
        //PhoneUtil.applog('Invalid action ID: expected $actionid, got $fid');
        // 不触发 recData，等待正确消息
      }
    } catch (e) {
     // PhoneUtil.applog('ApiObj error parsing response: $e, value: $value');
      recData?.call('err');
      _subscription?.cancel();
    }
  }

  @override
  String toString() {
    return JsonUtil.maptostr(_getJSON());
  }

  toJson()=> _getJSON();

  Map<String, dynamic> _getJSON() {
    return {
      'api': apiname.name,
      'data': data,
      'sign': sign,
      'id': actionid,
      'userid': UserObj.userid,
    };
  }

  void dispose() {
    _subscription?.cancel();
    PhoneUtil.applog('ApiObj disposed for actionid: $actionid');
  }
}