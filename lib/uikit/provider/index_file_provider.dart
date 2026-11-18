import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/te_effect_plan.dart';
import '../model/te_index_file_model.dart';
import '../model/te_ui_property.dart';

/// 用于加载并解析美颜面板的入口文件 `index.json` 及其引用的 panel_json 配置。
///
/// 对应 Android 端 `com.tencent.effect.beautykit.provider.IndexFileProvider`。
///
/// 目录约定（名称在代码中固定，不可重命名）：
/// ```
/// beauty_panel/
/// ├── index.json        ← 定义面板包含哪些 Tab
/// ├── panel_json/       ← 定义每个 Tab 内的功能项
/// └── panel_icon/       ← 图标资源
/// ```
class IndexFileProvider {
  static const String _tag = 'IndexFileProvider';

  /// index.json 所在目录下用于存放子面板 json 的相对目录名。
  static const String panelJsonDir = 'panel_json/';

  /// 入口文件名，用于从完整路径推导父目录。
  static const String indexJsonFileName = 'index.json';

  /// index.json 的路径。以 `/` 开头视为本地绝对路径，否则视为 Flutter assets 相对路径。
  final String indexJsonFilePath;

  /// 当前使用的套餐，用于 SHAPESET 分发与分类裁剪。
  final EffectPlan effectPlan;

  IndexFileProvider({
    required this.indexJsonFilePath,
    required this.effectPlan,
  });

  /// 加载并解析 index.json。
  ///
  /// 解析失败（文件不存在、内容为空、json 语法错误）时返回 null 并输出错误日志。
  Future<TEIndexFileModel?> loadIndexJson() async {
    if (indexJsonFilePath.isEmpty) {
      debugPrint('$_tag: loadIndexJson failed, indexJsonFilePath is empty.');
      return null;
    }
    final String? content = await _readFileContent(indexJsonFilePath);
    if (content == null || content.trim().isEmpty) {
      debugPrint('$_tag: loadIndexJson failed, file is empty. path=$indexJsonFilePath');
      return null;
    }
    try {
      final dynamic decoded = json.decode(content.trim());
      if (decoded is! Map<String, dynamic>) {
        debugPrint('$_tag: loadIndexJson failed, root is not a json object. path=$indexJsonFilePath');
        return null;
      }
      return TEIndexFileModel.fromJson(decoded);
    } catch (e) {
      debugPrint('$_tag: loadIndexJson json syntax error. path=$indexJsonFilePath, error=$e');
      return null;
    }
  }

  /// 按 [TEIndexItem.config] 加载并合并出一个可展示的 [TEUIProperty]（即一个 Tab）。
  ///
  /// 主要步骤：
  /// 1. 依次读取 `item.config` 中每个 json 文件；
  /// 2. 若为 [UICategory.SHAPESET]，则根据当前套餐展开 `dataList` 中匹配的子配置；
  /// 3. 将上述结果按顺序合并（详见 [_mergeUIProperties]）；
  /// 4. 最后交给 [EffectPlanFilter.filter] 做套餐相关裁剪。
  ///
  /// 若无有效数据返回 null（该 Tab 不展示）。
  Future<TEUIProperty?> loadUIPropertyFromItem(TEIndexItem item) async {
    final List<String>? configList = item.config;
    if (configList == null || configList.isEmpty) {
      debugPrint('$_tag: loadUIPropertyFromItem skipped, item.config is empty.');
      return null;
    }
    final String parentPath = _panelJsonParentPath();
    final List<TEUIProperty> resultList = [];

    for (final String jsonPath in configList) {
      TEUIProperty? property = await _readAndParseUIProperty(parentPath, jsonPath);
      if (property == null) {
        continue;
      }
      if (property.uiCategory == UICategory.SHAPESET) {
        property = await _expandShapeSet(parentPath, property);
        if (property == null) {
          continue;
        }
      }
      // index.json 中的 name 会覆盖 panel_json 根节点的 name
      property.name = item.name;
      resultList.add(property);
    }

    if (resultList.isEmpty) {
      return null;
    }
    final TEUIProperty merged = _mergeUIProperties(resultList);
    return effectPlan.filter(merged);
  }

  // ===========================================================================
  // 私有辅助方法
  // ===========================================================================

  /// 根据路径类型读取文件内容。
  ///
  /// 以 [Platform.pathSeparator] 或 `/` 开头视为本地绝对路径，其余视为 assets 相对路径。
  Future<String?> _readFileContent(String filePath) async {
    if (filePath.isEmpty) {
      return null;
    }
    try {
      if (_isAbsolutePath(filePath)) {
        final File file = File(filePath);
        if (!await file.exists()) {
          debugPrint('$_tag: file not exists. path=$filePath');
          return null;
        }
        return await file.readAsString();
      }
      return await rootBundle.loadString(filePath);
    } catch (e) {
      debugPrint('$_tag: read file failed. path=$filePath, error=$e');
      return null;
    }
  }

  static bool _isAbsolutePath(String filePath) {
    return filePath.startsWith('/') || filePath.startsWith(Platform.pathSeparator);
  }

