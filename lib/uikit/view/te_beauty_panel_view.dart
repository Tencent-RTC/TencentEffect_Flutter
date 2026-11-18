import 'package:flutter/material.dart';
import '../../uikit/view/widget/revert_button.dart';
import '../../uikit/view/widget/compare_button.dart';
import '../../uikit/view/widget/te_download_progress_dialog.dart';
import '../config/te_res_config.dart';
import '../download/te_material_checker.dart';
import '../model/te_ui_property.dart';
import '../producer/te_general_data_producer.dart';
import '../producer/te_panel_data_producer.dart';
import '../utils/te_light_makeup_item_builder.dart';
import '../utils/te_panel_display.dart';
import '../utils/te_producer_utils.dart';
import 'te_beauty_panel_view_callback.dart';
import 'te_beauty_panel_view_controller.dart';
import 'widget/beauty_panel_slider.dart';
import 'model/te_slider_view_model.dart';

/// 面板各区域的尺寸，取值与 Android 端 `te_beauty_panel_view_layout.xml` 一一对应
/// （Android 的 dp 与 Flutter 的逻辑像素等价，可直接沿用同一数值）。
class _PanelMetrics {
  _PanelMetrics._();

  /// 顶部 seekbar 区高度。对应 `te_panel_view_custom_view_seekbar_layout` 的 35dp。
  static const double seekBarAreaHeight = 35;

  /// 标题区高度。对应 `te_panel_view_title_content`（FrameLayout）的 40dp。
  ///
  /// 一级标题栏与下钻标题栏在 Android 中是叠放在这同一个 FrameLayout 内的两个兄弟
  /// 布局（互相切换可见性），因此两者高度相同。
  static const double titleBarHeight = 40;

  /// 标题区底部分割线高度。对应 `te_panel_view_title_divider` 的 1dp。
  ///
  /// Android 中该分割线是标题区 FrameLayout 的子 View 且 `layout_gravity="bottom"`，
  /// 即叠在标题区内部贴底，**不额外占用布局高度**。
  static const double titleDividerHeight = 1;

  /// 二级标题栏高度。对应 `te_panel_view_sub_title_tab_layout` 的 32dp。
  static const double subTabBarHeight = 32;

  /// 列表区高度（横向线性布局）。对应 `TEDetailPanel.recycleViewHeightLinear` 的 100dp。
  static const double listAreaHeightLinear = 100;

  /// 列表区高度（纵向网格布局）。对应 `TEDetailPanel.recycleViewHeightGrid` 的 126dp。
  static const double listAreaHeightGrid = 126;

  /// 一级标题栏 Tab 文字大小。对应 `mainTabLayout.setData(propertyList, 15)`。
  static const double mainTabTextSize = 15;

  /// 二级标题栏 Tab 文字大小。对应 `subTabLayout.setData(property.propertyList, 13)`。
  static const double subTabTextSize = 13;

  /// Tab 内边距（每侧）。对应 Material `Widget.Design.TabLayout` 默认的
  /// `tabPaddingStart` / `tabPaddingEnd` = 12dp（工程未自定义 TabLayout style）。
  static const double tabPaddingHorizontal = 12;

  /// Tab 文字左右外边距，单位为**物理像素**。
  ///
  /// 对应 `TEBeautyTabLayout.setData` 中 `layoutParams.leftMargin = 5`：Java 代码里
  /// 直接给 margin 赋值的单位是 px 而非 dp，因此在 Flutter 侧需要按
  /// `devicePixelRatio` 换算成逻辑像素才能得到一致的视觉宽度。
  /// 详见 [TEPanelViewState._tabTextMargin]。
  static const double tabTextMarginPx = 5;

  /// 下钻标题文字大小。对应 `te_panel_view_title_text` 的 16sp。
  static const double drillDownTitleTextSize = 16;

  /// 返回按钮控件尺寸与内边距。对应 `te_panel_view_back_btn` 的 25dp + padding 2dp
  /// （即图标实际绘制区为 21dp）。
  static const double backBtnSize = 25;
  static const double backBtnPadding = 2;
  static const double backBtnMarginLeft = 15;

  /// "还原"按钮区尺寸。对应 `te_panel_view_top_right_layout` 的
  /// `layout_width=75dp` + `layout_marginRight=10dp`（固定宽度，不随文案变化）。
  ///
  /// 一级标题栏的可用宽度 = 面板宽度 - (revertLayoutWidth + revertLayoutMarginRight)，
  /// 直接决定 Tab 居中时的中心位置，因此必须与 Android 保持一致。
  /// 按钮内部各元素的尺寸见 `RevertButton`。
  static const double revertLayoutWidth = 75;
  static const double revertLayoutMarginRight = 10;

  /// 标题区分割线颜色。对应 `TEUIConfig.panelDividerColor` 默认值 0x19FFFFFF。
  static const Color dividerColor = Color(0x19FFFFFF);

  /// 标题栏 Tab 的未选中 / 选中文字颜色。
  /// 对应 `TEUIConfig.textColor` = 0x99FFFFFF、`textCheckedColor` = 0xFFFFFFFF。
  static const Color tabTextColor = Color(0x99FFFFFF);
  static const Color tabTextCheckedColor = Color(0xFFFFFFFF);

  /// 列表项图标尺寸。对应列表项布局中 `te_panel_view_item_layout_icon` 的 48dp。
  static const double itemIconSize = 48;

  /// 轻美妆"可下钻编辑"角标的背景色、圆角与内边距。
  /// 对应 `te_beauty_panel_view_edit_icon_bg.xml`（`#44000000` + 5dp 圆角）
  /// 与编辑图标的 11dp padding（48dp 内 26dp 图标）。
  static const Color editBadgeColor = Color(0x44000000);
  static const double editBadgeRadius = 5;
  static const double editBadgePadding = 11;
}

class TEBeautyPanelView extends StatefulWidget {
  final TEBeautyPanelController? controller;
  final TEBeautyPanelViewCallBack? _beautyPanelViewCallBack;

  final int onSliderUpdateValueType;
  final TEPanelDataProducer? panelDataProducer;

