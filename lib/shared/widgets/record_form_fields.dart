import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'structural_border_label.dart';

class RecordFormPanel extends StatelessWidget {
  const RecordFormPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3A40),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF66737A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class RecordTextField extends StatelessWidget {
  const RecordTextField({
    super.key,
    required this.label,
    this.helperText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final String? helperText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String? Function(String? value)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (helperText != null) ...[
          Text(
            helperText!,
            style: const TextStyle(
              color: Color(0xFFD4DDE1),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              validator: validator,
              onChanged: onChanged,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (value) {
                if (nextFocusNode != null) {
                  nextFocusNode!.requestFocus();
                  return;
                }
                onFieldSubmitted?.call(value);
              },
              style: const TextStyle(
                color: Color(0xFF101416),
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                errorStyle: const TextStyle(
                  color: Color(0xFFFFD4D4),
                  fontWeight: FontWeight.w800,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFF879299)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8EA),
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(
                    color: Color(0xFFD32222),
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(
                    color: Color(0xFFD32222),
                    width: 2,
                  ),
                ),
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
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RecordDropdownField<T> extends StatelessWidget {
  const RecordDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFAAB4B9),
            contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFF879299)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFFE2E8EA), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
          ),
          dropdownColor: const Color(0xFFAAB4B9),
          iconEnabledColor: const Color(0xFF101416),
          style: const TextStyle(
            color: Color(0xFF101416),
            fontWeight: FontWeight.w800,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
        Positioned(
          left: 8,
          right: 8,
          top: -8,
          child: StructuralBorderLabel(
            label: label,
            alignment: Alignment.centerLeft,
            maxWidthFactor: 0.48,
          ),
        ),
      ],
    );
  }
}

class RecordSectionTitle extends StatelessWidget {
  const RecordSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFE2E8EA),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
