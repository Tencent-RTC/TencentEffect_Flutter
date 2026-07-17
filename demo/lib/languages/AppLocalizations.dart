// 1
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  // 1
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    AppLocalizations? appLocalizations = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return appLocalizations;
  }

  Map<String, Map<String, String>> _localizedStrings = {};

  /// 获取当前 locale 对应的 JSON key
  /// 繁体中文（TW/HK/Hant）使用 "zh_TW"，其他使用 languageCode
  String get _localeKey {
    if (locale.languageCode == 'zh' &&
        (locale.countryCode == 'TW' ||
            locale.countryCode == 'HK' ||
            locale.countryCode == 'MO' ||
            locale.scriptCode == 'Hant')) {
      return 'zh_TW';
    }
    return locale.languageCode;
  }

  // 3
  Future loadJson() async {
    final jsonString = await rootBundle.loadString("assets/labels/i18n.json");
    Map<String, dynamic> map = json.decode(jsonString);
    _localizedStrings = map.map((key, value) => MapEntry(key, value.cast<String, String>()));
  }

  String? get getDemoLiveLabel2 => _localizedStrings[_localeKey]!["demo_live_label2"];

  String? get getDemoLiveLabel3 => _localizedStrings[_localeKey]!["demo_live_label3"];

  String? get getDemoLiveLabel4 => _localizedStrings[_localeKey]!["demo_live_label4"];

  String? get getEffectModeDes => _localizedStrings[_localeKey]!["effect_mode_des"];
}
