import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';

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
    'empty drafts are removed instead of cluttering the home screen',
    () async {
      final drafts = await ExpenseDraftController.create();

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'empty',
          receiptDate: DateTime(2026, 6, 11),
          updatedAt: DateTime(2026, 6, 11, 12),
        ),
      );

      expect(drafts.drafts, isEmpty);
    },
  );

  test('drafts keep receipt attachment metadata', () async {
    final drafts = await ExpenseDraftController.create();
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-photo',
      receiptDate: DateTime(2026, 6, 11),
      updatedAt: DateTime(2026, 6, 11, 12),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 11, 12),
          byteSize: 120000,
        ),
        ReceiptAttachmentRecord(
          id: 'email-1',
          path: '',
          kind: ReceiptAttachmentKind.emailText,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 11, 12),
          displayName: 'Advance Auto email receipt',
          importedText: 'OIL FILTER 12.99',
          byteSize: 16,
        ),
      ],
    );

    await drafts.saveDraft(draft);

    final loaded = drafts.draftById('draft-photo')!;
    expect(loaded.hasReceiptAttachment, isTrue);
    expect(loaded.attachments.first.path, '/tmp/receipt.jpg');
    expect(loaded.attachments.first.byteSize, 120000);
    expect(loaded.attachments.last.kind, ReceiptAttachmentKind.emailText);
    expect(loaded.attachments.last.displayName, 'Advance Auto email receipt');
    expect(loaded.attachments.last.importedText, contains('OIL FILTER'));
  });

  test('drafts report missing receipt proof files for recovery', () async {
    final drafts = await ExpenseDraftController.create();
    final existingProof = File('${Directory.systemTemp.path}/draft-proof.pdf');
    await existingProof.writeAsString('%PDF-1.7\n%%EOF', flush: true);
    addTearDown(() {
      if (existingProof.existsSync()) existingProof.deleteSync();
    });
    final missingPath = '${Directory.systemTemp.path}/missing-draft-proof.pdf';
    if (File(missingPath).existsSync()) File(missingPath).deleteSync();

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-missing-proof',
        receiptDate: DateTime(2026, 6, 11),
        updatedAt: DateTime(2026, 6, 11, 12),
        attachments: [
          ReceiptAttachmentRecord(
            id: 'existing-pdf',
            path: existingProof.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
          ReceiptAttachmentRecord(
            id: 'missing-pdf',
            path: missingPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
          ReceiptAttachmentRecord(
            id: 'text-proof',
            path: '',
            kind: ReceiptAttachmentKind.emailText,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            importedText: 'EMAIL TOTAL 10.00',
          ),
        ],
      ),
    );

    final missing = drafts.missingAttachmentsForDraft('draft-missing-proof');

    expect(drafts.draftHasMissingProof('draft-missing-proof'), isTrue);
    expect(missing.map((attachment) => attachment.id), ['missing-pdf']);
  });

  test(
    'recovery snapshot summarizes restorable and missing proof drafts',
    () async {
      final drafts = await ExpenseDraftController.create();
      final existingProof = File('${Directory.systemTemp.path}/snapshot.pdf');
      await existingProof.writeAsString('%PDF-1.7\n%%EOF', flush: true);
      addTearDown(() {
        if (existingProof.existsSync()) existingProof.deleteSync();
      });
      final missingPath = '${Directory.systemTemp.path}/snapshot-missing.pdf';
      if (File(missingPath).existsSync()) File(missingPath).deleteSync();

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'recoverable-draft',
          receiptDate: DateTime(2026, 6, 14),
          updatedAt: DateTime(2026, 6, 14, 12),
          merchantName: 'Advance Auto',
          attachments: [
            ReceiptAttachmentRecord(
              id: 'existing',
              path: existingProof.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 14),
              storageState: ReceiptAttachmentStorageState.staged,
            ),
            ReceiptAttachmentRecord(
              id: 'missing',
              path: missingPath,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 14),
              storageState: ReceiptAttachmentStorageState.staged,
            ),
          ],
        ),
      );

      final snapshot = drafts.recoverySnapshot();

      expect(snapshot.hasRecoverableWork, isTrue);
      expect(snapshot.draftCount, 1);
      expect(snapshot.recoverableDraftIds, ['recoverable-draft']);
      expect(snapshot.hasMissingProof, isTrue);
      expect(snapshot.missingProofDraftCount, 1);
      expect(snapshot.missingProofCount, 1);
      expect(snapshot.retainedStagedProofPaths, contains(existingProof.path));
      expect(snapshot.retainedStagedProofPaths, contains(missingPath));
    },
  );

  test(
    'startup cleanup keeps active draft proofs and removes old orphan staging',
    () async {
      final drafts = await ExpenseDraftController.create();
      final retainedSource = File(
        '${Directory.systemTemp.path}/retained-draft.pdf',
      );
      final orphanSource = File(
        '${Directory.systemTemp.path}/orphan-draft.pdf',
      );
      await retainedSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      await orphanSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (retainedSource.existsSync()) retainedSource.deleteSync();
        if (orphanSource.existsSync()) orphanSource.deleteSync();
      });

      final retained = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'retained-draft-pdf',
          path: retainedSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 14),
        ),
      );
      final orphan = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'orphan-draft-pdf',
          path: orphanSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 14),
        ),
      );
      await File(retained.path).setLastModified(DateTime(2026, 1, 1));
      await File(orphan.path).setLastModified(DateTime(2026, 1, 1));

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'active-draft',
          receiptDate: DateTime(2026, 6, 14),
          updatedAt: DateTime(2026, 6, 14, 12),
          attachments: [retained],
        ),
      );

      final snapshot = await drafts.cleanAbandonedStagedProofs(
        now: DateTime(2026, 6, 14),
      );

      expect(snapshot.recoverableDraftIds, ['active-draft']);
      expect(await File(retained.path).exists(), isTrue);
      expect(await File(orphan.path).exists(), isFalse);
      expect(await retainedSource.exists(), isTrue);
      expect(await orphanSource.exists(), isTrue);
    },
  );

  test('deleting a draft removes only app-staged receipt proofs', () async {
    final drafts = await ExpenseDraftController.create();
    final original = File('${Directory.systemTemp.path}/draft-delete.pdf');
    await original.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (original.existsSync()) original.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'draft-delete-pdf',
        path: original.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 14),
      ),
    );

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-delete',
        receiptDate: DateTime(2026, 6, 14),
        updatedAt: DateTime(2026, 6, 14, 12),
        attachments: [staged],
      ),
    );

    expect(await File(staged.path).exists(), isTrue);
    await drafts.deleteDraft('draft-delete');

    expect(drafts.draftById('draft-delete'), isNull);
    expect(await File(staged.path).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

  test('clearing drafts removes retained staged proof copies', () async {
    final drafts = await ExpenseDraftController.create();
    final original = File('${Directory.systemTemp.path}/draft-clear.pdf');
    await original.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (original.existsSync()) original.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'draft-clear-pdf',
        path: original.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 14),
      ),
    );

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-clear',
        receiptDate: DateTime(2026, 6, 14),
        updatedAt: DateTime(2026, 6, 14, 12),
        attachments: [staged],
      ),
    );

    await drafts.clear();

    expect(drafts.drafts, isEmpty);
    expect(await File(staged.path).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });
}
