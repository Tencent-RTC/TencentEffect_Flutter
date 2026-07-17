import 'package:flutter/material.dart';

/// 对比按钮，仅包含一个图标，支持手指按下和抬起事件
/// 按下时通知底层美颜SDK暂停处理，抬起时通知恢复处理
class CompareButton extends StatelessWidget {
  /// 手指按下时回调
  final VoidCallback? onPressDown;

  /// 手指抬起时回调
  final VoidCallback? onPressUp;

  const CompareButton({Key? key, this.onPressDown, this.onPressUp})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressDown?.call(),
      onTapUp: (_) => onPressUp?.call(),
      onTapCancel: () => onPressUp?.call(),
      child: Image.asset(
          'assets/icon/te_beauty_panel_view_compare_icon.png',
          package: 'tencent_effect_flutter',
          width: 35,
          height: 35,
        ),
    );
  }
}
