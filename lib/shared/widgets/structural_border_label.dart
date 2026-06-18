import 'package:flutter/material.dart';

const _labelScale = 0.03;
const _minLabelFontSize = 9.5;
const _maxLabelFontSize = 11.25;
const _labelPaddingScale = 0.02;
const _minHorizontalPadding = 5.0;
const _maxHorizontalPadding = 8.0;

class StructuralBorderLabel extends StatelessWidget {
  const StructuralBorderLabel({
    super.key,
    required this.label,
    this.maxWidthFactor = 0.74,
    this.alignment = Alignment.topCenter,
    this.backgroundColor = const Color(0xFFAAB4B9),
    this.textColor = const Color(0xFF101416),
  });

  final String label;
  final double maxWidthFactor;
  final Alignment alignment;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final fontSize = (availableWidth * _labelScale).clamp(
          _minLabelFontSize,
          _maxLabelFontSize,
        );
        final horizontalPadding = (availableWidth * _labelPaddingScale).clamp(
          _minHorizontalPadding,
          _maxHorizontalPadding,
        );

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: availableWidth * maxWidthFactor,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF101416), width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 1.5,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
