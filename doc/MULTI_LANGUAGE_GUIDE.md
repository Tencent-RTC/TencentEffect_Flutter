# tencent_effect_flutter 多语言适配指南

> **适用版本**：4.4.0 及之后版本（面板配置：`index.json` + `panel_json`，多语言字段：`name`）。

## 1. 概述

面板文案分为两类，取值来源不同，需要分别适配：

| 适配内容 | 适配方式 | 说明 |
|---------|---------|---------|
| 面板功能项文案（Tab 标题、二级标题、列表项名称、轻美妆单项） | JSON 中的 `name` 多语言表 + `TEResConfig.setDisPlayNameKey()` | 语言 key 由业务显式指定 |
| 面板固定 UI 文案（`美妆` / `滤镜` / `重置` 等按钮） | 继承 `TEPanelLocalizations` + 自定义 Delegate | 插件内置 **en** / **zh**，其他语言需自行扩展 |

> 两部分相互独立，需同时完成才能实现完整的多语言效果，且**均无需修改插件源码**。

---

## 2. 架构与取值流程

```
                    ┌──────────────────────────────┐
面板入口 index.json →│  defaultLanguage: "zh"       │
                    └──────────────┬───────────────┘
                                   │ 面板数据加载时回填
                                   ▼
                    TEResConfig.defaultDisPlayNameKey
                                   │
            业务调用 setDisPlayNameKey("en")  ──优先级更高──┐
                                   │                      │
                                   ▼                      ▼
                         TEPanelDisplay.getDisplayName(context, uiProperty)
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
        节点有 name 表                 节点无 name 表
        取 name[key]，缺 key 返回 ""    TEPanelLocalizations.of(context)
                                        （按 Locale 取内置 en/zh）
```

要点：

1. 语言 key 的优先级为 **`setDisPlayNameKey()` > `index.json` 的 `defaultLanguage`**。
2. 取不到对应 key 时返回**空字符串**，不做跨语言兜底。这是刻意设计，便于联调期暴露漏配的语言。
3. 文案在 `build` 时实时读取配置，切换语言无需重新解析 JSON。
4. `TEPanelLocalizations.of(context)` 在未注册自定义 Delegate 时会按 `Localizations.localeOf(context)` 兜底查找内置实现，因此内置 en/zh 无需手动注册也能工作。

---

## 3. 面板资源目录约定

目录名在代码中固定，不可重命名：

```
assets/beauty_panel/
├── index.json          ← 面板入口：定义有哪些 Tab、每个 Tab 用哪些配置、默认语言
├── panel_json/         ← 各 Tab 的功能项配置
│   ├── beauty.json
│   ├── lut.json
│   ├── beauty_makeup.json
│   └── ...
└── panel_icon/         ← 图标资源
```

---

## 4. `index.json`：默认语言与 Tab 标题

```json
{
    "defaultLanguage": "zh",
    "data": [
        {
            "name": { "zh": "美颜", "en": "Beauty", "ja": "美顔" },
            "config": ["beauty.json", "beauty_image.json", "shape.json"]
        },
        {
            "name": { "zh": "美妆", "en": "Makeup", "ja": "メイク" },
            "config": ["beauty_makeup.json"]
        },
        {
            "name": { "zh": "滤镜", "en": "Lut", "ja": "フィルター" },
            "config": ["lut.json"]
        }
    ]
}
```

| 字段 | 说明 |
|------|------|
| `defaultLanguage` | 默认语言 key，必须存在于各节点 `name` 中。面板数据加载时自动回填到 `TEResConfig.defaultDisPlayNameKey` |
| `data[].name` | Tab 标题的多语言表 |
| `data[].config` | 组成该 Tab 的 panel_json 文件名（仅文件名，不含路径），多个文件按顺序合并展示到同一 Tab |

> `defaultLanguage` 只在面板数据加载时回填，因此需要按运行时语言切换面板文案时，应显式调用 `setDisPlayNameKey()`。

---

## 5. `panel_json/`：各层级节点的 `name`

任意层级的节点都支持 `name`，包括二级标题、列表项：

```json
{
    "name": { "zh": "美颜", "en": "Beauty", "ja": "美顔" },
    "uiCategory": "BEAUTY",
    "propertyList": [
        {
            "name": { "zh": "美白", "en": "Brighten", "ja": "美白" },
            "icon": "panel_icon/beauty/beauty_whiten.png",
            "sdkParam": {
                "effectName": "beauty.lutFoundationAlpha0",
                "effectValue": 40
            }
        },
        {
            "name": { "zh": "无", "en": "None", "ja": "なし" },
            "icon": "panel_icon/beauty/none.png"
        }
    ]
}
```

