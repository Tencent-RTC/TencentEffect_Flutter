
import 'package:tencent_effect_flutter_demo/model/te_ui_property.dart';

class TEPanelDataModel {
  late String jsonFilePath;
  late UICategory category;

  String? abilityType;

  TEPanelDataModel(String _jsonFilePath, UICategory _category,
      {this.abilityType}) {
    jsonFilePath = _jsonFilePath;
    category = _category;
  }
}
