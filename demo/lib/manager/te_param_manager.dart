
import '../constant/te_constant.dart';
import '../model/te_ui_property.dart';

class TEParamManager {
  Map<String, TESDKParam> allData = {};

  void putTEParam(TESDKParam? param) {
    if (param != null &&
        param.effectName != null &&
        param.effectName!.isNotEmpty) {
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
      case TEffectName.BEAUTY_WHITEN:
      case TEffectName.BEAUTY_WHITEN_2:
      case TEffectName.BEAUTY_WHITEN_3:
        return TEffectName.BEAUTY_WHITEN;
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
}
