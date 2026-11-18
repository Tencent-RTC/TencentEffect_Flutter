/// 美颜面板入口文件 `index.json` 的数据模型。
///
/// 对应 Android 端 `com.tencent.effect.beautykit.model.TEIndexFileModel`。
///
/// 结构示例：
/// ```json
/// {
///   "defaultLanguage": "zh",
///   "data": [
///     {
///       "name": { "zh": "美颜", "en": "Beauty", "ja": "美顔" },
///       "config": [ "beauty.json", "beauty_image.json", "shape.json" ]
///     }
///   ]
/// }
/// ```
class TEIndexFileModel {
  /// 面板文案的默认语言，取值必须为各节点 `name` 中已声明的 key，例如 `zh` / `en` / `ja`。
  String? defaultLanguage;

  /// Tab 列表，数组顺序即为 Tab 自左至右的展示顺序。
  List<TEIndexItem>? data;

  TEIndexFileModel({this.defaultLanguage, this.data});

  TEIndexFileModel.fromJson(Map<String, dynamic> json) {
    defaultLanguage = json['defaultLanguage']?.toString();
    final rawData = json['data'];
    if (rawData is List) {
      final List<TEIndexItem> items = [];
      for (final element in rawData) {
        if (element is Map<String, dynamic>) {
          items.add(TEIndexItem.fromJson(element));
        }
      }
      data = items;
    }
  }
}

/// `index.json` 中 `data` 数组的单个元素，对应面板上的一个 Tab。
class TEIndexItem {
  /// Tab 标题的多语言文案，key 为语言代码。该取值会覆盖 panel_json 文件根节点的 `name`。
  Map<String, String>? name;

  /// 构成该 Tab 的 panel_json 文件名列表（仅文件名，不含路径）。
  ///
  /// 配置多个文件时会按顺序合并展示到同一个 Tab 内。
  List<String>? config;

  TEIndexItem({this.name, this.config});

  TEIndexItem.fromJson(Map<String, dynamic> json) {
    name = parseNameMap(json['name']);
    final rawConfig = json['config'];
    if (rawConfig is List) {
      config = rawConfig
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }
  }

  /// 将 json 中的多语言 name 节点解析为 `Map<String, String>`。
  ///
  /// 兼容 value 为非字符串的情况（统一 toString），value 为 null 时跳过该 key。
  static Map<String, String>? parseNameMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final Map<String, String> result = {};
    raw.forEach((key, value) {
      if (key != null && value != null) {
        result[key.toString()] = value.toString();
      }
    });
    return result.isEmpty ? null : result;
  }
}

/// `shape.json` 中 `dataList` 数组的元素：按套餐分发具体的配置文件。
///
/// 对应 Android 端 `TEIndexFileModel.DataSetItem`。
class TEDataSetItem {
  /// 命中该条记录的套餐名列表，与 [EffectPlan] 的枚举名一一对应。
  List<String>? effectPlanSet;

  /// 命中该套餐时实际加载的配置文件名。
  String? config;

  TEDataSetItem({this.effectPlanSet, this.config});

  TEDataSetItem.fromJson(Map<String, dynamic> json) {
    final rawSet = json['effectPlanSet'];
    if (rawSet is List) {
      effectPlanSet = rawSet
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    }
    config = json['config']?.toString();
  }

  static List<TEDataSetItem>? decodeList(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    final List<TEDataSetItem> result = [];
    for (final element in raw) {
      if (element is Map<String, dynamic>) {
        result.add(TEDataSetItem.fromJson(element));
      }
    }
    return result;
  }
}
