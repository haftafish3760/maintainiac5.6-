import 'dart:io';

class AssistedReviewSourceFixture {
  const AssistedReviewSourceFixture({
    required this.entryScreen,
    required this.entryScaffold,
    required this.stateActions,
    required this.lineModels,
    required this.lineEditorActions,
    required this.lineFields,
    required this.attachmentPanel,
    required this.attachmentOcr,
    required this.importActions,
    required this.parseReview,
    required this.parseModels,
    required this.parseLogic,
    required this.recap,
    required this.photoControls,
    required this.photoPreviewControls,
    required this.receiptModels,
    required this.ocrService,
    required this.telemetry,
    required this.saveActions,
    required this.totals,
  });

  final String entryScreen;
  final String entryScaffold;
  final String stateActions;
  final String lineModels;
  final String lineEditorActions;
  final String lineFields;
  final String attachmentPanel;
  final String attachmentOcr;
  final String importActions;
  final String parseReview;
  final String parseModels;
  final String parseLogic;
  final String recap;
  final String photoControls;
  final String photoPreviewControls;
  final String receiptModels;
  final String ocrService;
  final String telemetry;
  final String saveActions;
  final String totals;
}

Future<AssistedReviewSourceFixture> readAssistedReviewSourceFixture() async {
  final entryScreen = await _readDartLibraryWithParts(
    'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
  );
  final entryScaffold = await File(
    'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
  ).readAsString();
  final stateActions = await _readExpenseReceiptEntryStateActionsUnit();
  final lineModels =
      await File(
        'lib/screens/expenses/entry/expense_receipt_line_support.dart',
      ).readAsString() +
      await File(
        'lib/screens/expenses/entry/expense_receipt_line_models.dart',
      ).readAsString() +
      await File(
        'lib/screens/expenses/entry/expense_receipt_line_labels.dart',
      ).readAsString() +
      await File(
        'lib/screens/expenses/entry/expense_receipt_line_computed_fields.dart',
      ).readAsString();
  final lineEditorActions = await File(
    'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
  ).readAsString();
  final lineEditorOdometerDialogs = await File(
    'lib/screens/expenses/entry/expense_receipt_line_editor_odometer_dialogs.dart',
  ).readAsString();
  final lineFields = await File(
    'lib/screens/expenses/entry/expense_receipt_line_fields.dart',
  ).readAsString();
  final attachmentPanel = await _readDartLibraryWithParts(
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
  );
  final attachmentOcr =
      await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
      ).readAsString() +
      await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_recovery_advice.dart',
      ).readAsString();
  final importActions = [
    attachmentPanel,
    await _readDartLibraryWithParts(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
    ),
  ].join('\n');
  final parseReview = await _readExpenseReceiptParseReviewUnit();
  final parseModels = await _readDartLibraryWithParts(
    'lib/screens/expenses/data/expense_receipt_parser.dart',
  );
  final recap = await _readExpenseReceiptRecapUnit();
  final photoControls = await _readReceiptPhotoControlsUnit();
  final photoPreviewControls = await _readReceiptPhotoPreviewUnit();
  final receiptModels = await _readDartLibraryWithParts(
    'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
  );
  final ocrService = await _readReceiptOcrServiceUnit();
  final telemetry = await _readDartLibraryWithParts(
    'lib/screens/expenses/data/expense_screen_telemetry.dart',
  );
  final saveActions = await _readExpenseReceiptSaveActionUnit();
  final totals = await File(
    'lib/screens/expenses/entry/expense_receipt_totals.dart',
  ).readAsString();

  return AssistedReviewSourceFixture(
    entryScreen: entryScreen,
    entryScaffold: entryScaffold,
    stateActions: stateActions,
    lineModels: lineModels,
    lineEditorActions: [
      lineEditorActions,
      lineEditorOdometerDialogs,
    ].join('\n'),
    lineFields: lineFields,
    attachmentPanel: attachmentPanel,
    attachmentOcr: attachmentOcr,
    importActions: importActions,
    parseReview: parseReview,
    parseModels: parseModels,
    parseLogic: parseModels,
    recap: recap,
    photoControls: photoControls,
    photoPreviewControls: photoPreviewControls,
    receiptModels: receiptModels,
    ocrService: ocrService,
    telemetry: telemetry,
    saveActions: saveActions,
    totals: totals,
  );
}

Future<String> _readDartLibraryWithParts(String entryPath) async {
  final entryFile = File(entryPath);
  final entry = await entryFile.readAsString();
  final directory = entryFile.parent.path;
  final contents = <String>[entry];
  final partPattern = RegExp(r"^part '([^']+)';", multiLine: true);
  for (final match in partPattern.allMatches(entry)) {
    contents.add(await File('$directory/${match.group(1)}').readAsString());
  }
  return contents.join('\n');
}

Future<String> _readExpenseReceiptEntryStateActionsUnit() async {
  final paths = [
    'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_split_percent_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_draft_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_imported_text_parse_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_telemetry_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_parser_telemetry_metadata.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_parse_apply_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_entry_split_percent_button.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readExpenseReceiptParseReviewUnit() async {
  final paths = [
    'lib/screens/expenses/entry/expense_receipt_parse_review.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_metrics.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_intro_panel.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_bottom_section_alert.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_guidance.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_guidance_factory.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_guidance_detail_text.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_guidance_fields.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_instruction_widgets.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_handoff_panel.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_photo_recovery.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_details.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_ocr_review_row.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_ocr_photo_helpers.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_ocr_action_helpers.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_ocr_readiness_helpers.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_ocr_review_helpers.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_line_evidence_panel.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_line_evidence_controls.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_misc_widgets.dart',
    'lib/screens/expenses/entry/expense_receipt_parse_review_text_helpers.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptOcrServiceUnit() async {
  final receiptCaptureDir = Directory('lib/shared/widgets/receipt_capture');
  final files =
      receiptCaptureDir
          .listSync()
          .whereType<File>()
          .where((file) {
            final path = file.path;
            return path.endsWith('/receipt_ocr_service.dart') ||
                RegExp(r'/receipt_ocr_.*\.dart$').hasMatch(path);
          })
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final contents = <String>[];
  for (final file in files) {
    contents.add(await file.readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptPhotoPreviewUnit() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptPhotoControlsUnit() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readExpenseReceiptSaveActionUnit() async {
  final paths = [
    'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    'lib/screens/expenses/entry/expense_receipt_save_readiness_helpers.dart',
    'lib/screens/expenses/entry/expense_receipt_save_readiness_dialog.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readExpenseReceiptRecapUnit() async {
  final paths = [
    'lib/screens/expenses/entry/expense_receipt_recap.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_classification.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_classification_guidance.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_whole_use_button.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_paper.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_allocation_controls.dart',
    'lib/screens/expenses/entry/expense_receipt_recap_line_controls.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}
