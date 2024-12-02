
import 'package:tencent_effect_flutter_demo/utils/producer_utils.dart';

import '../constant/te_constant.dart';
import '../model/te_ui_property.dart';

class TEParamManager {
  Map<String, TESDKParam> allData = {};

  void putTEParam(TESDKParam? param) {
    if (param != null &&
        param.effectName != null &&
        param.effectName!.isNotEmpty) {
      if (TEffectName.EFFECT_LIGHT_MAKEUP == param.effectName) {
        //如果是轻美妆
        //当设置了轻美妆的时候 需要删除 单点美妆和滤镜
        removePointMakeup();
      }
      if (ProducerUtils.isPointMakeup(param)) {
        //当设置了单点妆容或滤镜的时候 需要删除 轻美妆
        removeLightMakeup();
      }
      String? key = getKey(param);
      if (key != null) {
        allData[key] = param;
      }
    }
  }

  void putTEParams(List<TESDKParam>? paramList) {
    if (paramList != null && paramList.isNotEmpty) {
      for (TESDKParam teParam in paramList) {
        putTEParam(teParam);
      }
    }
  }

  String? getKey(TESDKParam param) {
    switch (param.effectName) {
      case TEffectName.BEAUTY_WHITEN_0:
      case TEffectName.BEAUTY_WHITEN:
      case TEffectName.BEAUTY_WHITEN_2:
      case TEffectName.BEAUTY_WHITEN_3:
        return TEffectName.BEAUTY_WHITEN;
      case TEffectName.BEAUTY_BLACK_1:
      case TEffectName.BEAUTY_BLACK_2:
        return TEffectName.BEAUTY_BLACK_1;
      case TEffectName.BEAUTY_FACE_NATURE:
      case TEffectName.BEAUTY_FACE_GODNESS:
      case TEffectName.BEAUTY_FACE_MALE_GOD:
        return TEffectName.BEAUTY_FACE_NATURE;
      case TEffectName.EFFECT_MAKEUP:
      case TEffectName.EFFECT_MOTION:
      case TEffectName.EFFECT_SEGMENTATION:
        return TEffectName.EFFECT_MOTION;
      default:
        return param.effectName;
    }
  }

  List<TESDKParam> getParams() {
    return allData.values.toList();
  }

  void clear() {
    allData.clear();
  }

  bool isEmpty() {
    return allData.isEmpty;
  }

  void removePointMakeup() {
    for (String effectName in ProducerUtils.pointMakeupEffectName) {
      allData.remove(effectName);
    }
  }

  void removeLightMakeup() {
    allData.remove(TEffectName.EFFECT_LIGHT_MAKEUP);
  }
}
