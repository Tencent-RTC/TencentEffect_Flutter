import 'dart:io';
import 'dart:typed_data';
import 'package:tencent_effect_flutter/api/android/tencent_effect_api_android.dart';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';

import 'ios/tencent_effect_api_ios.dart';


abstract class TencentEffectApi {
  static TencentEffectApi? _api;

  TencentEffectApi._internal();

  static TencentEffectApi? getApi() {
    if (_api != null) {
      return _api;
    }
    if (Platform.isAndroid) {
      _api = TencentEffectApiAndroid();
    } else if (Platform.isIOS) {
      _api = TencentEffectApiIOS();
    } else {}
    return _api;
  }
   ///Set the local path for storing beauty resources. This method must be called before using the beauty feature.
   ///Added in v0.3.5.
  void setResourcePath(String xmagicResDir);

  /// Initialize beauty data
  /// Before version 0.3.1.0, this method must be called before using the beauty feature.
  /// Starting from version 0.3.5.0, this method only needs to be called once per version, and the setResourcePath method must be called before this method to set the resource path. The previous xmagicResDir parameter has been removed.
  void initXmagic(InitXmagicCallBack callBack);

  ///check auth
  void setLicense(String licenseKey, String licenseUrl, LicenseCheckListener checkListener);


  void setXmagicLogLevel(int logLevel);


  void onResume();


  void onPause();


  void enableEnhancedMode();


  void setDowngradePerformance();



  void setAudioMute(bool isMute);


  void setFeatureEnableDisable(String featureName, bool enable);


  void setImageOrientation(TEImageOrientation orientation);


  @deprecated
  void updateProperty(XmagicProperty property);

  void setEffect(String effectName,int effectValue,String? resourcePath,Map<String,String>? extraInfo);


  void setOnCreateXmagicApiErrorListener(OnCreateXmagicApiErrorListener? errorListener);


  void setTipsListener(XmagicTipsListener? tipsListener);


  void setYTDataListener(XmagicYTDataListener? ytDataListener);


  void setAIDataListener(XmagicAIDataListener? aiDataListener);

  @deprecated
  Future<List<XmagicProperty>> isBeautyAuthorized(List<XmagicProperty> properties);


  Future<bool> isSupportBeauty();


  Future<Map<String, bool>> getDeviceAbilities();

  @deprecated
  Future<Map<XmagicProperty, List<String>?>> getPropertyRequiredAbilities(List<XmagicProperty> assetsList);


  Future<bool> isDeviceSupportMotion(String motionResPath);

  @deprecated
  Future<List<XmagicProperty>> isDeviceSupport(List<XmagicProperty> assetsList);
}


typedef LicenseCheckListener = void Function(int errorCode, String msg);


typedef OnCreateXmagicApiErrorListener = void Function(String errorMsg, int code);

typedef XmagicYTDataListener = void Function(String data);

typedef InitXmagicCallBack = void Function(bool reslut);

typedef ProcessImgCallBack = void Function(Uint8List uint8list, int width, int height);

abstract class XmagicTipsListener {
  ///Show the tip.
  /// @param tips tips。Tip's content
  /// @param tipsIcon tips icon。Tip's icon
  /// @param type tips category, 0 means that both strings and icons are displayed, 1 means that only the icon is displayed for the pag material
  /// @param duration , Tips display duration, milliseconds
  void tipsNeedShow(String tips, String tipsIcon, int type, int duration);

  /// *
  /// Hide the tip.
  /// @param tips tips。Tip's content
  /// @param tipsIcon tips icon。Tip's icon
  /// @param type tips category, 0 means that both strings and icons are displayed, 1 means that only the icon is displayed for the pag material
  void tipsNeedHide(String tips, String tipsIcon, int type);
}

abstract class XmagicAIDataListener {
  void onFaceDataUpdated(String faceDataList);

  void onHandDataUpdated(String handDataList);

  void onBodyDataUpdated(String bodyDataList);
}

class LogLevel {
  static const int VERBOSE = 2;
  static const int DEBUG = 3;
  static const int INFO = 4;
  static const int WARN = 5;
  static const int ERROR = 6;
  static const int ASSERT = 7;
}


enum TEImageOrientation {
  ROTATION_0,
  ROTATION_90,
  ROTATION_180,
  ROTATION_270,
}

extension TEImageOrientationExtension on TEImageOrientation {
  int toType() {
    switch (this) {
      case TEImageOrientation.ROTATION_0:
        return 0;
      case TEImageOrientation.ROTATION_90:
        return 1;
      case TEImageOrientation.ROTATION_180:
        return 2;
      case TEImageOrientation.ROTATION_270:
        return 3;
    }
  }
}
