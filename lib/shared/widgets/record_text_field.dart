import 'package:flutter/material.dart';

import 'structural_border_label.dart';

class RecordTextField extends StatelessWidget {
  const RecordTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            color: Color(0xFF101416),
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFAAB4B9),
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF879299)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE2E8EA), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          top: -8,
          child: StructuralBorderLabel(
            label: label,
            alignment: Alignment.centerLeft,
            maxWidthFactor: 0.48,
            backgroundColor: const Color(0xFF11181B),
            textColor: const Color(0xFFF0F4F2),
          ),
        ),
      ],
    );
  }
}
