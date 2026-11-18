import 'package:flutter/material.dart';
import '../../l10n/te_panel_localizations.dart';

/// 面板右上角的"还原"按钮。
///
/// 布局对齐 Android `te_beauty_panel_view_layout.xml` 中的
/// `te_panel_view_top_right_layout`：一个水平方向、垂直居中的容器，依次排列
/// 竖向分割线（右外边距 3dp）、25dp 图标、14sp 文案，各元素之间没有额外间距。
/// 容器宽度由外部固定为 75dp，内容左对齐、右侧留白。
class RevertButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// 竖向分割线的高度。对应 Android 分割线 `height=match_parent` 且上下各 10dp
  /// 外边距，在 40dp 高的标题区内实际高度为 20。
  static const double _dividerHeight = 20;
  static const double _dividerWidth = 1;
  static const double _dividerMarginRight = 3;
  static const double _iconSize = 25;
  static const double _textSize = 14;
  static const Color _dividerColor = Color(0x19FFFFFF);
  static const Color _textColor = Color(0x99FFFFFF);

  const RevertButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _dividerWidth,
              height: _dividerHeight,
              margin: const EdgeInsets.only(right: _dividerMarginRight),
              color: _dividerColor,
            ),
            Image.asset(
              'assets/icon/te_beauty_panel_view_revert_icon.png',
              package: 'tencent_effect_flutter',
              width: _iconSize,
              height: _iconSize,
            ),
            Flexible(
              child: Text(
                TEPanelLocalizations.of(context).revert,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: const TextStyle(color: _textColor, fontSize: _textSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
