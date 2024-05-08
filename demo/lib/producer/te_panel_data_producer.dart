import '../model/te_panel_data_model.dart';
import '../model/te_ui_property.dart';


abstract class TEPanelDataProducer {

/// Set the data to be loaded
  /// @param panelDataList
  void setPanelDataList(List<TEPanelDataModel> panelDataList);



  /// Set the default data selected by the user, generally only set beauty data
  /// @param paramList
  void setUsedParams(List<TESDKParam> paramList);



  /// Retrieve data
  ///
  /// @return
  Future<List<TEUIProperty>> getPanelData() ;



  /// Force refresh data
  ///
  /// @param context Application context
  /// @return
  Future<List<TEUIProperty>> forceRefreshPanelData();



  /// This method is called when a category is clicked, and it handles the change of the selected state of categorical data
  /// @param index
  onTabItemClick(TEUIProperty uiProperty) ;



  /// Called when a list item is clicked
  ///
  /// @param uiProperty
  /// @return Returns a sub-item if available, otherwise returns null
  List<TEUIProperty>? onItemClick(TEUIProperty uiProperty);



  /// Retrieves the attribute collection used to restore the beauty effect
  ///
  /// @return
  List<TESDKParam> getRevertData();



  /// Used to close the current classification effect's attribute list
  ///
  /// @return
  List<TESDKParam>? getCloseEffectItems(TEUIProperty uiProperty);



  /// Retrieve the beauty data used by the user
  /// @return
  List<TESDKParam> getUsedProperties();



  /// According to the JSON file, obtain the list data of the first selected item
  /// @return
  List<TEUIProperty>? getFirstCheckedItems();

  

}
