import 'package:flutter/cupertino.dart';

import 'AppLocalizations.dart';

class APPLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  // 1.
  static const APPLocalizationDelegate delegate = APPLocalizationDelegate();

  const APPLocalizationDelegate();

  // 2.
  @override
  bool isSupported(Locale locale) {
    return [
      "en",
      "zh",
    ].contains(locale.languageCode);
  }

  // 3
  @override
  Future<AppLocalizations> load(Locale locale) async {
    final appLocalizations = AppLocalizations(locale);
    await appLocalizations.loadJson();
    return appLocalizations;
  }

  // 4
  @override
  bool shouldReload(APPLocalizationDelegate old) {
    return false;
  }
}
