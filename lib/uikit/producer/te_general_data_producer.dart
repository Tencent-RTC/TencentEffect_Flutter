import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../uikit/producer/te_panel_data_producer.dart';
import '../config/te_res_config.dart';
import '../constant/te_constant.dart';
import '../manager/te_param_manager.dart';
import '../model/te_index_file_model.dart';
import '../model/te_panel_data_model.dart';
import '../model/te_ui_property.dart';
import '../provider/index_file_provider.dart';
import '../utils/te_producer_utils.dart';

/// 一个 Tab 的根节点，以及该 Tab 内子节点的继承分类。
class _TabRoot {
  final TEUIProperty property;

  /// 子节点未显式声明 `uiCategory` 时继承的分类。
  ///
  /// 注意：整棵子树继承的都是这个"Tab 级"分类，而不是各自的直接父节点分类，
  /// 与 Android 端保持一致。
  final UICategory inheritCategory;

  _TabRoot(this.property, this.inheritCategory);
}

class TEGeneralDataProducer implements TEPanelDataProducer {
  static const String _tag = 'TEGeneralDataProducer';

  List<TEPanelDataModel>? _panelDataList;
  List<TEUIProperty> _allData = [];
  List<TESDKParam>? _originalParamList = [];
  final Map<String, TEUIProperty> _titleTypeData = {};

  final Map<String, TEUIProperty> _uiPropertyIndexByNameMap = HashMap<String, TEUIProperty>();

  bool pointMakeupChecked = false;
  bool lightMakeupChecked = false;
  bool _hasBeautyTemplateChecked = true;
  List<TEUIProperty> pointMakeup = [];
  bool _hasLightMakeup = false;
  bool _isInitializing = false;
  Completer<List<TEUIProperty>>? _initializationCompleter;

  @override
  void setPanelDataList(List<TEPanelDataModel> panelDataList) {
    _panelDataList = panelDataList;
  }

  @override
  void setUsedParams(List<TESDKParam>? paramList) {
    _originalParamList = paramList;
  }

  @override
  Future<List<TEUIProperty>> getPanelData({bool forceRefreshData = false}) async {
    if (!forceRefreshData) {
      if (_allData.isNotEmpty) {
        return _allData;
      }
    }
    if (_isInitializing) {
      return await _initializationCompleter!.future;
    }
    try {
      _isInitializing = true;
      _initializationCompleter = Completer<List<TEUIProperty>>();
      _allData = await forceRefreshPanelData();
      _initializationCompleter!.complete(_allData);
      return _allData;
    } catch (e) {
      _initializationCompleter?.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
      _initializationCompleter = null;
    }
  }