> `name` 只负责展示文案。`icon`、`sdkParam`、`resourceUri`、`uiCategory` 等功能字段与语言无关，所有语言共用同一份配置。

---

## 6. 轻美妆单项的 `itemDisplayMap`

轻美妆下钻后的单项（口红 / 腮红 / 眼影 / 滤镜等）文案来自 `itemDisplayMap` 每项的 `name`，结构与节点 `name` 一致：

```json
{
    "name": { "zh": "轻美妆", "en": "Light Makeup" },
    "uiCategory": "LIGHT_MAKEUP",
    "itemDisplayMap": {
        "beauty.faceFeatureLipsLut": {
            "name": { "zh": "口红", "en": "Lipstick", "ja": "リップ" },
            "icon": "panel_icon/makeup/lips.png"
        },
        "lut": {
            "name": { "zh": "滤镜", "en": "Lut", "ja": "フィルター" },
            "icon": "panel_icon/makeup/lut.png"
        }
    }
}
```

- `itemDisplayMap` 的 key 为 `effectName`，value 为该单项的多语言名称与图标。
- 未配置 `itemDisplayMap` 时轻美妆退化为只能调节整套强度（不下钻），不会报错。

---

## 7. 注册面板并指定语言

```dart
import 'package:tencent_effect_flutter/uikit/config/te_effect_plan.dart';
import 'package:tencent_effect_flutter/uikit/config/te_res_config.dart';

void initPanelViewConfig() {
  // 入口文件 + License 套餐（Tab 数量、顺序、分类全部由 index.json 描述）
  TEResConfig.getConfig().setPanelViewResAndEffectPlanName(
    'assets/beauty_panel/index.json',
    EffectPlan.S1_07,
  );

  // 面板文案使用的语言 key，需与 JSON 中 name 的 key 一致
  TEResConfig.getConfig().setDisPlayNameKey('en');
}
```

| 接口 | 说明 |
|------|------|
| `setPanelViewResAndEffectPlanName(indexFilePath, effectPlan)` | 注册面板入口。`indexFilePath` 以 `/` 开头视为本地绝对路径，否则视为 Flutter assets 路径；`effectPlan` 为 License 授权的套餐 |
| `setDisPlayNameKey(String? key)` | 指定文案语言 key，如 `zh` / `en` / `ja`；传 `null` 则使用 `index.json` 的 `defaultLanguage` |

---

## 8. 按设备语言动态选择

插件不会自动把 `Locale` 映射为语言 key（`zh-Hant`、`zh_TW` 等变体如何归并属于业务规则），需业务自行判断后传入：

```dart
String resolveDisplayNameKey(Locale locale) {
  if (locale.languageCode == 'zh') {
    final bool isTraditional = locale.countryCode == 'TW' ||
        locale.countryCode == 'HK' ||
        locale.countryCode == 'MO' ||
        locale.scriptCode == 'Hant';
    return isTraditional ? 'zh_hant' : 'zh';
  }
  switch (locale.languageCode) {
    case 'ja':
      return 'ja';
    default:
      return 'en';
  }
}

void initPanelViewConfig(Locale locale) {
  TEResConfig.getConfig()
    ..setPanelViewResAndEffectPlanName('assets/beauty_panel/index.json', EffectPlan.S1_07)
    ..setDisPlayNameKey(resolveDisplayNameKey(locale));
}
```

对应 JSON 中需同时存在该 key：

```json
{ "zh": "美白", "zh_hant": "美白", "en": "Brighten", "ja": "美白" }
```

---

## 9. 运行时切换语言

文案在 `build` 时实时读取，切换语言只需：

1. 调用 `setDisPlayNameKey(newKey)`；
2. 触发宿主重建（`setState` 或 `MaterialApp` 更换 `locale`）。

注意：面板内部已缓存的标题（如下钻态标题）在重建前不会刷新，建议**运行期切换语言时重建面板视图**，保证所有层级文案一致。

---

## 10. 固定 UI 文案适配（Delegate 方式）

适用于 `slider_type_toggle_widget` 的「美妆 / 滤镜」切换标签、`revert_button` 的「重置」按钮等固定文案。

