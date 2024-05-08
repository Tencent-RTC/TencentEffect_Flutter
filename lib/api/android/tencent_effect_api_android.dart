import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/utils/Logs.dart';
import 'package:tencent_effect_flutter/utils/xmagic_decode_utils.dart';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';


///Android Api
class TencentEffectApiAndroid implements TencentEffectApi {
  static const String METHOD_CHANNEL_NAME = "tencent_effect_methodChannel_call_native";
  static const String EVENT_CHANNEL_NAME = "tencent_effect_methodChannel_call_flutter";
  static const String TAG = "TencentEffectApiAndroid";


  MethodChannel _channel = MethodChannel(METHOD_CHANNEL_NAME);
  OnCreateXmagicApiErrorListener? _onCreateXMagicApiErrorListener;
  XmagicAIDataListener? _xMagicAIDataListener;
  XmagicTipsListener? _xMagicTipsListener;
  XmagicYTDataListener? _xMagicYTDataListener;
  LicenseCheckListener? _licenseCheckListener;
  InitXmagicCallBack? _initXMagicCallBack;
  Map<String,AddAiModeCallBack> _addAiModeCallBackMap = new Map();

  TencentEffectApiAndroid() {
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
        if (_initXMagicCallBack != null) {
          var data = parameter['data'] as bool;
          _initXMagicCallBack!(data);
          _initXMagicCallBack = null;
        }
        break;
      case "addAiMode":
        Map map = parameter['data'];
        String inputDir = map['input'] as String;
        int code = map['code'] as int;
        AddAiModeCallBack callBack =
            _addAiModeCallBackMap[inputDir] as AddAiModeCallBack;
        callBack!(inputDir, code);
        _addAiModeCallBackMap.remove(inputDir);
        break;
      case "onLicenseCheckFinish":
        Map map = parameter['data'];
        int code = map['code'] as int;
        String msg = map['msg'] as String;
        if (_licenseCheckListener != null) {
          _licenseCheckListener!(code, msg);
          _licenseCheckListener = null;
        }
        break;
      case "onXmagicPropertyError":
        Map map = parameter['data'];
        String msg = map['msg'] as String;
        int code = map['code'] as int;
        if (_onCreateXMagicApiErrorListener != null) {
          _onCreateXMagicApiErrorListener!(msg, code);
        }
        break;
      case "aidata_onFaceDataUpdated":
        _xMagicAIDataListener?.onFaceDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onHandDataUpdated":
        _xMagicAIDataListener?.onHandDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onBodyDataUpdated":
        _xMagicAIDataListener?.onBodyDataUpdated(parameter['data'] as String);
        break;
      case "tipsNeedShow":
        Map map = parameter['data'];
        String tips = map['tips'] as String;
        String tipsIcon = map['tipsIcon'] as String;
        int type = map['type'] as int;
        int duration = map['duration'] as int;
        _xMagicTipsListener?.tipsNeedShow(tips, tipsIcon, type, duration);
        break;
      case "tipsNeedHide":
        Map map = parameter['data'];
        String tips = map['tips'] as String;
        String tipsIcon = map['tipsIcon'] as String;
        int type = map['type'] as int;
        _xMagicTipsListener?.tipsNeedHide(tips, tipsIcon, type);
        break;
      case "onYTDataUpdate":
        if (_xMagicYTDataListener != null) {
          _xMagicYTDataListener!(parameter['data'] as String);
        }
        break;

    }
  }

  @override
  void setOnCreateXmagicApiErrorListener(OnCreateXmagicApiErrorListener? errorListener) {
    _onCreateXMagicApiErrorListener = errorListener;
  }



  @override
  void initXmagic(InitXmagicCallBack xmagicCallBack) {
    _initXMagicCallBack = xmagicCallBack;
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
  void setLicense(String licenseKey, String licenseUrl,
      LicenseCheckListener checkListener) {
    var parameter = {"licenseKey": licenseKey, "licenseUrl": licenseUrl};
    _channel.invokeMethod("setLicense", parameter);
    _licenseCheckListener = checkListener;
  }

  @override
  void setXmagicLogLevel(int logLevel) {
    _channel.invokeMethod("setXmagicLogLevel", logLevel);
  }

  @override
  void updateProperty(XmagicProperty xmagicProperty) {
    _channel.invokeMethod("updateProperty", json.encode(xmagicProperty.toJson()));
  }

  @override
  void setAIDataListener(XmagicAIDataListener? aiDataListener) {
    this._xMagicAIDataListener = aiDataListener;
    _channel.invokeMethod("enableAIDataListener", aiDataListener != null);
  }

  @override
  void setTipsListener(XmagicTipsListener? tipsListener) {
    this._xMagicTipsListener = tipsListener;
    _channel.invokeMethod("enableTipsListener", tipsListener != null);
  }

  @override
  void setYTDataListener(XmagicYTDataListener? ytDataListener) {
    this._xMagicYTDataListener = ytDataListener;
    _channel.invokeMethod("enableYTDataListener", ytDataListener != null);
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
    TXLog.printlog("$TAG method is getPropertyRequiredAbilities ,parameter is $parameter");
    dynamic result =
    await _channel.invokeMethod("getPropertyRequiredAbilities", parameter);
    Map<XmagicProperty, List<String>> map = Map();
    if (result == null || result == "null") {
      return map;
    }
    TXLog.printlog("$TAG method is getPropertyRequiredAbilities,native result data is $result");
    Map<dynamic, dynamic> data = json.decode(result);
    data.forEach((key, value) {
      if (value != null) {
        List<String>? list = XmagicDecodeUtil.decodeStringList(value);
        if (list != null && list.length > 0) {
         XmagicProperty property= XmagicProperty.fromJson(json.decode(key));
          map[property] = list;
        }
      }
    });
    return map;
  }

  @override
  Future<bool> isSupportBeauty() async {
    dynamic result = await _channel.invokeMethod("isSupportBeauty");
    return result as bool;
  }

  @override
  Future<List<XmagicProperty>> isBeautyAuthorized(
      List<XmagicProperty> properties) async {
    String parameter = json.encode(properties);
    TXLog.printlog("$TAG method is isBeautyAuthorized ,parameter is  $parameter");
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
  void enableEnhancedMode() {
    _channel.invokeMethod("enableEnhancedMode");
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


  void addAiMode(String inputDir, String resDir, AddAiModeCallBack callBack) {
    this._addAiModeCallBackMap[inputDir] = callBack;
    Map<String,String> parameter = {"input": inputDir, "res": resDir};
    _channel.invokeMethod("addAiMode",parameter );
  }


  Future<bool> setLibPathAndLoad(String libPath) async  {
     var result = await _channel.invokeMethod("setLibPathAndLoad",libPath );
     return result;
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
  void setResourcePath(String xMagicResDir) {
    _channel.invokeMethod("setResourcePath",{"pathDir":xMagicResDir});
  }

  @override
  Future<bool> isDeviceSupportMotion(String motionResPath) async {
    return await _channel.invokeMethod(
        "isDeviceSupportMotion", {"motionResPath": motionResPath});
  }
}
typedef AddAiModeCallBack = void Function(String inputDir, int code);