import 'package:flutter/material.dart';

class MaintenanceFormSurface extends StatelessWidget {
  const MaintenanceFormSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A1E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF6F7C82), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
