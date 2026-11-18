import 'dart:io';

import '../../uikit/model/te_json_decoder.dart';

import '../constant/te_constant.dart';
import 'te_index_file_model.dart';

class TEUIProperty {
  int id = -1;

  /// 旧版多语言字段（中文名）。已过时。
  ///
  /// 新版面板配置（index.json + panel_json）请使用 [name]，本字段仅为兼容旧 json 保留。
  String? displayName;

  /// 旧版多语言字段（英文名）。已过时。
  ///
  /// 新版面板配置（index.json + panel_json）请使用 [name]，本字段仅为兼容旧 json 保留。
  String? displayNameEn;

  /// 新版多语言显示名，key 为语言代码，例如 `{"zh":"美白","en":"Brighten","ja":"美白"}`。
  ///
  /// 取值语言由 `TEResConfig.disPlayNameKey`（优先）或 `index.json` 的
  /// `defaultLanguage` 决定，详见 `TEPanelDisplay.getDisplayName`。
  Map<String, String>? name;

  String? icon;
  String? resourceUri;
  String? downloadPath;

  String? titleType;

  /// 仅 `shape.json`（[UICategory.SHAPESET]）使用：按套餐分发实际加载的配置文件。
  List<TEDataSetItem>? dataList;

  List<TEUIProperty>? propertyList;
  TESDKParam? sdkParam;
  List<TESDKParam>? paramList;

  /// 轻美妆场景下，单项（口红/腮红/眼影/滤镜等）的展示信息映射表。
  ///
  /// key 为 `makeup.json` 中的 `effectName`（例如 `beauty.faceFeatureLipsLut`、`lut`），
  /// value 为对应的 UI 展示信息（多语言 name / icon）。
  /// 由 beauty_makeup.json 中「轻美妆」类目节点顶层的 `itemDisplayMap` 反序列化而来，
  /// 其它场景无需使用。未配置该项时，轻美妆退化为仅可调节整套强度（不下钻）。
  Map<String, TELightMakeupItemDisplay>? itemDisplayMap;

  TEUIProperty? parentUIProperty;
  UICategory? uiCategory;
  TEMotionDLModel? dlModel;
  bool verticalLayout = false;
  bool hasSubTitle = false;

  int uiState = 0;

  int getUiState() {
    return uiState;
  }

  void setUiState(int uiState) {
    this.uiState = uiState;
  }

  TEUIProperty(
      this.displayName,
      this.displayNameEn,
      this.icon,
      this.resourceUri,
      this.downloadPath,
      this.propertyList,
      this.sdkParam,
      this.uiState);

  bool isNoneItem() {
    return (sdkParam == null && propertyList == null && paramList == null);
  }

  /// 当前节点是否是一级主 Tab 节点（即面板顶部一级标题栏承载的节点）。
  ///
  /// 无父节点时返回 true。
  bool isMainTabNode() {
    return parentUIProperty == null;
  }

  /// 当前节点是否是二级标题节点（即面板二级标题栏承载的节点）。
  ///
  /// 注意 [hasSubTitle] 的语义是"该节点的**孩子**是二级标题"，
  /// 因此判断"自己是不是二级标题"需要看父节点的该标记。
  bool isSubTitleNode() {
    return parentUIProperty != null && parentUIProperty!.hasSubTitle;
  }

  bool isGSV2ImportImageItem() {
    return (uiCategory == UICategory.GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE);
  }

