import 'dart:io';

import 'receipt_camera_source_readers.dart';

class ReceiptLongGuidanceSources {
  const ReceiptLongGuidanceSources({
    required this.reviewControls,
    required this.reviewPreviewControls,
    required this.orderControls,
    required this.contextControls,
    required this.modeControls,
    required this.commonControls,
    required this.stitchControls,
    required this.reviewTopBar,
    required this.reviewActions,
    required this.captureActions,
    required this.imagePicker,
    required this.reviewScreen,
    required this.sectionLabels,
    required this.reviewSaveActions,
    required this.edgeCropper,
    required this.productStandard,
    required this.realDeviceScript,
    required this.policySource,
    required this.imageEditActions,
    required this.nativeGhostGuide,
    required this.nativeGhostShell,
  });

  final String reviewControls;
  final String reviewPreviewControls;
  final String orderControls;
  final String contextControls;
  final String modeControls;
  final String commonControls;
  final String stitchControls;
  final String reviewTopBar;
  final String reviewActions;
  final String captureActions;
  final String imagePicker;
  final String reviewScreen;
  final String sectionLabels;
  final String reviewSaveActions;
  final String edgeCropper;
  final String productStandard;
  final String realDeviceScript;
  final String policySource;
  final String imageEditActions;
  final String nativeGhostGuide;
  final String nativeGhostShell;
}

Future<ReceiptLongGuidanceSources> readReceiptLongGuidanceSources() async {
  final reviewActions = await readReceiptPhotoReviewSaveActionsSource();
  return ReceiptLongGuidanceSources(
    reviewControls: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString(),
    reviewPreviewControls:
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString(),
    orderControls:
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_thumbnail.dart',
        ).readAsString(),
    contextControls: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString(),
    modeControls: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart',
    ).readAsString(),
    commonControls: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString(),
    stitchControls:
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_readiness.dart',
        ).readAsString(),
    reviewTopBar: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString(),
    reviewActions: reviewActions,
    captureActions: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString(),
    imagePicker: await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString(),
    reviewScreen: await readReceiptPhotoReviewScreenSource(),
    sectionLabels: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString(),
    reviewSaveActions: reviewActions,
    edgeCropper: await File(
      'lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart',
    ).readAsString(),
    productStandard: await File(
      'docs/receipt_camera_ocr_product_standard.md',
    ).readAsString(),
    realDeviceScript: await File(
      'docs/receipt_real_device_test_script.md',
    ).readAsString(),
    policySource: await readDartLibraryWithParts(
      'lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart',
    ),
    imageEditActions: await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString(),
    nativeGhostGuide: await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart',
    ).readAsString(),
    nativeGhostShell: await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_ghost_guidance.dart',
    ).readAsString(),
  );
}

Future<String> readDartLibraryWithParts(String entryPath) async {
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
