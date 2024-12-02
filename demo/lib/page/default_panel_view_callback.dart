
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter_demo/constant/te_constant.dart';
import 'package:tencent_effect_flutter_demo/manager/te_param_manager.dart';
import 'package:tencent_effect_flutter_demo/utils/producer_utils.dart';

import '../model/te_ui_property.dart';
import '../view/beauty_panel_view.dart';
import '../view/beauty_panel_view_callback.dart';

class DefaultPanelViewCallBack implements BeautyPanelViewCallBack {
  final GlobalKey globalKey = GlobalKey();
  List<TESDKParam>? _defaultEffectList;
  bool _isEnable = false;
  TEParamManager paramManager = TEParamManager();
  bool hasLightMakeup = false;

  final bool _pickImg = true ; // true indicates selecting an image for custom background, false indicates selecting a video.

  ///The purpose of this method is:
  ///When enabling beauty effect, set the default beauty data returned by the panel.
   ///When disabling the beauty effect, temporarily store the previously applied beauty attributes, and reapply them when the beauty effect is enabled again.
  void setEnableEffect(bool enable) {
    _isEnable = enable;
    if (_defaultEffectList != null) {
      onUpdateEffectList(_defaultEffectList!);
      _defaultEffectList = null;
    }
    if (!enable) {
      _defaultEffectList = getUsedParams();
    }
  }

  List<TESDKParam> getUsedParams() {
    return paramManager.getParams();
  }

  @override
  Future<void> onClickCustomSeg(TEUIProperty uiProperty) async {
    if (uiProperty.sdkParam?.extraInfo == null) {
      return;
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
    ].request();
    if (statuses[Permission.photos] != PermissionStatus.denied) {
      final ImagePicker _picker = ImagePicker();
      // Pick an image
      XFile? xFile = _pickImg
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickVideo(source: ImageSource.gallery);
      if (xFile == null) {
        return;
      }
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_TYPE] =
          _pickImg
              ? TESDKParam.EXTRA_INFO_BG_TYPE_IMG
              : TESDKParam.EXTRA_INFO_BG_TYPE_VIDEO;
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_PATH] =
          xFile.path;
      onUpdateEffect(uiProperty.sdkParam!);
      PanelViewState panelViewState = globalKey.currentState as PanelViewState;
      panelViewState.checkPanelViewItem(uiProperty);
    }
  }

  @override
  void onDefaultEffectList(List<TESDKParam> paramList) {
    if (_isEnable) {
      onUpdateEffectList(paramList);
    } else {
      _defaultEffectList = paramList;
    }
  }

  @override
  void onUpdateEffect(TESDKParam sdkParam) {
    debugPrint("onUpdateEffect   ${sdkParam.toJson().toString()}");
    if (sdkParam.effectName != null) {
      paramManager.putTEParam(sdkParam);
      _setEffect(sdkParam);
    }
  }

  @override
  void onUpdateEffectList(List<TESDKParam> sdkParams) {
    for (TESDKParam sdkParam in sdkParams) {
      onUpdateEffect(sdkParam);
    }
  }

  void _setEffect(TESDKParam sdkParam){
    _clearLightMakeup(sdkParam);
    TencentEffectApi.getApi()?.setEffect(sdkParam.effectName!,
        sdkParam.effectValue, sdkParam.resourcePath, sdkParam.extraInfo);
  }


  void _clearLightMakeup(TESDKParam sdkParam) {
    if (TEffectName.EFFECT_LIGHT_MAKEUP == sdkParam.effectName) {
      hasLightMakeup = true;
    }
    if (hasLightMakeup && ProducerUtils.isPointMakeup(sdkParam)) {
      hasLightMakeup = false;
      TencentEffectApi.getApi()
          ?.setEffect(TEffectName.EFFECT_LIGHT_MAKEUP, 0, null, null);
    }
  }
}