  /// 是否是"美妆无效果占位项"（各单点美妆里的「无」）。
  ///
  /// 判定条件：`sdkParam.resourcePath` 为空，且 effectName 属于单点美妆类。
  /// 面板据此隐藏滑竿（点「无」时没有可调节的强度）。
  ///
  /// 注意：轻美妆下钻态单项（[UICategory.LIGHT_MAKEUP_ITEM]）复用单点美妆的 effectName
  /// 且 resourcePath 为空，但它不是"无效果占位项"，必须排除，
  /// 否则会被滑竿判定误判而隐藏滑竿（对应 Android 端「修改轻美妆子项没有展示滑竿的问题」）。
  bool isBeautyMakeupNoneItem() {
    if (uiCategory == UICategory.LIGHT_MAKEUP_ITEM) {
      return false;
    }
    if (sdkParam != null && (sdkParam!.resourcePath == null || sdkParam!.resourcePath!.isEmpty)) {
      switch (sdkParam!.effectName) {
        case TEffectName.BEAUTY_MOUTH_LIPSTICK:
        case TEffectName.BEAUTY_FACE_SOFTLIGHT:
        case TEffectName.BEAUTY_FACE_RED_CHEEK:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYE_SHADOW:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYE_LINER:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYELASH:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYE_SEQUINS:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYEBROW:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYEBALL:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYELIDS:
        case TEffectName.BEAUTY_FACE_MAKEUP_EYEWOCAN:
        case TEffectName.BEAUTY_HAIR_COLOR_LUT:
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  /// 将 json 中的 `uiCategory` 字符串解析为枚举。
  ///
  /// 未知取值返回 null，此时该节点会继承父节点（或 Tab 根节点）的分类，
  /// 与 Android 端 Gson 解析未知枚举时的行为一致。
  static UICategory? _parseUICategory(dynamic value) {
    if (value == null) return null;
    final String str = value.toString().trim();
    if (str.isEmpty) return null;
    for (final UICategory category in UICategory.values) {
      if (category.name == str) {
        return category;
      }
    }
    return null;
  }

  TEUIProperty.fromJson(Map<String, dynamic> json) {
    var rawId = json['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? -1;
    } else {
      id = -1;
    }
    displayName = json['displayName'];
    displayNameEn = json['displayNameEn'];
    name = TEIndexItem.parseNameMap(json['name']);
    icon = json['icon'];
    resourceUri = json['resourceUri'];
    downloadPath = json['downloadPath'];
    verticalLayout = _parseBool(json['verticalLayout']);
    hasSubTitle = _parseBool(json['hasSubTitle']);
    // Parse uiCategory from JSON string (e.g., "GREEN_BACKGROUND_V2_ITEM")
    if (json['uiCategory'] != null) {
      uiCategory = _parseUICategory(json['uiCategory']);
    }
    dataList = TEDataSetItem.decodeList(json['dataList']);
    itemDisplayMap = TELightMakeupItemDisplay.decodeMap(json['itemDisplayMap']);
    propertyList = TEJsonDecoder.decodeTEUIPropertyList(json['propertyList']);
    Map<String, dynamic>? tempSdkParam = json['sdkParam'];
    sdkParam = tempSdkParam != null ? TESDKParam.fromJson(tempSdkParam) : null;
    if (json['paramList'] != null) {
      paramList = (json['paramList'] as List).map((e) => TESDKParam.fromJson(e as Map<String, dynamic>)).toList();
    }
    var tempState = json['uiState'];
    if (tempState != null) {
      uiState = tempState;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['displayName'] = displayName;
    data['displayNameEn'] = displayNameEn;
    data['name'] = name;
    data['icon'] = icon;
    data['resourceUri'] = resourceUri;
    data['downloadPath'] = downloadPath;
    data['verticalLayout'] = verticalLayout;
    data['hasSubTitle'] = hasSubTitle;
    if (itemDisplayMap != null && itemDisplayMap!.isNotEmpty) {
      data['itemDisplayMap'] = itemDisplayMap!.map((key, value) => MapEntry(key, value.toJson()));
    }
    data['propertyList'] = propertyList?.map((e) => e.toJson()).toList();
    data['sdkParam'] = sdkParam?.toJson();
    data['paramList'] = paramList?.map((e) => e.toJson()).toList();
    data['uiState'] = uiState;
    return data;
  }
}

/// 轻美妆单项的展示信息。
///
/// 由 beauty_makeup.json 中「轻美妆」类目节点顶层的 `itemDisplayMap` 反序列化而来，
/// 对应 Android 端 `TEUIProperty.LightMakeupItemDisplay`。
class TELightMakeupItemDisplay {
  /// 多语言名称，key 为语言代码，例如 `{"zh":"口红","en":"Lipstick","ja":"リップ"}`。
  ///
  /// 结构与应用在 [TEUIProperty.name] 上的一致，可直接复用 `TEPanelDisplay.getDisplayName`。
  Map<String, String>? name;

  /// 单项图标，取值规则与 [TEUIProperty.icon] 相同（相对面板资源根目录）。
  String? icon;

  TELightMakeupItemDisplay({this.name, this.icon});

  TELightMakeupItemDisplay.fromJson(Map<String, dynamic> json)
      : name = TEIndexItem.parseNameMap(json['name']),
        icon = json['icon'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['icon'] = icon;
    return data;
  }

  /// 反序列化 `itemDisplayMap` 节点。
  ///
  /// 保留 json 中的声明顺序（Dart 的 Map 为 LinkedHashMap），
  /// 与 Android 端按 `itemDisplayMap` 声明顺序渲染单项的行为一致。
  static Map<String, TELightMakeupItemDisplay>? decodeMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final Map<String, TELightMakeupItemDisplay> result = <String, TELightMakeupItemDisplay>{};
    raw.forEach((dynamic key, dynamic value) {
      if (key == null || value is! Map) {
        return;
      }
      result[key.toString()] = TELightMakeupItemDisplay.fromJson(Map<String, dynamic>.from(value));
    });
    return result.isEmpty ? null : result;
  }
}

class TESDKParam {
  static const String BEAUTY_TEMPLATE_EFFECT_NAME = "BEAUTY_TEMPLATE";

  static const String EXTRA_INFO_BG_TYPE_IMG = "0";
  static const String EXTRA_INFO_BG_TYPE_VIDEO = "1";

  static const List<String> EXTRA_INFO_SEG_TYPE_GREEN = ["green_background", "green_background_v2"];
  static const String EXTRA_INFO_SEG_TYPE_CUSTOM = "custom_background";
  static const String GREEN_PARAMS_V2 = "green_params_v2";

  static const String EXTRA_INFO_KEY_BG_TYPE = "bgType";
  static const String EXTRA_INFO_KEY_BG_PATH = "bgPath";
  static const String EXTRA_INFO_KEY_SEG_TYPE = "segType";
  static const String EXTRA_INFO_KEY_KEY_COLOR = "keyColor";
  static const String EXTRA_INFO_KEY_MERGE_WITH_CURRENT_MOTION = "mergeWithCurrentMotion";
  static const String EXTRA_INFO_KEY_LUT_STRENGTH = "makeupLutStrength";

  String? effectName;
  int effectValue = 0;
  String? resourcePath;
  Map<String, String>? extraInfo;

  /// Transient tag field for template data (not serialized to JSON)
  Object? tag;

  TESDKParam(
      {this.effectName,
      this.effectValue = 0,
      this.resourcePath,
      this.extraInfo});

  TESDKParam.fromJson(Map<String, dynamic> json) {
    effectName = json['effectName'];
    effectValue = json['effectValue'] ?? 0;
    resourcePath = json['resourcePath'];

    Map<String, dynamic>? tempExtraInfo = json['extraInfo'];
    if (tempExtraInfo != null) {
      extraInfo = tempExtraInfo.cast<String, String>();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['effectName'] = effectName;
    data['effectValue'] = effectValue;
    data['resourcePath'] = resourcePath;
    data['extraInfo'] = extraInfo;
    return data;
  }

  TESDKParam clone() {
    TESDKParam cloned = TESDKParam(
      effectName: effectName,
      effectValue: effectValue,
      resourcePath: resourcePath,
    );
    if (extraInfo != null) {
      cloned.extraInfo = Map<String, String>.from(extraInfo!);
    }
    return cloned;
  }
}

/// 面板功能项的分类。
///
/// 决定渲染方式以及 `effectName` 的自动填充逻辑。子节点未声明时会继承所属 Tab
/// 根节点的取值（注意：继承的是 Tab 根节点，而非直接父节点）。
enum UICategory {
  BEAUTY,

  /// 画质调整类（`beauty_image.json`）。经 `EffectPlan.filter` 后会被改写为 [BEAUTY]。
  BEAUTY_IMAGE,

  /// 美型类（`beauty_*_shape.json`）。经 `EffectPlan.filter` 后会被改写为 [BEAUTY]。
  BEAUTY_SHAPE,

  BODY_BEAUTY,

  /// 美妆容器（`beauty_makeup.json` 根节点）。经 `EffectPlan.filter` 后会被改写为 [BEAUTY]。
  BEAUTY_MAKEUP,

  LUT,
  MOTION,
  MAKEUP,
  LIGHT_MAKEUP,

  /// 轻美妆下钻态中的单项（口红/腮红/眼影/滤镜等）。
  ///
  /// 由 [TELightMakeupItemBuilder] 在运行时构造：`sdkParam.effectName` 仅用作
  /// 父套装 `extraInfo` 读写的 key，不会作为独立效果下发给 SDK。
  LIGHT_MAKEUP_ITEM,

  /// 轻美妆下钻态列表中"返回"占位项（兜底，不参与选中逻辑）。
  LIGHT_MAKEUP_BACK,

  BEAUTY_TEMPLATE,
  SEGMENTATION,

  /// 配置分发器（`shape.json`），自身不参与渲染，按套餐展开为具体的美型配置。
  SHAPESET,

  /// 绿幕 V2 子项。
  GREEN_BACKGROUND_V2_ITEM,

  /// 绿幕 V2 子项中的"导入图片"项。
  GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE,
}

class UIState {
  static const int CHECKED_AND_IN_USE = 2;
  static const int IN_USE = 1;
  static const int INIT = 0;
}

class TEMotionDLModel {
  String? localDir;
  String? fileName;
  String? url;

  String? getLocalDir() {
    return localDir;
  }

  void setLocalDir(String? _localDir) {
    if (_localDir == null) {
      return;
    }
    localDir = _localDir;
    if (localDir!.startsWith(Platform.pathSeparator, 0)) {
      localDir = localDir?.replaceFirst(Platform.pathSeparator, "");
    }
    if (localDir!.endsWith(Platform.pathSeparator)) {
      localDir = localDir?.substring(0, localDir!.length - 1);
    }
  }

  String? getFileName() {
    return fileName;
  }

  String? getFileNameNoZip() {
    if (fileName != null && fileName!.endsWith(".zip")) {
      return fileName!.substring(0, fileName!.length - ".zip".length);
    }
    return fileName;
  }

  void setFileName(String _fileName) {
    fileName = _fileName;
  }

  String? getUrl() {
    return url;
  }

  void setUrl(String _url) {
    url = _url;
  }

  TEMotionDLModel(String? _localDir, String? _fileName, String? _url) {
    setLocalDir(_localDir);
    fileName = _fileName;
    url = _url;
  }
}

class GreenBackgroundItemName {
  static const String BACKGROUND_V2_SIMILARITY = "green_background_v2.similarity";
  static const String BACKGROUND_V2_SMOOTH = "green_background_v2.smooth";
  static const String BACKGROUND_V2_CORROSION = "green_background_v2.corrosion";
  static const String BACKGROUND_V2_DE_SPILL = "green_background_v2.despill";
  static const String BACKGROUND_V2_DE_SHADOW = "green_background_v2.deshadow";
}

class EffectValueType {
  final int min;
  final int max;

  const EffectValueType(this.min, this.max);

  static const RANGE_0_0 = EffectValueType(0, 0);
  static const RANGE_0_POS100 = EffectValueType(0, 100);
  static const RANGE_NEG100_POS100 = EffectValueType(-100, 100);
  static const RANG_1_POS100 = EffectValueType(1, 100);
  static const RANG_0_POS3 = EffectValueType(0, 3);
  static const RANG_0_POS5 = EffectValueType(0, 5);

  int getMin() {
    return min;
  }

  int getMax() {
    return max;
  }

  static const Map<String, EffectValueType> VALUE_TYPE_MAP = {
    TEffectName.EFFECT_MOTION: EffectValueType.RANGE_0_0,
    TEffectName.EFFECT_SEGMENTATION: EffectValueType.RANGE_0_0,
    TEffectName.BEAUTY_CONTRAST: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_SATURATION: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_IMAGE_WARMTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_IMAGE_TINT: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_IMAGE_BRIGHTNESS: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_DISTANCE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_ANGLE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_WIDTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_HEIGHT: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_OUT_CORNER: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYE_POSITION: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_ANGLE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_DISTANCE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_HEIGHT: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_LENGTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_THICKNESS: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_EYEBROW_RIDGE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_NOSE_WING: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_NOSE_HEIGHT: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_NOSE_BRIDGE_WIDTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_NASION: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_MOUTH_SIZE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_MOUTH_HEIGHT: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_MOUTH_WIDTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_MOUTH_POSITION: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_SMILE_FACE: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_FACE_THIN_CHIN: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_FACE_FOREHEAD: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BEAUTY_FACE_FOREHEAD2: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BODY_ENLARGE_CHEST_STRENGTH: EffectValueType.RANGE_NEG100_POS100,
    TEffectName.BODY_SLIM_ARM_STRENGTH: EffectValueType.RANGE_NEG100_POS100,
    // Green Background V2 sub-parameters
    GreenBackgroundItemName.BACKGROUND_V2_SIMILARITY: EffectValueType.RANGE_0_POS100,
    GreenBackgroundItemName.BACKGROUND_V2_SMOOTH: EffectValueType.RANG_1_POS100,
    GreenBackgroundItemName.BACKGROUND_V2_CORROSION: EffectValueType.RANG_0_POS3,
    GreenBackgroundItemName.BACKGROUND_V2_DE_SPILL: EffectValueType.RANGE_0_POS100,
    GreenBackgroundItemName.BACKGROUND_V2_DE_SHADOW: EffectValueType.RANG_0_POS5,
  };

  static EffectValueType getEffectValueType(TESDKParam teParam) {
    EffectValueType? type = VALUE_TYPE_MAP[teParam.effectName];
    if (type != null) {
      return type;
    } else {
      return EffectValueType.RANGE_0_POS100;
    }
  }
}
