import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('receipt capture barrel exports the shared camera OCR flow', () {
    const options = ReceiptCaptureFlowOptions(
      module: ReceiptCaptureFlowModule.materialsInventory,
      forceAssistedReceiptFill: true,
      forceReviewDepth: ReceiptNativeReviewDepth.detailedLines,
    );

    expect(options.module.storageName, 'materials_inventory');
    expect(options.module.settingsArea, ReceiptCaptureArea.materialsInventory);
    expect(options.forceReviewDepth, ReceiptNativeReviewDepth.detailedLines);
    expect(ReceiptCaptureFlowStatus.accepted.name, 'accepted');
    expect(const ReceiptCaptureFlow(), isA<ReceiptCaptureFlow>());
  });

  test(
    'continuation guide carries missing-bottom context into flow options',
    () {
      final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
        previousPhotoPaths: const [
          ' /tmp/receipt-top.jpg ',
          '',
          ' /tmp/receipt-middle.jpg ',
        ],
        reasonCode: ' missing_bottom_edge_and_totals ',
        guidance: ' Add the lower receipt section. ',
      );

      final options = guide.applyTo(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.expenses,
          forceAssistedReceiptFill: true,
          forceLongReceiptMode: true,
          forceReviewDepth: ReceiptNativeReviewDepth.detailedLines,
        ),
      );

      expect(guide.hasReason, isTrue);
      expect(guide.hasGuidePhoto, isTrue);
      expect(options.module, ReceiptCaptureFlowModule.expenses);
      expect(options.forceAssistedReceiptFill, isTrue);
      expect(options.forceLongReceiptMode, isTrue);
      expect(options.forceReviewDepth, ReceiptNativeReviewDepth.detailedLines);
      expect(options.previousSectionGuidePhotoPath, '/tmp/receipt-middle.jpg');
      expect(
        options.previousSectionReasonCode,
        'missing_bottom_edge_and_totals',
      );
      expect(options.previousSectionGuidance, 'Add the lower receipt section.');
    },
  );

  test('continuation guide stays inactive without a reason code', () {
    final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const ['/tmp/receipt-top.jpg'],
      reasonCode: '   ',
      guidance: 'Ignored guidance',
    );
    const options = ReceiptCaptureFlowOptions(
      module: ReceiptCaptureFlowModule.materialsInventory,
    );

    expect(guide.hasReason, isFalse);
    expect(guide.hasGuidePhoto, isFalse);
    expect(identical(guide.applyTo(options), options), isTrue);
  });

  test('shared camera OCR flow stays module neutral', () async {
    final source = await readReceiptCaptureFlowSource();

    expect(source, contains('ReceiptNativeCameraService'));
    expect(source, contains('ReceiptOcrService'));
    expect(source, contains('ReceiptPhotoReviewScreen'));
    expect(source, contains('reviewDepth:'));
    expect(source, contains('options.forceReviewDepth'));
    expect(source, isNot(contains("screens/expenses")));
    expect(source, isNot(contains("screens/work_supplies")));
    expect(source, isNot(contains("screens/maintenance")));
  });

  test(
    'shared camera defaults inventory and maintenance to detailed review',
    () async {
      final source = await readReceiptCaptureFlowSource();

      expect(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.materialsInventory,
        ).effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.maintenanceRepair,
        ).effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.expenses,
        ).effectiveReviewDepth,
        ReceiptNativeReviewDepth.pricesOnly,
      );
      expect(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.shared,
          forceReviewDepth: ReceiptNativeReviewDepth.detailedLines,
        ).effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(source, contains('reviewDepth: options.effectiveReviewDepth'));
    },
  );

  test(
    'shared camera passes receipt review-depth intent from attachment UI',
    () async {
      final actions = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
      ).readAsString();

      expect(
        actions,
        contains(
          'forceReviewDepth: _receiptNativeReviewDepthForCurrentCapture()',
        ),
      );
      expect(actions, contains('ExpenseReceiptReviewStyle.fullItemDetails'));
      expect(actions, contains('ReceiptNativeReviewDepth.detailedLines'));
      expect(actions, contains('ReceiptNativeReviewDepth.pricesOnly'));
    },
  );

  test(
    'accepted receipt camera photos publish source and module metadata',
    () async {
      final panel =
          await File(
            'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_attachment_publish_signals.dart',
          ).readAsString();

      expect(
        panel,
        contains("sourceLabel: 'Maintainiac receipt camera review'"),
      );
      expect(panel, contains('linkedModule: _receiptAttachmentLinkedModule'));
      expect(panel, contains('ReceiptCaptureArea.expenses =>'));
      expect(panel, contains("'expenses'"));
      expect(panel, contains("'materials_inventory'"));
      expect(panel, contains("'maintenance_repair'"));
    },
  );
}
