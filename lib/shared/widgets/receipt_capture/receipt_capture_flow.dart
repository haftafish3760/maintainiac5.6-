import 'dart:io';

import 'package:flutter/material.dart';

import '../../navigation/app_page_routes.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_camera_permission.dart';
import 'receipt_capture_models.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_native_capture_staging.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_camera_service.dart';
import 'receipt_ocr_service.dart';
import 'receipt_photo_path_identity.dart';
import 'receipt_photo_review_screen.dart';
import 'receipt_proof_storage.dart';

part 'receipt_capture_flow_models.dart';
part 'receipt_capture_flow_recovery.dart';
part 'receipt_capture_flow_recovery_results.dart';
part 'receipt_capture_flow_helpers.dart';
part 'receipt_capture_flow_handoff_signals.dart';
part 'receipt_capture_flow_handoff_risks.dart';
part 'receipt_capture_flow_continuation_signals.dart';
part 'receipt_capture_flow_native_signals.dart';
part 'receipt_capture_flow_ocr_helpers.dart';
part 'receipt_capture_flow_attachment_helpers.dart';
part 'receipt_capture_flow_capture_and_review.dart';
part 'receipt_capture_flow_review_result.dart';

class ReceiptCaptureFlow {
  const ReceiptCaptureFlow({
    ReceiptNativeCameraService nativeCameraService =
        const ReceiptNativeCameraService(),
    ReceiptNativeCaptureStaging staging = const ReceiptNativeCaptureStaging(),
  }) : _nativeCameraService = nativeCameraService,
       _staging = staging;

  final ReceiptNativeCameraService _nativeCameraService;
  final ReceiptNativeCaptureStaging _staging;

  Future<ReceiptCaptureFlowResult> captureAndReview(
    BuildContext context, {
    ReceiptCaptureFlowOptions options = const ReceiptCaptureFlowOptions(),
  }) async {
    return _captureAndReview(this, context, options: options);
  }

  static Future<ReceiptOcrResult> readTextFromReviewResult(
    ReceiptPhotoReviewResult result, {
    ReceiptDeviceCapability deviceCapability =
        const ReceiptDeviceCapability.standard(),
    ReceiptCaptureFlowModule module = ReceiptCaptureFlowModule.shared,
  }) {
    return ReceiptOcrService.forDevice(
      deviceCapability,
    ).recognizeTextFromAttachments(attachmentsFromReviewResult(result, module));
  }

  static List<ReceiptAttachmentRecord> attachmentsFromReviewResult(
    ReceiptPhotoReviewResult result,
    ReceiptCaptureFlowModule module,
  ) {
    return _attachmentsFromReviewResult(result, module);
  }
}
