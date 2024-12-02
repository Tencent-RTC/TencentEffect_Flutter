import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_effect_flutter/utils/xmagic_decode_utils.dart';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';

///ios Api
class TencentEffectApiIOS implements TencentEffectApi {
  static const String METHOD_CHANNEL_NAME =
      "tencent_effect_methodChannel_call_native";
  static const String EVENT_CHANNEL_NAME =
      "tencent_effect_methodChannel_call_flutter";
  static const String TAG = "TencentEffectApiIOS";

  MethodChannel _channel = MethodChannel(METHOD_CHANNEL_NAME);
  OnCreateXmagicApiErrorListener? _onCreateXmagicApiErrorListener;
  XmagicAIDataListener? _xmagicAIDataListener;
  XmagicTipsListener? _xmagicTipsListener;
  XmagicYTDataListener? _xmagicYTDataListener;
  LicenseCheckListener? _licenseCheckListener;
  InitXmagicCallBack? _initXmagicCallBack;

  TencentEffectApiIOS() {
    EventChannel(EVENT_CHANNEL_NAME)
      ..receiveBroadcastStream().listen(_onEventChannelCallbackData);
  }

  void _onEventChannelCallbackData(parameter) {
    if(!(parameter is Map)){
      return;
    }
    String methodName = parameter['methodName'];
    switch (methodName) {
      case "initXmagic":
        if (_initXmagicCallBack != null) {
          var data = parameter['data'] as int;
          _initXmagicCallBack!(data == 1);
          _initXmagicCallBack = null;
        }
        break;
      case "onLicenseCheckFinish":
        int code = parameter['code'] as int;
        String msg = parameter['msg'] as String;
        if (_licenseCheckListener != null) {
          _licenseCheckListener!(code, msg);
          _licenseCheckListener = null;
        }
        break;
      case "onXmagicPropertyError":
        Map map = parameter['data'];
        String msg = map['msg'] as String;
        int code = map['code'] as int;
        if (_onCreateXmagicApiErrorListener != null) {
          _onCreateXmagicApiErrorListener!(msg, code);
        }
        break;
      case "aidata_onFaceDataUpdated":
        _xmagicAIDataListener?.onFaceDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onHandDataUpdated":
        _xmagicAIDataListener?.onHandDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onBodyDataUpdated":
        _xmagicAIDataListener?.onBodyDataUpdated(parameter['data'] as String);
        break;
      case "tipsNeedShow":
        String tips = parameter['tips'] as String;
        String tipsIcon = parameter['tipsIcon'] as String;
        int type = parameter['type'] as int;
        int duration = parameter['duration'] as int;
        _xmagicTipsListener?.tipsNeedShow(tips, tipsIcon, type, duration);
        break;
      case "tipsNeedHide":
        String tips = parameter['tips'] as String;
        String tipsIcon = parameter['tipsIcon'] as String;
        int type = parameter['type'] as int;
        _xmagicTipsListener?.tipsNeedHide(tips, tipsIcon, type);
        break;
      case "onYTDataUpdate":
        if (_xmagicYTDataListener != null) {
          _xmagicYTDataListener!(parameter['data'] as String);
        }
        break;
    }
  }

  @override
  void setOnCreateXmagicApiErrorListener(
      OnCreateXmagicApiErrorListener? errorListener) {
    _onCreateXmagicApiErrorListener = errorListener;
  }

  @override
  void initXmagic(InitXmagicCallBack xmagicCallBack) {
    _initXmagicCallBack = xmagicCallBack;
    _channel.invokeMethod("initXmagic");
  }

  @override
  void onPause() {
    _channel.invokeMethod("onPause");
  }

  @override
  void onResume() {
    _channel.invokeMethod("onResume");
  }

  @override
  void enableEnhancedMode() {
    _channel.invokeMethod("enableEnhancedMode");
  }

  @override
  void setLicense(String licenseKey, String licenseUrl,
      LicenseCheckListener checkListener) {
    var paramter = {"licenseKey": licenseKey, "licenseUrl": licenseUrl};
    _channel.invokeMethod("setLicense", paramter);
    _licenseCheckListener = checkListener;
  }

  @override
  void setXmagicLogLevel(int logLevel) {
    _channel.invokeMethod("setXmagicLogLevel", logLevel);
  }

  @override
  void updateProperty(XmagicProperty xmagicProperty) {
    _channel.invokeMethod<String>(
        "updateProperty", json.encode(xmagicProperty.toJson()));
  }

  @override
  void setAIDataListener(XmagicAIDataListener? aiDataListener) {
    this._xmagicAIDataListener = aiDataListener;
  }

  @override
  void setTipsListener(XmagicTipsListener? xmagicTipsListener) {
    this._xmagicTipsListener = xmagicTipsListener;
  }

