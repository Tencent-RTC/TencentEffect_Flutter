import '../model/te_ui_property.dart';
import '../utils/te_producer_utils.dart';

/// 腾讯特效套餐。
///
/// 对应 Android 端 `com.tencent.effect.beautykit.config.EffectPlan`。
/// 套餐代表 License 授权的能力范围，面板会依据套餐自动隐藏当前不可用的功能分类，
/// 即使 json 中已完成配置也不会展示。
///
/// 说明：Android 端为每个枚举常量重写 `applyPlanRule` 方法，其中存在 4 组完全重复的
/// 实现（A1_01≡A1_04、A1_02≡A1_03、S1_01≡S1_02、S1_03≡S1_04）。此处改为
/// 数据化的规则表 [_planRules]，行为与 Android 端逐条等价，且便于后续新增套餐。
enum EffectPlan {
  A1_00,
  A1_01,
  A1_02,
  A1_03,
  A1_04,
  A1_05,
  A1_06,
  S1_00,
  S1_01,
  S1_02,
  S1_03,
  S1_04,
  S1_07,
}

/// 单个套餐的裁剪规则。
class _PlanRule {
  /// 匹配模式。
  ///
  /// true —— 黑名单：默认保留全部分类，仅丢弃 [categories] 中列举的；
  /// false —— 白名单：默认丢弃全部分类，仅保留 [categories] 中列举的。
  final bool isBlacklist;

  /// 配合 [isBlacklist] 使用的分类集合。
  final Set<UICategory> categories;

  /// 对指定分类，需要裁掉的一级子分类。
  ///
  /// 例如 `{MOTION: {SEGMENTATION}}` 表示保留特效分类，但裁掉其中的虚拟背景子项。
  final Map<UICategory, Set<UICategory>> removeChildren;

  /// 需要额外裁掉"染发 LUT 所属分组"的分类。
  final Set<UICategory> removeHairColorGroupIn;

  const _PlanRule({
    required this.isBlacklist,
    this.categories = const {},
    this.removeChildren = const {},
    this.removeHairColorGroupIn = const {},
  });
}

/// 无论何种套餐都直接放行的分类（模板 / 美颜 / 滤镜）。
///
/// 在 [EffectPlanFilter.filter] 入口处前置放行，因此各套餐规则无需重复处理这三项。
const Set<UICategory> kAlwaysKeepCategories = {
  UICategory.BEAUTY_TEMPLATE,
  UICategory.BEAUTY,
  UICategory.LUT,
};

/// 过滤后需要统一改写为 [UICategory.BEAUTY] 的分类。
const Set<UICategory> _kRewriteToBeautyCategories = {
  UICategory.BEAUTY_IMAGE,
  UICategory.BEAUTY_SHAPE,
  UICategory.BEAUTY_MAKEUP,
};

/// 各套餐的裁剪规则表。
const Map<EffectPlan, _PlanRule> _planRules = {
  /// 仅保留通用三项（模板 / 美颜 / 滤镜），其余全部丢弃。
  EffectPlan.A1_00: _PlanRule(isBlacklist: false),

  /// 保留画质、美型（均改写为 BEAUTY）。
  EffectPlan.A1_01: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE},
  ),

  /// 保留画质、美型 + 特效（子项裁掉整妆、虚拟背景）。
  EffectPlan.A1_02: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE, UICategory.MOTION},
    removeChildren: {
      UICategory.MOTION: {UICategory.MAKEUP, UICategory.SEGMENTATION},
    },
  ),

  /// 同 A1_02。
  EffectPlan.A1_03: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE, UICategory.MOTION},
    removeChildren: {
      UICategory.MOTION: {UICategory.MAKEUP, UICategory.SEGMENTATION},
    },
  ),

  /// 同 A1_01。
  EffectPlan.A1_04: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE},
  ),

  /// 保留画质、美型 + 特效（子项裁掉整妆）。
  EffectPlan.A1_05: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE, UICategory.MOTION},
    removeChildren: {
      UICategory.MOTION: {UICategory.MAKEUP},
    },
  ),

  /// 保留画质、美型 + 特效（子项裁掉虚拟背景）。
  EffectPlan.A1_06: _PlanRule(
    isBlacklist: false,
    categories: {UICategory.BEAUTY_IMAGE, UICategory.BEAUTY_SHAPE, UICategory.MOTION},
    removeChildren: {
      UICategory.MOTION: {UICategory.SEGMENTATION},
    },
  ),

  /// 保留画质、美型 + 美妆（子项裁掉轻美妆，并裁掉染发分组）。
  EffectPlan.S1_00: _PlanRule(
    isBlacklist: false,
    categories: {
      UICategory.BEAUTY_IMAGE,
      UICategory.BEAUTY_SHAPE,
      UICategory.BEAUTY_MAKEUP,
    },
    removeChildren: {
      UICategory.BEAUTY_MAKEUP: {UICategory.LIGHT_MAKEUP},
    },
    removeHairColorGroupIn: {UICategory.BEAUTY_MAKEUP},
  ),

  /// 黑名单：几乎全部保留；丢弃美体；特效子项裁掉虚拟背景。
  EffectPlan.S1_01: _PlanRule(
    isBlacklist: true,
    categories: {UICategory.BODY_BEAUTY},
    removeChildren: {
      UICategory.MOTION: {UICategory.SEGMENTATION},
    },
  ),

  /// 同 S1_01。
  EffectPlan.S1_02: _PlanRule(
    isBlacklist: true,
    categories: {UICategory.BODY_BEAUTY},
    removeChildren: {
      UICategory.MOTION: {UICategory.SEGMENTATION},
    },
  ),

  /// 黑名单：几乎全部保留；仅丢弃美体。
  EffectPlan.S1_03: _PlanRule(
    isBlacklist: true,
    categories: {UICategory.BODY_BEAUTY},
  ),

  /// 同 S1_03。
  EffectPlan.S1_04: _PlanRule(
    isBlacklist: true,
    categories: {UICategory.BODY_BEAUTY},
  ),

  /// 全部保留。
  EffectPlan.S1_07: _PlanRule(isBlacklist: true),
};

