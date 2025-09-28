import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:dio/dio.dart';
import 'package:fchatapi/util/SignUtil.dart';
import 'package:fchatapi/webapi/HttpWebApi.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as pathobj;
import '../util/JsonUtil.dart';
import '../util/PhoneUtil.dart';
import '../util/UserObj.dart';
import 'WebCommand.dart'; // 用于二进制处理

class FChatFileObj {
  html.File? file;
  String? filedata;
  String filename="";
  final Dio _dio = Dio();
  Uint8List? fileBytes;
  FChatFileMD filemd = FChatFileMD.base;
  bool ispublic=false;  //文件是否公开货私有
  String authHeader = 'Bearer ${UserObj.servertoken}'; // 设置 Bearer Token

  initfile() async {
    try {
      if (file == null) return;
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      reader.onLoad.listen((event) {
        final result = reader.result as Uint8List;
        completer.complete(result);
      });
      // 读取文件为字节数据
      reader.readAsArrayBuffer(file!); // 等待读取完成
      fileBytes = await completer.future;
    } catch (e) {
      print("Error generating MD5 from file: $e");
      return "Error";
    }
  }

  Map<String, dynamic> _getFileMap() {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    if(ispublic){
      map.putIfAbsent("command", () => WebCommand.upfilepublic);
    }else{
      map.putIfAbsent("command", () => WebCommand.fchatupfile);
    }
    map.putIfAbsent("filename", () => filename);
    map.putIfAbsent("sapppath", () => filemd.name);
    return map;
  }

  Map<String, dynamic> _getDataMap() {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.fchatupData);
    map.putIfAbsent("filename", () => filename);
    map.putIfAbsent("sapppath", () => filemd.name);
    return map;
  }

  Future<void> writeByte(Uint8List data, String name, void Function(bool state) upstate) async {
    try {
      fileBytes = data;
      Map<String, dynamic> map = _getFileMap();
      map.putIfAbsent(
        'file',
            () => MultipartFile.fromBytes(
          fileBytes!,
          filename: name,
          contentType: MediaType('text', 'html'),
        ),
      );
      FormData formData = FormData.fromMap(map);
      // 发送 POST 请求
      String url = HttpWebApi.geturl();
      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            "Authorization": authHeader
          },
        ),
      );
      // 检查上传结果
      if (response.statusCode == 200) {
        upstate(true);
        String rec = JsonUtil.getbase64(response.data);
        print("writeByte文件上传成功: $rec");
      } else {
        print("文件上传失败: ${response.statusCode}");
      }
    } catch (e) {
      print("上传过程中出现错误: $e");
    }
  }

  Future<void> editData(String data, String name, String md5,void Function(String state) upstate) async {
    try {
      if (data.isEmpty) {
        print("无法读取文件内容");
        return;
      }
      filedata = JsonUtil.setbase64(data);
      fileBytes = Uint8List.fromList(filedata!.codeUnits);
      if (fileBytes == null) {
        print("数据转换base64 byte错误");
        return;
      }
      Map<String, dynamic> map = _getDataMap();
      map.putIfAbsent(
        'file',
            () => MultipartFile.fromBytes(
          fileBytes!,
          filename: name,
          contentType: MediaType('text', 'html'),
        ),
      );
      FormData formData = FormData.fromMap(map);
      // 发送 POST 请求
      String url = HttpWebApi.geturl();
      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            "Authorization": authHeader
          },
        ),
      );
      // 检查上传结果
      if (response.statusCode == 200) {
        String rec = JsonUtil.getbase64(response.data);
        upstate(rec);
        print(" editData 文件上传成功: $rec");
      } else {
        print("文件上传失败: ${response.statusCode}");
      }
    } catch (e) {
      print("上传过程中出现错误: $e");
    }
  }


  Future<void> writeData(String data, String name, void Function(String state) upstate) async {
    try {
      if (data.isEmpty) {
        print("无法读取文件内容");
        return;
      }
      filedata = JsonUtil.setbase64(data);
      fileBytes = Uint8List.fromList(filedata!.codeUnits);
      if (fileBytes == null) {
        print("数据转换base64 byte错误");
        return;
      }
      Map<String, dynamic> map = _getDataMap();
      map.putIfAbsent('data', () => data);
      FormData formData = FormData.fromMap(map);
      String url = HttpWebApi.geturl();     // 发送 POST 请求
      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            "Authorization": authHeader
          },
        ),
      );
      // 检查上传结果
      if (response.statusCode == 200) {
        String rec = JsonUtil.getbase64(response.data);
        upstate(rec);
        //print(" writeData 文件上传成功: $rec");
      } else {
        print("文件上传失败: ${response.statusCode}");
      }
    } catch (e) {
      print("上传过程中出现错误: $e");
    }
  }

  Future<void> writeFile(
      html.File file, void Function(String url) upstate) async {
    this.file = file;
    await initfile();
    filename=file.name;
    try {
      if (fileBytes == null) {
        print("无法读取文件内容");
        return;
      }
      // 准备表单数据
      Map<String, dynamic> map = _getFileMap();
      map.putIfAbsent(
        'file',
            () => MultipartFile.fromBytes(
          fileBytes!,
          filename: filename,
          contentType: MediaType('text', 'html'),
        ),
      );
      FormData formData = FormData.fromMap(map);
      // 发送 POST 请求
      String url = HttpWebApi.geturl();
      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            "Authorization": authHeader
          },
        ),
      );
      // 检查上传结果
      if (response.statusCode == 200) {
        String rec = JsonUtil.getbase64(response.data);
        Map recmap=JsonUtil.strtoMap(rec);
        String url="";
        PhoneUtil.applog("writeFile file 文件上传成功: $rec");
        if(recmap.containsKey(filename)){
          String md5=recmap[filename];
          url="https://fchatmenchat.s3.ap-southeast-1.amazonaws.com/"+UserObj.userid+"/"+filemd.name+"/"+md5;
          print("file 公开访问链接: $url");
        }
        upstate(url);
        PhoneUtil.applog("file 文件上传成功: $rec");
      } else {
        print("文件上传失败: ${response.statusCode}");
      }
    } catch (e) {
      print("上传过程中出现错误: $e");
    }
  }

  Map<String, dynamic> _getreadMap(path) {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.fchatreadfile);
    map.putIfAbsent("sapppath", () => path);
    return map;
  }

  Future<void> readFile(
      String path, void Function(String data) filedata) async {
    try {
      Map<String, dynamic> map = _getreadMap(path);
      String rec = await HttpWebApi.httpspost(map);
      String data = RecObj(rec).data;
      filedata(data);
    } catch (e) {
      filedata("err");
      //PhoneUtil.applog("读取文件过程中出现错误: $e");
    }
  }

  Map<String, dynamic> _getdelMap(path) {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.delfile);
    map.putIfAbsent("sapppath", () => path);
    return map;
  }

  Future<void> delFile(String path, void Function(bool state) call) async {
    try {
      Map<String, dynamic> map = _getdelMap(path);
      String rec = await HttpWebApi.httpspost(map);
      String data = RecObj(rec).data;
      call(true);
    } catch (e) {
      print("上传过程中出现错误: $e");
    }
  }
}