  @override
  void setYTDataListener(XmagicYTDataListener? xmagicYTDataListener) {
    this._xmagicYTDataListener = xmagicYTDataListener;
  }

  @override
  Future<Map<String, bool>> getDeviceAbilities() async {
    dynamic result = await _channel.invokeMethod("getDeviceAbilities");
    if (result == null || result == "null") {
      return {};
    }
    Map<String, bool> map = Map();
    var data = json.decode(result);
    data.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  @override
  Future<Map<XmagicProperty, List<String>?>> getPropertyRequiredAbilities(
      List<XmagicProperty> assetsList) async {
    String parameter = json.encode(assetsList);
    TXLog.printlog(
        "$TAG method is getPropertyRequiredAbilities ,parameter is $parameter");
    dynamic result =
        await _channel.invokeMethod("getPropertyRequiredAbilities", parameter);
    Map<XmagicProperty, List<String>> map = Map();
    if (result == null || result == "null") {
      return map;
    }
    TXLog.printlog(
        "$TAG method is getPropertyRequiredAbilities,native result data is $result");
    Map<dynamic, dynamic> data = json.decode(result);
    data.forEach((key, value) {
      if (value != null) {
        List<String>? list = XmagicDecodeUtil.decodeStringList(value);
        if (list != null && list.length > 0) {
          map[XmagicProperty.fromJson(key)] = list;
        }
      }
    });
    return map;
  }

  @override
  Future<bool> isSupportBeauty() async {
    dynamic result = await _channel.invokeMethod("isSupportBeauty");
    result = (result == 1);
    return result as bool;
  }

  @override
  Future<List<XmagicProperty>> isBeautyAuthorized(
      List<XmagicProperty> properties) async {
    String parameter = json.encode(properties);
    TXLog.printlog(
        "$TAG method is isBeautyAuthorized ,parameter is  $parameter");
    var result = await _channel.invokeMethod("isBeautyAuthorized", parameter);
    if (result == null || result == "null") {
      return [];
    }
    List<dynamic> data = json.decode(result);
    List<XmagicProperty> resultData = [];
    data.forEach((element) {
      resultData.add(XmagicProperty.fromJson(element));
    });
    return resultData;
  }

  @override
  Future<List<XmagicProperty>> isDeviceSupport(
      List<XmagicProperty> assetsList) async {
    String parameter = json.encode(assetsList);
    TXLog.printlog("$TAG method is isDeviceSupport ,parameter is  $parameter");
    var result = await _channel.invokeMethod("isDeviceSupport", parameter);
    if (result == null || result == "null") {
      return [];
    }
    List<dynamic> data = json.decode(result);
    List<XmagicProperty> resultData = [];
    data.forEach((element) {
      resultData.add(XmagicProperty.fromJson(element));
    });
    return resultData;
  }

  @override
  void setDowngradePerformance() {
    _channel.invokeMethod("setDowngradePerformance");
  }

  @override
  void setAudioMute(bool isMute) {
    _channel.invokeMethod("setAudioMute", isMute);
  }

  @override
  void setFeatureEnableDisable(String featureName, enable) {
    var parameter = {featureName: enable};
    _channel.invokeMethod("setFeatureEnableDisable", parameter);
  }

  @override
  void setImageOrientation(TEImageOrientation orientation) {
    _channel.invokeMethod("setImageOrientation", orientation.toType());
  }

  @override
  void setEffect(String effectName, int effectValue, String? resourcePath, Map<String, String>? extraInfo) {
    Map<String, Object> params = {};
    params["effectName"] = effectName;
    params["effectValue"] = effectValue;
    if (resourcePath != null) {
      params["resourcePath"] = resourcePath;
    }
    if (extraInfo != null) {
      params["extraInfo"] = extraInfo;
    }
    _channel.invokeMethod("setEffect", params);
  }

  @override
  void setResourcePath(String xmagicResDir) {
    _channel.invokeMethod("setResourcePath",{"pathDir":xmagicResDir});
  }

  @override
  Future<bool>  isDeviceSupportMotion(String motionResPath) async{
    return await _channel.invokeMethod(
        "isDeviceSupportMotion", {"motionResPath": motionResPath});
  }

  @override
  void enableHighPerformance() {
    _channel.invokeMethod("enableHighPerformance");
  }

  @override
  @override
  Future<int> getDeviceLevel() async {
    return await _channel.invokeMethod("getDeviceLevel");
  }

  @override
  void setEffectMode(EffectMode effectMode) {
    if (effectMode == EffectMode.NORMAL) {
      _channel.invokeMethod("setEffectMode", "0");
    } else {
      _channel.invokeMethod("setEffectMode", "1");
    }
  }
}
