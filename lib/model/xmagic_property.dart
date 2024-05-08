import 'dart:convert';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_effect_flutter/utils/xmagic_decode_utils.dart';

@deprecated
class XmagicProperty {
  static final String ID_NONE = "ID_NONE";
  String? category;
  String? id;
  String? resPath;
  String? effKey;
  XmagicPropertyValues? effValue;
  bool isSupport = false;
  bool isAuth = false;

  XmagicProperty({String? category,
    String? id,
    String? resPath,
    String? effKey,
    XmagicPropertyValues? effValue,
    bool isSupport = true,
    bool isAuth = true}) {
    this.category = category;
    this.id = id;
    this.resPath = resPath;
    this.effKey = effKey;
    this.effValue = effValue;
    this.isAuth = isAuth;
    this.isSupport = isSupport;
  }

  XmagicProperty.fromJson(Map<String, dynamic>? json) {
    if (json?['effValue'] == '') {
      json?['effValue'] = null;
    }
    Map<String, dynamic>? value = json?['effValue'];
    if (json?['isAuth'] is int) {
      json?['isAuth'] = (json['isAuth'] == 1);
    }
    if (json?['isSupport'] is int) {
      json?['isSupport'] = (json['isSupport'] == 1);
    }

    this.category = json?['category'];
    this.id = json?['id'];
    this.resPath = json?['resPath'];
    this.effValue =
    (value == null ? null : XmagicPropertyValues.fromJson(value));
    this.effKey = json?['effKey'];
    this.isSupport = json?['isSupport'];
    this.isAuth = json?['isAuth'];
  }

  Map<String, dynamic> toJson() =>
      {
        'category': category,
        'id': id,
        'resPath': resPath,
        'effKey': effKey,
        'effValue': effValue == null ? null : effValue?.toJson(),
        'isSupport': isSupport,
        'isAuth': isAuth,
      };
}

class XmagicPropertyValues {
  //  Constant for UI display
  double displayMinValue = 0;
  double displayMaxValue = 0;
  double displayDefaultValue = 0;

  // Constant for real value
  double innerMinValue = 0;
  double innerMaxValue = 0;
  double innerDefaultValue = 0;

  double currentDisplayValue = 0;
  double currentInnerValue = 0;

  XmagicPropertyValues(this.displayMinValue, this.displayMaxValue,
      this.displayDefaultValue, this.innerMinValue, this.innerMaxValue) {
    innerDefaultValue = (displayDefaultValue - displayMinValue) /
        (displayMaxValue - displayMinValue) *
        (innerMaxValue - innerMinValue) +
        innerMinValue;

    setCurrentDisplayValue(displayDefaultValue);
  }

  double getCurrentDisplayValue() {
    TXLog.printlog("getCurrentDisplayValue  $currentDisplayValue");
    return currentDisplayValue;
  }

  void setCurrentDisplayValue(double currentDisplayValue) {
    if (currentDisplayValue < displayMinValue) {
      currentDisplayValue = displayMinValue;
    } else if (currentDisplayValue > displayMaxValue) {
      currentDisplayValue = displayMaxValue;
    }
    this.currentDisplayValue = currentDisplayValue;
    TXLog.printlog("setCurrentDisplayValue  ${this.currentDisplayValue}");
    updateCurrentInnerValue();
  }

  double getCurrentInnerValue() {
    return currentInnerValue;
  }

  void updateCurrentInnerValue() {
    double displayPercent = (currentDisplayValue - displayMinValue) /
        (displayMaxValue - displayMinValue);
    currentInnerValue =
        displayPercent * (innerMaxValue - innerMinValue) + innerMinValue;
  }

  XmagicPropertyValues.fromJson(Map<String, dynamic>? json) {
    double disValue =
    double.parse(json?['displayDefaultValue'].toString() as String);
    this.displayMinValue =
        double.parse(json?['displayMinValue'].toString() as String);
    this.displayMaxValue =
        double.parse(json?['displayMaxValue'].toString() as String);
    this.displayDefaultValue = disValue;
    this.innerMinValue =
        double.parse(json?['innerMinValue'].toString() as String);
    this.innerMaxValue =
        double.parse(json?['innerMaxValue'].toString() as String);
    setCurrentDisplayValue(disValue);
  }

