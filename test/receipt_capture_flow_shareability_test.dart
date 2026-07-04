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
      expect(
        options.effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(options.previousSectionGuidePhotoPath, '/tmp/receipt-middle.jpg');
      expect(
        options.previousSectionReasonCode,
        'missing_bottom_edge_and_totals',
      );
      expect(options.previousSectionGuidance, 'Add the lower receipt section.');
    },
  );

  test(
    'continuation guide preserves module default detailed review intent',
    () {
      final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
        previousPhotoPaths: const ['/tmp/receipt-top.jpg'],
        reasonCode: 'missing_bottom_edge_and_totals',
      );

      final inventory = guide.applyTo(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.materialsInventory,
        ),
      );
      final maintenance = guide.applyTo(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.maintenanceRepair,
        ),
      );
      final expenses = guide.applyTo(
        const ReceiptCaptureFlowOptions(
          module: ReceiptCaptureFlowModule.expenses,
        ),
      );

      expect(
        inventory.effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(
        maintenance.effectiveReviewDepth,
        ReceiptNativeReviewDepth.detailedLines,
      );
      expect(
        expenses.effectiveReviewDepth,
        ReceiptNativeReviewDepth.pricesOnly,
      );
      expect(
        inventory.previousSectionReasonCode,
        'missing_bottom_edge_and_totals',
      );
      expect(maintenance.previousSectionGuidePhotoPath, '/tmp/receipt-top.jpg');
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

  test('continuation guide ignores unsafe previous photo paths', () {
    final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const [
        'relative-receipt.jpg',
        'https://example.test/receipt.jpg',
        '/tmp/receipt-not-image.txt',
        '/tmp/receipt-guide.jpg\u0000.png',
      ],
      reasonCode: 'missing_bottom_edge_and_totals',
      guidance: 'Continue the receipt.',
    );
    final options = guide.applyTo(
      const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
      ),
    );

    expect(guide.hasReason, isTrue);
    expect(guide.hasGuidePhoto, isFalse);
    expect(options.previousSectionGuidePhotoPath, isNull);
    expect(options.previousSectionReasonCode, 'missing_bottom_edge_and_totals');

    final uppercaseGuide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const [' /tmp/receipt-guide.PNG '],
      reasonCode: 'missing_bottom_edge_and_totals',
    );
    expect(uppercaseGuide.hasGuidePhoto, isTrue);
    expect(
      uppercaseGuide.applyTo(options).previousSectionGuidePhotoPath,
      '/tmp/receipt-guide.PNG',
    );
  });

  test('continuation diagnostics bound malformed ghost fractions', () async {
    final source = await readReceiptCaptureFlowSource();

    expect(source, contains('final ghostSourceHeightFraction ='));
    expect(source, contains('_boundedPreviousSectionGhostFraction('));
    expect(
      source,
      contains(
        "'previousSectionGhostSlicePercent': (ghostSourceHeightFraction * 100)",
      ),
    );
    expect(source, contains('.round(),'));
    expect(
      source,
      isNot(
        contains(
          '((options.previousSectionGhostSourceHeightFraction ?? 0) * 100).round()',
        ),
      ),
    );
  });

  test('manual continuation guide cannot poison ghost overlay options', () {
    const guide = ReceiptCaptureContinuationGuide(
      guidePhotoPath: ' /tmp/receipt-bottom.jpg ',
      reasonCode: ' MISSING_BOTTOM_EDGE_AND_TOTALS ',
      guidance: ' Keep the overlap visible. ',
      ghostSourceStartFraction: -0.2,
      ghostSourceHeightFraction: double.infinity,
      ghostOverlayTopFraction: 1.8,
      ghostOverlayHeightFraction: double.nan,
      ghostOpacity: 0.42,
    );

    final options = guide.applyTo(
      const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
      ),
    );

    expect(options.previousSectionGuidePhotoPath, '/tmp/receipt-bottom.jpg');
    expect(options.previousSectionReasonCode, 'missing_bottom_edge_and_totals');
    expect(options.previousSectionGuidance, 'Keep the overlap visible.');
    expect(options.previousSectionGhostSourceStartFraction, 0);
    expect(options.previousSectionGhostSourceHeightFraction, isNull);
    expect(options.previousSectionGhostOverlayTopFraction, 1);
    expect(options.previousSectionGhostOverlayHeightFraction, isNull);
    expect(options.previousSectionGhostOpacity, 0.42);
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

  test('shared camera clamps review opening index inside new photos', () async {
    final source = await readReceiptCaptureFlowSource();

    expect(source, contains('int _reviewInitialSelectedIndex({'));
    expect(
      source,
      contains('final addedPhotoCount = staged.photoPaths.length'),
    );
    expect(
      source,
      contains('final initialPhotoCount = uniqueNormalizedReceiptPhotoPaths('),
    );
    expect(source, contains('return initialPhotoCount + addedPhotoIndex'));
    expect(source, contains('.clamp(0, addedPhotoCount - 1)'));
    expect(
      source,
      isNot(
        contains(
          'options.initialPhotoPaths.length + options.initialSelectedIndex',
        ),
      ),
    );
  });

  test('photo review normalizes initial photo paths once', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final saveActions = await readReceiptPhotoReviewSaveActionsSource();

    expect(
      reviewScreen,
      contains('uniqueNormalizedReceiptPhotoPaths(widget.initialPhotoPaths)'),
    );
    expect(reviewScreen, contains('late final List<String> _photoPaths'));
    expect(reviewScreen, contains('_initialPhotoPaths.length'));
    expect(
      saveActions,
      contains('receiptPhotoPathSetContains(_initialPhotoPaths, photoPath)'),
    );
  });

  test('photo review normalizes initial quality check keys', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();

    expect(
      reviewScreen,
      contains(
        'for (final entry in widget.initialQualityChecksByPath.entries)',
      ),
    );
    expect(
      reviewScreen,
      contains('final normalizedPath = normalizedReceiptPhotoPath(entry.key)'),
    );
    expect(
      reviewScreen,
      contains(
        '!receiptPhotoPathSetContains(_initialPhotoPaths, normalizedPath)',
      ),
    );
    expect(
      reviewScreen,
      isNot(contains('...widget.initialQualityChecksByPath')),
    );
  });

  test('photo review normalizes initial diagnostics keys', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();

    expect(
      reviewScreen,
      contains(
        'for (final entry in widget.initialCaptureDiagnosticsByPath.entries)',
      ),
    );
    expect(
      reviewScreen,
      contains('final normalizedPath = normalizedReceiptPhotoPath(entry.key)'),
    );
    expect(reviewScreen, contains('Map<String, Object?>.unmodifiable('));
    expect(
      reviewScreen,
      isNot(contains('...widget.initialCaptureDiagnosticsByPath')),
    );
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