class FChatFileArrObj {
  Map<String, dynamic> _getReadmdMap(String md) {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.fchatreadMD);
    map.putIfAbsent("sapppath", () => md);
    return map;
  }

  Map<String, dynamic> _getReadfileMap(String md, String name) {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.fchatreadfile);
    map.putIfAbsent("sapppath", () => md + "/" + name);
    return map;
  }

  Map<String, dynamic> _getReadmdthbMap(String md) {
    Map<String, dynamic> map = {};
    map.putIfAbsent("userid", () => UserObj.userid);
    map.putIfAbsent("command", () => WebCommand.readMDthb);
    map.putIfAbsent("sapppath", () => md);
    return map;
  }

  Future<void> readfile(void Function(FChatFileObj) file,
      {String md = "", String filename = ""}) async {
    if (md.isEmpty) md = FChatFileMD.base.name;
    Map<String, dynamic> map = _getReadfileMap(md, filename);
    String rec = await HttpWebApi.httpspost(map);
    rec = JsonUtil.getbase64(rec);
    //print("读取文件制定文件返回$rec");
    file(parsefile(RecObj(rec).data, filename));
  }

  Future<void> readMD(void Function(List<FChatFileObj>) filearr, {String md = ""}) async {
    if (md.isEmpty) md = FChatFileMD.base.name;
    Map<String, dynamic> map = _getReadmdMap(md);
    String rec = await HttpWebApi.httpspost(map);
    filearr(parsefileobj(RecObj(rec).json));
  }

  Future<void> readMDthb(void Function(List) filearr, {String md = ""}) async {
    if (md.isEmpty) md = FChatFileMD.base.name;
    Map<String, dynamic> map = _getReadmdthbMap(md);
    String rec = await HttpWebApi.httpspost(map);
    filearr(RecObj(rec).listarr);
  }

  List<FChatFileObj> parsefileobj(Map map) {
    List<FChatFileObj> arr = [];
    map.forEach((key, value) {
      FChatFileObj file = FChatFileObj();
      file.filename = pathobj.basename(key);
      file.filedata = value;
      arr.add(file);
    });
    return arr;
  }

  FChatFileObj parsefile(String data, String name) {
    FChatFileObj file = FChatFileObj();
    file.filename = name;
    file.filedata = data;
    file.fileBytes = Uint8List.fromList(data.codeUnits);
    return file;
  }
}


abstract class FChatFileMD {
  String name;
  FChatFileMD(this.name);
  static  FChatFileMD base = _DefaultFileMD('base');
  @override
  String toString() => name;
}

// 内部默认实现，防止外部直接实例化
class _DefaultFileMD extends FChatFileMD {
  _DefaultFileMD(super.name);
}

// 客户可以继承 FileMD 并扩展
class CustomFChatFileMD extends FChatFileMD {
  CustomFChatFileMD(super.name);
  static  FChatFileMD logs = CustomFChatFileMD('logs');
}


