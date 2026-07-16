import 'dart:convert';
import 'package:flutter/services.dart';
import '../api/tencent_effect_api.dart';
import '../utils/Logs.dart';
import '../utils/xmagic_decode_utils.dart';
import '../model/xmagic_property.dart';

/// 平台 API 基类，封装 Android 和 iOS 共用的逻辑
abstract class TencentEffectApiBase extends TencentEffectApi {
  static const String METHOD_CHANNEL_NAME = "tencent_effect_methodChannel_call_native";
  static const String EVENT_CHANNEL_NAME = "tencent_effect_methodChannel_call_flutter";

  /// 子类需要提供的 TAG，用于日志打印
  String get tag;

  final MethodChannel channel = MethodChannel(METHOD_CHANNEL_NAME);
  final EventChannel eventChannel = EventChannel(EVENT_CHANNEL_NAME);
  final MethodChannel _tencentRTCChannel = MethodChannel("TencentRTCffi");

  OnCreateXmagicApiErrorListener? onCreateXmagicApiErrorListener;
  XmagicAIDataListener? xmagicAIDataListener;
  XmagicTipsListener? xmagicTipsListener;
  XmagicYTDataListener? xmagicYTDataListener;
  LicenseCheckListener? licenseCheckListener;
  InitXmagicCallBack? initXmagicCallBack;
  XmagicApiCreatedListener? apiCreatedListener;

  TencentEffectApiBase() {
    eventChannel.receiveBroadcastStream().listen(onEventChannelCallbackData);
  }

  /// 处理原生回调数据，子类可以重写此方法来处理平台特有的数据格式
  void onEventChannelCallbackData(dynamic parameter) {
    if (!(parameter is Map)) {
      return;
    }
    String methodName = parameter['methodName'];
    switch (methodName) {
      case "initXmagic":
        handleInitXmagicCallback(parameter);
        break;
      case "onLicenseCheckFinish":
        handleLicenseCheckCallback(parameter);
        break;
      case "aidata_onFaceDataUpdated":
        xmagicAIDataListener?.onFaceDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onHandDataUpdated":
        xmagicAIDataListener?.onHandDataUpdated(parameter['data'] as String);
        break;
      case "aidata_onBodyDataUpdated":
        xmagicAIDataListener?.onBodyDataUpdated(parameter['data'] as String);
        break;
      case "tipsNeedShow":
        handleTipsNeedShow(parameter);
        break;
      case "tipsNeedHide":
        handleTipsNeedHide(parameter);
        break;
      case "onYTDataUpdate":
        if (xmagicYTDataListener != null) {
          xmagicYTDataListener!(parameter['data'] as String);
        }
        break;
      case "onXmagicApiCreated":
        if (apiCreatedListener != null) {
          String code = parameter['data'] as String;
          apiCreatedListener!(int.parse(code));
        }
        break;
      default:
        handlePlatformSpecificCallback(methodName, parameter);
    }
  }

  /// 处理 initXmagic 回调，子类需要实现以处理平台差异
  void handleInitXmagicCallback(Map parameter) {
    TXLog.i("handleInitXmagicCallback parameter: $parameter");
    if (initXmagicCallBack != null) {
      // iOS 端传递的 @true/@false (NSNumber) 会被解码为 int (1/0)
      // 需要兼容 bool 和 int 两种类型
      var rawData = parameter['data'];
      bool data;
      if (rawData is bool) {
        data = rawData;
      } else if (rawData is int) {
        data = rawData != 0;
      } else {
        data = false;
      }
      initXmagicCallBack!(data);
      initXmagicCallBack = null;
    }
  }

  /// 处理 License 检查回调（iOS 和 Android 格式已统一）
  void handleLicenseCheckCallback(Map parameter) {
    Map map = parameter['data'];
    int code = map['code'] as int;
    String msg = map['msg'] as String;
    if (licenseCheckListener != null) {
      licenseCheckListener!(code, msg);
      licenseCheckListener = null;
    }
  }

  /// 处理 tipsNeedShow 回调，子类需要实现以处理平台差异
  void handleTipsNeedShow(Map parameter);

  /// 处理 tipsNeedHide 回调，子类需要实现以处理平台差异
  void handleTipsNeedHide(Map parameter);

  /// 处理平台特有的回调，子类可以重写
  void handlePlatformSpecificCallback(String methodName, Map parameter) {}

  @override
  void setOnCreateXmagicApiErrorListener(OnCreateXmagicApiErrorListener? errorListener) {
    onCreateXmagicApiErrorListener = errorListener;
  }

  @override
  void setXmagicApiCreatedListener(XmagicApiCreatedListener? createListener) {
    apiCreatedListener = createListener;
  }

  @override
  void setAIDataListener(XmagicAIDataListener? aiDataListener) {
    this.xmagicAIDataListener = aiDataListener;
    channel.invokeMethod("enableAIDataListener", aiDataListener != null);
  }

  @override
  void setTipsListener(XmagicTipsListener? tipsListener) {
    this.xmagicTipsListener = tipsListener;
    channel.invokeMethod("enableTipsListener", tipsListener != null);
  }

  @override
  void setYTDataListener(XmagicYTDataListener? ytDataListener) {
    this.xmagicYTDataListener = ytDataListener;
    channel.invokeMethod("enableYTDataListener", ytDataListener != null);
  }

