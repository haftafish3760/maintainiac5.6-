import 'package:flutter/material.dart';

import 'odometer_entry_sheet.dart';

Future<bool> openOdometerEntry(
  BuildContext context, {
  String title = 'Update Odometer',
  String saveLabel = 'Save Reading',
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (_) => OdometerEntrySheet(title: title, saveLabel: saveLabel),
  );
  return saved ?? false;
}
