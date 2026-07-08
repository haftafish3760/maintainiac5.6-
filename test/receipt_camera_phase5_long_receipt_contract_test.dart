import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
  test('long-receipt review copy keeps numbered section language', () async {
    final labels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final previewRow = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();
    final alignmentActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
    ).readAsString();

    expect(labels, contains("return 'Section \${index + 1} of \$total';"));
    expect(
      labels,
      contains(
        "return total <= 1 ? 'Add Another Photo' : 'Add Next Receipt Photo';",
      ),
    );
    expect(labels, contains("return 'Retake Section \${index + 1}';"));
    expect(
      labels,
      contains(
        "Section 1 must be the top; every next section should continue lower with 3-5 repeated readable lines.",
      ),
    );
    expect(
      previewRow,
      contains(
        'Add bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(alignmentActions, contains('Add Bottom Receipt Section'));
    expect(alignmentActions, contains('Add Next Receipt Section'));
    expect(alignmentActions, contains('Retake Section'));
  });

  test('retaking a middle section preserves slot and keeps both contexts', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['middle-new.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 1);
    expect(plan.photoPaths, const ['top.jpg', 'middle-new.jpg', 'bottom.jpg']);
    expect(plan.originalSectionNumber, 2);
    expect(plan.alignmentContext.previousPhotoPath, 'top.jpg');
    expect(plan.alignmentContext.nextPhotoPath, 'bottom.jpg');
    expect(plan.alignmentContext.hasTwoSidedContext, isTrue);
    expect(
      plan.alignmentContext.guidanceCode,
      'retake_middle_with_previous_next_context',
    );

    final diagnostics = plan.captureDiagnosticsForReplacementPaths(const [
      'middle-new.jpg',
    ]);
    expect(
      diagnostics['middle-new.jpg'],
      containsPair('receiptRetakePreservedOriginalSlot', true),
    );
    expect(
      diagnostics['middle-new.jpg'],
      containsPair('receiptRetakeOriginalSectionNumber', 2),
    );
    expect(
      diagnostics['middle-new.jpg'],
      containsPair('receiptRetakeFinalSectionNumber', 2),
    );
    expect(
      diagnostics['middle-new.jpg'],
      containsPair('receiptRetakePreviousContextSectionNumber', 1),
    );
    expect(
      diagnostics['middle-new.jpg'],
      containsPair('receiptRetakeNextContextSectionNumber', 3),
    );
  });

  test(
    'retaking top or bottom section keeps the correct ghost-guide context',
    () {
      final topPlan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const ['top-old.jpg', 'middle.jpg', 'bottom.jpg'],
        targetPhotoPath: 'top-old.jpg',
        replacementPhotoPaths: const ['top-new.jpg'],
      );
      final bottomPlan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom-old.jpg'],
        targetPhotoPath: 'bottom-old.jpg',
        replacementPhotoPaths: const ['bottom-new.jpg'],
      );

      expect(topPlan, isNotNull);
      expect(topPlan!.alignmentContext.previousPhotoPath, isNull);
      expect(topPlan.alignmentContext.nextPhotoPath, 'middle.jpg');
      expect(
        topPlan.alignmentContext.guidanceCode,
        'retake_top_with_next_context',
      );

      expect(bottomPlan, isNotNull);
      expect(bottomPlan!.alignmentContext.previousPhotoPath, 'middle.jpg');
      expect(bottomPlan.alignmentContext.nextPhotoPath, isNull);
      expect(
        bottomPlan.alignmentContext.guidanceCode,
        'retake_bottom_with_previous_context',
      );
      expect(
        bottomPlan.alignmentContext.previousSectionGuidePhotoPath,
        'middle.jpg',
      );
    },
  );

  test(
    'native session keeps long-receipt ghost guide policy for continuation and retake',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        hasRearCamera: true,
      );

      final bottomContinuation = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionReasonCode: 'missing_bottom_edge_and_totals',
      );

      expect(bottomContinuation.hasPreviousSectionGuide, isTrue);
      expect(
        bottomContinuation.previousSectionGuideReasonCode,
        'missing_bottom_edge_and_totals',
      );
      expect(
        bottomContinuation.previousSectionGhostGuidePolicy,
        'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
      );
      expect(
        bottomContinuation.previousSectionGhostGuideRepeatLineTarget,
        'repeat_3_to_5_readable_lines',
      );
      expect(
        bottomContinuation.previousSectionGhostGuideMatchTarget,
        'subtotal_total_and_final_lines',
      );
      expect(bottomContinuation.previousSectionGhostSlicePercent, 20);

      final topRetake = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-2.jpg',
        previousSectionReasonCode: 'retake_top_with_next_context',
        previousSectionGhostSourceStartFraction: 0,
        previousSectionGhostSourceHeightFraction: .20,
        previousSectionGhostOverlayTopFraction: 0,
        previousSectionGhostOverlayHeightFraction: .20,
        previousSectionGhostOpacity: .32,
      );

      expect(topRetake.hasPreviousSectionGuide, isTrue);
      expect(topRetake.previousSectionGuideUsesNextContext, isTrue);
      expect(
        topRetake.previousSectionGhostGuidePolicy,
        'next_section_top_context_ghost_at_top_repeat_3_to_5_lines',
      );
      expect(
        topRetake.previousSectionGhostGuideMatchTarget,
        'next_section_top_lines',
      );
      expect(topRetake.previousSectionGhostSlicePercent, 20);
    },
  );
}