  Map<String, dynamic> toJson() =>
      {
        'displayMinValue': displayMinValue,
        'displayMaxValue': displayMaxValue,
        'displayDefaultValue': displayDefaultValue,
        'currentDisplayValue': currentDisplayValue,
        'currentInnerValue': currentInnerValue,
        'innerMinValue': innerMinValue,
        'innerMaxValue': innerMaxValue,
        'innerDefaultValue': innerDefaultValue
      };
}

class Category {
  static const String BEAUTY = "BEAUTY";
  static const String BODY_BEAUTY = "BODY_BEAUTY";
  static const String LUT = "LUT";
  static const String MOTION = "MOTION";
  static const String SEGMENTATION = "SEGMENTATION";
  static const String MAKEUP = "MAKEUP";
  static const String KV = "KV";

  static List<String> orderKeys = [
    BEAUTY,
    LUT,
    BODY_BEAUTY,
    MOTION,
    MAKEUP,
    SEGMENTATION
  ];

  static String getNameByCode(String code) {
    switch (code) {
      case "LUT":
        return "滤镜";
      case "BEAUTY":
        return "美颜";
      case "BODY_BEAUTY":
        return "美体";
      case "MOTION":
        return "动效";
      case "SEGMENTATION":
        return "分割";
      case "MAKEUP":
        return "美妆";
    }
    return "";
  }
}

class XmagicUIProperty {
  XmagicProperty? property;
  String? displayName;
  String? thumbDrawableName;
  String? thumbImagePath;
  String? uiCategory;
  String? rootDisplayName;
  bool isUsed = false;
  bool isChecked = false;
  List<XmagicUIProperty>? xmagicUIPropertyList;

  XmagicUIProperty({
    String? uiCategory,
    String? displayName = null,
    String? thumbDrawableName = null,
    String? thumbImagePath = null,
    String? id = null,
    String? resPath = null,
    String? effKey = null,
    XmagicPropertyValues? effValue = null,
    String? rootDisplayName,
    List<XmagicUIProperty>? xmagicUIPropertyList}) {
    this.property = XmagicProperty(category: uiCategory,
        id: id,
        resPath: resPath,
        effKey: effKey,
        effValue: effValue);
    this.displayName = displayName;
    this.thumbDrawableName = thumbDrawableName;
    this.thumbImagePath = thumbImagePath;
    this.uiCategory = uiCategory;
    this.rootDisplayName = rootDisplayName;
    this.xmagicUIPropertyList = xmagicUIPropertyList;
  }


  XmagicUIProperty.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? propertyDynamic = json['property'];
    if (json['xmagicUIPropertyList'] == '') {
      json['xmagicUIPropertyList'] = null;
    }
    XmagicUIProperty(
        displayName: json['displayName'],
        thumbDrawableName: json['thumbDrawableName'],
        thumbImagePath: json['thumbImagePath'],
        uiCategory: json['uiCategory'],
        rootDisplayName: json['rootDisplayName'],
        xmagicUIPropertyList: XmagicDecodeUtil.decodeXmagicUIPropertyList(
            json['xmagicUIPropertyList']))
      ..property = (propertyDynamic == null
          ? null
          : XmagicProperty.fromJson(propertyDynamic));
  }

  Map<String, dynamic> toJson() =>
      {
        'property': property == null ? null : property?.toJson(),
        'displayName': displayName,
        'thumbDrawableName': thumbDrawableName,
        'thumbImagePath': thumbImagePath,
        'uiCategory': uiCategory,
        'rootDisplayName': rootDisplayName,
        'xmagicUIPropertyList':
        xmagicUIPropertyList == null ? null : xmagicUIPropertyListToJson(),
      };

  List<dynamic> xmagicUIPropertyListToJson() {
    var reslut = [];
    xmagicUIPropertyList?.forEach((element) {
      reslut.add(element.toJson());
    });
    return reslut;
  }
}

class LutData {
  String? name;
  String? id;
  String? resourceName = null;

  LutData(String name, String id, String resourceIdName) {
    this.name = name;
    this.id = id;
    this.resourceName = resourceIdName;
  }
}