  @override
  Future<List<TEUIProperty>> forceRefreshPanelData() async {
    List<TEUIProperty> result = [];
    _uiPropertyIndexByNameMap.clear();
    _titleTypeData.clear();
    pointMakeup.clear();
    TEUIProperty? templateData;

    // 链路分叉：优先使用旧接口注册的分类列表（保证已接入客户的行为完全不变），
    // 未注册时若配置了 index.json 则走新链路。
    final bool useIndexFile =
        (_panelDataList == null || _panelDataList!.isEmpty) && TEResConfig.getConfig().isIndexFileMode;
    final List<_TabRoot> tabRoots =
        useIndexFile ? await _loadTabRootsFromIndexFile() : await _loadTabRootsFromPanelDataList();

    int titleTypeIndex = 0;
    for (final _TabRoot tabRoot in tabRoots) {
      titleTypeIndex++;
      final TEUIProperty uiProperty = tabRoot.property;
      // titleType 是"该 item 属于哪个 Tab"的分组标识，不参与展示。
      // 使用序号而非显示名，避免新版 json 中 displayName 为空或多个 Tab 同名导致分组串台。
      final String titleType = 'group_$titleTypeIndex';
      uiProperty.titleType = titleType;
      if (uiProperty.propertyList != null) {
        await _completeParams(uiProperty.propertyList!, tabRoot.inheritCategory, titleType, uiProperty);
      }
      if (uiProperty.uiCategory == UICategory.BEAUTY_TEMPLATE) {
        templateData = uiProperty;
      }
      _indexProperty(uiProperty);
      result.add(uiProperty);
      _titleTypeData[titleType] = uiProperty;
    }

    // IMPORTANT: assign result to _allData before any _uncheckBeautyAndLut calls,
    // because _uncheckBeautyAndLut operates on _allData via _getDataByUICategory
    _allData = result;

    // Step 1: processTemplateData must always be called to create sdkParam for template items
    TEProducerUtils.processTemplateData(templateData);

    // Step 2: Determine what beauty data to sync to the panel
    List<TESDKParam>? beautyDataToSync;

    if (_originalParamList != null && _originalParamList!.isNotEmpty) {
      TEProducerUtils.processLastData(_originalParamList!);

      // Check if originalParamList contains a template param
      TESDKParam? templateParam;
      for (TESDKParam param in _originalParamList!) {
        if (param.effectName == TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME) {
          templateParam = param;
          break;
        }
      }

      if (templateParam != null) {
        // User had a template selected: use user's saved beauty data (from tag), not JSON's full paramList
        _uncheckBeautyAndLut();
        _uncheckLightMakeup();
        _restoreUIStateFromParams(_originalParamList);
        if (templateParam.tag is List) {
          beautyDataToSync = templateParam.tag as List<TESDKParam>;
        }
      } else {
        // User had individual beauty params (no template)
        _uncheckBeautyAndLut();
        _uncheckLightMakeup();
        _restoreUIStateFromParams(_originalParamList);
      }
    } else {
      // No originalParamList: check if JSON has a default-selected template
      List<TESDKParam>? checkedTemplateBeautyData;
      if (templateData != null &&
          templateData.propertyList != null) {
        for (TEUIProperty prop in templateData.propertyList!) {
          if (prop.getUiState() >= UIState.IN_USE && prop.paramList != null) {
            checkedTemplateBeautyData = prop.paramList;
            break;
          }
        }
      }
      if (checkedTemplateBeautyData != null && checkedTemplateBeautyData.isNotEmpty) {
        beautyDataToSync = checkedTemplateBeautyData;
      }
    }

    // Step 3: If we have beauty data to sync from template, apply it
    if (beautyDataToSync != null && beautyDataToSync.isNotEmpty) {
      _uncheckBeautyAndLut();
      // 模板默认选中项与轻美妆互斥
      _uncheckLightMakeup();
      _restoreUIStateFromParams(beautyDataToSync);
    }

    _restoreUIState(result);
    return result;
  }

  /// 旧链路：按业务通过 `TEResConfig.setXxxRes()` 注册的分类列表逐个加载 json。
  ///
  /// 每个 json 文件对应一个 Tab，Tab 的分类由注册时指定（json 根节点若声明了
  /// `uiCategory` 则以 json 为准）。
  Future<List<_TabRoot>> _loadTabRootsFromPanelDataList() async {
    final List<TEPanelDataModel>? dataModels = _panelDataList;
    if (dataModels == null || dataModels.isEmpty) {
      debugPrint('$_tag: no panel data registered, and index.json is not configured. '
          'Please call TEResConfig.setPanelViewResAndEffectPlanName() or setXxxRes().');
      return [];
    }
    final List<_TabRoot> result = [];
    for (final TEPanelDataModel dataModel in dataModels) {
      final TEUIProperty? uiProperty = await _loadUIPropertyFromAsset(dataModel.jsonFilePath);
      if (uiProperty == null) {
        continue;
      }
      uiProperty.uiCategory ??= dataModel.category;
      // 保持旧行为：子节点继承的是注册时指定的分类，而非 json 根节点声明的分类。
      result.add(_TabRoot(uiProperty, dataModel.category));
    }
    return result;
  }

