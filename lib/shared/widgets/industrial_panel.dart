import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IndustrialPanel extends StatelessWidget {
  const IndustrialPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF61675F), Color(0xFF363C38), Color(0xFF4A504A)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF8B9089), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x55FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BorderLabel extends StatelessWidget {
  const BorderLabel({
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    super.key,
  });

  final String label;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.18);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.label,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.label,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9A9D94), width: 1.2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: padding,
      ),
      child: child,
    );
  }
}
