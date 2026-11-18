import 'dart:core';
import 'dart:ui';
import '../model/te_panel_data_model.dart';
import '../model/te_ui_property.dart';
import 'te_effect_plan.dart';

class TEResConfig {
  List<TEPanelDataModel> defaultPanelDataList = [];

  TEResConfig._internal();

  Color panelBackgroundColor = const Color(0xAA000000);  //Default background color

  bool revertEffect2Json = true;   //如果设置为true,
  // 那么在点击面板还原按钮的时候就会还原到json配置的状态，否则还原到进入面板设置了 lastParam的状态

  bool cleanLightMakeup = false;   //此配置是当设置滤镜，或者单点美妆的时候是否清理轻美妆

  /// 新版链路：面板入口文件 `index.json` 的路径。
  ///
  /// 以 `/` 开头视为本地绝对路径，否则视为 Flutter assets 相对路径。
  /// 由 [setPanelViewResAndEffectPlanName] 设置。
  String? panelViewIndexJsonFilePath;

  /// 新版链路：当前使用的套餐。
  ///
  /// 请通过 [effectPlan] 读取（未设置时会返回默认套餐）。
  EffectPlan? _effectPlan;

  /// 新版链路：面板文案的语言 key，由业务显式指定，优先级高于 `index.json` 的 `defaultLanguage`。
  ///
  /// 由 [setDisPlayNameKey] 设置。
  String? disPlayNameKey;

  /// 新版链路：`index.json` 中声明的 `defaultLanguage`，在面板数据加载时自动回填。
  String? defaultDisPlayNameKey;

  static TEResConfig? resConfig;

  static TEResConfig getConfig() {
    resConfig ??= TEResConfig._internal();
    return resConfig!;
  }

  /// 当前生效的套餐。未通过 [setPanelViewResAndEffectPlanName] 设置时返回
  /// [EffectPlanParser.defaultPlan]（即 `S1_07`，全功能保留）。
  EffectPlan get effectPlan => _effectPlan ?? EffectPlanParser.defaultPlan;

  /// 是否已配置新版链路（即通过 [setPanelViewResAndEffectPlanName] 指定了 index.json）。
  bool get isIndexFileMode =>
      panelViewIndexJsonFilePath != null && panelViewIndexJsonFilePath!.isNotEmpty;

  /// 配置美颜面板的入口文件与套餐（新版链路，推荐）。
  ///
  /// 调用后面板的 Tab 数量与顺序、各 Tab 内的功能项、多语言文案全部由 json 描述，
  /// 业务侧无需再按分类逐个注册 json 文件。
  ///
  /// ```dart
  /// TEResConfig.getConfig().setPanelViewResAndEffectPlanName(
  ///     'assets/beauty_panel/index.json', EffectPlan.S1_07);
  /// ```
  ///
  /// [indexFilePath] index.json 的路径，入口文件名必须为 `index.json`，
  ///                 且同级目录下必须存在 `panel_json/` 目录。
  /// [effectPlan]    License 授权的套餐。传 null 时使用
  ///                 [EffectPlanParser.defaultPlan]（`S1_07`，全功能保留）。
  ///
  /// 注意：本方法与 [setBeautyRes] 等旧接口互斥，调用后旧接口注册的分类列表会被清空。
  void setPanelViewResAndEffectPlanName(String indexFilePath, EffectPlan? effectPlan) {
    defaultPanelDataList.clear();
    panelViewIndexJsonFilePath = indexFilePath;
    _effectPlan = effectPlan;
  }

  /// 设置面板文案使用的语言 key（新版链路）。
  ///
  /// 取值需与 panel_json 各节点 `name` 中声明的 key 一致，例如 `zh` / `en` / `ja`。
  /// 未设置时使用 `index.json` 中的 `defaultLanguage`。
  ///
  /// 该配置仅对新版链路（[setPanelViewResAndEffectPlanName]）生效；旧链路的文案
  /// 仍按 App 当前 locale 从 `displayName` / `displayNameEn` 中取值。
  void setDisPlayNameKey(String? key) {
    disPlayNameKey = key;
  }

  /// 清理新版链路的配置，使面板回退到旧链路。
  ///
  /// 在调用任一旧接口时会自动触发，业务侧通常无需手动调用。
  void _clearIndexFileConfig() {
    panelViewIndexJsonFilePath = null;
    _effectPlan = null;
    defaultDisPlayNameKey = null;
  }

  /// 注册一个美颜分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setBeautyRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.BEAUTY));
  }

  /// 注册美体分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setBeautyBodyRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.BODY_BEAUTY));
  }

  /// 注册滤镜分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setLutRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.LUT));
  }

  /// 注册美妆分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setMakeUpRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.MAKEUP));
  }

  /// 注册动效贴纸分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setMotionRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.MOTION));
  }

  /// 注册虚拟背景分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setSegmentationRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.SEGMENTATION));
  }

  /// 注册轻美妆分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setLightMakeupRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.LIGHT_MAKEUP));
  }

  /// 注册美颜模板分类的 json（旧链路）。
  ///
  /// 已过时：推荐使用 [setPanelViewResAndEffectPlanName]。
  @deprecated
  void setBeautyTemplateRes(String resourcePath) {
    _clearIndexFileConfig();
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.BEAUTY_TEMPLATE));
  }

  List<TEPanelDataModel> getPanelDataList() {
    return defaultPanelDataList;
  }
}
