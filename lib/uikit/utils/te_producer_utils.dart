import 'dart:convert';
import 'dart:io';

import '../constant/te_constant.dart';
import '../manager/te_res_path_manager.dart';
import '../model/te_ui_property.dart';

class TEProducerUtils {
  static const String HTTP_NAME = "http";
  static const String ZIP_NAME = ".zip";

  static final List<String> BEAUTY_BLACK_EFFECT_NAMES = [TEffectName.BEAUTY_BLACK_1, TEffectName.BEAUTY_BLACK_2];

  static final List<String> BEAUTY_WHITEN_EFFECT_NAMES = [
    TEffectName.BEAUTY_WHITEN_0,
    TEffectName.BEAUTY_WHITEN,
    TEffectName.BEAUTY_WHITEN_2,
    TEffectName.BEAUTY_WHITEN_3,
  ];

  static final List<String> BEAUTY_FACE_EFFECT_NAMES = [
    TEffectName.BEAUTY_FACE_NATURE,
    TEffectName.BEAUTY_FACE_GODNESS,
    TEffectName.BEAUTY_FACE_MALE_GOD,
  ];

  static final List<String> BEAUTY_SMOOTH_NAMES = [
    TEffectName.BEAUTY_SMOOTH,
    TEffectName.BEAUTY_SMOOTH2,
    TEffectName.BEAUTY_SMOOTH3,
    TEffectName.BEAUTY_SMOOTH4,
    TEffectName.BEAUTY_SMOOTH5,
  ];

  ///
  /// @param teuiProperty
  /// @param uiCategory
  static void createDlModelAndSDKParam(TEUIProperty uiProperty, UICategory uiCategory) async {
    switch (uiCategory) {
      case UICategory.LUT:
      case UICategory.MAKEUP:
      case UICategory.MOTION:
      case UICategory.LIGHT_MAKEUP:
      case UICategory.SEGMENTATION:
        final resourceUri = uiProperty.resourceUri;
        if (resourceUri == null || resourceUri.isEmpty) {
          break;
        }
        uiProperty.sdkParam ??= TESDKParam();
        final isHttpResource = resourceUri.startsWith(HTTP_NAME);
        if (isHttpResource) {
          final downloadPath = TEProducerUtils._getDownloadPath(uiProperty);
          final fileName = getFileNameByHttpUrl(resourceUri);
          if (downloadPath != null && fileName != null) {
            uiProperty.dlModel = TEMotionDLModel(downloadPath, fileName, resourceUri);
            String finalFileName = fileName;
            if (fileName.endsWith(ZIP_NAME)) {
              finalFileName = uiProperty.dlModel?.getFileNameNoZip() ?? fileName;
            }
            uiProperty.sdkParam?.resourcePath = downloadPath + finalFileName;
          }
        } else {
          uiProperty.sdkParam?.resourcePath = resourceUri;
        }
        break;
      default:
        break;
    }
  }

  static String? _getDownloadPath(TEUIProperty? uiProperty) {
    if (uiProperty == null) {
      return null;
    }
    if (uiProperty.downloadPath != null && uiProperty.downloadPath!.isNotEmpty) {
      return uiProperty.downloadPath;
    } else {
      return TEProducerUtils._getDownloadPath(uiProperty.parentUIProperty);
    }
  }

  static String? getFileNameByHttpUrl(String httpUrl) {
    if (httpUrl.isEmpty || !httpUrl.startsWith("http")) {
      return null;
    }
    String fileName;
    Uri uri = Uri.parse(httpUrl);
    fileName = uri.pathSegments.last;
    return fileName;
  }

  ///
  /// @param uiProperty
  /// @return
  static Future<void> completionResPath(TEUIProperty? uiProperty) async {
    if (uiProperty == null) {
      return;
    }
    if (uiProperty.uiCategory == UICategory.BEAUTY || uiProperty.uiCategory == UICategory.BODY_BEAUTY) {
      return;
    }

    if (uiProperty.sdkParam != null && uiProperty.sdkParam!.resourcePath != null && !uiProperty.sdkParam!.resourcePath!.startsWith('/')) {
      uiProperty.sdkParam!.resourcePath = await getFilePath(uiProperty.sdkParam!.resourcePath!);
    }
  }

