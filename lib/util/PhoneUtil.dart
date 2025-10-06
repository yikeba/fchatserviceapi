import 'package:flutter/foundation.dart';

class PhoneUtil{

  static applog(String info) {
    bool inputinfo = false;
    if (kDebugMode || inputinfo || kProfileMode) {
        print("[FChat Api: ${DateTime.now().millisecondsSinceEpoch}]$info");
    }
  }

}