  /// 新链路：从 `index.json` 加载。Tab 的数量、顺序、标题、分类全部由 json 描述。
  Future<List<_TabRoot>> _loadTabRootsFromIndexFile() async {
    final TEResConfig config = TEResConfig.getConfig();
    final IndexFileProvider provider = IndexFileProvider(
      indexJsonFilePath: config.panelViewIndexJsonFilePath!,
      effectPlan: config.effectPlan,
    );
    final TEIndexFileModel? fileModel = await provider.loadIndexJson();
    if (fileModel == null || fileModel.data == null || fileModel.data!.isEmpty) {
      debugPrint('$_tag: index.json has no valid data, panel will be empty. '
          'path=${config.panelViewIndexJsonFilePath}');
      return [];
    }
    // 面板文案的默认语言由 index.json 声明，在此回填供 TEPanelDisplay 使用。
    config.defaultDisPlayNameKey = fileModel.defaultLanguage;

    final List<_TabRoot> result = [];
    for (final TEIndexItem item in fileModel.data!) {
      final TEUIProperty? uiProperty = await provider.loadUIPropertyFromItem(item);
      if (uiProperty == null) {
        // 该 Tab 在当前套餐下被裁剪掉，或其 config 文件全部加载失败
        continue;
      }
      final UICategory? category = uiProperty.uiCategory;
      if (category == null) {
        debugPrint('$_tag: tab root has no uiCategory, skipped. config=${item.config}');
        continue;
      }
      result.add(_TabRoot(uiProperty, category));
    }
    return result;
  }

  /// 从 Flutter assets 或本地绝对路径读取并解析单个 panel json。
  ///
  /// 读取或解析失败时返回 null 并输出日志，不中断其余 Tab 的加载。
  Future<TEUIProperty?> _loadUIPropertyFromAsset(String jsonFilePath) async {
    if (jsonFilePath.isEmpty) {
      return null;
    }
    try {
      final String jsonString = await rootBundle.loadString(jsonFilePath);
      if (jsonString.trim().isEmpty) {
        debugPrint('$_tag: panel json is empty. path=$jsonFilePath');
        return null;
      }
      final dynamic decoded = json.decode(jsonString.trim());
      if (decoded is! Map<String, dynamic>) {
        debugPrint('$_tag: panel json root is not a json object. path=$jsonFilePath');
        return null;
      }
      return TEUIProperty.fromJson(decoded);
    } catch (e) {
      debugPrint('$_tag: load panel json failed. path=$jsonFilePath, error=$e');
      return null;
    }
  }

  void _restoreUIStateFromParams(List<TESDKParam>? paramList) {
    if (paramList == null || paramList.isEmpty) return;
    for (TESDKParam param in paramList) {
      TEUIProperty? uiProperty = _uiPropertyIndexByNameMap[_generateKey(param)];
      if (uiProperty != null) {
        if (uiProperty.sdkParam != null) {
          uiProperty.sdkParam!.effectValue = param.effectValue;
          uiProperty.sdkParam!.extraInfo = param.extraInfo;
        }
        if (uiProperty.uiCategory == UICategory.BEAUTY || uiProperty.uiCategory == UICategory.BODY_BEAUTY) {
          uiProperty.setUiState(UIState.IN_USE);
          TEProducerUtils.changeParentUIState(uiProperty, UIState.IN_USE);
        } else {
          uiProperty.setUiState(UIState.CHECKED_AND_IN_USE);
          TEProducerUtils.changeParentUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
        }
      }
    }
  }