### 10.1 需要实现的接口

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `makeup` | `String` | 美妆 / 单点美妆切换标签 |
| `lut` | `String` | 滤镜切换标签 |
| `revert` | `String` | 重置按钮文案 |
| `getDisplayName(uiProperty)` | `String?` | 基类要求的接口。功能项文案已由 JSON `name` 表提供，返回 `null` 即可 |

### 10.2 创建翻译实现类

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
  String? getDisplayName(TEUIProperty uiProperty) => null;
}
```

### 10.3 创建自定义 Delegate

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

### 10.4 注册到 MaterialApp

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

> **注意**：Flutter 按 `localizationsDelegates` 顺序查找，第一个 `isSupported()` 为 `true` 的 Delegate 生效，因此自定义 Delegate 必须放在 `TEPanelLocalizations.delegate` **之前**。插件内置 `TEPanelLocalizations.delegate` 的 `isSupported` 只认 `en` / `zh`。

---

## 11. 扩展新语言完整流程（以日语为例）

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 在 `index.json` 的每个 Tab `name` 中增加 `ja` | Tab 标题多语言 |
| 2 | 在 `panel_json/*.json` 所有节点 `name` 中增加 `ja` | 二级标题、列表项名称 |
| 3 | 在 `itemDisplayMap` 每项 `name` 中增加 `ja` | 轻美妆下钻单项（若使用轻美妆） |
| 4 | 调用 `setDisPlayNameKey('ja')` | 指定功能项文案语言 |
| 5 | 创建 `TEPanelLocalizationsJa` + `TEPanelLocalizationsJaDelegate` | 固定 UI 文案（美妆 / 滤镜 / 重置） |
| 6 | 在 `MaterialApp` 的 `localizationsDelegates` 中注册，放在内置 Delegate 之前 | 固定 UI 文案生效 |
| 7 | 在 `supportedLocales` 中增加 `Locale.fromSubtags(languageCode: 'ja')` | 系统语言识别 |

`pubspec.yaml` 中只需声明面板资源根目录，**不需要**为每种语言复制目录：

```yaml
flutter:
  assets:
    - assets/beauty_panel/
```

---

## 12. 注意事项

1. **key 必须一致**：`setDisPlayNameKey()` 的取值、`index.json` 的 `defaultLanguage`、各处 `name` 表中的 key 三者必须完全一致（大小写敏感，如 `zh_hant` ≠ `zh_Hant`）。
2. **缺 key 显示空白**：插件不做跨语言兜底，某个节点漏配当前语言会显示为空字符串。批量适配时建议写脚本校验所有 JSON 的 key 集合是否一致。
3. **`index.json` 的 `name` 覆盖 Tab 根节点文案**：面板顶部 Tab 标题以 `index.json` 的 `data[].name` 为准，若与 `panel_json` 根节点 `name` 同时配置，应保持一致。
4. **`defaultLanguage` 依赖加载时机**：该字段在面板数据加载时才回填，切换语言请显式调用 `setDisPlayNameKey`。
5. **两套机制独立**：JSON 的 `name` 表管功能项文案，Delegate 管固定 UI 文案，需同时适配才完整。
6. **运行期切换需重建视图**：下钻标题等文案会被面板状态缓存，建议重建 `TEBeautyPanelView`。
7. **资源只需一份**：所有语言共用同一套 `beauty_panel/` 资源，不要按语言复制目录。

---

## 13. 相关代码索引

| 功能 | 文件 |
|------|------|
| 语言 key 与面板配置 | `lib/uikit/config/te_res_config.dart` |
| 文案取值（key 优先级与空值兜底） | `lib/uikit/utils/te_panel_display.dart` |
| `index.json` 模型（`defaultLanguage` / `name`） | `lib/uikit/model/te_index_file_model.dart` |
| 节点 `name` 反序列化 | `lib/uikit/model/te_ui_property.dart` |
| `index.json` / `panel_json` 加载 | `lib/uikit/provider/index_file_provider.dart` |
| 面板数据装配 | `lib/uikit/producer/te_general_data_producer.dart` |
| 固定 UI 文案基类与内置 en/zh | `lib/uikit/l10n/te_panel_localizations.dart`、`te_panel_localizations_en.dart`、`te_panel_localizations_zh.dart` |
| 轻美妆下钻单项 | `lib/uikit/utils/te_light_makeup_item_builder.dart` |
