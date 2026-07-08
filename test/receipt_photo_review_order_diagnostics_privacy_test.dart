import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
  test(
    'retake diagnostics keep neighboring absolute section paths private',
    () {
      final plan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const [
          '/tmp/maintainiac/top-section.jpg',
          '/tmp/maintainiac/middle-old.jpg',
          '/tmp/maintainiac/bottom-section.jpg',
        ],
        targetPhotoPath: '/tmp/maintainiac/middle-old.jpg',
        replacementPhotoPaths: const ['/tmp/maintainiac/middle-new.jpg'],
      );

      expect(plan, isNotNull);
      expect(plan!.photoPaths, const [
        '/tmp/maintainiac/top-section.jpg',
        '/tmp/maintainiac/middle-new.jpg',
        '/tmp/maintainiac/bottom-section.jpg',
      ]);
      final diagnostics = plan.captureDiagnosticsForReplacementPaths(const [
        '/tmp/maintainiac/middle-new.jpg',
      ]);
      final replacementDiagnostics =
          diagnostics['/tmp/maintainiac/middle-new.jpg'];

      expect(replacementDiagnostics, isNotNull);
      expect(
        replacementDiagnostics,
        containsPair('receiptRetakeOriginalSectionNumber', 2),
      );
      expect(
        replacementDiagnostics,
        containsPair('receiptRetakePreviousContextSectionNumber', 1),
      );
      expect(
        replacementDiagnostics,
        containsPair('receiptRetakeNextContextSectionNumber', 3),
      );
      expect(
        replacementDiagnostics,
        containsPair(
          'receiptRetakeOrderPolicy',
          'preserve_original_slot_insert_extra_sections_after_target',
        ),
      );
      expect(
        replacementDiagnostics.toString(),
        isNot(contains('/tmp/maintainiac/top-section.jpg')),
      );
      expect(
        replacementDiagnostics.toString(),
        isNot(contains('/tmp/maintainiac/bottom-section.jpg')),
      );
    },
  );

  test(
    'insert-after diagnostics preserve order without leaking absolute paths',
    () {
      final plan = ReceiptPhotoInsertAfterOrderPlan.build(
        currentPhotoPaths: const [
          '/tmp/maintainiac/top-section.jpg',
          '/tmp/maintainiac/middle-section.jpg',
          '/tmp/maintainiac/bottom-section.jpg',
        ],
        anchorIndex: 1,
        anchorPhotoPath: '/tmp/maintainiac/middle-section.jpg',
        insertedPhotoPaths: const [
          '/tmp/maintainiac/inserted-a.jpg',
          '/tmp/maintainiac/inserted-b.jpg',
        ],
      );

      expect(plan, isNotNull);
      expect(plan!.selectedIndex, 2);
      expect(plan.photoPaths, const [
        '/tmp/maintainiac/top-section.jpg',
        '/tmp/maintainiac/middle-section.jpg',
        '/tmp/maintainiac/inserted-a.jpg',
        '/tmp/maintainiac/inserted-b.jpg',
        '/tmp/maintainiac/bottom-section.jpg',
      ]);
      final diagnostics = plan.captureDiagnosticsForInsertedPhotoPaths(const [
        '/tmp/maintainiac/inserted-a.jpg',
        '/tmp/maintainiac/inserted-b.jpg',
      ]);
      final first = diagnostics['/tmp/maintainiac/inserted-a.jpg'];
      final second = diagnostics['/tmp/maintainiac/inserted-b.jpg'];

      expect(first, containsPair('receiptInsertAfterAnchorSectionNumber', 2));
      expect(first, containsPair('receiptInsertAfterOffset', 0));
      expect(first, containsPair('receiptInsertFinalSectionNumber', 3));
      expect(first, containsPair('receiptInsertFinalSectionCount', 5));
      expect(second, containsPair('receiptInsertAfterOffset', 1));
      expect(second, containsPair('receiptInsertFinalSectionNumber', 4));
      expect(
        first,
        containsPair(
          'receiptInsertOrderPolicy',
          'insert_new_sections_after_selected_anchor',
        ),
      );
      expect(diagnostics.values.toString(), isNot(contains('middle-section')));
      expect(diagnostics.values.toString(), isNot(contains('bottom-section')));
    },
  );

  test('move diagnostics preserve order without leaking absolute paths', () {
    final plan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/maintainiac/top-section.jpg',
        '/tmp/maintainiac/middle-section.jpg',
        '/tmp/maintainiac/bottom-section.jpg',
      ],
      selectedIndex: 1,
      selectedPhotoPath: '/tmp/maintainiac/middle-section.jpg',
      direction: 1,
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 2);
    expect(plan.photoPaths, const [
      '/tmp/maintainiac/top-section.jpg',
      '/tmp/maintainiac/bottom-section.jpg',
      '/tmp/maintainiac/middle-section.jpg',
    ]);
    final diagnostics = plan.captureDiagnosticsForMovedPhotoPath(
      '/tmp/maintainiac/middle-section.jpg',
    );

    expect(
      diagnostics,
      containsPair('receiptManualReorderOriginalSectionNumber', 2),
    );
    expect(
      diagnostics,
      containsPair('receiptManualReorderFinalSectionNumber', 3),
    );
    expect(diagnostics, containsPair('receiptManualReorderDirection', 'later'));
    expect(
      diagnostics,
      containsPair(
        'receiptManualReorderPolicy',
        'user_reordered_sections_preserve_paths',
      ),
    );
    expect(diagnostics.toString(), isNot(contains('/tmp/maintainiac/')));
    expect(
      plan.captureDiagnosticsForMovedPhotoPath(
        '/tmp/maintainiac/top-section.jpg',
      ),
      isEmpty,
    );
  });
}