  /// 递归归一化整棵属性树。
  ///
  /// [category] 为该 Tab 的继承分类：子节点未显式声明 `uiCategory` 时使用它。
  /// 注意递归时下传的始终是 Tab 级分类，而不是直接父节点的分类 —— 这与 Android 端
  /// 一致，意味着嵌套结构中每一层若需要独立分类都必须在 json 中显式声明。
  Future<void> _completeParams(
      List<TEUIProperty> list, UICategory category, String? titleType, TEUIProperty parentProperty) async {
    for (TEUIProperty property in list) {
      property.parentUIProperty = parentProperty;
      if (property.uiCategory == null) {
        property.uiCategory = category;
      }
      property.titleType = titleType;
      // 按节点自身的分类补全资源路径与下载模型。此处必须用 property.uiCategory 而非
      // Tab 级 category：新版结构中轻美妆是"美妆(BEAUTY)"Tab 下显式声明为
      // LIGHT_MAKEUP 的子项，若按 Tab 级分类处理会命中 default 分支，导致
      // resourcePath 无法从 resourceUri 拼出，妆容点了不生效。
      TEProducerUtils.createDlModelAndSDKParam(property, property.uiCategory!);
      if (property.sdkParam != null) {
        switch (property.uiCategory!) {
          case UICategory.LUT:
            property.sdkParam!.effectName = TEffectName.EFFECT_LUT;
            break;
          case UICategory.MAKEUP:
            property.sdkParam!.effectName = TEffectName.EFFECT_MAKEUP;
            break;
          case UICategory.MOTION:
            property.sdkParam!.effectName = TEffectName.EFFECT_MOTION;
            break;
          case UICategory.SEGMENTATION:
            property.sdkParam!.effectName = TEffectName.EFFECT_SEGMENTATION;
            break;
          case UICategory.LIGHT_MAKEUP:
            property.sdkParam!.effectName = TEffectName.EFFECT_LIGHT_MAKEUP;
            break;
          default:
            break;
        }
      }
      _indexProperty(property);
      if (property.sdkParam != null && TEProducerUtils.isPointMakeup(property.sdkParam!)) {
        pointMakeup.add(property);
      }
      if (property.propertyList != null) {
        await _completeParams(property.propertyList!, category, titleType, property);
      }
    }
  }

  void _indexProperty(TEUIProperty property) {
    if (property.uiCategory == UICategory.BEAUTY_TEMPLATE) {
      if (_originalParamList != null && _originalParamList!.isNotEmpty) {
        property.setUiState(UIState.INIT);
      }
      if (property.paramList != null) {
        String? uiIndex = _getNameMapKeyFromProperty(property);
        if (uiIndex != null && uiIndex.isNotEmpty) {
          _uiPropertyIndexByNameMap[uiIndex] = property;
        }
      }
    } else {
      String? uiIndex = _getNameMapKeyFromProperty(property);
      if (uiIndex != null && uiIndex.isNotEmpty) {
        _uiPropertyIndexByNameMap[uiIndex] = property;
      }
    }
  }

  String? _getNameMapKeyFromProperty(TEUIProperty property) {
    if (property.uiCategory == UICategory.BEAUTY_TEMPLATE &&
        property.paramList != null && property.paramList!.isNotEmpty) {
      return '${TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME}${property.id}';
    }
    if (property.sdkParam == null) return null;
    return _generateKey(property.sdkParam!);
  }

  String _generateKey(TESDKParam param) {
    if (param.effectName == TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME) {
      return '${TESDKParam.BEAUTY_TEMPLATE_EFFECT_NAME}${param.effectValue}';
    }
    StringBuffer keyBuilder = StringBuffer();
    if (param.effectName != null && param.effectName!.isNotEmpty) {
      keyBuilder.write(param.effectName);
    }
    if (param.resourcePath != null && param.resourcePath!.isNotEmpty) {
      keyBuilder.write(param.resourcePath);
    }
    return keyBuilder.toString();
  }

