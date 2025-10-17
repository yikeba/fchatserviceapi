import '../Util/PhoneUtil.dart';
import 'FChatApiObj.dart';

class GpsApi {
  ApiObj? _gpsApiObj; // 用于 GPS 请求
  ApiObj? _mapApiObj; // 用于地图请求

  // 获取 GPS 位置
  Future<void> getgps(void Function(String recdata) state) async {
    // 如果已有 GPS 请求，先清理
    _gpsApiObj?.dispose();
    // 创建新的 ApiObj 实例
    _gpsApiObj = ApiObj(ApiName.gps, (value) {
      state(value);
    });
    await _gpsApiObj!.setData("");
  }

  // 获取地图 GPS 位置
  Future<void> getMapgps(void Function(String recdata) state) async {
    // 如果已有地图请求，先清理
    _mapApiObj?.dispose();
    // 创建新的 ApiObj 实例
    _mapApiObj = ApiObj(ApiName.map, (value) {
      state(value);
    });
    await _mapApiObj!.setData("");
  }

  // 清理所有 ApiObj 实例
  void dispose() {
    _gpsApiObj?.dispose();
    _mapApiObj?.dispose();
    _gpsApiObj = null;
    _mapApiObj = null;
    PhoneUtil.applog('GpsApi disposed');
  }
}