import 'package:flutter/material.dart';
import 'package:tencent_effect_flutter_demo/utils/panel_display.dart';
import '../config/te_res_config.dart';
import '../constant/te_constant.dart';
import '../languages/AppLocalizations.dart';
import '../model/te_ui_property.dart';
import '../producer/te_general_data_producer.dart';
import '../producer/te_panel_data_producer.dart';
import 'beauty_panel_view_callback.dart';

class BeautyPanelView extends StatefulWidget {
  static const String MAKEUP_LUT_STRENGTH_KEY = 'makeupLutStrength';

  final BeautyPanelViewCallBack? _beautyPanelViewCallBack;

  final int onSliderUpdateValueType; //Default means callback in onChanged method 2. means call in onChangeEnd
  final TEPanelDataProducer? panelDataProducer;

  const BeautyPanelView(this._beautyPanelViewCallBack, this.panelDataProducer, {Key? key, this.onSliderUpdateValueType = 1}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PanelViewState();
  }
}

class PanelViewState extends State<BeautyPanelView> {
  final ScrollController _scrollController = ScrollController();
  final List<double> _listViewOffset = [];
  Map<String, double> typeDataListViewOffset = {};
  bool _isShowSlider = false;
  double _progressMin = 0;
  double _progressMax = 100;
  double _currentProgress = 0;
  String _subTitleName = "";

  TESDKParam? _currentSDKParam; //

  bool _isShowSubTitleLayout = false; //

  List<TEUIProperty>? _currentList;

  List<TEUIProperty>? _panelViewData;

  final List<bool> _selectedList = [true, false];

  bool _isShowSliderTypeLayout = false;

  late TEPanelDataProducer _tePanelDataProducer;

  @override
  initState() {
    super.initState();
    if (widget.panelDataProducer != null) {
      _tePanelDataProducer = widget.panelDataProducer!;
    } else {
      _tePanelDataProducer = TEGeneralDataProducer();
      debugPrint("TEResConfig.getConfig().defaultPanelDataList  ${TEResConfig.getConfig().defaultPanelDataList.length}");

      _tePanelDataProducer.setPanelDataList(TEResConfig.getConfig().defaultPanelDataList);
    }
    _getPanelViewData();
  }

  void _getPanelViewData() async {
    var data = await _tePanelDataProducer.getPanelData();
    if (widget._beautyPanelViewCallBack != null) {
      List<TESDKParam> usedProperties = _tePanelDataProducer.getUsedProperties();
      widget._beautyPanelViewCallBack?.onDefaultEffectList(usedProperties);
    }
    var dataList = _tePanelDataProducer.getFirstCheckedItems();
    setState(() {
      _panelViewData = data;
      _currentList = dataList;
    });
  }

