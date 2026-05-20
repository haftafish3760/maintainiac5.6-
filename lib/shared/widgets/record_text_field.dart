import 'package:flutter/material.dart';

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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
      decoration: InputDecoration(labelText: label),
    );
  }
}
