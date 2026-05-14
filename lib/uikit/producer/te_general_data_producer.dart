import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../uikit/producer/te_panel_data_producer.dart';
import '../config/te_res_config.dart';
import '../constant/te_constant.dart';
import '../manager/te_param_manager.dart';
import '../model/te_panel_data_model.dart';
import '../model/te_ui_property.dart';
import '../utils/te_producer_utils.dart';

class TEGeneralDataProducer implements TEPanelDataProducer {
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

    for (var dataModel in _panelDataList!) {
      final jsonString = await rootBundle.loadString(dataModel.jsonFilePath);
      Map<String, dynamic> map = json.decode(jsonString);
      TEUIProperty uiProperty = TEUIProperty.fromJson(map);
      if (uiProperty.uiCategory == null) {
        uiProperty.uiCategory = dataModel.category;
      }
      uiProperty.titleType = uiProperty.displayName;
      if (uiProperty.propertyList != null) {
        await _completeParams(uiProperty.propertyList!, dataModel.category, uiProperty.titleType, uiProperty);
      }
      if (uiProperty.uiCategory == UICategory.BEAUTY_TEMPLATE) {
        templateData = uiProperty;
      }
      _indexProperty(uiProperty);
      result.add(uiProperty);
      _titleTypeData["${uiProperty.titleType}"] = uiProperty;
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
        _restoreUIStateFromParams(_originalParamList);
        if (templateParam.tag is List) {
          beautyDataToSync = templateParam.tag as List<TESDKParam>;
        }
      } else {
        // User had individual beauty params (no template)
        _uncheckBeautyAndLut();
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
      _restoreUIStateFromParams(beautyDataToSync);
    }

    _restoreUIState(result);
    return result;
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

  Future<void> _completeParams(
      List<TEUIProperty> list, UICategory category, String? titleType, TEUIProperty parentProperty) async {
    for (TEUIProperty property in list) {
      property.parentUIProperty = parentProperty;
      if (property.uiCategory == null) {
        property.uiCategory = category;
      }
      property.titleType = titleType;
      TEProducerUtils.createDlModelAndSDKParam(property, category);
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
    lightMakeupChecked = true;
    _checkItem(property, isFromUI);
    if (!pointMakeupChecked) return;
    _uncheckPointMakeup();
  }

  void _uncheckPointMakeup() {
    pointMakeupChecked = false;
    List<TEUIProperty> lutData = _getDataByUICategory(UICategory.LUT);
    for (TEUIProperty teuiProperty in lutData) {
      _unCheckItem(teuiProperty);
    }
    TEProducerUtils.revertUIStateToInit(pointMakeup);
  }

  void _uncheckLightMakeup() {
    lightMakeupChecked = false;
    List<TEUIProperty> lightMakeup = _getDataByUICategory(UICategory.LIGHT_MAKEUP);
    for (TEUIProperty teuiProperty in lightMakeup) {
      _unCheckItem(teuiProperty);
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
