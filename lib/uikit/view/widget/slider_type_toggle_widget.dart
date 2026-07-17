import 'package:flutter/material.dart';
import '../../l10n/te_panel_localizations.dart';

class SliderTypeToggleWidget extends StatelessWidget {
  final List<bool> selectedList;
  final Function(int) onPressed;

  const SliderTypeToggleWidget({
    super.key,
    required this.selectedList,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 95,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xA6FFFFFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem(
              context,
              TEPanelLocalizations.of(context).makeup,
              selectedList[0],
              0,
            ),
          ),
          Expanded(
            child: _buildItem(
              context,
              TEPanelLocalizations.of(context).lut,
              selectedList[1],
              1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String text, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => onPressed(index),
      child: Container(
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xCC000000) : const Color(0x4D000000),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
