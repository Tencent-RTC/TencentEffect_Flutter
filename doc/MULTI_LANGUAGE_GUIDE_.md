# tencent_effect_flutter 多语言适配指南

## 1. 概述

`tencent_effect_flutter` 插件内置支持 **英文（en）** 和 **简体中文（zh）** 两种语言。

宿主 App 如需扩展其他语言（如繁体中文、日语等），可通过以下两种机制实现，**无需修改插件源码**：

| 适配内容 | 适配方式 | 影响范围 |
|---------|---------|---------|
| 面板 UI 固定文案（标签、按钮） | 继承基类 + 自定义 Delegate | `makeup`、`lut`、`revert` 等 |
| 面板中各美颜项名称 | 多语言 JSON 配置文件 | 所有美颜/滤镜/动效项的 `displayName` |

> **说明**：以上两部分相互独立，需同时配置才能实现完整的多语言支持。

---

## 2. 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        MaterialApp                               │
│  localizationsDelegates:                                         │
│    1. TEPanelLocalizationsZhTWDelegate()  ← 宿主 App 自定义      │
│    2. TEPanelLocalizations.delegate        ← 插件内置（兜底）     │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼                               ▼
┌──────────────────────┐         ┌──────────────────────────┐
│    插件层（内置）      │         │   宿主 App 层（扩展）      │
├──────────────────────┤         ├──────────────────────────┤
│ TEPanelLocalizations │◄────────│ TEPanelLocalizationsZhTW │
│   (抽象基类)          │         │   (繁体中文实现)          │
├──────────────────────┤         ├──────────────────────────┤
│ TEPanelLocalizationsEn│         │ TEPanelLocalizationsZhTW │
│ TEPanelLocalizationsZh│         │   Delegate               │
└──────────────────────┘         └──────────────────────────┘
```

**核心机制**：Flutter 按 `localizationsDelegates` 列表顺序查找，第一个 `isSupported()` 返回 `true` 的 Delegate 生效。将自定义 Delegate 放在插件内置 Delegate **之前**即可优先拦截。

---

## 3. 面板 UI 文案适配（Delegate 方式）

适用于面板中的固定 UI 文案，如标签名称、按钮文字等。

### 3.1 需要实现的接口

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `makeup` | `String` | 美妆 Tab 标签文案 |
| `lut` | `String` | 滤镜 Tab 标签文案 |
| `revert` | `String` | 重置按钮文案 |
| `getDisplayName(uiProperty)` | `String?` | 面板中各美颜项的显示名称来源 |

> `getDisplayName` 中可选择返回 `uiProperty.displayName`（中文名）或 `uiProperty.displayNameEn`（英文名），取决于目标语言。

### 3.2 创建翻译实现类

继承 `TEPanelLocalizations` 抽象基类，实现所有抽象属性：

```dart
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
```

### 3.3 创建自定义 Delegate

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tencent_effect_flutter/uikit/l10n/te_panel_localizations.dart';

class TEPanelLocalizationsZhTWDelegate
    extends LocalizationsDelegate<TEPanelLocalizations> {
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
    return SynchronousFuture<TEPanelLocalizations>(
        TEPanelLocalizationsZhTW());
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<TEPanelLocalizations> old) => false;
}
```

### 3.4 注册到 MaterialApp

```dart
MaterialApp(
  localizationsDelegates: const [
    // 自定义 Delegate 放在前面，优先匹配
    TEPanelLocalizationsZhTWDelegate(),
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    // 插件内置 Delegate 放在后面，作为兜底
    TEPanelLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale.fromSubtags(languageCode: 'en'),
    Locale.fromSubtags(languageCode: 'zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'MO'),
  ],
);
```

> ⚠️ **注意**：自定义 Delegate 必须注册在 `TEPanelLocalizations.delegate` **之前**，否则会被插件内置 Delegate 优先拦截。

---

## 4. 面板 JSON 配置文件多语言适配

适用于面板中各美颜/滤镜/动效项的显示名称（`displayName`）。

### 4.1 默认 JSON 结构

默认 JSON 文件位于 `assets/beauty_panel/` 目录，内置 `displayName`（简体中文）和 `displayNameEn`（英文）两个字段：

```json
{
    "displayName": "美颜",
    "displayNameEn": "Beauty",
    "propertyList": [
        {
            "displayName": "美白",
            "displayNameEn": "Brighten",
            "icon": "beauty_panel/panel_icon/beauty/beauty_whiten.png",
            "sdkParam": {
                "effectName": "beauty.lutFoundationAlpha0",
                "effectValue": 40
            }
        }
    ]
}
```

### 4.2 创建语言目录

在 `assets/beauty_panel/` 下创建对应语言的子目录：

