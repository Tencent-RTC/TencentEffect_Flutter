import 'package:flutter/widgets.dart';

import '../config/te_res_config.dart';
import '../l10n/te_panel_localizations.dart';
import '../model/te_ui_property.dart';

/// 面板文案的取值工具，同时兼容新旧两套多语言方案。
class TEPanelDisplay {
  TEPanelDisplay._();

  /// 获取面板功能项应展示的文案。
  ///
  /// 取值规则：
  /// - 新版链路（节点配置了 [TEUIProperty.name]）：按语言 key 从 `name` 中取值，
  ///   key 的优先级为 `TEResConfig.disPlayNameKey` > `index.json` 的 `defaultLanguage`。
  ///   若该节点缺少当前语言对应的 key，返回空字符串（与 Android 端行为一致，
  ///   不做跨语言兜底，便于在联调期暴露漏配的语言）。
  /// - 旧版链路（节点只有 `displayName` / `displayNameEn`）：沿用原有实现，
  ///   按 App 当前 locale 选取。
  static String getDisplayName(BuildContext context, TEUIProperty? uiProperty) {
    if (uiProperty == null) {
      return '';
    }
    final Map<String, String>? nameMap = uiProperty.name;
    if (nameMap != null && nameMap.isNotEmpty) {
      final String? key = resolveDisplayNameKey();
      if (key == null || key.isEmpty) {
        return '';
      }
      return nameMap[key] ?? '';
    }
    return TEPanelLocalizations.of(context).getDisplayName(uiProperty) ?? '';
  }

  /// 解析当前生效的语言 key：业务显式设置的优先，其次是 `index.json` 的 `defaultLanguage`。
  static String? resolveDisplayNameKey() {
    final TEResConfig config = TEResConfig.getConfig();
    final String? custom = config.disPlayNameKey;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return config.defaultDisPlayNameKey;
  }
}
