import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/te_ui_property.dart';

class BeautyParamManager {
  static const String beautyParamKey = "beauty_Params_key";

  static void saveBeautyParam(List<TESDKParam> sdkParams) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String params = json.encode(sdkParams);
    sharedPreferences.setString(beautyParamKey, params);
  }

  static Future<List<TESDKParam>?> getBeautyParam() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? params = sharedPreferences.getString(beautyParamKey);
    if (params != null) {
      List<dynamic> data = json.decode(params);
      List<TESDKParam> resultData = [];
      for (var element in data) {
        resultData.add(TESDKParam.fromJson(element));
      }
      return resultData;
    }
    return null;
  }
}
