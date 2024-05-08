import 'package:flutter/material.dart';

import '../model/te_ui_property.dart';

class PanelDisplay {
  static Locale? _currentLocal;

  static void setLocale(BuildContext context) {
    _currentLocal =  Localizations.localeOf(context);
  }

  static String? getDisplayName(TEUIProperty uiProperty) {
    if (_currentLocal?.languageCode == "zh") {
      return uiProperty.displayName;
    } else {
      return uiProperty.displayNameEn;
    }
  }
}