  @override
  Widget build(BuildContext context) {
    PanelDisplay.setLocale(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: _isShowSlider ? _buildSlider(context) : Container(),
        ),
        Container(
          color: Colors.black54,
          child: Column(
            children: [
              _isShowSubTitleLayout ? _buildSubTitleLayout() : _buildMainTitleLayout(context),
              SizedBox(
                height: 100,
                child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: false,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: buildListViewItem,
                    itemCount: _currentList?.length),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTitleLayout() {
    return Flex(
      direction: Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          iconSize: 22,
          onPressed: onSubTitleBackBtnClick,
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        Text(
          _subTitleName,
          style: const TextStyle(color: Colors.white),
        ),
        Container(
          width: 30,
        ),
      ],
    );
  }

  ///create type layout
  Widget _buildMainTitleLayout(BuildContext context) {
    List<Widget> titlesView = [];
    if (_panelViewData == null) {
      return Container();
    }
    bool hasFirstItemChecked = false;
    for (TEUIProperty property in _panelViewData!) {
      titlesView.add(TextButton(
        onPressed: () {
          _onMainTitleItemClick(property);
        },
        child: Text(
          PanelDisplay.getDisplayName(property)!,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(color: property.uiState == UIState.CHECKED_AND_IN_USE && !hasFirstItemChecked ? Colors.blue : Colors.white),
        ),
      ));
      if (property.uiState == UIState.CHECKED_AND_IN_USE) {
        hasFirstItemChecked = true;
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: titlesView,
      ),
    );
  }

  ///create slider layout
  Widget _buildSlider(BuildContext context) {
    return Row(
      children: [
        _isShowSliderTypeLayout ? _buildSliderTypeLayout(context) : Container(),
        Expanded(
          child: Slider(
            value: _currentProgress,
            thumbColor: Colors.blue,
            activeColor: Colors.blue,
            inactiveColor: Colors.white,
            divisions: 100,
            onChanged: (value) {
              var localValue = value.round().toInt();
              if (localValue != _currentProgress) {
                if (_isShowSliderTypeLayout && _isSelectedLut()) {
                  _currentSDKParam!.extraInfo![BeautyPanelView.MAKEUP_LUT_STRENGTH_KEY] = localValue.toString();
                } else {
                  _currentSDKParam?.effectValue = localValue;
                }
                if (widget.onSliderUpdateValueType == 1) {
                  widget._beautyPanelViewCallBack?.onUpdateEffect(_currentSDKParam!);
                }
              }
              setState(() {
                _currentProgress = localValue.toDouble();
              });
            },
            onChangeEnd: (value) {
              if (widget.onSliderUpdateValueType == 2) {
                widget._beautyPanelViewCallBack?.onUpdateEffect(_currentSDKParam!);
              }
            },
            min: _progressMin,
            max: _progressMax,
            label: '$_currentProgress',
          ),
        )
      ],
    );
  }

  Widget _buildSliderTypeLayout(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 100,
      child: ToggleButtons(
        renderBorder: true,
        borderRadius: BorderRadius.circular(30),
        borderColor: Colors.blueGrey,
        selectedBorderColor: Colors.blueGrey,
        textStyle: const TextStyle(fontSize: 12),
        isSelected: _selectedList,
        color: Colors.white70,
        fillColor: Colors.white,
        selectedColor: Colors.black,
        children: <Widget>[
          Text(AppLocalizations.of(context)?.getPanelSliderTypeMakeup ?? ""),
          Text(AppLocalizations.of(context)?.getPanelSliderTypeLut ?? "")
        ],
        onPressed: (index) => {_onSliderTypeClick(index)},
      ),
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
    if (_currentList?[index].icon?.isNotEmpty ?? false) {
      return Container(
        width: 45,
        height: 45,
        padding: EdgeInsets.all(1),
        decoration: _currentList?[index].uiState == UIState.CHECKED_AND_IN_USE
            ? BoxDecoration(border: Border.all(width: 1, color: Colors.blue
            .shade500), borderRadius: BorderRadius.circular(8))
            : BoxDecoration(border: Border.all(width: 1, color: Colors.transparent
            ), borderRadius: BorderRadius.circular(8)),
        child: Image.asset(
          "assets/${_currentList?[index].icon}",
          width: 45,
          height: 45,
        ),
      );
    }
    return Container();
  }

  ///create listview items
  Widget buildListViewItem(BuildContext context, int index) {
    return InkWell(
      onTap: () {
        _onListViewItemClick(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: _buildListViewItemIcon(index),
          ),
          Container(
              margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Text(
                _currentList?[index] == null ? "" : PanelDisplay.getDisplayName(_currentList![index])!,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
              )),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
                color: _isShowPoint(_currentList?[index]) ? Colors.blue : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(3))),
          ),
        ],
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

  void onSubTitleBackBtnClick() {
    if (_currentList != null) {
      TEUIProperty titleProperty = _getParentProperty();
      TEUIProperty? parentUIProperty = titleProperty.parentUIProperty;
      if (parentUIProperty == null || parentUIProperty.parentUIProperty == null) {
        for (TEUIProperty property in _panelViewData!) {
          if (property.uiState == UIState.CHECKED_AND_IN_USE) {
            setState(() {
              _isShowSubTitleLayout = false;
              _currentList = property.propertyList;
            });
            _scrollController.jumpTo(_listViewOffset.removeLast());
            _setSliderState(null);
            return;
          }
        }
      } else {
        setState(() {
          _isShowSubTitleLayout = true;
          _subTitleName = PanelDisplay.getDisplayName(parentUIProperty)!;
          _currentList = parentUIProperty.propertyList;
        });
      }
      _scrollController.jumpTo(_listViewOffset.removeLast());
      _setSliderState(null);
    }
  }

  TEUIProperty _getParentProperty() {
    TEUIProperty uiProperty = _currentList![0];
    return uiProperty.parentUIProperty!;
  }

  void _onMainTitleItemClick(TEUIProperty uiProperty) {
    for (TEUIProperty property in _panelViewData!) {
      if (property.uiState == UIState.CHECKED_AND_IN_USE) {
        typeDataListViewOffset[_getTypeDataListViewOffsetKey(property)] = _scrollController.offset;
        break;
      }
    }
    _tePanelDataProducer.onTabItemClick(uiProperty);
    setState(() {
      _isShowSubTitleLayout = false;
      _currentList = uiProperty.propertyList;
    });
    double? offset = typeDataListViewOffset[_getTypeDataListViewOffsetKey(uiProperty)];
    _scrollController.jumpTo(offset ?? 0);
    _setSliderState(null);
  }

  /// item click
  void _onListViewItemClick(int index) {
    TEUIProperty uiProperty = _currentList![index];
    if (uiProperty.sdkParam?.extraInfo?[TESDKParam.EXTRA_INFO_KEY_SEG_TYPE] == TESDKParam.EXTRA_INFO_SEG_TYPE_GREEN ||
        uiProperty.sdkParam?.extraInfo?[TESDKParam.EXTRA_INFO_KEY_SEG_TYPE] == TESDKParam.EXTRA_INFO_SEG_TYPE_CUSTOM) {
      widget._beautyPanelViewCallBack?.onClickCustomSeg(uiProperty);
      return;
    }
    List<TEUIProperty>? resultList = _tePanelDataProducer.onItemClick(uiProperty);
    if (resultList != null && resultList.isNotEmpty) {
      _listViewOffset.add(_scrollController.offset);

      _currentSDKParam = null;
      setState(() {
        _currentList = resultList;
        _isShowSubTitleLayout = true;
        _subTitleName = PanelDisplay.getDisplayName(uiProperty)!;
        _panelViewData = _panelViewData;
      });
      _scrollController.jumpTo(0);
    } else {
      _currentSDKParam = uiProperty.sdkParam;
      if (uiProperty.isNoneItem()) {
        List<TESDKParam>? closeEffectList = _tePanelDataProducer.getCloseEffectItems(uiProperty);
        if (closeEffectList != null) {
          widget._beautyPanelViewCallBack?.onUpdateEffectList(closeEffectList);
        }
      } else {
        if (_currentSDKParam != null) {
          widget._beautyPanelViewCallBack?.onUpdateEffect(_currentSDKParam!);
        }
      }
    }
    _setSliderState(_currentSDKParam);
  }

  void _setSliderState(TESDKParam? sdkParam) {
    bool isShowSlider = false;
    /// Controls the visibility of the slider type layout (makeup/lut toggle buttons)
    bool isShowSliderTypeLayout = false;
    EffectValueType valueType = EffectValueType.RANGE_0_0;
    if (sdkParam != null) {
      isShowSliderTypeLayout = (sdkParam.effectName == TEffectName.EFFECT_MAKEUP || sdkParam.effectName == TEffectName.EFFECT_LIGHT_MAKEUP) &&
          (sdkParam.extraInfo?[BeautyPanelView.MAKEUP_LUT_STRENGTH_KEY] != null);
      valueType = EffectValueType.getEffectValueType(sdkParam);
      if (valueType == EffectValueType.RANGE_0_0) {
        isShowSlider = false;
      } else {
        isShowSlider = true;
      }
    }
    var makeupLutStrengthDouble = 0.0;
    if (isShowSlider && isShowSliderTypeLayout && _isSelectedLut()) {
      String? makeupLutStrength = sdkParam!.extraInfo![BeautyPanelView.MAKEUP_LUT_STRENGTH_KEY];
      if (makeupLutStrength != null) {
        makeupLutStrengthDouble = double.parse(makeupLutStrength);
      } else {
        sdkParam.extraInfo ??= <String, String>{};
      }
    }
    setState(() {
      _isShowSliderTypeLayout = isShowSliderTypeLayout;
      _isShowSlider = isShowSlider;
      if (isShowSlider) {
        if (_isShowSliderTypeLayout && _isSelectedLut()) {
          _currentProgress = makeupLutStrengthDouble;
          _progressMax = 100;
          _progressMin = 0;
        } else {
          _currentProgress = sdkParam!.effectValue.toDouble();
          _progressMax = valueType.max.toDouble();
          _progressMin = valueType.min.toDouble();
        }
      }
    });
  }

  bool _isSelectedLut() {
    return _selectedList[1];
  }

  void checkPanelViewItem(TEUIProperty uiProperty) {
    _tePanelDataProducer.onItemClick(uiProperty);
    setState(() {});
    _setSliderState(uiProperty.sdkParam);
  }

  String _getTypeDataListViewOffsetKey(TEUIProperty property) {
    return "${property.displayName}${property.displayNameEn}";
  }

  void _clickItem(TESDKParam sdkParam) {}
}