  @override
  void initXmagic(InitXmagicCallBack xmagicCallBack) {
    initXmagicCallBack = xmagicCallBack;
    channel.invokeMethod("initXmagic");
  }

  @override
  void onPause() {
    channel.invokeMethod("onPause");
  }

  @override
  void onResume() {
    channel.invokeMethod("onResume");
  }

  @override
  void enableEnhancedMode() {
    channel.invokeMethod("enableEnhancedMode");
  }

  @override
  void setLicense(String licenseKey, String licenseUrl, LicenseCheckListener checkListener) {
    var parameter = {"licenseKey": licenseKey, "licenseUrl": licenseUrl};
    channel.invokeMethod("setLicense", parameter);
    licenseCheckListener = checkListener;
  }

  @override
  void setXmagicLogLevel(int logLevel) {
    channel.invokeMethod("setXmagicLogLevel", logLevel);
  }

  @override
  void updateProperty(XmagicProperty xmagicProperty) {
    channel.invokeMethod("updateProperty", json.encode(xmagicProperty.toJson()));
  }

  @override
  Future<Map<String, bool>> getDeviceAbilities() async {
    dynamic result = await channel.invokeMethod("getDeviceAbilities");
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
  Future<Map<XmagicProperty, List<String>?>> getPropertyRequiredAbilities(List<XmagicProperty> assetsList) async {
    String parameter = json.encode(assetsList);
    TXLog.printlog("$tag method is getPropertyRequiredAbilities ,parameter is $parameter");
    dynamic result = await channel.invokeMethod("getPropertyRequiredAbilities", parameter);
    Map<XmagicProperty, List<String>> map = Map();
    if (result == null || result == "null") {
      return map;
    }
    TXLog.printlog("$tag method is getPropertyRequiredAbilities,native result data is $result");
    Map<dynamic, dynamic> data = json.decode(result);
    data.forEach((key, value) {
      if (value != null) {
        List<String>? list = XmagicDecodeUtil.decodeStringList(value);
        if (list != null && list.length > 0) {
          XmagicProperty property = parsePropertyFromKey(key);
          map[property] = list;
        }
      }
    });
    return map;
  }

  /// 解析 XmagicProperty，子类需要实现以处理平台差异
  XmagicProperty parsePropertyFromKey(dynamic key);

  @override
  Future<List<XmagicProperty>> isBeautyAuthorized(List<XmagicProperty> properties) async {
    String parameter = json.encode(properties);
    TXLog.printlog("$tag method is isBeautyAuthorized ,parameter is  $parameter");
    var result = await channel.invokeMethod("isBeautyAuthorized", parameter);
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
  Future<List<XmagicProperty>> isDeviceSupport(List<XmagicProperty> assetsList) async {
    String parameter = json.encode(assetsList);
    TXLog.printlog("$tag method is isDeviceSupport ,parameter is  $parameter");
    var result = await channel.invokeMethod("isDeviceSupport", parameter);
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
    channel.invokeMethod("setDowngradePerformance");
  }

  @override
  void setAudioMute(bool isMute) {
    channel.invokeMethod("setAudioMute", isMute);
  }

  @override
  void setFeatureEnableDisable(String featureName, enable) {
    var parameter = {featureName: enable};
    channel.invokeMethod("setFeatureEnableDisable", parameter);
  }

  @override
  void setImageOrientation(TEImageOrientation orientation) {
    channel.invokeMethod("setImageOrientation", orientation.toType());
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
    channel.invokeMethod("setEffect", params);
  }

  @override
  void setResourcePath(String xMagicResDir) {
    channel.invokeMethod("setResourcePath", {"pathDir": xMagicResDir});
  }

  @override
  Future<bool> isDeviceSupportMotion(String motionResPath) async {
    return await channel.invokeMethod("isDeviceSupportMotion", {"motionResPath": motionResPath});
  }

  @override
  void enableHighPerformance() {
    channel.invokeMethod("enableHighPerformance");
  }

  @override
  Future<int> getDeviceLevel() async {
    return await channel.invokeMethod("getDeviceLevel");
  }

  @override
  void setEffectMode(EffectMode effectMode) {
    if (effectMode == EffectMode.NORMAL) {
      channel.invokeMethod("setEffectMode", "0");
    } else {
      channel.invokeMethod("setEffectMode", "1");
    }
  }

  @override
  Future<bool> isSupportBeauty() async {
    dynamic result = await channel.invokeMethod("isSupportBeauty");
    if (result is bool) {
      return result;
    } else if (result is int) {
      return result != 0;
    }
    return false;
  }

  bool isBeautyEnabled = false;

  @override
  Future<int> enableBeauty(bool enable) async {
    if (enable == isBeautyEnabled) {
      return -1;
    }
    isBeautyEnabled = enable;
    try {
      int result = await _tencentRTCChannel.invokeMethod('enableVideoProcessByNative', {"enable": enable});
      return result;
    } catch (e) {
      return -2;
    }
  }

  @override
  void setSyncMode(bool isSync, int syncFrameCount) {
    channel.invokeMethod("setSyncMode", {"isSync": isSync, "syncFrameCount": syncFrameCount});
  }

  @override
  void setBeautyProcessPaused(bool paused) {
    channel.invokeMethod("setBeautyProcessPaused", {"beautyProcessPaused": paused});
  }


  @override
  void setOutputTextureKeepRatio(double ratio){
    channel.invokeMethod("setOutputTextureKeepRatio", ratio);
  }
}
