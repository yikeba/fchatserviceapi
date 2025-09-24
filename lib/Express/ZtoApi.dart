import 'package:fchatapi/Util/JsonUtil.dart';

import '../Util/PhoneUtil.dart';
import '../util/Translate.dart';
import '../webapi/HttpWebApi.dart';
import '../webapi/StripeUtil/WebPayUtil.dart';
import '../webapi/WebCommand.dart';
import 'ZtotrackWidget.dart';

class ZtoApi {
  static ZtoKHObj ztoobj = ZtoKHObj();

  static Future<Map> ztocreatorder(String data) async {
    Map map = {};
    map.putIfAbsent("data", () => data);
    map.putIfAbsent("express", () => "zto");
    map.putIfAbsent("action", ()=> "creat");
    Map<String, dynamic> sendmap =
        WebPayUtil.getDataMap(map, WebCommand.expresszto);
    String rec = await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj = RecObj(rec);
   //PhoneUtil.applog("快递返回情况${robj.json}");
    return robj.json;
  }


  static Future<Map> ztoreadorder(String data) async {
    Map map = {};
    map.putIfAbsent("data", () => data);
    map.putIfAbsent("express", () => "zto");
    map.putIfAbsent("action", ()=> "read");
    Map<String, dynamic> sendmap =
    WebPayUtil.getDataMap(map, WebCommand.expresszto);
    String rec = await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj = RecObj(rec);
    PhoneUtil.applog("读取快递单${robj.json}");
    return robj.json;
  }

   //读取中通快递单轨迹数据
  static Future<List<ZtoTrackObj>> fetchztoreadtrack(String customerNO) async {
     List<ZtoTrackObj> arr=[];
     if(customerNO.isEmpty) return arr;
     Map map={};
     map.putIfAbsent("customerNO", () => customerNO);
     List recstr=await ztoreadtrack(JsonUtil.maptostr(map));
     List recobj=[];
     for(String str in recstr){
        Map map=JsonUtil.strtoMap(str);
        recobj.add(map);
     }
     arr=recobj.map((item) => ZtoTrackObj.fromJson(item)).toList();
     PhoneUtil.applog("读取到支付轨迹记录${arr.length}");
     return arr;
  }

  static Future<List> ztoreadtrack(String data) async {
    Map map = {};
    map.putIfAbsent("data", () => data);
    map.putIfAbsent("express", () => "zto");
    map.putIfAbsent("action", ()=> "track");
    Map<String, dynamic> sendmap =
    WebPayUtil.getDataMap(map, WebCommand.expresszto);
    String rec = await WebPayUtil.httpFchatserver(sendmap);
    RecObj robj = RecObj(rec);
    PhoneUtil.applog("读取快递单进度估计${robj.listarr}");
    return robj.listarr;
  }

  static initZtoObj(Map map) {
    ztoobj.init(map);
  }
}



class provinceObj{
  String name;
  String nameen;
  String namekh;
  List<cityObj> cityobj=[];
  getName(){
    if(Translate.language=="en") return nameen;
    if(Translate.language.contains("zh")) return name;
    if(Translate.language=="kh") return namekh;
    return nameen;
  }
  provinceObj(this.name,this.nameen,this.namekh);
}
class cityObj{
  String name;
  String nameen;
  String namekh;
  List<districtObj> districtobj=[];
  getName(){
    if(Translate.language=="en") return nameen;
    if(Translate.language.contains("zh")) return name;
    if(Translate.language=="kh") return namekh;
    return nameen;
  }
  cityObj(this.name,this.nameen,this.namekh);
}

class districtObj{
  String name;
  String nameen;
  String namekh;
  getName(){
    if(Translate.language=="en") return nameen;
    if(Translate.language.contains("zh")) return name;
    if(Translate.language=="kh") return namekh;
    return nameen;
  }
  districtObj(this.name,this.nameen,this.namekh);
}

