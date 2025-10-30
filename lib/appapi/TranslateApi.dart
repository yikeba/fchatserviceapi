import 'package:fchatapi/Util/PhoneUtil.dart';
import 'package:fchatapi/util/Translate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../Util/JsonUtil.dart';
import 'FChatApiObj.dart';

class TranslateApi{
  //从app获取可以下载的端口和ip
  ApiObj? _aobj;
  String text;
  TranslateApi(this.text);
  send(void Function(String recdata) fchatsend){
    _aobj?.dispose();
    _aobj=ApiObj(ApiName.translate,(value){
      fchatsend(value);
    });
    _aobj!.setData(toString());
  }

  read(void Function(String recdata) fchatsend){
    _aobj?.dispose();
    _aobj=ApiObj(ApiName.readtranslate,(value) async {
      Map rec=JsonUtil.strtoMap(value);
      if(rec.containsKey("port")){
        int port=rec["port"];
        Map<String,dynamic> sendmap=_aobj!.toJson();
        PhoneUtil.applog("本地服务发送数据请求$sendmap");
        final recmap = await PostClient(port).sendData(sendmap);
        if(recmap.containsKey("tra")){
          PhoneUtil.applog("服务号收到翻译数据类型${recmap.values.first.runtimeType}");
          List tralist=recmap["tra"];
          //List tralist=JsonUtil.strotList(trastr);
          Translate.translateList.addAll(tralist);
          PhoneUtil.applog("读取app翻译记录${tralist.length}");
          fchatsend("ok");
          return;
        }
      }
      fchatsend("err");
     /* PhoneUtil.applog("读取app翻译记录${rec.length},数据key${rec.keys.first}");
      if(rec.containsKey("tra")){
         String trastr=rec["tra"];
         List tralist=JsonUtil.strotList(trastr);
         Translate.translateList.addAll(tralist);
         PhoneUtil.applog("读取app翻译记录${tralist.length}");
      }*/

    });
    _aobj!.setData("");
  }

  _getJson(){
    Map map={};
    map.putIfAbsent("text", ()=> text);
    return map;
  }

  @override
  String toString(){
    return JsonUtil.maptostr(_getJson());
  }
}



/// Flutter Web 端 POST 客户端类，用于向 App 的本地服务器发送大容量 JSON 数据。
/// 默认端口 49999，支持动态端口（如果 App 切换到 49998）。
/// 需要在 pubspec.yaml 中添加依赖：http: ^1.2.1（或最新版）。
/// 示例用法：
/// PostClient client = PostClient();
/// client.sendData({'records': yourLargeArrayOf10000Items})
///   .then((response) => PhoneUtil.applog('发送成功: $response'))
///   .catchError((error) => PhoneUtil.applog('发送失败: $error'));
class PostClient {
  int port;
  
  PostClient(this.port);
  /// 向服务器发送 POST 请求，body 为 JSON 数据。
  /// @param data 要发送的 JSON 数据（例如 {'records': [...]}，支持 10000 条大数组）。
  /// @param endpoint 请求路径，默认 /data。
  /// @returns Future<Map<String, dynamic>> 服务器响应 JSON 对象。
  Future<Map<String, dynamic>> sendData(
      Map<String, dynamic> data, {
        String endpoint = '/data',
      }) async {
    try {
      Uri _baseUri =Uri.parse('http://127.0.0.1:$port');
      final uri = _baseUri.resolve(endpoint);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data), // 支持大 JSON 序列化
      );

      if (response.statusCode != 200) {
        throw http.ClientException('HTTP 错误: ${response.statusCode} - ${response.reasonPhrase}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      PhoneUtil.applog('数据发送成功，接收确认: ${result.keys.first}');
      return result;
    } on http.ClientException catch (error) {
      PhoneUtil.applog('POST 请求失败: $error');
      // 如果端口 49999 失败，尝试备份端口 49998（模拟 App 的切换逻辑）
      if (port == 49999 &&
          (error.toString().contains('Connection refused') ||
              error.toString().contains('Failed host lookup'))) {
        PhoneUtil.applog('主端口不可用，尝试备份端口 49998...');
        port = 49998;
        return sendData(data, endpoint: endpoint); // 递归重试
      }
      rethrow;
    } catch (error) {
      PhoneUtil.applog('意外错误: $error');
      rethrow;
    }
  }

  /// 批量发送大容量数据（分块发送，避免单次超大 body 导致超时/OOM）。
  /// @param largeArray 大数组，例如 10000 条 JSON 对象。
  /// @param batchSize 每批大小，默认 1000 条。
  /// @param endpoint 请求路径。
  /// @returns Future<List<Map<String, dynamic>>> 所有批次的响应列表。
  Future<List<Map<String, dynamic>>> sendDataInBatches(
      List<dynamic> largeArray, {
        int batchSize = 1000,
        String endpoint = '/data',
      }) async {
    final batches = <Map<String, dynamic>>[];
    for (int i = 0; i < largeArray.length; i += batchSize) {
      final batch = largeArray.sublist(i, (i + batchSize).clamp(0, largeArray.length));
      final data = {'batch_id': (i / batchSize).round() + 1, 'records': batch};
      final response = await sendData(data, endpoint: endpoint);
      batches.add(response);
      // 可选：添加延迟，避免服务器过载
      await Future.delayed(const Duration(milliseconds: 100));
    }
    PhoneUtil.applog('批量发送完成，共 ${batches.length} 批次');
    return batches;
  }

  /// 更新端口（如果 App 通知端口变化）。
  /// @param newPort 新端口号。
  void updatePort(int newPort) {
    port = newPort;
    PhoneUtil.applog('端口更新为: $newPort');
  }
}