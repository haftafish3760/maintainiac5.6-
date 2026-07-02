import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_recovery_handoff_fixture.dart';

void main() {
  test('native recovery metadata aggregates privacy-safe handoff counts', () {
    final result = buildNativeRecoveryReviewResult();

    expect(result.editedPhotoActionCounts, {'manual_crop': 1});
    expect(result.editedPhotoSourceSelectionCounts, {'manual_crop': 1});
    expect(result.editedPhotoReplacedOriginalCounts, {'manual_crop': 1});
    expect(result.nativeRecoveryFreshnessCounts, {'stale': 2});
    expect(result.nativeRecoveryStorageStatusCounts, {
      'partial_photos_available': 2,
    });
    expect(
      result.nativeCaptureSourcePolicyCounts,
      containsPair('native_recovery', 2),
    );
    expect(
      result.nativeCaptureSourcePolicyCounts,
      containsPair('storage_saver_native', 2),
    );
    expect(
      result.nativeCaptureSourcePolicyCounts,
      containsPair('older_phone_native', 2),
    );
    expect(result.nativeCaptureSourcePolicyOutcome, 'native_recovery');
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('native_recovery_freshness_stale', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('native_recovery_storage_partial_photos_available', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('native_capture_source_native_recovery', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('native_capture_surface_maintainiac_native_android', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'native_capture_surface_verified_maintainiac_custom_surface_verified',
        2,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'native_capture_identity_maintainiac_in_app_receipt_camera',
        2,
      ),
    );
    expect(result.nativeReceiptCameraSurfaceActualCounts, {
      'maintainiac_native_android': 2,
    });
    expect(result.nativeReceiptCameraSurfaceVerificationCounts, {
      'maintainiac_custom_surface_verified': 2,
    });
    expect(result.nativeCameraIdentityCounts, {
      'maintainiac_in_app_receipt_camera': 2,
    });
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('review_photo_edit_manual_crop', 1),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('review_photo_edit_source_selected_manual_crop', 1),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('review_photo_edit_replaced_original_manual_crop', 1),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'receipt_brain_release_ship_lean_base_and_defer_optional_receipt_packs',
        2,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair(
        'receipt_brain_install_base_app_only_optional_cloud_assist',
        2,
      ),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_brain_storage_critical', 2),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_brain_local_ocr_lean_local_ocr', 2),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('reviewPhotoEditActionCounts', {'manual_crop': 1}),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('reviewPhotoEditSourceSelectionCounts', {'manual_crop': 1}),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('reviewPhotoEditReplacedOriginalCounts', {'manual_crop': 1}),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nativeRecoveryFreshnessCounts', {'stale': 2}),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nativeRecoveryStorageStatusCounts', {
        'partial_photos_available': 2,
      }),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nativeCaptureSourcePolicyCounts',
        result.nativeCaptureSourcePolicyCounts,
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nativeCaptureSourcePolicyOutcome', 'native_recovery'),
    );
  });
}