```
assets/beauty_panel/
├── beauty.json                ← 默认（简体中文 + 英文）
├── lut.json
├── makeup.json
├── ...
└── zh_hant/                   ← 繁体中文
    ├── beauty.json
    ├── lut.json
    ├── makeup.json
    └── ...
```

### 4.3 翻译 JSON 文件

将默认目录下的 JSON 文件复制到新语言目录，修改 `displayName` 为目标语言翻译：

```json
{
    "displayName": "美顏",
    "propertyList": [
        {
            "displayName": "美白",
            "icon": "beauty_panel/panel_icon/beauty/beauty_whiten.png",
            "sdkParam": {
                "effectName": "beauty.lutFoundationAlpha0",
                "effectValue": 40
            }
        }
    ]
}
```

> **说明**：新语言 JSON 中只需保留 `displayName` 字段，无需 `displayNameEn`。`icon`、`sdkParam` 等功能字段保持不变。

### 4.4 动态加载对应语言目录

在 `initPanelViewConfig` 方法中，根据设备语言环境动态切换 JSON 加载路径：

```dart
void initPanelViewConfig() {
  String panelDir = "assets/beauty_panel/";
  TEResConfig.getConfig().defaultPanelDataList.clear();

  // 判断当前设备语言环境
  Locale currentLocale = PlatformDispatcher.instance.locale;
  bool isTraditionalChinese = currentLocale.languageCode == 'zh' &&
      (currentLocale.countryCode == 'TW' ||
          currentLocale.countryCode == 'HK' ||
          currentLocale.countryCode == 'MO' ||
          currentLocale.scriptCode == 'Hant');

  if (isTraditionalChinese) {
    panelDir = "assets/beauty_panel/zh_hant/";
  }

  TEResConfig.getConfig()
    ..setBeautyTemplateRes("${panelDir}beauty_template.json")
    ..setBeautyRes("${panelDir}beauty.json")
    ..setBeautyRes("${panelDir}beauty_image.json")
    ..setBeautyRes("${panelDir}beauty_makeup.json")
    ..setBeautyRes("${panelDir}beauty_shape.json")
    ..setBeautyBodyRes("${panelDir}beauty_body.json")
    ..setLutRes("${panelDir}lut.json")
    ..setLightMakeupRes("${panelDir}light_makeup.json")
    ..setMakeUpRes("${panelDir}makeup.json")
    ..setMotionRes("${panelDir}motion_2d.json")
    ..setMotionRes("${panelDir}motion_3d.json")
    ..setMotionRes("${panelDir}motion_gesture.json")
    ..setSegmentationRes("${panelDir}segmentation.json");
}
```

### 4.5 声明资源文件

在 `pubspec.yaml` 中声明新语言目录：

```yaml
flutter:
  assets:
    - assets/beauty_panel/
    - assets/beauty_panel/zh_hant/
```

---

## 5. 扩展其他语言（示例）

以日语为例，完整适配流程如下：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 创建 `TEPanelLocalizationsJa` 类 | 继承基类，实现日语翻译 |
| 2 | 创建 `TEPanelLocalizationsJaDelegate` | `isSupported` 判断 `locale.languageCode == 'ja'` |
| 3 | 注册 Delegate 到 `MaterialApp` | 放在 `TEPanelLocalizations.delegate` 之前 |
| 4 | 创建 `assets/beauty_panel/ja/` 目录 | 复制 JSON 文件并翻译 `displayName` |
| 5 | 在 `initPanelViewConfig` 中添加判断 | 日语环境加载 `ja/` 目录 |
| 6 | 在 `pubspec.yaml` 中声明资源 | 添加 `assets/beauty_panel/ja/` |
| 7 | 在 `supportedLocales` 中添加 | `Locale.fromSubtags(languageCode: 'ja')` |

---

## 6. 注意事项

1. **Delegate 注册顺序**：自定义 Delegate 必须在 `TEPanelLocalizations.delegate` 之前，否则无法生效。
2. **supportedLocales 声明**：所有需要支持的 Locale 变体都必须在 `supportedLocales` 中声明。
3. **scriptCode 说明**：`Hant` 表示繁体中文书写系统（Han Traditional），`Hans` 表示简体中文（Han Simplified）。部分系统（如 iOS）会使用 `scriptCode` 而非 `countryCode` 标识繁简体。
4. **两部分独立配置**：Delegate 适配（面板 UI 文案）和 JSON 适配（美颜项名称）是独立的两部分，需同时完成才能实现完整的多语言效果。
5. **JSON 文件一致性**：新语言目录下的 JSON 文件数量和结构应与默认目录保持一致，避免加载失败。