  void _restoreUIState(List<TEUIProperty> allData) {
    List<TEUIProperty> allBeautyPropertyList = [];
    for (TEUIProperty property in allData) {
      if (property.uiCategory == UICategory.BODY_BEAUTY && property.propertyList != null) {
        TEProducerUtils.findFirstInUseItemAndMakeChecked(property.propertyList);
      }
      if (property.uiCategory == UICategory.BEAUTY) {
        allBeautyPropertyList.add(property);
        _obtainPointMakeup(property);
        pointMakeupChecked = TEProducerUtils.getUsedProperties(pointMakeup).isNotEmpty || pointMakeupChecked;
        // 轻美妆既可能作为独立一级标题存在（见下方 LIGHT_MAKEUP 分支），
        // 也可能被配置在"单点美妆"标题下作为二级标题；而单点美妆在解析后 uiCategory
        // 会被归并成 BEAUTY（见 EffectPlan），导致顶层遍历时只能看到 BEAUTY，
        // 因此需继续深入其二级标题才能发现嵌套的轻美妆。
        _checkNestedLightMakeup(property);
      }
      if (property.uiCategory == UICategory.LUT) {
        pointMakeupChecked = TEProducerUtils.getUsedProperties(pointMakeup).isNotEmpty || pointMakeupChecked;
      }
      if (property.uiCategory == UICategory.LIGHT_MAKEUP) {
        _hasLightMakeup = true;
        lightMakeupChecked = TEProducerUtils.getUsedProperties([property]).isNotEmpty;
      }
    }
    if (allBeautyPropertyList.isNotEmpty) {
      TEProducerUtils.findFirstInUseItemAndMakeChecked(allBeautyPropertyList);
    }
  }

  /// 从"单点美妆"类目（[UICategory.BEAUTY]）的二级标题中识别嵌套的轻美妆节点，
  /// 用于互斥逻辑（[lightMakeupChecked] / [_hasLightMakeup]）的正确判断。
  void _checkNestedLightMakeup(TEUIProperty beautyProperty) {
    final List<TEUIProperty>? children = beautyProperty.propertyList;
    if (children == null || children.isEmpty) {
      return;
    }
    for (final TEUIProperty child in children) {
      if (child.uiCategory != UICategory.LIGHT_MAKEUP) {
        continue;
      }
      _hasLightMakeup = true;
      // 判断该轻美妆是否有默认选中项（与 Android 一致：直接覆盖，保证面板重建后不残留旧状态）
      lightMakeupChecked = TEProducerUtils.getUsedProperties([child]).isNotEmpty;
    }
  }

  void _obtainPointMakeup(TEUIProperty teuiProperty) {
    if (teuiProperty.propertyList != null) {
      for (TEUIProperty uiProperty in teuiProperty.propertyList!) {
        _obtainPointMakeup(uiProperty);
      }
    } else if (teuiProperty.sdkParam != null && TEProducerUtils.isPointMakeup(teuiProperty.sdkParam!)) {
      pointMakeup.add(teuiProperty);
    }
  }

  @override
  List<TESDKParam>? getCloseEffectItems(TEUIProperty uiProperty) {
    switch (uiProperty.uiCategory) {
      case UICategory.BEAUTY:
      case UICategory.BODY_BEAUTY:
        TEUIProperty? currentProperty = _titleTypeData[uiProperty.titleType];
        if (currentProperty != null && currentProperty.propertyList != null) {
          List<TESDKParam> usedList = TEProducerUtils.getUsedProperties(currentProperty.propertyList!);
          TEProducerUtils.changParamValuedTo0(usedList);
          return usedList;
        }
        break;
      case UICategory.LUT:
        return [TEProducerUtils.createNoneItem(TEffectName.EFFECT_LUT)];
      case UICategory.MAKEUP:
      case UICategory.MOTION:
      case UICategory.SEGMENTATION:
        return [TEProducerUtils.createNoneItem(TEffectName.EFFECT_MOTION)];
      case UICategory.LIGHT_MAKEUP:
        return [TEProducerUtils.createNoneItem(TEffectName.EFFECT_LIGHT_MAKEUP)];
      case UICategory.GREEN_BACKGROUND_V2_ITEM:
        TEUIProperty? gsv2uiProperty = uiProperty.parentUIProperty;
        if (gsv2uiProperty?.sdkParam?.extraInfo != null) {
          gsv2uiProperty!.sdkParam!.extraInfo!.remove(TESDKParam.EXTRA_INFO_KEY_BG_PATH);
        }
        return [TEProducerUtils.createNoneItem(TEffectName.EFFECT_MOTION)];
      default:
        return null;
    }
    return null;
  }

