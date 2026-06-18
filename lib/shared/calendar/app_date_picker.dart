import 'package:flutter/material.dart';

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    builder: (context, child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD166),
          surface: Color(0xFF1F2528),
        ),
      ),
      child: child!,
    ),
  );
}

String appShortDateLabel(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
