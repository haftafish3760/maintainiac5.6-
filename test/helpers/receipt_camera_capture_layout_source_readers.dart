import 'dart:io';

Future<String> readReceiptDartLibraryWithParts(String entryPath) async {
  final entryFile = File(entryPath);
  final entry = await entryFile.readAsString();
  final directory = entryFile.parent.path;
  final contents = <String>[entry];
  final partPattern = RegExp(r"^part '([^']+)';", multiLine: true);
  for (final match in partPattern.allMatches(entry)) {
    final partPath = '$directory/${match.group(1)}';
    contents.add(await File(partPath).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptCaptureModelsSource() {
  return readReceiptDartLibraryWithParts(
    'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
  );
}

Future<String> readReceiptCaptureFlowSource() {
  return readReceiptDartLibraryWithParts(
    'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
  );
}

Future<String> readReceiptPhotoReviewControlsUnit() async {
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

Future<String> readAndroidReceiptCameraUnit() async {
  final directory = Directory('android/app/src/main/kotlin/com/maintainiac');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last;
            return name.startsWith('ReceiptCamera') && name.endsWith('.kt');
          })
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final contents = <String>[];
  for (final file in files) {
    contents.add(await file.readAsString());
  }
  return contents.join('\n');
}

Future<String> readIosReceiptCameraUnit() async {
  final directory = Directory('ios/Runner');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last;
            return name.startsWith('ReceiptCameraViewController') &&
                name.endsWith('.swift');
          })
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final contents = <String>[];
  for (final file in files) {
    contents.add(await file.readAsString());
  }
  return contents.join('\n');
}

Future<String> readExpenseReceiptEntrySource() {
  return readReceiptDartLibraryWithParts(
    'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
  );
}

Future<String> readReceiptPhotoReviewSaveActionsSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_feedback.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_save_models.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptAttachmentImportActionsSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptAttachmentPanelSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_recovery_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart',
    'lib/shared/widgets/receipt_capture/receipt_interrupted_capture_banner.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptNativeCameraContractSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_session.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_policy.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_descriptors.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_session_config.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptPhotoReviewScreenSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_photo_surface.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_async_work.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_widgets.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_preview.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> readReceiptNativeCaptureStagingSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_diagnostics.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_record.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_manifest_helpers.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_manifest_writer.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_recovery_index.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_diagnostics.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_keys.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_cleanup.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}
