import 'dart:io';

Future<String> readReceiptCaptureSettingsSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_runtime_settings.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
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
