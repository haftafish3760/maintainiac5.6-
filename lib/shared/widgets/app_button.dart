import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonTone { general, commit, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.general,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final Widget? icon;
  final bool compact;

  Color get _color {
    return switch (tone) {
      AppButtonTone.general => AppColors.blue,
      AppButtonTone.commit => AppColors.green,
      AppButtonTone.destructive => AppColors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final radius = BorderRadius.circular(5);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 15,
            ),
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 42 : (44 * textScale).clamp(44, 58),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _color,
            disabledBackgroundColor: AppColors.panelLight.withValues(
              alpha: 0.55,
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 9 : 12,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
