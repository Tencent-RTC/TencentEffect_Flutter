
import '../model/te_ui_property.dart';

abstract class BeautyPanelViewCallBack {
  ///Used when updating beauty attributes
  void onUpdateEffect(TESDKParam sdkParam);



  ///Used for updating multiple beauty attributes, for example, when clicking the close button
  void onUpdateEffectList(List<TESDKParam> sdkParams);



  /// @param paramList This method is used to return the default beauty effect list attributes to participants
  void onDefaultEffectList(List<TESDKParam> paramList);



  /// Since Green Screen and Custom segmentation attributes are quite special and require special handling, the corresponding data is returned through this method separately
  /// This callback is triggered when the Green Screen or Custom segmentation has been clicked
  /// @param uiProperty
  void onClickCustomSeg(TEUIProperty uiProperty);
}