  @override
  Future<List<TESDKParam>> getRevertData() async {
    List<TESDKParam> usedList = TEProducerUtils.getUsedProperties(_allData);
    bool hasLut = false;
    bool hasMotion = false;
    for (TESDKParam param in usedList) {
      if (param.effectName == TEffectName.EFFECT_LUT) {
        hasLut = true;
      }
      if (param.effectName == TEffectName.EFFECT_MAKEUP ||
          param.effectName == TEffectName.EFFECT_MOTION ||
          param.effectName == TEffectName.EFFECT_SEGMENTATION) {
        hasMotion = true;
      }
    }
    if (TEResConfig.getConfig().revertEffect2Json) {
      _originalParamList = null;
    }
    await getPanelData(forceRefreshData: true);
    List<TESDKParam> defaultUsedList = TEProducerUtils.getUsedProperties(_allData);
    for (TESDKParam param in defaultUsedList) {
      if (param.effectName == TEffectName.EFFECT_LUT) {
        hasLut = false;
      }
      if (param.effectName == TEffectName.EFFECT_MAKEUP ||
          param.effectName == TEffectName.EFFECT_MOTION ||
          param.effectName == TEffectName.EFFECT_SEGMENTATION) {
        hasMotion = false;
      }
    }

    TEParamManager paramManager = TEParamManager();
    paramManager.putTEParams(TEProducerUtils.clone0ValuedParam(usedList));
    paramManager.putTEParams(defaultUsedList);
    if (hasLut) {
      paramManager.putTEParam(TEProducerUtils.createNoneItem(TEffectName.EFFECT_LUT));
    }
    if (hasMotion) {
      paramManager.putTEParam(TEProducerUtils.createNoneItem(TEffectName.EFFECT_MOTION));
    }
    return paramManager.getParams();
  }

  @override
  List<TESDKParam> getUsedProperties() {
    return TEProducerUtils.getUsedProperties(_allData);
  }

  @override
  List<TEUIProperty>? onItemClick(TEUIProperty uiProperty) {
    return _onItemClickInternal(uiProperty, true);
  }

  List<TEUIProperty>? _onItemClickInternal(TEUIProperty uiProperty, bool isFromUI) {
    if (uiProperty.uiCategory == null) {
      return null;
    }
    switch (uiProperty.uiCategory) {
      case UICategory.BEAUTY_TEMPLATE:
        _hasBeautyTemplateChecked = true;
        _uncheckBeautyAndLut();
        // 模板与轻美妆互斥：选中模板时清掉轻美妆套装
        _uncheckLightMakeup();
        _checkItem(uiProperty, isFromUI);
        break;
      case UICategory.BEAUTY:
      case UICategory.LUT:
        _uncheckBeautyTemplate();
        _onClickPointMakeup(uiProperty, isFromUI);
        break;
      case UICategory.BODY_BEAUTY:
        _onClickPointMakeup(uiProperty, isFromUI);
        break;
      case UICategory.LIGHT_MAKEUP:
        _onClickLightMakeup(uiProperty, isFromUI);
        break;
      case UICategory.LIGHT_MAKEUP_ITEM:
        _onClickLightMakeupItem(uiProperty);
        break;
      case UICategory.LIGHT_MAKEUP_BACK:
        // 返回项由 UI 层拦截处理，不走选中逻辑
        break;
      case UICategory.MAKEUP:
      case UICategory.MOTION:
      case UICategory.SEGMENTATION:
        _handleMakeupMotionSegmentation(uiProperty, isFromUI);
        break;
      case UICategory.GREEN_BACKGROUND_V2_ITEM:
      case UICategory.GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE:
        _handleMakeupMotionSegmentation(uiProperty, isFromUI);
        break;
      default:
        break;
    }
    return uiProperty.propertyList;
  }