  static Future<void> completionResPathForTESDKParam(TESDKParam? sdkParam) async {
    if (sdkParam == null) {
      return;
    }
    if (sdkParam.effectName == TEffectName.EFFECT_LUT ||
        sdkParam.effectName == TEffectName.EFFECT_MAKEUP ||
        sdkParam.effectName == TEffectName.EFFECT_LIGHT_MAKEUP ||
        sdkParam.effectName == TEffectName.EFFECT_SEGMENTATION ||
        sdkParam.effectName == TEffectName.EFFECT_MOTION) {
      if (sdkParam.resourcePath != null && !sdkParam.resourcePath!.startsWith('/')) {
        sdkParam.resourcePath = await getFilePath(sdkParam.resourcePath!);
      }
    }
  }

  static Future<String> getFilePath(String resourcePath) async {
    StringBuffer stringBuffer = StringBuffer();
    if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_LUT)) {
      stringBuffer.write(await TEResPathManager.getResManager().getLutDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_MAKEUP)) {
      stringBuffer.write(await TEResPathManager.getResManager().getMakeUpDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_2D)) {
      stringBuffer.write(await TEResPathManager.getResManager().getMotion2dDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_3D)) {
      stringBuffer.write(await TEResPathManager.getResManager().getMotion3dDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_GAN)) {
      stringBuffer.write(await TEResPathManager.getResManager().getMotionGanDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_GESTURE)) {
      stringBuffer.write(await TEResPathManager.getResManager().getMotionGestureDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_SEG)) {
      stringBuffer.write(await TEResPathManager.getResManager().getSegDir());
    } else if (resourcePath.startsWith(TEResPathManager.JSON_RES_MARK_LIGHT_MAKEUP)) {
      stringBuffer.write(await TEResPathManager.getResManager().getLightMakeupDir());
    }
    stringBuffer.write(_getFileName(resourcePath));
    return stringBuffer.toString();
  }

  /// 将相对目录转换为绝对路径
  /// 例如：MotionRes/2dMotionRes -> /data/.../xmagic/MotionRes/2dMotionRes
  static Future<String> getAbsoluteLocalDir(String relativeDir) async {
    String baseDir = await TEResPathManager.getResManager().getResPath();
    if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_2D)) {
      baseDir = await TEResPathManager.getResManager().getMotion2dDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_3D)) {
      baseDir = await TEResPathManager.getResManager().getMotion3dDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_GAN)) {
      baseDir = await TEResPathManager.getResManager().getMotionGanDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_MOTION_GESTURE)) {
      baseDir = await TEResPathManager.getResManager().getMotionGestureDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_MAKEUP)) {
      baseDir = await TEResPathManager.getResManager().getMakeUpDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_SEG)) {
      baseDir = await TEResPathManager.getResManager().getSegDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_LUT)) {
      baseDir = await TEResPathManager.getResManager().getLutDir();
    } else if (relativeDir.startsWith(TEResPathManager.JSON_RES_MARK_LIGHT_MAKEUP)) {
      baseDir = await TEResPathManager.getResManager().getLightMakeupDir();
    } else {
      return relativeDir;
    }
    if (!baseDir.endsWith(Platform.pathSeparator)) {
      baseDir = '$baseDir${Platform.pathSeparator}';
    }
    return baseDir;
  }

  static String _getFileName(String path) {
    String fileName;
    Uri uri = Uri.parse(path);
    fileName = uri.pathSegments.last;
    return fileName;
  }

  static void changeParentUIState(TEUIProperty current, int uiState) {
    TEUIProperty? parent = current.parentUIProperty;
    if (parent != null) {
      parent.setUiState(uiState);
      TEProducerUtils.changeParentUIState(parent, uiState);
    }
  }

  static bool findFirstInUseItemAndMakeChecked(List<TEUIProperty>? allData) {
    if (allData == null) {
      return false;
    }
    for (TEUIProperty uiProperty in allData) {
      if (uiProperty.propertyList != null) {
        if (findFirstInUseItemAndMakeChecked(uiProperty.propertyList)) {
          return true;
        }
      } else if (uiProperty.sdkParam != null && uiProperty.getUiState() == UIState.IN_USE) {
        uiProperty.setUiState(UIState.CHECKED_AND_IN_USE);
        TEProducerUtils.changeParentUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
        return true;
      }
    }
    return false;
  }

  static List<TESDKParam> getUsedProperties(List<TEUIProperty> uiProperties) {
    List<TESDKParam> usedProperties = [];
    TESDKParam? templateSDKParam;
    templateSDKParam = _getUsedProperties(uiProperties, usedProperties);
    if (templateSDKParam != null) {
      // 模板生效时，美颜 / 滤镜 / 轻美妆都以模板内的数据为准，独立参数一律剔除
      usedProperties.removeWhere((param) => isBeautyLutLightMakeupName(param.effectName));
    }
    return usedProperties;
  }

  static TESDKParam? _getUsedProperties(List<TEUIProperty> uiProperties, List<TESDKParam> properties) {
    TESDKParam? templateResult;
    if (uiProperties.isNotEmpty) {
      for (TEUIProperty? uiProperty in uiProperties) {
        if (uiProperty == null) {
          continue;
        }
        // 轻美妆下钻态单项（LIGHT_MAKEUP_ITEM）与返回占位项（LIGHT_MAKEUP_BACK）都是
        // 运行时构造的虚拟节点，其 sdkParam 仅用于读写父套装的 extraInfo，不能下发给 SDK，
        // 否则会把"口红/腮红"当成独立效果下发。
        if (uiProperty.getUiState() != UIState.INIT &&
            uiProperty.sdkParam != null &&
            uiProperty.uiCategory != UICategory.GREEN_BACKGROUND_V2_ITEM &&
            uiProperty.uiCategory != UICategory.LIGHT_MAKEUP_ITEM &&
            uiProperty.uiCategory != UICategory.LIGHT_MAKEUP_BACK) {
          properties.add(uiProperty.sdkParam!);
        }
        if (uiProperty.uiCategory == UICategory.BEAUTY_TEMPLATE &&
            uiProperty.getUiState() != UIState.INIT &&
            uiProperty.paramList != null &&
            uiProperty.paramList!.isNotEmpty) {
          templateResult = uiProperty.sdkParam;
        }
        if (uiProperty.propertyList != null) {
          TESDKParam? childResult = _getUsedProperties(uiProperty.propertyList!, properties);
          templateResult ??= childResult;
        }
      }
    }
    return templateResult;
  }

  static TESDKParam createNoneItem(String effectName) {
    TESDKParam param = TESDKParam();
    param.effectName = effectName;
    return param;
  }

  static void changParamValuedTo0(List<TESDKParam>? usedList) {
    if (usedList == null) {
      return;
    }
    for (TESDKParam param in usedList) {
      param.effectValue = 0;
    }
  }

  static List<TESDKParam>? clone0ValuedParam(List<TESDKParam>? usedList) {
    if (usedList == null) {
      return null;
    }
    List<TESDKParam> resultList = [];
    for (TESDKParam param in usedList) {
      TESDKParam cloneParam = TESDKParam();
      cloneParam.effectName = param.effectName;
      cloneParam.effectValue = 0;
      cloneParam.resourcePath = param.resourcePath;
      if (param.extraInfo != null && param.extraInfo!.isNotEmpty) {
        Map<String, String> newExtraInfo = {};
        Iterable<MapEntry<String, String>> iterable = param.extraInfo!.entries;
        for (MapEntry<String, String> item in iterable) {
          newExtraInfo[item.key] = item.value;
        }
        cloneParam.extraInfo = newExtraInfo;
      }
      resultList.add(cloneParam);
    }
    return resultList;
  }

  static void revertUIState(List<TEUIProperty>? uiPropertyList, TEUIProperty currentItem) {
    if (uiPropertyList == null) {
      return;
    }
    for (TEUIProperty? property in uiPropertyList) {
      if (property == null) {
        continue;
      }
      TEProducerUtils.revertUIState(property.propertyList, currentItem);

      if (property.getUiState() == UIState.INIT) {
        continue;
      }
      if (property.uiCategory == UICategory.BEAUTY || property.uiCategory == UICategory.BODY_BEAUTY) {
        if (isSameEffectName(property, currentItem)) {
          changeParamUIState(property, UIState.INIT);
        } else {
          changeParamUIState(property, UIState.IN_USE);
        }
      } else {
        // 轻美妆与单点美妆/滤镜的互斥由上层 onClickPointMakeup / onClickLightMakeup 按
        // cleanLightMakeup 控制，这里只负责"同为轻美妆"套装间的单选；跨类（如点击单点美妆）
        // 时跳过，避免误清轻美妆。
        if (isLightMakeupCategory(property) && !isLightMakeupCategory(currentItem)) {
          continue;
        }
        changeParamUIState(property, UIState.INIT);
      }
    }
  }

  /// 判断是否为轻美妆相关分类（轻美妆套装 [UICategory.LIGHT_MAKEUP]
  /// 或下钻态单项 [UICategory.LIGHT_MAKEUP_ITEM]）。
  static bool isLightMakeupCategory(TEUIProperty? property) {
    return property != null &&
        (property.uiCategory == UICategory.LIGHT_MAKEUP ||
            property.uiCategory == UICategory.LIGHT_MAKEUP_ITEM);
  }

  static bool isSameEffectName(TEUIProperty? property, TEUIProperty? property2) {
    if (property == null || property2 == null) {
      return false;
    }
    if (property.sdkParam == null || property2.sdkParam == null) {
      return false;
    }
    if (property.sdkParam!.effectName == property2.sdkParam!.effectName) {
      return true;
    }
    if (TEProducerUtils.contains(BEAUTY_WHITEN_EFFECT_NAMES, property.sdkParam!.effectName) &&
        TEProducerUtils.contains(BEAUTY_WHITEN_EFFECT_NAMES, property2.sdkParam!.effectName)) {
      return true;
    }
    if (TEProducerUtils.contains(BEAUTY_FACE_EFFECT_NAMES, property.sdkParam!.effectName) &&
        TEProducerUtils.contains(BEAUTY_FACE_EFFECT_NAMES, property2.sdkParam!.effectName)) {
      return true;
    }
    if (TEProducerUtils.contains(BEAUTY_BLACK_EFFECT_NAMES, property.sdkParam!.effectName) &&
        TEProducerUtils.contains(BEAUTY_BLACK_EFFECT_NAMES, property2.sdkParam!.effectName)) {
      return true;
    }
    if (TEProducerUtils.contains(BEAUTY_SMOOTH_NAMES, property.sdkParam!.effectName) &&
        TEProducerUtils.contains(BEAUTY_SMOOTH_NAMES, property2.sdkParam!.effectName)) {
      return true;
    }
    return false;
  }

  static bool contains(List<String> names, String? effectName) {
    for (String name in names) {
      if (name == effectName) {
        return true;
      }
    }
    return false;
  }

  static void changeParamUIState(TEUIProperty? teuiProperty, int uiState) {
    if (teuiProperty == null) {
      return;
    }
    teuiProperty.setUiState(uiState);
    TEProducerUtils.changeParamUIState(teuiProperty.parentUIProperty, uiState);
  }

  /// 将item的状态强制设置为 init
  /// @param uiPropertyList
  static void revertUIStateToInit(List<TEUIProperty>? uiPropertyList) {
    if (uiPropertyList == null) {
      return;
    }

    for (TEUIProperty? property in uiPropertyList) {
      if (property == null) {
        continue;
      }
      TEProducerUtils.revertUIStateToInit(property.propertyList);
      if (property.getUiState() == UIState.INIT) {
        continue;
      }
      changeParamUIState(property, UIState.INIT);
    }
  }

  static bool isPointMakeup(TESDKParam sdkParam) {
    if (sdkParam.effectName == null || sdkParam.effectName!.isEmpty) {
      return false;
    }
    return pointMakeupEffectName.contains(sdkParam.effectName);
  }

  static List<String> pointMakeupEffectName = [
    TEffectName.BEAUTY_MOUTH_LIPSTICK,
    TEffectName.BEAUTY_FACE_RED_CHEEK,
    TEffectName.BEAUTY_FACE_SOFTLIGHT,
    TEffectName.BEAUTY_FACE_MAKEUP_EYE_SHADOW,
    TEffectName.BEAUTY_FACE_MAKEUP_EYE_LINER,
    TEffectName.BEAUTY_FACE_MAKEUP_EYELASH,
    TEffectName.BEAUTY_FACE_MAKEUP_EYE_SEQUINS,
    TEffectName.BEAUTY_FACE_MAKEUP_EYEBROW,
    TEffectName.BEAUTY_FACE_MAKEUP_EYEBALL,
    TEffectName.BEAUTY_FACE_MAKEUP_EYELIDS,
    TEffectName.BEAUTY_FACE_MAKEUP_EYEWOCAN,
    TEffectName.EFFECT_LUT,
  ];

  /// 判断 effectName 是否属于「美颜 / 滤镜 / 轻美妆」这一类
  /// （排除贴纸、整妆、分割、美体与模板）。
  ///
  /// 对应 Android 端 `ProviderUtils.isBeautyLutLightMakeupName`。
  /// 这三类效果共用同一套「模板互斥」逻辑：
  /// - 设置模板时，需要把已生效的它们清零并从参数管理器中移除；
  /// - 设置它们时，需要把已生效的模板拆解为独立参数。
  ///
  /// 注意：轻美妆必须参与该判断。否则模板与轻美妆会同时生效
  /// （UI 上已互斥，但下发给 SDK 的参数不会互相清理）。
  static bool isBeautyLutLightMakeupName(String? effectName) {
    if (effectName == null || effectName.isEmpty) {
      return false;
    }
    if (effectName == TEffectName.EFFECT_LIGHT_MAKEUP) {
      return true;
    }
    if (effectName == TEffectName.EFFECT_LUT) {
      return true;
    }
    if (effectName.startsWith("body.")) {
      return false;
    }
    if (effectName == TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME) {
      return false;
    }
    return effectName != TEffectName.EFFECT_MOTION &&
        effectName != TEffectName.EFFECT_MAKEUP &&
        effectName != TEffectName.EFFECT_SEGMENTATION;
  }

  /// Process template data: create TESDKParam for each template item and return checked template beauty data.
  static List<TESDKParam>? processTemplateData(TEUIProperty? teuiProperty) {
    List<TESDKParam>? result;
    if (teuiProperty != null &&
        teuiProperty.uiCategory == UICategory.BEAUTY_TEMPLATE &&
        teuiProperty.propertyList != null &&
        teuiProperty.propertyList!.isNotEmpty) {
      for (TEUIProperty uiProperty in teuiProperty.propertyList!) {
        TESDKParam tesdkParam = TESDKParam();
        tesdkParam.effectName = TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME;
        tesdkParam.effectValue = uiProperty.id;
        tesdkParam.resourcePath = uiProperty.paramList != null ? jsonEncode(uiProperty.paramList!.map((e) => e.toJson()).toList()) : null;
        tesdkParam.tag = uiProperty.paramList;
        uiProperty.sdkParam = tesdkParam;
        if (uiProperty.getUiState() >= UIState.IN_USE) {
          result = uiProperty.paramList;
        }
      }
    }
    return result;
  }

  /// Process last saved data for template parameters (restore tag from resourcePath JSON)
  static void processLastData(List<TESDKParam>? sdkParamList) {
    if (sdkParamList == null) return;
    for (TESDKParam param in sdkParamList) {
      if (param.effectName == TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME &&
          param.resourcePath != null &&
          param.resourcePath!.isNotEmpty &&
          param.tag == null) {
        try {
          List<dynamic> decoded = jsonDecode(param.resourcePath!);
          param.tag = decoded.map((e) => TESDKParam.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }
  }

  /// Collect green screen V2 sub-parameter values into a JSON array string
  static String getGreenParamsV2(TEUIProperty teuiProperty) {
    List<int> result = [0, 0, 0, 0, 0];
    if (teuiProperty.propertyList != null && teuiProperty.propertyList!.isNotEmpty) {
      for (TEUIProperty item in teuiProperty.propertyList!) {
        if (item.sdkParam == null) continue;
        switch (item.sdkParam!.effectName) {
          case GreenBackgroundItemName.BACKGROUND_V2_SIMILARITY:
            result[0] = item.sdkParam!.effectValue;
            break;
          case GreenBackgroundItemName.BACKGROUND_V2_SMOOTH:
            result[1] = item.sdkParam!.effectValue;
            break;
          case GreenBackgroundItemName.BACKGROUND_V2_CORROSION:
            result[2] = item.sdkParam!.effectValue;
            break;
          case GreenBackgroundItemName.BACKGROUND_V2_DE_SPILL:
            result[3] = item.sdkParam!.effectValue;
            break;
          case GreenBackgroundItemName.BACKGROUND_V2_DE_SHADOW:
            result[4] = item.sdkParam!.effectValue;
            break;
        }
      }
    }
    return '[${result.map((e) => '${e.toDouble()}').join(',')}]';
  }

  /// Get the import image item from a green screen V2 property
  static TEUIProperty? getImportTEUIPropertyItem(TEUIProperty teuiProperty) {
    if (teuiProperty.propertyList == null || teuiProperty.propertyList!.isEmpty) {
      return null;
    }
    for (TEUIProperty property in teuiProperty.propertyList!) {
      if (property.uiCategory == UICategory.GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE) {
        return property;
      }
    }
    return null;
  }

  /// 删除 [teuiProperty] 的一级子项中 uiCategory 命中 [categories] 的节点（只遍历一层）。
  ///
  /// 常用于套餐规则中"保留父分类但裁掉某些子分类"的场景，
  /// 对应 Android 端 `ProviderUtils.removeChildrenByCategory`。
  static void removeChildrenByCategory(
      TEUIProperty? teuiProperty, Set<UICategory> categories) {
    final List<TEUIProperty>? children = teuiProperty?.propertyList;
    if (children == null || children.isEmpty || categories.isEmpty) {
      return;
    }
    children.removeWhere((item) => categories.contains(item.uiCategory));
  }

  /// 移除 [teuiProperty] 下包含染发 LUT 子项的那一整个分组。
  ///
  /// 递归查找 effectName 为 [TEffectName.BEAUTY_HAIR_COLOR_LUT] 的节点，
  /// 取其父节点，并将该父节点整体从 [teuiProperty] 的一级子项中移除。
  /// 对应 Android 端 `ProviderUtils.removeHairColorGroup`。
  static void removeHairColorGroup(TEUIProperty? teuiProperty) {
    final List<TEUIProperty>? children = teuiProperty?.propertyList;
    if (children == null || children.isEmpty) {
      return;
    }
    final TEUIProperty? parent =
        _findParentByEffectName(null, teuiProperty!, TEffectName.BEAUTY_HAIR_COLOR_LUT);
    if (parent != null) {
      children.remove(parent);
    }
  }

  /// 深度优先查找 effectName 等于 [effectName] 的首个节点，并返回它的父节点。
  ///
  /// 这里不依赖 [TEUIProperty.parentUIProperty]（套餐裁剪发生在父链回填之前），
  /// 而是在递归下探时显式携带 parent。
  static TEUIProperty? _findParentByEffectName(
      TEUIProperty? parent, TEUIProperty current, String effectName) {
    if (current.sdkParam != null && current.sdkParam!.effectName == effectName) {
      return parent;
    }
    final List<TEUIProperty>? children = current.propertyList;
    if (children == null || children.isEmpty) {
      return null;
    }
    for (final TEUIProperty child in children) {
      final TEUIProperty? found = _findParentByEffectName(current, child, effectName);
      if (found != null) {
        return found;
      }
    }
    return null;
  }
}
