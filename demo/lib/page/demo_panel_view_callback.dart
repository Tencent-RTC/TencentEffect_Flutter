import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/uikit/callback/te_default_panel_view_callback.dart';
import 'package:tencent_effect_flutter/uikit/model/te_ui_property.dart';
import 'package:tencent_effect_flutter/uikit/view/te_beauty_panel_view.dart';
import 'package:tencent_effect_flutter_demo/view/common_dialog.dart';


class DemoPanelViewCallBack extends TEDefaultPanelViewCallBack {
  final bool _pickImg = true;


 

  @override
  Future<void> onClickCustomSeg(TEUIProperty uiProperty) async {
    if (uiProperty.sdkParam?.extraInfo == null) {
      return;
    }
    try {
      final ImagePicker _picker = ImagePicker();
      // Pick an image
      XFile? xFile = _pickImg
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickVideo(source: ImageSource.gallery);
      if (xFile == null) {
        return;
      }
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_TYPE] =
          _pickImg
              ? TESDKParam.EXTRA_INFO_BG_TYPE_IMG
              : TESDKParam.EXTRA_INFO_BG_TYPE_VIDEO;
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_PATH] =
          xFile.path;
      onUpdateEffect(uiProperty.sdkParam!);
      panelController.checkPanelViewItem(uiProperty);
    } catch (e) {
      debugPrint("Pick image/video failed: $e");
    }
  }



  @override
  void onDefaultEffectList(List<TESDKParam> paramList) {
    super.onDefaultEffectList(paramList);

  }


  @override
  void onRevertBtnClick(BuildContext context, TEBeautyPanelView panelView) {
    CommonDialog.show(
        context: context,
        title: "重置美颜效果？",
        content: "重置后所有效果将会恢复至默认状态，且重置操作不可撤回。",
        leftText: "取消",
        rightText: "重置",
        onLeftPress: null,
        onRightPress: () {
          revertEffectAndPanelView(context);
          Navigator.of(context).pop(true);
        });
  }
}
