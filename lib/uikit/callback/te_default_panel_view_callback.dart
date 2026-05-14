import 'package:flutter/cupertino.dart';

import '../../api/tencent_effect_api.dart';
import '../config/te_res_config.dart';
import '../constant/te_constant.dart';
import '../enhance/te_param_enhancing_strategy.dart';
import '../enhance/default_enhancing_strategy.dart';
import '../manager/te_param_manager.dart';
import '../model/te_ui_property.dart';
import '../utils/te_producer_utils.dart';
import '../view/te_beauty_panel_view_callback.dart';
import '../view/te_beauty_panel_view_controller.dart';

abstract class TEDefaultPanelViewCallBack implements TEBeautyPanelViewCallBack {
  final TEBeautyPanelController panelController = TEBeautyPanelController();
  TEParamManager paramManager = TEParamManager();
  bool hasLightMakeup = false;

  bool _isEnableEnhancedMode = false;
  TEParamEnhancingStrategy _enhancingStrategy = DefaultEnhancingStrategy();

  bool get isEnableEnhancedMode => _isEnableEnhancedMode;

  bool enableEnhancedMode(bool enable) {
    if (_isEnableEnhancedMode != enable) {
      _isEnableEnhancedMode = enable;
      return true;
    }
    return false;
  }

  void setParamEnhancingStrategy(TEParamEnhancingStrategy strategy) {
    _enhancingStrategy = strategy;
  }

  List<TESDKParam> getUsedParams() {
    return paramManager.getParams();
  }

  @override
  void onDefaultEffectList(List<TESDKParam> paramList) {
    onUpdateEffectList(paramList);
  }

  @override
  void onUpdateEffect(TESDKParam sdkParam) {
    if (sdkParam.effectName != null) {
      // For template data, apply first then store (matching Android behavior).
      // This ensures _applyEffect can still read the old template params
      // before they get overwritten by the new sdkParam.
      if (TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME == sdkParam.effectName) {
        _applyEffect(sdkParam);
        paramManager.putTEParam(sdkParam);
      } else {
        paramManager.putTEParam(sdkParam);
        _applyEffect(sdkParam);
      }
    }
  }

  @override
  void onUpdateEffectList(List<TESDKParam> sdkParams) {
    for (TESDKParam sdkParam in sdkParams) {
      onUpdateEffect(sdkParam);
    }
  }

  void _applyEffect(TESDKParam sdkParam) async {
    if (TEffectName.EFFECT_LIGHT_MAKEUP == sdkParam.effectName) {
      hasLightMakeup = true;
    }
    if (hasLightMakeup && TEProducerUtils.isPointMakeup(sdkParam) && TEResConfig.getConfig().cleanLightMakeup) {
      hasLightMakeup = false;
      _setEffectToSDK(TESDKParam(effectName: TEffectName.EFFECT_LIGHT_MAKEUP, effectValue: 0));
    }

    // Handle template data (mirrors Android's applySDKParameterWithTemplateHandling)
    if (TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME == sdkParam.effectName) {
      TEParamManager tempManager = TEParamManager();
      List<TESDKParam> currentParams = paramManager.getParams();
      for (TESDKParam param in currentParams) {
        // Clear old template's beauty data
        if (TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME == param.effectName && param.tag is List) {
          List<TESDKParam> oldTemplateParams = param.tag as List<TESDKParam>;
          List<TESDKParam>? cleared = TEProducerUtils.clone0ValuedParam(oldTemplateParams);
          if (cleared != null) tempManager.putTEParams(cleared);
        }
        // Clear independent beauty/LUT data
        if (TEProducerUtils.isBeautyOrLutName(param.effectName)) {
          TESDKParam cloneParam = param.clone();
          cloneParam.effectValue = 0;
          cloneParam.resourcePath = null;
          paramManager.allData.remove(paramManager.getKey(param));
          tempManager.putTEParam(cloneParam);
        }
      }
      // Add new template's beauty data
      if (sdkParam.tag is List) {
        tempManager.putTEParams(sdkParam.tag as List<TESDKParam>);
      }
      // Apply all merged params to SDK
      for (TESDKParam param in tempManager.getParams()) {
        _setEffectToSDK(param);
      }
    } else if (TEProducerUtils.isBeautyOrLutName(sdkParam.effectName)) {
      // If there was a template, decompose it into individual params
      TESDKParam? templateData = paramManager.allData[TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME];
      if (templateData != null) {
        paramManager.allData.remove(TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME);
        if (templateData.tag is List) {
          paramManager.putTEParams(templateData.tag as List<TESDKParam>);
        }
      }
      _setEffectToSDK(sdkParam);
    } else {
      _setEffectToSDK(sdkParam);
    }
  }

  void _setEffectToSDK(TESDKParam sdkParam) async {
    int effectValue = _isEnableEnhancedMode
        ? _enhancingStrategy.enhanceValue(sdkParam)
        : sdkParam.effectValue;
    TESDKParam param = TESDKParam(
      effectName: sdkParam.effectName,
      effectValue: effectValue,
      resourcePath: sdkParam.resourcePath,
      extraInfo: sdkParam.extraInfo,
    );
    await TEProducerUtils.completionResPathForTESDKParam(param);
    TencentEffectApi.getApi()?.setEffect(param.effectName!, param.effectValue, param.resourcePath, param.extraInfo);
  }

  @override
  void revertEffectAndPanelView(BuildContext context) async {
    List<TESDKParam>? list = await panelController.getRevertPanelData();
    if (list != null) {
      onUpdateEffectList(list);
    }
  }

  @override
  void onTitleClick(TEUIProperty uiProperty) {
    // Default: no-op, subclasses can override
  }

  @override
  void onCompareBtnPressed(bool pressed) {
    TencentEffectApi.getApi()?.setBeautyProcessPaused(pressed);
  }
}
