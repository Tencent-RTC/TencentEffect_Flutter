// 中文繁体本地化实现
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_effect_flutter/uikit/l10n/te_panel_localizations.dart';
import 'package:tencent_effect_flutter/uikit/model/te_ui_property.dart';

class TEPanelLocalizationsZhTW extends TEPanelLocalizations {
  TEPanelLocalizationsZhTW() : super('zh_TW');

  @override
  String get makeup => '美妝';

  @override
  String get lut => '濾鏡';

  @override
  String get revert => '重置';

  @override
  String? getDisplayName(TEUIProperty uiProperty) {
    return uiProperty.displayName;
  }
}

// 中文繁体 Delegate
class TEPanelLocalizationsZhTWDelegate extends LocalizationsDelegate<TEPanelLocalizations> {
  const TEPanelLocalizationsZhTWDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'zh' &&
        (locale.countryCode == 'TW' ||
            locale.countryCode == 'HK' ||
            locale.countryCode == 'MO' ||
            locale.scriptCode == 'Hant');
  }

  @override
  Future<TEPanelLocalizations> load(Locale locale) {
    return SynchronousFuture<TEPanelLocalizations>(TEPanelLocalizationsZhTW());
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<TEPanelLocalizations> old) => false;
}
