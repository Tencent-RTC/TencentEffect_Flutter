import 'package:flutter/material.dart';
import '../../../uikit/view/widget/slider_type_toggle_widget.dart';


class BeautyPanelSlider extends StatelessWidget {
  final bool isShowSliderTypeLayout;
  final List<bool> selectedList;
  final Function(int) onSliderTypeClick;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const BeautyPanelSlider({
    Key? key,
    required this.isShowSliderTypeLayout,
    required this.selectedList,
    required this.onSliderTypeClick,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isShowSliderTypeLayout
            ? SliderTypeToggleWidget(
                selectedList: selectedList,
                onPressed: onSliderTypeClick,
              )
            : Container(),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.0,
              activeTrackColor: const Color(0xFFFFFFFF),
              inactiveTrackColor: const Color(0xA6FFFFFF),
              thumbColor: const Color(0xFFFFFFFF),
              thumbShape: const _ThumbWithBorder(
                outerRadius: 7.5,
                innerRadius: 4.5,
                outerColor: Colors.white,
                innerColor: Color(0xFFFFFFFF),
              ),
              overlayColor: const Color(0x33FFFFFF),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackShape: const _CustomTrackShape(
                activeTrackHeight: 2.0,
                inactiveTrackHeight: 2.0,
              ),
              valueIndicatorColor: const Color(0xFFFFFFFF),
              valueIndicatorShape: const _PillSliderValueIndicatorShape(),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
              showValueIndicator: ShowValueIndicator.always,
            ),
            child: Slider(
              value: value,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              min: min,
              max: max,
              label: '${value.round()}',
            ),
          ),
        )
      ],
    );
  }
}

/// Custom thumb shape: white outer circle with blue inner circle,
/// matching Android's te_beauty_seekbar_thumb (15dp outer, 3dp inset for inner).
class _ThumbWithBorder extends SliderComponentShape {
  final double outerRadius;
  final double innerRadius;
  final Color outerColor;
  final Color innerColor;

  const _ThumbWithBorder({
    required this.outerRadius,
    required this.innerRadius,
    required this.outerColor,
    required this.innerColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(outerRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw outer white circle
    final Paint outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Draw inner blue circle
    final Paint innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }
}

/// Custom track shape that allows different heights for active and inactive tracks.
/// Active track (blue progress) can be thinner, while inactive track (white background) is thicker.
class _CustomTrackShape extends SliderTrackShape {
  final double activeTrackHeight;
  final double inactiveTrackHeight;

  const _CustomTrackShape({
    required this.activeTrackHeight,
    required this.inactiveTrackHeight,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx + 12;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 24;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    final Canvas canvas = context.canvas;
    final double centerY = trackRect.center.dy;

    // Draw inactive track (white background) - full width, thicker
    final double inactiveTop = centerY - inactiveTrackHeight / 2;
    final RRect inactiveRRect = RRect.fromLTRBR(
      trackRect.left,
      inactiveTop,
      trackRect.right,
      inactiveTop + inactiveTrackHeight,
      Radius.circular(inactiveTrackHeight / 2),
    );
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white;
    canvas.drawRRect(inactiveRRect, inactivePaint);

    // Draw active track (blue progress) - from left to thumb, thinner
    final double activeTop = centerY - activeTrackHeight / 2;
    final RRect activeRRect = RRect.fromLTRBR(
      trackRect.left,
      activeTop,
      thumbCenter.dx,
      activeTop + activeTrackHeight,
      Radius.circular(activeTrackHeight / 2),
    );
    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? const Color(0xFF006EFF);
    canvas.drawRRect(activeRRect, activePaint);
  }
}

/// Custom pill-shaped value indicator with no bottom arrow/tip,
/// matching Android's `te_beauty_isb_indicator` (rounded_rectangle, arrow hidden).
///
/// Android layout:
/// - background: white (`#FFFFFFFF`), 20dp corner radius (capsule shape)
/// - TextView padding: horizontal 8dp, vertical 4dp, text 10sp black
/// - ArrowView is set to View.GONE, so no triangle tip
/// - Fixed width 33dp (INDICATOR_FIXED_WIDTH_DP), so the bubble does not
///   resize while the value changes from 0 to 100.
class _PillSliderValueIndicatorShape extends SliderComponentShape {
  const _PillSliderValueIndicatorShape();

  /// Fixed width that fits the widest label "100" (three digits), matching
  /// Android's INDICATOR_FIXED_WIDTH_DP = 33.
  static const double _fixedWidth = 33.0;

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    assert(labelPainter != null);
    return Size(
      _fixedWidth,
      labelPainter!.height + 8.0,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final double scale = activationAnimation.value;
    if (scale == 0.0) {
      return;
    }

    final double width = _fixedWidth;
    final double height = labelPainter.height + 8.0;

    // Position bubble above the thumb. Unscaled gap = 10 (so at scale=1,
    // bubble bottom sits ~10px above thumb center, leaving room for the 7.5px thumb).
    final double bubbleCenterY = center.dy - height / 2 - 10.0;

    final Rect rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );

    // Capsule shape: corner radius = height / 2
    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(height / 2),
    );

    final Paint fillPaint = Paint()
      ..color = sliderTheme.valueIndicatorColor ?? const Color(0xFFFFFFFF);

    canvas.save();
    canvas.translate(center.dx, bubbleCenterY);
    canvas.scale(scale, scale);
    canvas.drawRRect(rRect, fillPaint);

    // Label is already styled by sliderTheme.valueIndicatorTextStyle
    // (black, 10sp). Center it inside the pill.
    final Offset textOffset = Offset(
      -labelPainter.width / 2,
      -labelPainter.height / 2,
    );
    labelPainter.paint(canvas, textOffset);
    canvas.restore();
  }
}
