import 'package:flutter/material.dart';

import 'app_action_colors.dart';

class AppButtonStyles {
  const AppButtonStyles._();

  static const flowButtonMinSize = Size(220, 48);
  static const flowButtonPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
  );
  static const flowButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );

  static ButtonStyle flow({
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: const Color(0xFF516064),
      disabledForegroundColor: const Color(0xFFC9D1D4),
      minimumSize: flowButtonMinSize,
      padding: flowButtonPadding,
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: flowButtonShape,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
    );
  }

  static ButtonStyle get primaryFlow {
    return flow(backgroundColor: AppActionColors.primary);
  }

  static ButtonStyle get positiveFlow {
    return flow(backgroundColor: AppActionColors.positive);
  }

  static ButtonStyle get dangerFlow {
    return flow(backgroundColor: AppActionColors.danger);
  }
}
