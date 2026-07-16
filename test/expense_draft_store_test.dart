import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'helpers/receipt_pdf_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Directory documentsDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_draft_store_test_',
    );
    documentsDirectory = await Directory.systemTemp.createTemp(
      'expense_draft_documents_test_',
    );
    mockDocumentsDirectory(documentsDirectory);
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    clearDocumentsDirectoryMock();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
    if (documentsDirectory.existsSync()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('saves and resumes unfinished receipt drafts', () async {
    final drafts = await ExpenseDraftController.create();
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-1',
      receiptDate: DateTime(2026, 6, 11),
      updatedAt: DateTime(2026, 6, 11, 12),
      merchantName: 'Lowes',
      enteredSubtotal: 42,
      enteredTax: 2.94,
      enteredTotal: 44.94,
      rawOcrText: 'LOWES MATERIALS 42.00',
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'line-1',
          description: 'Materials',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 42,
        ),
      ],
    );

    await drafts.saveDraft(draft);

    final loaded = drafts.draftById('draft-1')!;
    expect(loaded.title, 'Lowes');
    expect(loaded.receiptTax, 2.94);
    expect(loaded.total, 44.94);
    expect(loaded.rawOcrText, 'LOWES MATERIALS 42.00');
    expect(drafts.drafts.map((item) => item.id), ['draft-1']);
  });

  test('rapid local checkpoints keep the most recent receipt draft', () async {
    final drafts = ExpenseDraftController.memory();
    final earlier = ExpenseReceiptDraftRecord(
      id: 'draft-checkpoint-order',
      receiptDate: DateTime(2026, 7, 15),
      updatedAt: DateTime(2026, 7, 15, 12),
      merchantName: 'First value',
    );
    final latest = ExpenseReceiptDraftRecord(
      id: earlier.id,
      receiptDate: earlier.receiptDate,
      updatedAt: earlier.updatedAt.add(const Duration(seconds: 1)),
      merchantName: 'Latest value',
    );

    await Future.wait([drafts.saveDraft(earlier), drafts.saveDraft(latest)]);

    expect(drafts.draftById(earlier.id)?.merchantName, 'Latest value');
  });

  test(
    'moves existing expense drafts into the shared durable draft store',
    () async {
      final legacy = await Hive.openBox<dynamic>(
        ExpenseDraftController.boxName,
      );
      final draft = ExpenseReceiptDraftRecord(
        id: 'legacy-draft',
        receiptDate: DateTime(2026, 7, 15),
        updatedAt: DateTime(2026, 7, 15, 12),
        merchantName: 'Legacy Store',
        enteredTotal: 16.25,
      );
      await legacy.put(draft.id, draft.toMap());

      final drafts = await ExpenseDraftController.create();

      expect(drafts.draftById(draft.id)?.merchantName, 'Legacy Store');
      expect(drafts.draftById(draft.id)?.total, 16.25);
      expect(legacy.containsKey(draft.id), isFalse);
    },
  );

  test(
    'receipt entry flushes its local draft when the app is interrupted',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
      ).readAsString();
      final scheduling = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
      ).readAsString();

      expect(source, contains('with WidgetsBindingObserver'));
      expect(source, contains('didChangeAppLifecycleState'));
      expect(source, contains('unawaited(_saveDraftNow())'));
      expect(scheduling, contains('Duration(milliseconds: 200)'));
    },
  );

  test('edit drafts retain the receipt they must resume', () {
    final draft = ExpenseReceiptDraftRecord.fromMap({
      'id': 'EXPD-EDIT-receipt-1',
      'receiptDate': DateTime.utc(2026, 7, 15).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 15).toIso8601String(),
      'editingReceiptId': 'receipt-1',
      'merchantName': 'Saved merchant',
    });

    expect(draft.editingReceiptId, 'receipt-1');
    expect(draft.hasUserContent, isTrue);
    expect(draft.toMap()['editingReceiptId'], 'receipt-1');
  });

  test(
    'receipt save shows the storage recovery message without losing a draft',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
      ).readAsString();

      expect(source, contains('error is StateError'));
      expect(source, contains('storage_guard_blocked_local_record_save'));
      expect(source, contains('storageMessage ??'));
      expect(source, contains('await ledger.ensureStorageForLocalSave()'));
    },
  );

  test('drafts keep OCR review metadata for resumed receipt review', () async {
    final ocr = await const ReceiptOcrService().recognizeTextFromAttachments([
      ReceiptAttachmentRecord(
        id: 'email-1',
        path: '',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 11, 12),
        importedText: 'LOWES\nPVC GLUE 7.99',
      ),
      ReceiptAttachmentRecord(
        id: 'email-2',
        path: '',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 11, 12),
        importedText: 'PVC GLUE 7.99\nTOTAL 7.99',
      ),
    ]);
    final drafts = await ExpenseDraftController.create();
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-ocr',
      receiptDate: DateTime(2026, 6, 11),
      updatedAt: DateTime(2026, 6, 11, 12),
      rawOcrText: ocr.rawText,
      ocrReview: ExpenseReceiptOcrReview.fromDiagnostics(
        diagnostics: ocr.diagnostics,
        warnings: ocr.structuredWarnings,
      ),
    );

    await drafts.saveDraft(draft);

    final loaded = drafts.draftById('draft-ocr')!;
    expect(loaded.ocrReview.hasData, isTrue);
    expect(loaded.ocrReview.severity, ReceiptOcrReviewSeverity.review.name);
    expect(loaded.ocrReview.warningKinds, [
      ReceiptOcrWarningKind.duplicateText.name,
    ]);
    expect(
      loaded.ocrReview.countForWarningKind(
        ReceiptOcrWarningKind.duplicateText.name,
      ),
      1,
    );
    expect(loaded.ocrReview.primaryWarningLabel, 'Duplicate lines ignored');
    expect(
      loaded.ocrReview.primaryWarningKind,
      ReceiptOcrWarningKind.duplicateText.name,
    );
    expect(
      loaded.ocrReview.primaryWarningTargetLabel,
      'Check long receipt overlap',
    );
    expect(
      loaded.ocrReview.primaryWarningTargetInstruction,
      contains('same charge was not counted twice'),
    );
    expect(loaded.ocrReview.recoveryAction, 'review_overlap');
    expect(loaded.ocrReview.recoveryTarget, 'receipt_overlap');
    expect(
      loaded.ocrReview.recoverySummary,
      'Check the long-receipt overlap before saving.',
    );
    expect(loaded.ocrReview.commandCenterSummary['source'], 'importedText');
    expect(loaded.ocrReview.hadDuplicateOrOverlapText, isTrue);
  });

  test('drafts keep accepted photo review handoff state', () async {
    final drafts = await ExpenseDraftController.create();
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-handoff',
      receiptDate: DateTime(2026, 6, 11),
      updatedAt: DateTime(2026, 6, 11, 12),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt-photo.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 11, 12),
        ),
      ],
      receiptReviewFlowStarted: true,
      receiptReadAttemptedWithoutText: true,
      receiptReadHandoffProofCount: 2,
      receiptReadHandoffOcrSourceCount: 1,
      receiptReadHandoffDecision: 'Next: review receipt lines',
      receiptReadHandoffAction: 'Review business, personal, or mixed use',
      receiptReadHandoffStage: 'Ready for receipt review',
      receiptReadHandoffRouteResult:
          'Accepted photo review opens receipt details next',
      receiptReadHandoffCoverageWarning: 'Possible missing receipt bottom',
      receiptReviewMode: 'detailedItems',
      receiptReviewModeChangedByUser: true,
    );

    await drafts.saveDraft(draft);

    final loaded = drafts.draftById('draft-handoff')!;
    expect(loaded.receiptReviewFlowStarted, isTrue);
    expect(loaded.receiptReadAttemptedWithoutText, isTrue);
    expect(loaded.receiptReadHandoffProofCount, 2);
    expect(loaded.receiptReadHandoffOcrSourceCount, 1);
    expect(loaded.receiptReadHandoffDecision, 'Next: review receipt lines');
    expect(
      loaded.receiptReadHandoffAction,
      'Review business, personal, or mixed use',
    );
    expect(loaded.receiptReadHandoffStage, 'Ready for receipt review');
    expect(
      loaded.receiptReadHandoffRouteResult,
      'Accepted photo review opens receipt details next',
    );
    expect(
      loaded.receiptReadHandoffCoverageWarning,
      'Possible missing receipt bottom',
    );
    expect(loaded.receiptReviewMode, 'detailedItems');
    expect(loaded.receiptReviewModeChangedByUser, isTrue);
  });

  test('OCR review summary stays privacy-safe for Command 1', () {
    const review = ExpenseReceiptOcrReview(
      severity: 'review',
      source: 'photo',
      primaryWarningKind: 'sectionGap',
      primaryWarningLabelOverride: 'Possible missing receipt section',
      primaryWarningTargetLabel: 'Check missing receipt section',
      primaryWarningTargetInstruction:
          'Check the receipt photos from top to bottom and add the missing middle section if needed.',
      warningCount: 2,
      reviewWarningCount: 2,
      attachmentsRead: 2,
      attachmentsSkipped: 1,
      parserLineCount: 9,
      recoveryAction: 'add_missing_section',
      recoveryTarget: 'receipt_sections',
      recoverySummary:
          'Add the missing receipt section or confirm the photos are in order.',
    );

    expect(review.commandCenterPrimaryIssue, 'Check missing receipt section');
    expect(
      review.commandCenterPrimaryAction,
      contains('receipt photos from top to bottom'),
    );
    expect(review.commandCenterSummary, {
      'severity': 'review',
      'source': 'photo',
      'needsReview': true,
      'warningCount': 2,
      'blockingWarningCount': 0,
      'partialWarningCount': 0,
      'reviewWarningCount': 2,
      'attachmentsRead': 2,
      'attachmentsSkipped': 1,
      'parserLineCount': 9,
      'primaryWarningKind': 'sectionGap',
      'recoveryAction': 'add_missing_section',
      'recoveryTarget': 'receipt_sections',
      'primaryIssue': 'Check missing receipt section',
      'primaryAction':
          'Check the receipt photos from top to bottom and add the missing middle section if needed.',
      'privacyScope': 'summary_only_no_receipt_content',
    });
    expect(review.commandCenterSummary.toString(), isNot(contains('LOWES')));
    expect(review.commandCenterSummary.toString(), isNot(contains('TOTAL')));
  });

  test('OCR review summary redacts unsafe warning copy for Command 1', () {
    const review = ExpenseReceiptOcrReview(
      severity: 'blocked',
      source: 'photo',
      primaryWarningKind: 'photoQuality',
      primaryWarningLabelOverride:
          'LOWES 6400 Brodie Lane Austin TX total 3.24',
      primaryWarningTargetLabel: 'Customer receipt at /tmp/private.jpg',
      primaryWarningTargetInstruction:
          'Call 512-895-5560 about LOWES invoice 18934 for 3.24',
      warningLabels: [
        'LOWES 6400 Brodie Lane Austin TX total 3.24',
        'Receipt photo quality needs review',
      ],
      warningCount: 1,
      blockingWarningCount: 1,
      attachmentsRead: 1,
      rawLineCount: 26,
      parserLineCount: 0,
      recoveryAction: 'private_store_total_3_24',
      recoveryTarget: 'receipt_photo',
      recoverySummary:
          'LOWES 6400 Brodie Lane Austin TX total 3.24 private receipt',
    );

    final summary = review.commandCenterSummary;
    final encoded = summary.toString().toLowerCase();

    expect(review.commandCenterPrimaryIssue, 'Receipt photo needs review');
    expect(
      review.commandCenterPrimaryAction,
      contains('Retake or crop the receipt'),
    );
    expect(summary['privacyScope'], 'summary_only_no_receipt_content');
    expect(summary['recoveryAction'], '');
    expect(summary['recoveryTarget'], 'receipt_photo');
    expect(encoded, isNot(contains('lowes')));
    expect(encoded, isNot(contains('brodie')));
    expect(encoded, isNot(contains('austin')));
    expect(encoded, isNot(contains('512')));
    expect(encoded, isNot(contains('/tmp')));
    expect(encoded, isNot(contains('3.24')));
    expect(encoded, isNot(contains('invoice 18934')));
    expect(summary['recoveryTarget'], 'receipt_photo');
  });

  test('OCR review map backfills safe recovery details for older drafts', () {
    final review = ExpenseReceiptOcrReview.fromMap({
      'severity': 'blocked',
      'source': 'pdf',
      'primaryWarningKind': 'pdfReadFailure',
      'warningCount': 1,
      'blockingWarningCount': 1,
      'attachmentsRead': 0,
      'attachmentsSkipped': 1,
    });

    expect(review.recoveryAction, 'scan_receipt_with_photos');
    expect(review.recoveryTarget, 'receipt_pdf');
    expect(review.recoverySummary, contains('Scan the receipt with photos'));
    expect(
      review.commandCenterSummary['recoveryAction'],
      'scan_receipt_with_photos',
    );
    expect(review.commandCenterSummary['recoveryTarget'], 'receipt_pdf');
    expect(review.commandCenterPrimaryAction, contains('Scan the receipt'));
  });

  test(
    'OCR review summary has safe defaults for healthy and empty records',
    () {
      const healthy = ExpenseReceiptOcrReview(
        severity: 'good',
        source: 'photo',
        attachmentsRead: 1,
        parserLineCount: 4,
      );
      const empty = ExpenseReceiptOcrReview();

      expect(healthy.commandCenterPrimaryIssue, 'Receipt OCR looks healthy');
      expect(healthy.commandCenterPrimaryAction, 'No OCR action needed.');
      expect(healthy.commandCenterSummary['needsReview'], isFalse);
      expect(healthy.commandCenterSummary['recoveryAction'], '');
      expect(healthy.commandCenterSummary['recoveryTarget'], '');
      expect(empty.commandCenterPrimaryIssue, 'No OCR review data');
      expect(
        empty.commandCenterPrimaryAction,
        'No receipt OCR action is available yet.',
      );
      expect(empty.commandCenterSummary['warningCount'], 0);
    },
  );

  test(
    'empty drafts remain recoverable instead of being deleted automatically',
    () async {
      final drafts = await ExpenseDraftController.create();

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'empty',
          receiptDate: DateTime(2026, 6, 11),
          updatedAt: DateTime(2026, 6, 11, 12),
        ),
      );

      expect(drafts.draftById('empty'), isNotNull);
    },
  );

  test(
    'receipt proof promotion checkpoints the draft before ledger save',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
      ).readAsString();

      final proofPromotion = source.indexOf('_persistReceiptProofs(receipt)');
      final checkpoint = source.indexOf('if (!await _saveDraftNow()) return;');
      final ledgerSave = source.indexOf(
        '_saveReceiptToLedger(ledger, receipt)',
      );

      expect(proofPromotion, greaterThanOrEqualTo(0));
      expect(checkpoint, greaterThan(proofPromotion));
      expect(ledgerSave, greaterThan(checkpoint));
    },
  );
}
