import 'dart:core';
import '../model/te_panel_data_model.dart';
import '../model/te_ui_property.dart';

class TEResConfig {
  List<TEPanelDataModel> defaultPanelDataList = [];

  TEResConfig._internal();

  static TEResConfig? resConfig;

  static TEResConfig getConfig() {
    resConfig ??= TEResConfig._internal();
    return resConfig!;
  }

 
  void setBeautyRes(String resourcePath) {
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.BEAUTY));
  }


  void setBeautyBodyRes(String resourcePath) {
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.BODY_BEAUTY));
  }


  void setLutRes(String resourcePath) {
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.LUT));
  }


  void setMakeUpRes(String resourcePath) {
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.MAKEUP));
  }


  void setMotionRes(String resourcePath) {
    defaultPanelDataList.add(TEPanelDataModel(resourcePath, UICategory.MOTION));
  }


  void setSegmentationRes(String resourcePath) {
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.SEGMENTATION));
  }

  void setLightMakeupRes(String resourcePath) {
    defaultPanelDataList
        .add(TEPanelDataModel(resourcePath, UICategory.LIGHT_MAKEUP));
  }
  List<TEPanelDataModel> getPanelDataList() {
    return defaultPanelDataList;
  }
}