extension EffectPlanFilter on EffectPlan {
  /// 套餐名，与 `shape.json` 中 `dataList[].effectPlanSet` 的取值一一对应。
  String get planName => name;

  /// 按本套餐的规则过滤 [property]。
  ///
  /// 处理流程与 Android 端 `EffectPlan#filter` 完全一致：
  /// 1. 入参或其 uiCategory 为空时原样返回；
  /// 2. uiCategory 命中 [kAlwaysKeepCategories] 时直接放行（不裁剪、不改写、不展平）；
  /// 3. 按规则表判定保留 / 丢弃，并裁掉需要移除的子分类；
  /// 4. 画质 / 美型 / 美妆统一改写为 [UICategory.BEAUTY]；
  /// 5. 最后做一次"孤儿子标题分组"展平。
  ///
  /// 返回 null 表示该分类在当前套餐下应被丢弃。
  TEUIProperty? filter(TEUIProperty? property) {
    if (property == null || property.uiCategory == null) {
      return property;
    }
    final UICategory category = property.uiCategory!;
    // 通用放行：模板 / 美颜 / 滤镜（所有套餐一视同仁）
    if (kAlwaysKeepCategories.contains(category)) {
      return property;
    }

    final _PlanRule rule = _planRules[this] ?? const _PlanRule(isBlacklist: true);
    final bool hit = rule.categories.contains(category);
    final bool keep = rule.isBlacklist ? !hit : hit;
    if (!keep) {
      return null;
    }

    final Set<UICategory>? childrenToRemove = rule.removeChildren[category];
    if (childrenToRemove != null) {
      TEProducerUtils.removeChildrenByCategory(property, childrenToRemove);
    }
    if (rule.removeHairColorGroupIn.contains(category)) {
      TEProducerUtils.removeHairColorGroup(property);
    }

    if (_kRewriteToBeautyCategories.contains(category)) {
      property.uiCategory = UICategory.BEAUTY;
    }

    _flattenSingleSubTitleGroup(property);
    return property;
  }

  /// 展平"孤儿子标题分组"。
  ///
  /// 当节点原本按子标题分组组织成两级结构（例如 美妆 → [眼妆分组 → 眼影/眼线/...]），
  /// 若套餐裁剪后只剩下唯一一个子标题分组，这个分组标题就成了多余的空壳，
  /// 会在 UI 上多出一行无意义的二级 Tab。此时把它的孩子提升上来，压平成一级。
  ///
  /// ```
  /// before: parent(hasSubTitle) → [group] → [A, B, C]
  /// after : parent(hasSubTitle) → [A, B, C]
  /// ```
  static void _flattenSingleSubTitleGroup(TEUIProperty? parent) {
    if (parent == null || !parent.hasSubTitle) {
      return;
    }
    final List<TEUIProperty>? children = parent.propertyList;
    if (children == null || children.length != 1) {
      return;
    }
    final List<TEUIProperty>? grandChildren = children[0].propertyList;
    if (grandChildren == null || grandChildren.isEmpty) {
      return;
    }
    final List<TEUIProperty> promoted = List<TEUIProperty>.from(grandChildren);
    children.clear();
    children.addAll(promoted);
    parent.hasSubTitle = false;
  }
}

/// [EffectPlan] 的解析工具。
class EffectPlanParser {
  EffectPlanParser._();

  /// 未显式设置套餐时使用的默认套餐（全功能保留）。
  static const EffectPlan defaultPlan = EffectPlan.S1_07;

  /// 按套餐名解析枚举，未匹配时返回 null。
  static EffectPlan? fromName(String? planName) {
    if (planName == null) {
      return null;
    }
    final String target = planName.trim();
    if (target.isEmpty) {
      return null;
    }
    for (final EffectPlan plan in EffectPlan.values) {
      if (plan.name == target) {
        return plan;
      }
    }
    return null;
  }
}