  const TEBeautyPanelView(
    this._beautyPanelViewCallBack,
    this.panelDataProducer,
    this.controller, {
    super.key,
    this.onSliderUpdateValueType = 1,
  });

  @override
  State<StatefulWidget> createState() {
    return TEPanelViewState();
  }
}

class TEPanelViewState extends State<TEBeautyPanelView> {
  final ScrollController _scrollController = ScrollController();

  /// 一级 / 二级标题栏的横向滚动控制器，用于把选中的 Tab 滚动到可见区域中间。
  final ScrollController _mainTabScrollController = ScrollController();
  final ScrollController _subTabScrollController = ScrollController();

  /// 指向当前选中 Tab 的 key，配合 [_ensureTabVisible] 定位滚动目标。
  final GlobalKey _mainTabSelectedKey = GlobalKey();
  final GlobalKey _subTabSelectedKey = GlobalKey();

  final List<double> _listViewOffset = [];
  Map<String, double> typeDataListViewOffset = {};
  SliderViewModel? _sliderViewModel;
  String _subTitleName = "";

  TESDKParam? _currentSDKParam;

  bool _isShowSubTitleLayout = false;

  /// Whether to show sub-tab bar (for hasSubTitle items)
  bool _isShowSubTabBar = false;
  List<TEUIProperty>? _subTabItems;
  int _selectedSubTabIndex = 0;

  /// 当前处于下钻态时所展开的那个节点（即 [_currentList] 的父节点）。
  ///
  /// 非 null 表示面板正处在下钻态（展示返回按钮 + 标题）。返回上一级时以它为锚点向上
  /// 回溯，而不是从 `_currentList[0].parentUIProperty` 反推 —— 后者在列表为空或子项
  /// 未回填父链时会拿到错误结果甚至抛异常。
  TEUIProperty? _currentDrillDownProperty;

  List<TEUIProperty>? _currentList;
  List<TEUIProperty>? _panelViewData;

  final List<bool> _selectedList = [true, false];

  /// Whether to use grid layout (for verticalLayout items)
  bool _useGridLayout = false;

  late TEPanelDataProducer _tePanelDataProducer;

  @override
  initState() {
    super.initState();
    if (widget.panelDataProducer != null) {
      _tePanelDataProducer = widget.panelDataProducer!;
    } else {
      _tePanelDataProducer = TEGeneralDataProducer();
      _tePanelDataProducer.setPanelDataList(TEResConfig.getConfig().defaultPanelDataList);
    }
    _getPanelViewData();
    widget.controller?.bind(onCheckPanelViewItem: checkPanelViewItem, getRevertPanelData: getRevertPanelData);
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    _scrollController.dispose();
    _mainTabScrollController.dispose();
    _subTabScrollController.dispose();
    super.dispose();
  }

  void _getPanelViewData({bool forceRefreshData = false}) async {
    var data = await _tePanelDataProducer.getPanelData(forceRefreshData: forceRefreshData);
    if (widget._beautyPanelViewCallBack != null) {
      List<TESDKParam> usedProperties = _tePanelDataProducer.getUsedProperties();
      widget._beautyPanelViewCallBack?.onDefaultEffectList(usedProperties);
    }
    setState(() {
      _panelViewData = data;
      // 面板数据整体刷新即退出下钻态，残留的下钻滚动位置栈必须一并清空
      _currentDrillDownProperty = null;
      _isShowSubTitleLayout = false;
      _listViewOffset.clear();
      _selectedSubTabIndex = 0;
      // 首屏同样按"选中的一级 Tab"级联出二级标题栏与列表：若该 Tab 带二级标题，
      // 它的 propertyList 是二级标题列表而非功能项列表，直接拿来渲染会把二级标题
      // 错误地画成功能项。
      if (data.isNotEmpty) {
        TEUIProperty? mainTab;
        for (final TEUIProperty property in data) {
          if (property.uiState == UIState.CHECKED_AND_IN_USE) {
            mainTab = property;
            break;
          }
        }
        if (mainTab == null) {
          // 没有默认选中项时手动选中第 0 个，否则一级标题栏会缺少高亮态
          mainTab = data[0];
          mainTab.setUiState(UIState.CHECKED_AND_IN_USE);
        }
        _applyMainTabSelection(mainTab);
      } else {
        _isShowSubTabBar = false;
        _subTabItems = null;
        _currentList = null;
      }
      _updateLayoutMode();
    });
    // 对应 Android `TEBeautyTabLayout.setData` 末尾的 setScrollPosition：
    // 数据重建后把选中的 Tab 滚动到可见区域中间
    _ensureTabVisible(_mainTabSelectedKey);
    _ensureTabVisible(_subTabSelectedKey);
  }

  Future<List<TESDKParam>> getRevertPanelData() async {
    List<TESDKParam> result = await _tePanelDataProducer.getRevertData();
    _getPanelViewData();
    _setSliderState(null);
    return result;
  }

