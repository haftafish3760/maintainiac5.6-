import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('readability visible health requires continuous focus evidence', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness|edge_guide',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'nativeControlReadinessSummary': 'ready',
          'tapFocusControlExpected': false,
          'continuousFocusExpected': false,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_readability_guides_blur_glare_light_edges_and_text_size',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'continuous_focus_missing');
    expect(
      result.nativeCameraUiHealthCounts.containsKey(
        'readability_guidance_visible_missing',
      ),
      isFalse,
    );
    expect(
      result.nativeCameraUiHealthCounts.containsKey(
        'readability_guidance_visible',
      ),
      isFalse,
    );
  });
}
