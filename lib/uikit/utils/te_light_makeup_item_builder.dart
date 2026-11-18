import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constant/te_constant.dart';
import '../manager/te_res_path_manager.dart';
import '../model/te_ui_property.dart';

/// 轻美妆下钻态单项列表构造器。
///
/// 对应 Android 端 `com.tencent.effect.beautykit.utils.provider.LightMakeupItemBuilder`。
///
/// 在用户二次点击某个已选中的轻美妆套装时，根据：
/// 1. 「轻美妆」类目节点的 [TEUIProperty.itemDisplayMap]（单项的多语言名称、图标）；
/// 2. 该套装资源目录下的 `makeup.json`（确定套装实际配置了哪些单项）；
///
/// 构造出一组 [UICategory.LIGHT_MAKEUP_ITEM] 子项。排序按 `itemDisplayMap` 的声明顺序，
/// `makeup.json` 中出现但 `itemDisplayMap` 未配置的 effectName 一律忽略
/// （避免未配置的项以无意义文案出现在 UI 上）。
class TELightMakeupItemBuilder {
  TELightMakeupItemBuilder._();

  static const String _tag = 'TELightMakeupItemBuilder';

  static const String _makeupJsonFileName = 'makeup.json';

  /// 为给定的轻美妆套装构造下钻态单项列表。
  ///
  /// 返回 null 或空列表表示该套装不可下钻（未配置 `itemDisplayMap`、资源未就绪、
  /// `makeup.json` 缺失或其中没有任何"已配置"的单项）。
  static Future<List<TEUIProperty>?> buildItemList(TEUIProperty? lightMakeupProperty) async {
    if (lightMakeupProperty == null || lightMakeupProperty.sdkParam == null) {
      return null;
    }
    final TEUIProperty? rootProperty = _findRootLightMakeupProperty(lightMakeupProperty);
    final Map<String, TELightMakeupItemDisplay>? displayMap = rootProperty?.itemDisplayMap;
    if (displayMap == null || displayMap.isEmpty) {
      debugPrint('$_tag: itemDisplayMap is missing, light makeup drill-down disabled');
      return null;
    }
    final String? resourcePath = lightMakeupProperty.sdkParam!.resourcePath;
    if (resourcePath == null || resourcePath.isEmpty) {
      debugPrint('$_tag: resourcePath is empty, cannot locate makeup.json');
      return null;
    }

    final Set<String> configuredEffectNames = await _parseMakeupJson(resourcePath);
    if (configuredEffectNames.isEmpty) {
      debugPrint('$_tag: makeup.json is empty or not found under $resourcePath');
      return null;
    }

    final List<TEUIProperty> items = <TEUIProperty>[];
    // 按 itemDisplayMap 声明顺序遍历，只保留 makeup.json 中实际配置（alpha>0 且 resourcePath 非空）的项
    displayMap.forEach((String effectName, TELightMakeupItemDisplay display) {
      if (!configuredEffectNames.contains(effectName)) {
        return;
      }
      items.add(_createLightMakeupItem(lightMakeupProperty, effectName, display));
    });
    return items;
  }

  /// 该节点是否为轻美妆下钻态的单项（运行时构造的虚拟节点）。
  static bool isLightMakeupItem(TEUIProperty? property) {
    return property != null && property.uiCategory == UICategory.LIGHT_MAKEUP_ITEM;
  }

  /// 该列表是否为轻美妆下钻态的单项列表。
  ///
  /// 轻美妆套装的 `propertyList` 正常为 null，仅在「选中后再次点击」时被临时挂载为
  /// 单项列表；此判据用于在返回上一级时识别并清理这份临时数据。
  static bool isLightMakeupItemList(List<TEUIProperty>? propertyList) {
    return propertyList != null && propertyList.isNotEmpty && isLightMakeupItem(propertyList.first);
  }

  /// 构造一个单项（口红/腮红/眼影/滤镜等）。
  static TEUIProperty _createLightMakeupItem(
      TEUIProperty parent, String effectName, TELightMakeupItemDisplay display) {
    final TEUIProperty item = TEUIProperty(
      null,
      null,
      display.icon,
      null,
      null,
      null,
      null,
      UIState.INIT,
    );
    item.uiCategory = UICategory.LIGHT_MAKEUP_ITEM;
    item.name = display.name;
    item.parentUIProperty = parent;
    // sdkParam.effectName 用作父套装 extraInfo 读写时的 key，不下发给 SDK；
    // effectValue 保存父套装中该项强度的快照，供通用滑竿逻辑直接读取。
    item.sdkParam = TESDKParam(
      effectName: effectName,
      effectValue: _resolveItemStrength(parent, effectName),
    );
    return item;
  }

  /// 轻美妆单项强度读取范式（供下钻构建时写入 item 的 effectValue 快照）：
  /// - lut 项：`extraInfo["lut"]` > `extraInfo["makeupLutStrength"]`（老字段） > 0
  /// - 非 lut 项：`extraInfo[effectName]` > `parent.effectValue`（整体强度）
  ///
  /// 保留对老字段 makeupLutStrength 的回退，是为了兼容外部仅保存老字段并回灌 UI 的场景。
  static int _resolveItemStrength(TEUIProperty parent, String effectName) {
    final TESDKParam? parentParam = parent.sdkParam;
    if (parentParam == null) {
      return 0;
    }
    final Map<String, String>? extraInfo = parentParam.extraInfo;
    if (extraInfo != null) {
      final int? override = int.tryParse(extraInfo[effectName] ?? '');
      if (override != null) {
        return _clampStrength(override);
      }
      if (effectName == TEffectName.EFFECT_LUT) {
        final int? oldLut = int.tryParse(extraInfo[TESDKParam.EXTRA_INFO_KEY_LUT_STRENGTH] ?? '');
        if (oldLut != null) {
          return _clampStrength(oldLut);
        }
        return 0;
      }
    }
    if (effectName == TEffectName.EFFECT_LUT) {
      return 0;
    }
    return _clampStrength(parentParam.effectValue);
  }