  void _updateLayoutMode() {
    if (_currentList != null && _currentList!.isNotEmpty) {
      TEUIProperty? parent = _currentList![0].parentUIProperty;
      _useGridLayout = parent != null
          ? (parent.parentUIProperty != null ? parent.parentUIProperty!.verticalLayout : parent.verticalLayout)
          : false;
    } else {
      _useGridLayout = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _PanelMetrics.seekBarAreaHeight,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: _sliderViewModel != null ? _buildSlider(context) : Container(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: CompareButton(
                  onPressDown: () {
                    widget._beautyPanelViewCallBack?.onCompareBtnPressed(true);
                  },
                  onPressUp: () {
                    widget._beautyPanelViewCallBack?.onCompareBtnPressed(false);
                  },
                ),
              ),
            ],
          ),
        ),
        
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  color: TEResConfig.getConfig().panelBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题区：一级标题栏与下钻标题栏共用同一块固定高度区域（二者互斥展示），
                      // 底部分割线以 Stack 叠在该区域内部贴底，与 Android 的
                      // FrameLayout + layout_gravity="bottom" 一致，不额外占用高度。
                      SizedBox(
                        height: _PanelMetrics.titleBarHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _isShowSubTitleLayout
                                  ? _buildSubTitleLayout()
                                  : _buildMainTitleLayout(context),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: _PanelMetrics.titleDividerHeight,
                                color: _PanelMetrics.dividerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isShowSubTabBar && _subTabItems != null) _buildSubTabBar(context),
                      SizedBox(
                        height: _useGridLayout
                            ? _PanelMetrics.listAreaHeightGrid
                            : _PanelMetrics.listAreaHeightLinear,
                        child: _useGridLayout ? _buildGridView() : _buildListView(),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Container(
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: false,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: buildListViewItem(context, index),
          );
        },
        itemCount: _currentList?.length,
      ),
      margin: const EdgeInsets.only(top: 10),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 0.9,
      ),
      itemBuilder: buildListViewItem,
      itemCount: _currentList?.length,
    );
  }

  Widget _buildSubTabBar(BuildContext context) {
    final List<TEUIProperty> items = _subTabItems ?? const [];
    return SizedBox(
      height: _PanelMetrics.subTabBarHeight,
      child: _buildTabBar(
        context: context,
        items: items,
        fontSize: _PanelMetrics.subTabTextSize,
        controller: _subTabScrollController,
        selectedKey: _subTabSelectedKey,
        isSelectedOf: (index, item) => index == _selectedSubTabIndex,
        onTap: (index, item) {
          setState(() {
            _selectedSubTabIndex = index;
            _currentList = item.propertyList;
            _updateLayoutMode();
          });
          _ensureTabVisible(_subTabSelectedKey);
          _jumpToOffset(0);
          _setSliderState(null);
        },
      ),
    );
  }

  /// 每个 Tab 文字的左右外边距（逻辑像素）。
  ///
  /// Android 端该值以物理像素赋值（`layoutParams.leftMargin = 5`），因此这里按当前
  /// 屏幕密度换算，保证不同 dpi 设备上与 Android 的视觉宽度一致。
  double _tabTextMargin(BuildContext context) {
    final double ratio = MediaQuery.of(context).devicePixelRatio;
    if (ratio <= 0) {
      return 0;
    }
    return _PanelMetrics.tabTextMarginPx / ratio;
  }

  /// 构建一个标题栏（一级 / 二级通用）。
  ///
  /// 排布规则对齐 Android `TabLayout` 的 `MODE_AUTO`：
  /// - 每个 Tab 按内容宽度排布，不等宽（`MODE_AUTO` 下 `lp.width = WRAP_CONTENT`）；
  /// - 所有 Tab 的总宽度小于容器时，整体**水平居中**（`TabLayout.onMeasure` 会把
  ///   tabStrip 重新测量到容器宽度，而 tabStrip 的 gravity 为 `CENTER_HORIZONTAL`）；
  /// - 总宽度超出容器时可横向滚动，且禁用越界回弹（`setOverScrollMode(OVER_SCROLL_NEVER)`）。
  Widget _buildTabBar({
    required BuildContext context,
    required List<TEUIProperty> items,
    required double fontSize,
    required ScrollController controller,
    required GlobalKey selectedKey,
    required bool Function(int index, TEUIProperty item) isSelectedOf,
    required void Function(int index, TEUIProperty item) onTap,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final double textMargin = _tabTextMargin(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final List<Widget> tabs = [];
        for (int index = 0; index < items.length; index++) {
          final TEUIProperty item = items[index];
          final bool isSelected = isSelectedOf(index, item);
          tabs.add(_buildTabItem(
            context: context,
            key: isSelected ? selectedKey : null,
            item: item,
            isSelected: isSelected,
            fontSize: fontSize,
            textMargin: textMargin,
            onTap: () => onTap(index, item),
          ));
        }
        return SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            // 内容不足时撑满容器宽度，配合 center 实现"短则居中、长则滚动"
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // Tab 高度撑满标题栏，点击区域与 Android 的 TabView（height=MATCH_PARENT）一致
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: tabs,
            ),
          ),
        );
      },
    );
  }

  /// 构建单个 Tab。
  ///
  /// 结构对齐 Android 的 `TabView`（LinearLayout，padding 12dp，gravity=CENTER）
  /// 内嵌一个带左右 margin 的 `TextView`：
  /// ```
  /// TabView(padding 12dp, gravity CENTER)
  ///   └── TextView(leftMargin/rightMargin 5px, 单行)
  /// ```
  /// 选中时 Android 会把 TextView 的左右 margin 置为 0（见 `onTabSelected`），
  /// 用于抵消文字加粗后变宽、保持 Tab 总宽度相对稳定，这里同样复刻。
  Widget _buildTabItem({
    required BuildContext context,
    required Key? key,
    required TEUIProperty item,
    required bool isSelected,
    required double fontSize,
    required double textMargin,
    required VoidCallback onTap,
  }) {
    final double margin = isSelected ? 0 : textMargin;
    // 外层 Material 用于承载点击水波纹：面板本身不保证处于 Material 之下，
    // 而 Android 的 TabView 默认带 selectableItemBackground 点击反馈
    return Material(
      key: key,
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: _PanelMetrics.tabPaddingHorizontal + margin),
          child: Center(
            // widthFactor 让 Center 收缩到文字宽度，避免在 Row 中被拉伸
            widthFactor: 1.0,
            child: Text(
              TEPanelDisplay.getDisplayName(context, item),
              // 对应 TextView.setLines(1)：单行，超长直接裁剪（Android 未设置 ellipsize）
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: isSelected
                    ? _PanelMetrics.tabTextCheckedColor
                    : _PanelMetrics.tabTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 把选中的 Tab 滚动到标题栏中间。
  ///
  /// 对应 Android `TEBeautyTabLayout.setData` 末尾的
  /// `setScrollPosition(finalPosition, 0, true)`：其 `calculateScrollXForTab`
  /// 的计算目标正是"把选中 Tab 的中心对齐到容器中心"。
  void _ensureTabVisible(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx = key.currentContext;
      if (ctx == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(ctx, alignment: 0.5, duration: Duration.zero);
    });
  }

  Widget _buildSubTitleLayout() {
    // 高度由外层标题区统一控制（对齐 Android 的 40dp），这里只负责内部排布
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Text(
            _subTitleName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.bold,
              fontSize: _PanelMetrics.drillDownTitleTextSize,
            ),
          ),
        ),
        Positioned(
          left: _PanelMetrics.backBtnMarginLeft,
          child: IconButton(
            // 控件占 25（21 图标 + 上下各 2 内边距），对齐 Android ImageView 25dp + padding 2dp
            iconSize: _PanelMetrics.backBtnSize - _PanelMetrics.backBtnPadding * 2,
            padding: const EdgeInsets.all(_PanelMetrics.backBtnPadding),
            constraints: const BoxConstraints(
              minWidth: _PanelMetrics.backBtnSize,
              minHeight: _PanelMetrics.backBtnSize,
            ),
            onPressed: onSubTitleBackBtnClick,
            icon: Image.asset(
              'assets/icon/te_beauty_panel_back_icon.png',
              package: 'tencent_effect_flutter',
              width: _PanelMetrics.backBtnSize - _PanelMetrics.backBtnPadding * 2,
              height: _PanelMetrics.backBtnSize - _PanelMetrics.backBtnPadding * 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTitleLayout(BuildContext context) {
    final List<TEUIProperty>? panelData = _panelViewData;
    if (panelData == null) {
      return Container();
    }
    // Android 的 TabLayout 天然单选，这里对数据中可能出现的多个选中态做收敛，
    // 只让第一个选中项高亮；都没有选中态时高亮第 0 个，与 Android
    // `TEBeautyTabLayout.setData` 中 "position == -1 则 checkTab(0)" 一致
    int selectedIndex = panelData.indexWhere(
        (property) => property.uiState == UIState.CHECKED_AND_IN_USE);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }
    return Row(
      children: [
        Expanded(
          child: _buildTabBar(
            context: context,
            items: panelData,
            fontSize: _PanelMetrics.mainTabTextSize,
            controller: _mainTabScrollController,
            selectedKey: _mainTabSelectedKey,
            isSelectedOf: (index, item) => index == selectedIndex,
            onTap: (index, item) => _onMainTitleItemClick(item),
          ),
        ),
        // 固定宽度 + 右外边距，与 Android `te_panel_view_top_right_layout` 一致：
        // 一级标题栏的可用宽度由此决定，直接影响 Tab 的居中位置
        Padding(
          padding: const EdgeInsets.only(
              right: _PanelMetrics.revertLayoutMarginRight),
          child: SizedBox(
            width: _PanelMetrics.revertLayoutWidth,
            child: RevertButton(
              onPressed: () {
                widget._beautyPanelViewCallBack?.onRevertBtnClick(context, widget);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    if (_sliderViewModel == null) return Container();
    return BeautyPanelSlider(
      isShowSliderTypeLayout: _sliderViewModel!.isShowSliderTypeLayout,
      selectedList: _sliderViewModel!.selectedList,
      onSliderTypeClick: _sliderViewModel!.onSliderTypeClick,
      value: _sliderViewModel!.value,
      min: _sliderViewModel!.min,
      max: _sliderViewModel!.max,
      divisions: _sliderViewModel!.divisions,
      onChanged: _sliderViewModel!.onChanged,
      onChangeEnd: _sliderViewModel!.onChangeEnd,
    );
  }

  void _onSliderTypeClick(index) {
    var length = _selectedList.length;
    setState(() {
      for (int i = 0; i < length; i++) {
        _selectedList[i] = index == i;
      }
    });
    _setSliderState(_currentSDKParam);
  }

  Widget _buildListViewItemIcon(int index) {
    final TEUIProperty? item = _currentList?[index];
    Widget icon;
    if (item?.icon?.isNotEmpty ?? false) {
      icon = Image.asset("assets/${item!.icon}", width: 48, height: 48, fit: BoxFit.cover);
    } else {
      icon = const SizedBox(width: 48, height: 48);
    }
    return Stack(
      children: [
        icon,
        if (_isShowLightMakeupEditBadge(item)) _buildLightMakeupEditBadge(),
      ],
    );
  }

  /// 轻美妆套装被选中时是否展示"可下钻编辑"角标。
  ///
  /// 对应 Android `TEDetailPanelAdapter`：仅 [UICategory.LIGHT_MAKEUP] 且已选中
  /// （且不是"无"这类空 sdkParam 项）时展示，提示用户可二次点击进入单项调节。
  bool _isShowLightMakeupEditBadge(TEUIProperty? item) {
    return item != null &&
        item.uiCategory == UICategory.LIGHT_MAKEUP &&
        item.uiState == UIState.CHECKED_AND_IN_USE &&
        item.sdkParam != null;
  }

  /// 轻美妆"可下钻编辑"角标：半透明黑底 + 居中编辑图标，叠加在 48dp 图标之上。
  Widget _buildLightMakeupEditBadge() {
    return Container(
      width: _PanelMetrics.itemIconSize,
      height: _PanelMetrics.itemIconSize,
      padding: const EdgeInsets.all(_PanelMetrics.editBadgePadding),
      decoration: BoxDecoration(
        color: _PanelMetrics.editBadgeColor,
        borderRadius: BorderRadius.circular(_PanelMetrics.editBadgeRadius),
      ),
      child: Image.asset(
        'assets/icon/te_beauty_panel_edit_icon.png',
        package: 'tencent_effect_flutter',
      ),
    );
  }

  Widget buildListViewItem(BuildContext context, int index) {
    final bool isChecked = _currentList?[index].uiState == UIState.CHECKED_AND_IN_USE;
    return InkWell(
      onTap: () {
        _onListViewItemClick(index);
      },
      child: Center(
        child: SizedBox(
          width: 52,
          height: 80,
          child: CustomPaint(
            painter: _PanelItemSelectorPainter(isChecked: isChecked),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _buildListViewItemIcon(index),
                ),
                Container(
                  height: 20, // Fixed height matching Android's TextView (20dp)
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _currentList?[index] == null
                        ? ""
                        : TEPanelDisplay.getDisplayName(context, _currentList![index]),
                    style: TextStyle(
                      color: isChecked ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _isShowPoint(_currentList?[index]) ? null : Colors.transparent,
                      gradient: _isShowPoint(_currentList?[index])
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFDCFC73),
                                Color(0xFF7BF38E),
                                Color(0xFF74ECEE),
                              ],
                            )
                          : null,
                      borderRadius: const BorderRadius.all(Radius.circular(1.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isShowPoint(TEUIProperty? uiProperty) {
    if (uiProperty == null) {
      return false;
    }
    if (UICategory.BEAUTY == uiProperty.uiCategory) {
      if (uiProperty.propertyList != null) {
        for (TEUIProperty uiProperty in uiProperty.propertyList!) {
          bool isShow = _isShowPoint(uiProperty);
          if (isShow) {
            return true;
          }
        }
      } else {
        int? value = uiProperty.sdkParam?.effectValue;
        if (value != null && value != 0 && uiProperty.uiState != UIState.INIT) {
          return true;
        }
      }
    }
    return false;
  }

  /// 进入下钻态：用返回按钮 + 标题的形式展示 [currentItem] 的子项列表。
  ///
  /// 与 Android `TEDetailPanel.showChildrenItems` 对应。所有"点击某项后展开其子项"
  /// 的入口都必须走这里，以保证下钻态的各项状态（返回按钮、标题、二级标题栏、
  /// 滚动位置栈、下钻锚点）始终一致。
  void _showChildrenItems(TEUIProperty currentItem, List<TEUIProperty> uiPropertyList) {
    _listViewOffset.add(_scrollController.hasClients ? _scrollController.offset : 0);
    _currentSDKParam = null;
    setState(() {
      _currentDrillDownProperty = currentItem;
      _currentList = uiPropertyList;
      _isShowSubTitleLayout = true;
      // 下钻态由标题栏承载层级信息，二级标题栏必须隐藏，否则会与返回按钮同时出现
      _isShowSubTabBar = false;
      _subTitleName = TEPanelDisplay.getDisplayName(context, currentItem);
      _updateLayoutMode();
    });
    _jumpToOffset(0);
    // 子项列表与上一级的选中项无关，进入时先收起 seekbar
    _setSliderState(null);
  }

  /// 恢复面板到主面板根状态（隐藏返回按钮，重新展示一级标题栏与二级标题栏）。
  ///
  /// 与 Android `TEDetailPanel.showView()` 对应：Android 通过重建 mainTabLayout
  /// 触发 tab 选中回调，从而级联恢复二级标题栏与列表内容；这里显式完成同样的级联。
  void _restoreMainPanel() {
    final List<TEUIProperty>? panelData = _panelViewData;
    if (panelData == null || panelData.isEmpty) {
      return;
    }
    // 选中的一级 Tab 以 uiState 为准，缺失时回退到第 0 个，与 Android TEBeautyTabLayout
    // "没有默认选中项则手动选中第 0 项"的行为一致
    TEUIProperty mainTab = panelData[0];
    for (final TEUIProperty property in panelData) {
      if (property.uiState == UIState.CHECKED_AND_IN_USE) {
        mainTab = property;
        break;
      }
    }
    setState(() {
      _currentDrillDownProperty = null;
      _isShowSubTitleLayout = false;
      _applyMainTabSelection(mainTab);
      _updateLayoutMode();
    });
  }

  /// 应用一级 Tab 的选中结果：按 [TEUIProperty.hasSubTitle] 决定是否展示二级标题栏，
  /// 并同步列表内容。
  ///
  /// 必须在 `setState` 回调内调用。
  void _applyMainTabSelection(TEUIProperty mainTab) {
    final List<TEUIProperty>? children = mainTab.propertyList;
    if (mainTab.hasSubTitle && children != null && children.isNotEmpty) {
      // 二级标题的选中项同样以 uiState 为准，这样从子项返回后仍会停留在原来的
      // 二级标题上（例如"特效 → 背景分割"），而不是跳回第一个二级标题
      int index = children.indexWhere((item) => item.uiState == UIState.CHECKED_AND_IN_USE);
      if (index < 0) {
        index = (_selectedSubTabIndex >= 0 && _selectedSubTabIndex < children.length)
            ? _selectedSubTabIndex
            : 0;
      }
      _isShowSubTabBar = true;
      _subTabItems = children;
      _selectedSubTabIndex = index;
      _currentList = children[index].propertyList;
    } else {
      _isShowSubTabBar = false;
      _subTabItems = null;
      _selectedSubTabIndex = 0;
      _currentList = children;
    }
  }

  /// 返回上一级。
  ///
  /// 以 [_currentDrillDownProperty] 为锚点取其父节点，并判断该父节点的子项列表由谁承载：
  /// - 父节点是一级主 Tab 或二级标题：其列表本就由一级/二级标题栏渲染，因此直接恢复
  ///   主面板根状态；
  /// - 否则父节点是中间下钻节点，继续以标题栏 + 列表的形式展示它。
  void onSubTitleBackBtnClick() {
    final TEUIProperty? titleProperty = _currentDrillDownProperty;
    if (titleProperty == null) {
      return;
    }
    // 轻美妆套装是叶子项，propertyList 正常为 null，仅在「已选中后再次点击」时由
    // TELightMakeupItemBuilder 临时挂载单项列表用于下钻。若不在此清理，残留列表会让
    // 后续「首次点击未选中套装」也直接下钻，破坏「首次点击选中、二次点击才下钻」的交互。
    if (titleProperty.uiCategory == UICategory.LIGHT_MAKEUP &&
        TELightMakeupItemBuilder.isLightMakeupItemList(titleProperty.propertyList)) {
      titleProperty.propertyList = null;
    }
    final TEUIProperty? parentUIProperty = titleProperty.parentUIProperty;
    if (parentUIProperty == null ||
        parentUIProperty.isMainTabNode() ||
        parentUIProperty.isSubTitleNode()) {
      _restoreMainPanel();
    } else {
      setState(() {
        _currentDrillDownProperty = parentUIProperty;
        _isShowSubTitleLayout = true;
        _subTitleName = TEPanelDisplay.getDisplayName(context, parentUIProperty);
        _currentList = parentUIProperty.propertyList;
        _updateLayoutMode();
      });
    }
    _jumpToOffset(_listViewOffset.isNotEmpty ? _listViewOffset.removeLast() : 0);
    _setSliderState(null);
  }

  /// 安全地跳转列表滚动位置。
  ///
  /// 列表内容刚被替换时 ScrollController 可能尚未 attach，此时 jumpTo 会抛断言异常，
  /// 因此先做 attach 检查。这里不对 offset 做范围夹取：setState 之后列表尚未重新
  /// 布局，`maxScrollExtent` 仍是旧列表的值，用它夹取会把待恢复的偏移错误地压到 0；
  /// 越界的偏移交由 ScrollPosition 在下一帧自行修正。
  void _jumpToOffset(double offset) {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(offset);
  }

  void _onMainTitleItemClick(TEUIProperty uiProperty) {
    for (TEUIProperty property in _panelViewData!) {
      if (property.uiState == UIState.CHECKED_AND_IN_USE) {
        typeDataListViewOffset[_getTypeDataListViewOffsetKey(property)] = _scrollController.offset;
        break;
      }
    }
    _tePanelDataProducer.onTabItemClick(uiProperty);
    widget._beautyPanelViewCallBack?.onTitleClick(uiProperty);

    // 切换一级 Tab 即退出下钻态，二级标题栏的可见性交由 _applyMainTabSelection 统一决定
    setState(() {
      _currentDrillDownProperty = null;
      _isShowSubTitleLayout = false;
      _applyMainTabSelection(uiProperty);
      _updateLayoutMode();
    });
    double? offset = typeDataListViewOffset[_getTypeDataListViewOffsetKey(uiProperty)];
    _jumpToOffset(offset ?? 0);
    _setSliderState(null);
    _ensureTabVisible(_mainTabSelectedKey);
    _ensureTabVisible(_subTabSelectedKey);
  }

  void _onListViewItemClick(int index) async {
    TEUIProperty uiProperty = _currentList![index];

    // 轻美妆主态下，用户再次点击已选中的套装：主动触发下钻到单项列表。
    // 首次点击仅做选中（此时 uiState 还是 INIT），因此不会误触发下钻。
    if (_shouldEnterLightMakeupEdit(uiProperty)) {
      final List<TEUIProperty>? itemList = await TELightMakeupItemBuilder.buildItemList(uiProperty);
      if (!mounted) {
        return;
      }
      if (itemList != null && itemList.isNotEmpty) {
        // 单项列表临时挂在套装节点上，复用面板既有的下钻机制
        uiProperty.propertyList = itemList;
        _showChildrenItems(uiProperty, itemList);
        return;
      }
    }

    // Check for green screen v2 import image item
    if (uiProperty.isGSV2ImportImageItem()) {
      TEUIProperty? parentProperty = uiProperty.parentUIProperty;
      if (parentProperty?.sdkParam?.extraInfo != null) {
        parentProperty!.sdkParam!.extraInfo![TESDKParam.GREEN_PARAMS_V2] =
            TEProducerUtils.getGreenParamsV2(parentProperty);
        uiProperty.sdkParam = parentProperty.sdkParam;
      }
      widget._beautyPanelViewCallBack?.onClickCustomSeg(uiProperty);
      return;
    }

    // Check for green screen / custom segmentation
    String? segType = uiProperty.sdkParam?.extraInfo?[TESDKParam.EXTRA_INFO_KEY_SEG_TYPE];
    if (segType != null &&
        (TESDKParam.EXTRA_INFO_SEG_TYPE_GREEN.contains(segType) || segType == TESDKParam.EXTRA_INFO_SEG_TYPE_CUSTOM)) {
      // Green screen V2: check if has background path, enter sub-items
      if (segType == TESDKParam.EXTRA_INFO_SEG_TYPE_GREEN[1]) {
        uiProperty.sdkParam?.extraInfo?[TESDKParam.GREEN_PARAMS_V2] = TEProducerUtils.getGreenParamsV2(uiProperty);
        if (uiProperty.sdkParam?.extraInfo?[TESDKParam.EXTRA_INFO_KEY_BG_PATH] != null &&
            uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_PATH]!.isNotEmpty) {
          _executeItemClickLogic(uiProperty);
          return;
        }
      }
      widget._beautyPanelViewCallBack?.onClickCustomSeg(uiProperty);
      return;
    }

    // Check if material needs download
    final TEMotionDLModel? dlModel = uiProperty.dlModel;
    if (dlModel != null) {
      dlModel.localDir = await TEProducerUtils.getAbsoluteLocalDir(dlModel.localDir!);
      if (!await TEMaterialChecker.isDownloaded(dlModel)) {
        final downloadSuccess = await _showDownloadDialog(uiProperty);
        if (!downloadSuccess) {
          return;
        }
      }
    }
    _executeItemClickLogic(uiProperty);
  }

  Future<bool> _showDownloadDialog(TEUIProperty uiProperty) async {
    return TEDownloadProgressDialog.show(context, uiProperty);
  }

  /// 是否应进入轻美妆下钻编辑：已选中的轻美妆套装被二次点击，且其拥有可读的套装资源。
  bool _shouldEnterLightMakeupEdit(TEUIProperty uiProperty) {
    return uiProperty.uiCategory == UICategory.LIGHT_MAKEUP &&
        uiProperty.uiState == UIState.CHECKED_AND_IN_USE &&
        uiProperty.sdkParam != null &&
        (uiProperty.sdkParam!.resourcePath?.isNotEmpty ?? false);
  }

  void _executeItemClickLogic(TEUIProperty uiProperty) {
    // 轻美妆下钻态单项（口红/腮红/眼影等）：只刷新子列表选中态与滑竿，
    // 不下发 effect（真正下发由滑竿拖动时触发），也不再下钻。
    if (TELightMakeupItemBuilder.isLightMakeupItem(uiProperty)) {
      _tePanelDataProducer.onItemClick(uiProperty);
      _currentSDKParam = uiProperty.sdkParam;
      _setSliderState(uiProperty.sdkParam, uiProperty: uiProperty);
      setState(() {});
      return;
    }
    List<TEUIProperty>? resultList = _tePanelDataProducer.onItemClick(uiProperty);
    if (resultList != null && resultList.isNotEmpty) {
      _showChildrenItems(uiProperty, resultList);
    } else {
      // Handle beauty template
      if (uiProperty.uiCategory == UICategory.BEAUTY_TEMPLATE) {
        widget._beautyPanelViewCallBack?.onUpdateEffect(uiProperty.sdkParam!);
        if (_tePanelDataProducer is TEGeneralDataProducer) {
          (_tePanelDataProducer as TEGeneralDataProducer).restoreUIStateFromParams(uiProperty.paramList);
        }
      } else if (uiProperty.isNoneItem()) {
        List<TESDKParam>? closeEffectList = _tePanelDataProducer.getCloseEffectItems(uiProperty);
        if (closeEffectList != null) {
          widget._beautyPanelViewCallBack?.onUpdateEffectList(closeEffectList);
        }
      } else {
        // Handle green screen V2 sub-item
        TESDKParam? paramToSend = _getSDKParamFromUIProperty(uiProperty);
        if (paramToSend != null) {
          widget._beautyPanelViewCallBack?.onUpdateEffect(paramToSend);
        }
      }
      _currentSDKParam = uiProperty.sdkParam;
    }
    _setSliderState(_currentSDKParam, uiProperty: uiProperty);
    setState(() {});
  }

  /// Get SDK param from UI property, with special handling for Green Screen V2
  TESDKParam? _getSDKParamFromUIProperty(TEUIProperty uiProperty) {
    if (uiProperty.uiCategory == UICategory.GREEN_BACKGROUND_V2_ITEM) {
      TEUIProperty? parentProperty = uiProperty.parentUIProperty;
      if (parentProperty?.sdkParam?.extraInfo != null) {
        String? bgPath = parentProperty!.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_PATH];
        String? keyColor = parentProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_KEY_COLOR];
        if ((bgPath == null || bgPath.isEmpty) && (keyColor == null || keyColor.isEmpty)) {
          return null;
        }
        parentProperty.sdkParam!.extraInfo![TESDKParam.GREEN_PARAMS_V2] =
            TEProducerUtils.getGreenParamsV2(parentProperty);
        return parentProperty.sdkParam;
      }
    }
    return uiProperty.sdkParam;
  }

  /// 仅凭 [sdkParam] 判断是否"美妆无效果占位项"。
  ///
  /// 无法感知节点分类，因此对轻美妆下钻态单项会误判。已知 [TEUIProperty] 时请优先使用
  /// [TEUIProperty.isBeautyMakeupNoneItem]，这里仅作为拿不到节点的兜底。
  bool isBeautyMakeupNoneItem(TESDKParam? sdkParam) {
    if (sdkParam != null && (sdkParam.resourcePath == null || sdkParam.resourcePath!.isEmpty)) {
      switch (sdkParam.effectName) {
        case "beauty.faceFeatureLipsLut":
        case "beauty.faceFeatureSoftlight":
        case "beauty.faceFeatureRedCheek":
        case "beauty.faceFeatureEyesMakeup.eyeShadow":
        case "beauty.faceFeatureEyesMakeup.eyeLiner":
        case "beauty.faceFeatureEyesMakeup.eyelash":
        case "beauty.faceFeatureEyesMakeup.eyeSequins":
        case "beauty.faceFeatureEyesMakeup.eyebrow":
        case "beauty.faceFeatureEyesMakeup.eyeball":
        case "beauty.faceFeatureEyesMakeup.eyelids":
        case "beauty.faceFeatureEyesMakeup.eyewocan":
        case "beauty.hairColorLut":
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  void _setSliderState(TESDKParam? sdkParam, {TEUIProperty? uiProperty}) {
    // Don't show slider for GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE
    if (_currentList != null && _currentList!.isNotEmpty) {
      for (TEUIProperty item in _currentList!) {
        if (item.uiState == UIState.CHECKED_AND_IN_USE &&
            item.uiCategory == UICategory.GREEN_BACKGROUND_V2_ITEM_IMPORT_IMAGE) {
          setState(() {
            _sliderViewModel = null;
          });
          return;
        }
      }
    }

    // 美妆无效果项不显示 slider。
    // 判定收敛在 TEUIProperty.isBeautyMakeupNoneItem() 中（与 Android 端
    // TEDetailPanel.setSeekBarState 同一位置）：轻美妆下钻态单项虽然复用了单点美妆的
    // effectName 且 resourcePath 为空，但需要展示滑竿来调节该项强度，故被显式排除。
    final bool isNoneItem =
        uiProperty != null ? uiProperty.isBeautyMakeupNoneItem() : isBeautyMakeupNoneItem(sdkParam);
    if (isNoneItem) {
      setState(() {
        _sliderViewModel = null;
      });
      return;
    }

    _sliderViewModel = SliderAdapter.fromSDKParam(
      sdkParam,
      _selectedList,
      onValueChange: (value) {
        var localValue = value.round().toDouble();
        if (_sliderViewModel != null && localValue != _sliderViewModel!.value) {
          bool isLutMode = _sliderViewModel!.isShowSliderTypeLayout && _isSelectedLut();
          SliderAdapter.updateSDKParam(sdkParam!, localValue, isLutMode);

          TESDKParam? paramToSend = _resolveParamToSend(sdkParam, uiProperty, localValue);

          if (widget.onSliderUpdateValueType == 1 && paramToSend != null) {
            widget._beautyPanelViewCallBack?.onUpdateEffect(paramToSend);
          }
          setState(() {
            _sliderViewModel = _sliderViewModel!.copyWith(value: localValue);
          });
        }
      },
      onChangeEnd: (value) {
        if (widget.onSliderUpdateValueType == 2 && sdkParam != null) {
          TESDKParam? paramToSend = _resolveParamToSend(sdkParam, uiProperty, value);
          if (paramToSend != null) {
            widget._beautyPanelViewCallBack?.onUpdateEffect(paramToSend);
          }
        }
      },
      onTypeClick: _onSliderTypeClick,
    );
    setState(() {});
  }

  /// 计算滑竿值变更后实际需要下发给 SDK 的参数。
  ///
  /// - 轻美妆下钻态单项：把该项强度写入父套装的 `extraInfo[effectName]`，再整套重发；
  /// - 绿幕 V2 子项：下发父节点（携带聚合后的 `green_params_v2`）；
  /// - 其余：直接下发自身参数。
  TESDKParam? _resolveParamToSend(TESDKParam? sdkParam, TEUIProperty? uiProperty, double value) {
    if (TELightMakeupItemBuilder.isLightMakeupItem(uiProperty)) {
      return _applyLightMakeupItemStrength(uiProperty!, value);
    }
    TESDKParam? paramToSend = sdkParam;
    if (_currentSDKParam != null) {
      TEUIProperty? gsv2Item = _findCurrentCheckedGSV2Item();
      if (gsv2Item != null) {
        paramToSend = _getSDKParamFromUIProperty(gsv2Item);
      }
    }
    return paramToSend;
  }

  /// 将轻美妆单项强度写入父套装的 `extraInfo[effectName]`，返回用于整套下发的父套装参数。
  ///
  /// 单项本身不是独立效果，SDK 侧只认套装（`light.makeup`）+ 各类单项强度，
  /// 因此调节单项必须整套重发。
  TESDKParam? _applyLightMakeupItemStrength(TEUIProperty item, double value) {
    final TEUIProperty? parent = item.parentUIProperty;
    final TESDKParam? itemParam = item.sdkParam;
    if (parent == null || parent.sdkParam == null || itemParam == null) {
      return null;
    }
    final int progress = value.round();
    final String effectName = itemParam.effectName ?? '';
    if (effectName.isEmpty) {
      return null;
    }
    parent.sdkParam!.extraInfo ??= <String, String>{};
    parent.sdkParam!.extraInfo![effectName] = '$progress';
    // 同步 item 的 effectValue 快照，保证通用滑竿逻辑读取到最新强度
    itemParam.effectValue = progress;
    return parent.sdkParam;
  }

  /// Find the currently checked GREEN_BACKGROUND_V2_ITEM in _currentList
  TEUIProperty? _findCurrentCheckedGSV2Item() {
    if (_currentList == null) return null;
    for (TEUIProperty item in _currentList!) {
      if (item.uiCategory == UICategory.GREEN_BACKGROUND_V2_ITEM && item.uiState == UIState.CHECKED_AND_IN_USE) {
        return item;
      }
    }
    return null;
  }

  bool _isSelectedLut() {
    return _selectedList[1];
  }

  void checkPanelViewItem(TEUIProperty uiProperty) {
    // Special handling for green screen V2 parent node (SEGMENTATION with segType=green_background_v2)
    String? segType = uiProperty.sdkParam?.extraInfo?[TESDKParam.EXTRA_INFO_KEY_SEG_TYPE];
    if (segType == TESDKParam.EXTRA_INFO_SEG_TYPE_GREEN[1] && uiProperty.uiCategory == UICategory.SEGMENTATION) {
      // Update state via producer
      List<TEUIProperty>? uiPropertyList = _tePanelDataProducer.onItemClick(uiProperty);
      if (uiPropertyList != null && uiPropertyList.isNotEmpty) {
        _showChildrenItems(uiProperty, uiPropertyList);
      }
      // Simulate clicking the "import image" item
      TEUIProperty? importItem = TEProducerUtils.getImportTEUIPropertyItem(uiProperty);
      if (importItem != null) {
        _executeItemClickLogic(importItem);
      }
      return;
    }
    _tePanelDataProducer.onItemClick(uiProperty);
    setState(() {});
    _setSliderState(uiProperty.sdkParam, uiProperty: uiProperty);
  }

  /// 列表滚动位置的缓存 key。
  ///
  /// 使用 titleType（形如 `group_1`）而非显示名：新版面板配置中 displayName 恒为空，
  /// 若用显示名拼 key 会让所有 Tab 共用同一个 key，导致滚动位置互相串台。
  String _getTypeDataListViewOffsetKey(TEUIProperty property) {
    final String? titleType = property.titleType;
    if (titleType != null && titleType.isNotEmpty) {
      return titleType;
    }
    return "${property.displayName}${property.displayNameEn}";
  }
}

/// Custom painter that replicates Android's PanelItemSelectorLayout selection effect.
///
/// When checked, draws a 1dp gradient stroke (rounded corner) around the icon
/// region only, matching Android's PanelItemSelectorLayout:
/// - gradient colors DCFC73 -> 74ECEE -> 7BF38E (top-left -> bottom-right)
/// - cornerRadius 10dp, strokeWidth 1dp, padding 2dp around the 48x48 icon.
class _PanelItemSelectorPainter extends CustomPainter {
  final bool isChecked;
  static const double _cornerRadius = 10.0;
  static const double _strokeWidth = 1.0;

  _PanelItemSelectorPainter({required this.isChecked});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isChecked) return;

    // Selection border wraps only the icon region (48x48 + 2dp padding = 52x52),
    // centered horizontally at the top of the item, same as Android's
    // PanelItemSelectorLayout (wrap_content with 2dp padding around a 48dp icon).
    final double side = size.width;
    final double halfStroke = _strokeWidth / 2;
    final Rect rect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      side - _strokeWidth,
      side - _strokeWidth,
    );

    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_cornerRadius),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFDCFC73),
          Color(0xFF74ECEE),
          Color(0xFF7BF38E),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_PanelItemSelectorPainter oldDelegate) {
    return oldDelegate.isChecked != isChecked;
  }
}