  /// 得到 panel_json 所在的父目录（含结尾 `/`）。
  ///
  /// 例如 index.json 路径为 `assets/beauty_panel/index.json`，
  /// 返回 `assets/beauty_panel/panel_json/`。
  ///
  /// 注意：这里用"仅裁掉结尾的文件名"的方式推导，避免路径中间恰好包含
  /// `index.json` 子串时被误替换（Android 端使用全局 replace，存在该隐患）。
  String _panelJsonParentPath() {
    String parentDir = '';
    if (indexJsonFilePath.endsWith(indexJsonFileName)) {
      parentDir = indexJsonFilePath.substring(
          0, indexJsonFilePath.length - indexJsonFileName.length);
    } else {
      final int slashIndex = indexJsonFilePath.lastIndexOf('/');
      if (slashIndex >= 0) {
        parentDir = indexJsonFilePath.substring(0, slashIndex + 1);
      }
    }
    return '$parentDir$panelJsonDir';
  }

  /// 读取并解析单个 panel_json 文件。
  ///
  /// [parentPath] 为 panel_json 父目录（含结尾 `/`），[jsonPath] 为文件名。
  /// 文件为空或 json 非法时返回 null（该文件被静默跳过，与 Android 端一致）。
  Future<TEUIProperty?> _readAndParseUIProperty(String parentPath, String jsonPath) async {
    final String fileName = jsonPath.trim();
    if (fileName.isEmpty) {
      return null;
    }
    final String fullPath = '$parentPath$fileName';
    final String? content = await _readFileContent(fullPath);
    if (content == null || content.trim().isEmpty) {
      debugPrint('$_tag: panel json is empty. path=$fullPath');
      return null;
    }
    try {
      final dynamic decoded = json.decode(content.trim());
      if (decoded is! Map<String, dynamic>) {
        debugPrint('$_tag: panel json root is not a json object. path=$fullPath');
        return null;
      }
      return TEUIProperty.fromJson(decoded);
    } catch (e) {
      debugPrint('$_tag: panel json syntax error. path=$fullPath, error=$e');
      return null;
    }
  }

  /// 展开 SHAPESET：从 `dataList` 中挑选与当前套餐匹配的项，读取对应的 json 返回。
  ///
  /// 匹配至首条 `effectPlanSet` 包含当前套餐名的记录后即加载对应文件，
  /// `shape.json` 自身被替换掉。若无任何记录命中，返回 null（美型部分为空）。
  Future<TEUIProperty?> _expandShapeSet(String parentPath, TEUIProperty shapeSetProperty) async {
    final List<TEDataSetItem>? dataList = shapeSetProperty.dataList;
    if (dataList == null || dataList.isEmpty) {
      debugPrint('$_tag: SHAPESET has no dataList, skipped.');
      return null;
    }
    final String currentPlanName = effectPlan.planName;
    for (final TEDataSetItem dataSetItem in dataList) {
      final List<String>? planSet = dataSetItem.effectPlanSet;
      final String? config = dataSetItem.config;
      if (planSet == null || config == null || config.isEmpty) {
        continue;
      }
      if (!planSet.contains(currentPlanName)) {
        continue;
      }
      final TEUIProperty? property = await _readAndParseUIProperty(parentPath, config);
      if (property != null) {
        return property;
      }
    }
    debugPrint('$_tag: no effectPlanSet matched plan=$currentPlanName, SHAPESET expanded to null.');
    return null;
  }

  /// 将多个 panel_json 的内容合并为一个 Tab。
  ///
  /// 合并规则（与 Android 端保持一致）：
  /// - 以第一个文件的根节点作为基础容器，它独占决定该 Tab 的 uiCategory / name /
  ///   downloadPath / hasSubTitle / verticalLayout；后续文件的根节点属性全部丢弃，
  ///   只贡献其 propertyList；
  /// - 若当前套餐为 [EffectPlan.A1_00] 且子项为 [UICategory.BEAUTY_IMAGE]，则跳过
  ///   （A1_00 套餐无画质调整）；
  /// - 被合并文件 propertyList 的第 0 项是"关闭 / 无"占位项，会被移除后再追加，
  ///   保证合并后整个 Tab 只保留一个占位项。
  TEUIProperty _mergeUIProperties(List<TEUIProperty> resultList) {
    if (resultList.length == 1) {
      return resultList[0];
    }
    final TEUIProperty base = resultList[0];
    for (int i = 1; i < resultList.length; i++) {
      final TEUIProperty item = resultList[i];
      // A1_00 套餐没有画质调整，其他套餐都有
      if (effectPlan == EffectPlan.A1_00 && item.uiCategory == UICategory.BEAUTY_IMAGE) {
        continue;
      }
      final List<TEUIProperty>? children = item.propertyList;
      if (children == null || children.isEmpty) {
        continue;
      }
      base.propertyList ??= [];
      // 去掉子面板自带的占位项后再合并
      children.removeAt(0);
      base.propertyList!.addAll(children);
    }
    return base;
  }
}