  static int _clampStrength(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  /// 读取某套轻美妆目录下的 `makeup.json`，提取出所有"已配置"的 effectName。
  ///
  /// 一项被判定为"已配置"当且仅当：`alpha > 0` 且 `resourcePath` 非空。
  /// 其余项（如 alpha=0 的占位项）表示套装未包含该单项，UI 不下发、不展示。
  static Future<Set<String>> _parseMakeupJson(String resourcePath) async {
    final Set<String> result = <String>{};
    final String configPath = await _resolveMakeupJsonPath(resourcePath);
    if (configPath.isEmpty) {
      return result;
    }
    try {
      final File file = File(configPath);
      if (!await file.exists()) {
        debugPrint('$_tag: makeup.json not found at $configPath');
        return result;
      }
      final dynamic decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return result;
      }
      for (final dynamic element in decoded) {
        if (element is! Map) {
          continue;
        }
        final dynamic effectName = element['effectName'];
        if (effectName is! String || effectName.isEmpty) {
          continue;
        }
        if (!_isItemConfigured(element)) {
          continue;
        }
        result.add(effectName);
      }
    } catch (e) {
      debugPrint('$_tag: parse makeup.json failed. path=$configPath, error=$e');
    }
    return result;
  }

  /// 该套装是否配置了此单项：`alpha > 0` 且 `resourcePath` 非空（两个条件须同时满足）。
  ///
  /// 注意：存在 alpha=0 但 resourcePath 非空的真实数据（如 light_danyan 的 eyebrow），
  /// 仅判断 resourcePath 会导致误展示。
  static bool _isItemConfigured(Map<dynamic, dynamic> config) {
    final dynamic alpha = config['alpha'];
    if (alpha is! num || alpha <= 0) {
      return false;
    }
    final dynamic resourcePath = config['resourcePath'];
    return resourcePath is String && resourcePath.isNotEmpty;
  }

  /// 将套装的 resourcePath 解析成 `makeup.json` 的绝对路径。
  ///
  /// resourcePath 有两种来源：
  /// - 本地资源，形如 `MotionRes/light_makeup/light_baixi`（相对 xmagic 资源根目录）；
  /// - http 下载的资源，落盘后同样是上述相对目录 + 资源名；
  /// - 也可能是已转换过的绝对路径（以分隔符开头）。
  ///
  /// 由于双端资源实际落盘位置不同（Android 为 `xmagic/MotionRes/light_makeup/xxx`，
  /// iOS 为 `xmagic/lightMakeupRes.bundle/xxx`），这里按候选路径逐个探测，
  /// 取第一个真实存在的 `makeup.json`。
  static Future<String> _resolveMakeupJsonPath(String resourcePath) async {
    final List<String> candidates = <String>[];
    if (resourcePath.startsWith(Platform.pathSeparator) || resourcePath.startsWith('/')) {
      candidates.add(_join(resourcePath, _makeupJsonFileName));
    } else {
      final String resPath = await TEResPathManager.getResManager().getResPath();
      candidates.add(_join(_join(resPath, resourcePath), _makeupJsonFileName));

      // 相对路径命中"轻美妆资源目录"标记时，按各端实际的轻美妆目录再探测一次
      const String mark = TEResPathManager.JSON_RES_MARK_LIGHT_MAKEUP;
      if (resourcePath.startsWith(mark)) {
        String remain = resourcePath.substring(mark.length);
        while (remain.startsWith('/') || remain.startsWith(Platform.pathSeparator)) {
          remain = remain.substring(1);
        }
        if (remain.isNotEmpty) {
          final String lightMakeupDir =
              await TEResPathManager.getResManager().getLightMakeupDir();
          candidates.add(_join(_join(lightMakeupDir, remain), _makeupJsonFileName));
        }
      }
    }

    for (final String candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }
    return candidates.isEmpty ? '' : candidates.first;
  }

  /// 拼接路径，自动归一化重复的分隔符，保证跨平台（`/` 与 Windows 的 `\`）可用。
  static String _join(String parent, String child) {
    if (parent.isEmpty) {
      return child;
    }
    final String separator = Platform.pathSeparator;
    String parentPath = parent;
    while (parentPath.length > 1 && (parentPath.endsWith('/') || parentPath.endsWith(separator))) {
      parentPath = parentPath.substring(0, parentPath.length - 1);
    }
    String childPath = child;
    while (childPath.startsWith('/') || childPath.startsWith(separator)) {
      childPath = childPath.substring(1);
    }
    return '$parentPath$separator$childPath';
  }

  /// 向上查找持有 `itemDisplayMap` 的节点（通常是「轻美妆」二级类目节点）。
  static TEUIProperty? _findRootLightMakeupProperty(TEUIProperty? property) {
    TEUIProperty? current = property;
    while (current != null) {
      final Map<String, TELightMakeupItemDisplay>? displayMap = current.itemDisplayMap;
      if (displayMap != null && displayMap.isNotEmpty) {
        return current;
      }
      current = current.parentUIProperty;
    }
    return null;
  }
}