  void _handleMakeupMotionSegmentation(TEUIProperty uiProperty, bool isFromUI) {
    List<TEUIProperty> makeUpProperty = _getDataByUICategory(UICategory.MAKEUP);
    List<TEUIProperty> motionProperty = _getDataByUICategory(UICategory.MOTION);
    List<TEUIProperty> segProperty = _getDataByUICategory(UICategory.SEGMENTATION);

    bool shouldProcess = !isFromUI ||
        ((uiProperty.propertyList == null && uiProperty.sdkParam != null) || uiProperty.isNoneItem());

    if (shouldProcess) {
      TEProducerUtils.revertUIState(makeUpProperty, uiProperty);
      TEProducerUtils.revertUIState(motionProperty, uiProperty);
      TEProducerUtils.revertUIState(segProperty, uiProperty);
      TEProducerUtils.changeParamUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
    }
  }

  void _checkItem(TEUIProperty uiProperty, bool isFromUI) {
    TEUIProperty? currentProperty = _titleTypeData[uiProperty.titleType];
    if (!isFromUI) {
      if (currentProperty == null) return;
      TEProducerUtils.revertUIState(currentProperty.propertyList, uiProperty);
      TEProducerUtils.changeParamUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
      return;
    }
    if ((uiProperty.propertyList == null && uiProperty.sdkParam != null) || uiProperty.isNoneItem()) {
      if (currentProperty != null) {
        TEProducerUtils.revertUIState(currentProperty.propertyList, uiProperty);
        TEProducerUtils.changeParamUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
      }
    } else if (uiProperty.paramList != null || uiProperty.isNoneItem()) {
      List<TEUIProperty> processData = [];
      for (TEUIProperty property in _allData) {
        if (property.uiCategory == uiProperty.uiCategory) {
          processData.add(property);
        }
      }
      TEProducerUtils.revertUIState(processData, uiProperty);
      TEProducerUtils.changeParamUIState(uiProperty, UIState.CHECKED_AND_IN_USE);
    }
  }

  void _onClickPointMakeup(TEUIProperty property, bool isFromUI) {
    _checkItem(property, isFromUI);
    if (_hasLightMakeup && property.sdkParam != null && TEProducerUtils.isPointMakeup(property.sdkParam!)) {
      pointMakeupChecked = true;
      if (!lightMakeupChecked) return;
      if (!TEResConfig.getConfig().cleanLightMakeup) return;
      _uncheckLightMakeup();
    }
  }

  void _onClickLightMakeup(TEUIProperty property, bool isFromUI) {
    // 轻美妆与模板互斥：选中轻美妆套装时清掉模板
    _uncheckBeautyTemplate();
    lightMakeupChecked = true;
    _checkItem(property, isFromUI);
    if (!pointMakeupChecked) return;
    _uncheckPointMakeup();
  }

  /// 下钻态下点击轻美妆单项：仅切换子列表内的选中状态，兄弟项统一回到 INIT。
  ///
  /// 单项不直接下发给 SDK，真正的效果下发由滑竿拖动时写入父套装 `extraInfo` 触发。
  void _onClickLightMakeupItem(TEUIProperty property) {
    final TEUIProperty? parentProperty = property.parentUIProperty;
    if (parentProperty != null) {
      TEProducerUtils.revertUIStateToInit(parentProperty.propertyList);
    }
    TEProducerUtils.changeParamUIState(property, UIState.CHECKED_AND_IN_USE);
  }

  void _uncheckPointMakeup() {
    pointMakeupChecked = false;
    List<TEUIProperty> lutData = _getDataByUICategory(UICategory.LUT);
    for (TEUIProperty teuiProperty in lutData) {
      _unCheckItem(teuiProperty);
    }
    TEProducerUtils.revertUIStateToInit(pointMakeup);
  }

