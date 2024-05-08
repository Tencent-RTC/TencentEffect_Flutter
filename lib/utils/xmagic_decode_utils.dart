

import 'dart:convert';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';




class XmagicDecodeUtil{


  static List<String>? decodeStringList(List<dynamic>? json) {
    if (json != null) {
      List<String> list = <String>[];
      json.forEach((element) {
        if (element != null) {
          list.add(element as String);
        }
      });
      return list;
    }
    return null;
  }

  static List<XmagicProperty>? decodeXmagicPropertyList(List<dynamic>? json) {
    if (json != null) {
      List<XmagicProperty> list = <XmagicProperty>[];
      json.forEach((element) {
        if (element != null) {
          list.add(XmagicProperty.fromJson(element));
        }
      });
      return list;
    }
    return null;
  }


  static List<XmagicUIProperty>? decodeXmagicUIPropertyList(List<dynamic>? json) {
    if (json != null) {
      List<XmagicUIProperty> list = <XmagicUIProperty>[];
      json.forEach((element) {
        if (element != null) {
          list.add(XmagicUIProperty.fromJson(element));
        }
      });
      return list;
    }
    return null;
  }

  static Map<String, List<XmagicUIProperty>> decodeAllDataJson(String jsonstr) {
    Map<String, List<XmagicUIProperty>> map = Map();
    var data = json.decode(jsonstr);
    data.forEach((key, value) {
      if (value != null) {
        List<XmagicUIProperty>? list = decodeXmagicUIPropertyList(data[key]);
        if (list != null) {
          map[key] = list;
        }
      }
    });
    return map;
  }
}