class ZtoKHObj {
  List<provinceObj> provincelist = [];
  List<districtObj> distlist = [];
  List<cityObj> citylist = [];
  init(Map map) {
    List plist = map["provinceList"];
    plist.sort((a, b) {
      // 提取 code 中的数字部分并转为整数
      int numA = int.parse(RegExp(r'\d+').firstMatch(a['code'])!.group(0)!);
      int numB = int.parse(RegExp(r'\d+').firstMatch(b['code'])!.group(0)!);
      return numA.compareTo(numB);
    });
    for (Map map in plist) {
      String code=map["code"];
      String name = _cleanInput(_decodeBrokenUnicode(map["name"]));
     // PhoneUtil.applog("获得province省份名称$name,省级单位排序code$code");
      String nameen = "";
      String namekh ="";
      if (map.containsKey("nameEn")) {
        nameen = map["nameEn"];
      }
      if (map.containsKey("nameLang")) {
        namekh =  _cleanInput(_decodeBrokenUnicode(map["nameLang"]));
      }
      provinceObj pobj=provinceObj(name,nameen,namekh);
      provincelist.add(pobj);
      List dlist = map["cityList"];
      for (Map citymap in dlist) {
        String citynameen = citymap["nameEn"];
        String cityname = _cleanInput(_decodeBrokenUnicode(citymap["name"]));
        String citynamekh=_cleanInput(_decodeBrokenUnicode(citymap["nameLang"]));
        cityObj cobj=cityObj(cityname,citynameen,citynamekh);
        pobj.cityobj.add(cobj);
        citylist.add(cobj);
        for (Map distmap in citymap["districtList"]) {
          String distnameen = distmap["nameEn"];
          String distname = _cleanInput(_decodeBrokenUnicode(distmap["name"]));
          String distnamekh = _cleanInput(_decodeBrokenUnicode(distmap["nameLang"]));
          districtObj distobj=districtObj(distname,distnameen,distnamekh);
          cobj.districtobj.add(distobj);
          // PhoneUtil.applog(
          //     "---------------区域对象:$distname 英文名称：$distnameen, ------------------");
          // PhoneUtil.applog("---------------区域结束------------------");
          distlist.add(distobj);
        }
      }
      //PhoneUtil.applog("---------------第一个省级单位读取完毕 ------------------");
    }
   /* for (String province in provincelist) {
      PhoneUtil.applog("---------------省级单位:$province ------------------");
    }
    PhoneUtil.applog("---------------省级单位结束------------------");
    for (String province in citylist) {
      PhoneUtil.applog("---------------市县单位:$province ------------------");
    }
    PhoneUtil.applog("---------------市县单位结束------------------");
    for (String province in distlist) {
      PhoneUtil.applog("---------------区级单位:$province ------------------");
    }*/
  }

  String _decodeBrokenUnicode(String input) {
    return input.replaceAllMapped(RegExp(r'u(\d{4,5})'), (match) {
      int code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    });
  }

  String _cleanInput(String input) {
    return input.replaceAll(RegExp(r'uc0'), '').trim();
  }

  getprovince(String locprovince) {
    for (provinceObj province in provincelist) {
      if (province.nameen == locprovince) return province;
      if (province.nameen.contains(locprovince)) return province;
      if (locprovince.contains(province.nameen)) return province;
    }
    return locprovince;
  }

  getcity(String loccity) {
    for (cityObj city in citylist) {
      if (city.nameen == loccity) return city;
      if (city.nameen.contains(loccity)) return city;
      if (loccity.contains(city.nameen)) return city;
    }
    return loccity;
  }

  getdist(String locdist) {
    for (districtObj dist in distlist) {
      if (dist.nameen == locdist) return dist;
      if (dist.nameen.contains(locdist)) return dist;
      if (locdist.contains(dist.nameen)) return dist;
    }
    return locdist;
  }

  List<cityObj> readCtiylist(String locprovince){
    provinceObj? selectprovince;
    for (provinceObj province in provincelist) {
      if (province.nameen == locprovince) {
          selectprovince=province;
          break;
      }
      if (province.name == locprovince) {
        selectprovince=province;
        break;
      }
      if (province.namekh == locprovince) {
        selectprovince=province;
        break;
      }
    }
    if(selectprovince==null) return [];
    return selectprovince.cityobj;
  }

  List<districtObj> readdistrictlist(String loccity){
    cityObj? selectprovince;
    for (cityObj province in citylist) {
      if (province.nameen == loccity) {
        selectprovince=province;
        break;
      }
      if (province.name == loccity) {
        selectprovince=province;
        break;
      }
      if (province.namekh == loccity) {
        selectprovince=province;
        break;
      }
    }
    if(selectprovince==null) return [];
    return selectprovince.districtobj;
  }
}