  /// 清空轻美妆套装（含任意层级下的轻美妆）。
  ///
  /// 轻美妆既可能作为独立一级标题存在，也可能配置在"单点美妆"标题下作为二级标题
  /// （单点美妆在解析后 uiCategory 会被归并成 [UICategory.BEAUTY]），
  /// 因此不能只遍历一级标题，需要递归收集。
  void _uncheckLightMakeup() {
    lightMakeupChecked = false;
    final List<TEUIProperty> lightMakeup = <TEUIProperty>[];
    for (final TEUIProperty teuiProperty in _allData) {
      _collectByUICategory(teuiProperty, UICategory.LIGHT_MAKEUP, lightMakeup);
    }
    TEProducerUtils.revertUIStateToInit(lightMakeup);
  }

  /// 递归收集指定 uiCategory 的所有项（含一级标题与任意层级子项）。
  void _collectByUICategory(TEUIProperty? property, UICategory uiCategory, List<TEUIProperty> result) {
    if (property == null) {
      return;
    }
    if (property.uiCategory == uiCategory) {
      result.add(property);
    }
    final List<TEUIProperty>? children = property.propertyList;
    if (children != null) {
      for (final TEUIProperty child in children) {
        _collectByUICategory(child, uiCategory, result);
      }
    }
  }

  void _uncheckBeautyTemplate() {
    if (!_hasBeautyTemplateChecked) return;
    _hasBeautyTemplateChecked = false;
    List<TEUIProperty> beautyTemplate = _getDataByUICategory(UICategory.BEAUTY_TEMPLATE);
    for (TEUIProperty teuiProperty in beautyTemplate) {
      _unCheckItem(teuiProperty);
    }
  }

  void _uncheckBeautyAndLut() {
    List<TEUIProperty> beautyData = _getDataByUICategory(UICategory.BEAUTY);
    for (TEUIProperty teuiProperty in beautyData) {
      _unCheckItem(teuiProperty);
    }
    List<TEUIProperty> lutData = _getDataByUICategory(UICategory.LUT);
    for (TEUIProperty teuiProperty in lutData) {
      _unCheckItem(teuiProperty);
    }
  }

  void _unCheckItem(TEUIProperty teuiProperty) {
    TEProducerUtils.revertUIStateToInit([teuiProperty]);
  }

  @override
  void onTabItemClick(TEUIProperty uiProperty) {
    for (TEUIProperty property in _allData) {
      if (property == uiProperty) {
        property.setUiState(UIState.CHECKED_AND_IN_USE);
      } else {
        property.setUiState(UIState.INIT);
      }
    }
  }

  @override
  List<TEUIProperty>? getFirstCheckedItems() {
    for (TEUIProperty property in _allData) {
      if (property.uiState == UIState.CHECKED_AND_IN_USE && property.propertyList != null) {
        return property.propertyList!;
      }
    }
    // No tab has CHECKED_AND_IN_USE state, fallback to selecting the first tab
    // (matches Android TEBeautyTabLayout behavior: "没有默认选中项，手动选中第0项")
    if (_allData.isNotEmpty) {
      _allData[0].setUiState(UIState.CHECKED_AND_IN_USE);
      return _allData[0].propertyList;
    }
    return null;
  }

  List<TEUIProperty> _getDataByUICategory(UICategory uiCategory) {
    List<TEUIProperty> result = [];
    for (TEUIProperty tuiProperty in _allData) {
      if (tuiProperty.uiCategory == uiCategory) {
        result.add(tuiProperty);
      }
    }
    return result;
  }

  /// Expose restoreUIStateFromParams for external use (e.g., panel view template sync)
  void restoreUIStateFromParams(List<TESDKParam>? paramList) {
    _restoreUIStateFromParams(paramList);
  }
}
