import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/app/incoming_receipt_destination_screen.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/incoming_receipt_share.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_storage_guard.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'helpers/pdf_torture_fixtures.dart';
import 'helpers/receipt_pdf_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF proof storage torture lifecycle', () {
    late Directory documentsDirectory;
    late PdfTortureFixtures fixtures;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp(
        'pdf_torture_docs_',
      );
      fixtures = await PdfTortureFixtures.create();
      mockDocumentsDirectory(documentsDirectory);
    });

    tearDown(() async {
      clearDocumentsDirectoryMock();
      await fixtures.dispose();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    test(
      'staging, promotion, cancel, and cleanup never delete originals',
      () async {
        final original = fixtures['valid_3_page'];
        final staged = await ReceiptProofStorage.instance.stageAttachment(
          pdfAttachment('stage-proof', original),
        );
        final stagedPath = staged.path;

        expect(staged.path, isNot(original.path));
        expect(staged.storageState, ReceiptAttachmentStorageState.staged);
        expect(await original.exists(), isTrue);
        expect(await File(stagedPath).exists(), isTrue);
        expect(_partialProofFiles(documentsDirectory), isEmpty);
        expect(
          Directory(
            '${documentsDirectory.path}/receipt_proofs/pdfs',
          ).existsSync(),
          isFalse,
        );

        final promoted = await ReceiptProofStorage.instance.persistAttachment(
          staged.copyWith(linkedModule: 'expenses', linkedRecordId: 'EXP-1'),
        );

        expect(promoted.storageState, ReceiptAttachmentStorageState.permanent);
        expect(promoted.path, contains('receipt_proofs/pdfs'));
        expect(await File(promoted.path).exists(), isTrue);
        expect(await File(stagedPath).exists(), isFalse);
        expect(await original.exists(), isTrue);
        expect(_partialProofFiles(documentsDirectory), isEmpty);

        final stagedForCancel = await ReceiptProofStorage.instance
            .stageAttachment(pdfAttachment('cancel-proof', original));
        await ReceiptProofStorage.instance.deleteStagedAttachment(
          stagedForCancel,
        );
        expect(await File(stagedForCancel.path).exists(), isFalse);
        expect(await original.exists(), isTrue);
        expect(_partialProofFiles(documentsDirectory), isEmpty);

        final activeDraft = await ReceiptProofStorage.instance.stageAttachment(
          pdfAttachment('active-draft-proof', original),
        );
        final oldOrphan = await ReceiptProofStorage.instance.stageAttachment(
          pdfAttachment('old-orphan-proof', original),
        );
        await File(oldOrphan.path).setLastModified(DateTime(2026, 1, 1));
        await File(activeDraft.path).setLastModified(DateTime(2026, 1, 1));

        await ReceiptProofStorage.instance.cleanOldStagedFiles(
          retainedPaths: [activeDraft.path],
          now: DateTime(2026, 6, 14),
        );

        expect(await File(activeDraft.path).exists(), isTrue);
        expect(await File(oldOrphan.path).exists(), isFalse);
        expect(await original.exists(), isTrue);
        expect(_partialProofFiles(documentsDirectory), isEmpty);
      },
    );

    test(
      'invalid source and copy failures fail safely without partial proof',
      () async {
        await expectLater(
          ReceiptProofStorage.instance.stageAttachment(
            pdfAttachment('bad-txt', fixtures['txt_renamed_pdf']),
          ),
          throwsA(isA<ReceiptProofStorageException>()),
        );
        expect(await fixtures['txt_renamed_pdf'].exists(), isTrue);

        final badDocumentsFile = File('${fixtures.root.path}/not_a_directory');
        await badDocumentsFile.writeAsString('blocking file', flush: true);
        mockDocumentsDirectory(badDocumentsFile);

        await expectLater(
          ReceiptProofStorage.instance.stageAttachment(
            pdfAttachment('copy-failure', fixtures['valid_1_page']),
          ),
          throwsA(
            isA<ReceiptProofStorageException>().having(
              (error) => error.message,
              'message',
              contains('could not be copied'),
            ),
          ),
        );
        expect(await fixtures['valid_1_page'].exists(), isTrue);
        mockDocumentsDirectory(documentsDirectory);
      },
    );

    test('low-storage and permission style messages are friendly', () {
      const operationBytes = 12 * 1024 * 1024;
      const lowStorage = ReceiptStorageCheck(
        availableBytes: 1024,
        operationBytes: operationBytes,
        requiredBytes:
            operationBytes + ReceiptStorageGuard.minimumDeviceReserveBytes,
        purpose: ReceiptStoragePurpose.importPdf,
      );
      const warningStorage = ReceiptStorageCheck(
        availableBytes: 128 * 1024 * 1024,
        operationBytes: operationBytes,
        requiredBytes:
            operationBytes + ReceiptStorageGuard.minimumDeviceReserveBytes,
        purpose: ReceiptStoragePurpose.importPdf,
        shouldWarnLowStorage: true,
      );
      final unknownStorage = ReceiptStorageCheck.unknown(
        operationBytes: operationBytes,
        requiredBytes: ReceiptStorageGuard.protectedRequiredBytes(
          operationBytes,
        ),
        purpose: ReceiptStoragePurpose.importPdf,
      );

      expect(lowStorage.hasEnoughSpace, isFalse);
      expect(
        lowStorage.blockingMessage(ReceiptStoragePurpose.importPdf),
        contains('not enough free storage'),
      );
      expect(
        lowStorage.blockingMessage(ReceiptStoragePurpose.importPdf),
        contains('will not delete anything'),
      );
      expect(
        ReceiptStorageGuard.protectedRequiredBytes(1),
        1 + ReceiptStorageGuard.minimumDeviceReserveBytes,
      );
      expect(
        lowStorage.blockingMessage(ReceiptStoragePurpose.importPdf),
        contains('device safety reserve'),
      );
      expect(warningStorage.hasEnoughSpace, isTrue);
      expect(warningStorage.warningMessage(), contains('getting low'));
      expect(unknownStorage.hasEnoughSpace, isTrue);
      expect(
        unknownStorage.unknownMessage(ReceiptStoragePurpose.importPdf),
        contains('could not verify'),
      );
      expect(
        unknownStorage.unknownMessage(ReceiptStoragePurpose.importPdf),
        contains('device safety reserve'),
      );
    });
  });

  group('PDF duplicate torture', () {
    late Directory documentsDirectory;
    late PdfTortureFixtures fixtures;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp(
        'pdf_duplicate_torture_docs_',
      );
      fixtures = await PdfTortureFixtures.create();
      mockDocumentsDirectory(documentsDirectory);
    });

    tearDown(() async {
      clearDocumentsDirectoryMock();
      await fixtures.dispose();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    test(
      'same PDF is detected across filename, folder, form, ledger, and override',
      () async {
        final original = await ReceiptProofStorage.instance.stageAttachment(
          pdfAttachment('dup-original', fixtures['duplicate_original']),
        );
        final differentName = await ReceiptProofStorage.instance
            .stageAttachment(
              pdfAttachment(
                'dup-different-name',
                fixtures['duplicate_different_filename'],
              ),
            );
        final differentPath = await ReceiptProofStorage.instance
            .stageAttachment(
              pdfAttachment(
                'dup-different-path',
                fixtures['duplicate_different_path'],
              ),
            );

        expect(original.fileHash, isNotEmpty);
        expect(differentName.fileHash, original.fileHash);
        expect(differentPath.fileHash, original.fileHash);

        final ledger = ExpenseLedgerController.memory();
        await ledger.saveReceipt(
          expenseReceiptWithAttachment(
            'EXP-original',
            original.copyWith(
              storageState: ReceiptAttachmentStorageState.permanent,
            ),
          ),
        );

        final currentFormCandidates = ledger.duplicateAttachmentCandidatesFor(
          fileHashSha256: original.fileHash,
          scope: ExpenseDuplicateAttachmentScope.currentForm,
          currentFormAttachments: [differentName],
        );
        expect(currentFormCandidates, hasLength(1));
        expect(currentFormCandidates.single.attachmentId, differentName.id);

        final ledgerCheck = ledger.checkDuplicatesFor(
          expenseReceiptWithAttachment('EXP-different-path', differentPath),
        );
        expect(ledgerCheck.status, ExpenseDuplicateCheckStatus.candidatesFound);
        expect(
          ledgerCheck.candidates.single.confidence,
          ExpenseDuplicateConfidence.exactFileMatch,
        );

        final overrideSaved = await ledger.saveReceipt(
          expenseReceiptWithAttachment(
            'EXP-save-anyway',
            differentPath,
          ).copyWith(
            fileHashSha256: ledgerCheck.fileHashSha256,
            duplicateCheckStatus: ExpenseDuplicateCheckStatus.overrideSaved,
            duplicateCandidates: ledgerCheck.candidates,
            duplicateOverride: true,
            duplicateOverrideReason: 'Legitimate repeat counter receipt.',
            duplicateCheckedAt: ledgerCheck.checkedAt,
          ),
        );
        expect(overrideSaved.duplicateOverride, isTrue);
        expect(
          overrideSaved.duplicateOverrideReason,
          'Legitimate repeat counter receipt.',
        );

        final afterOverride = ledger.checkDuplicatesFor(
          expenseReceiptWithAttachment('EXP-after-override', differentName),
        );
        expect(afterOverride.candidates, isNotEmpty);
      },
    );
  });

  group('PDF share routing torture', () {
    testWidgets('shared PDF asks destination and does not assume receipt', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IncomingReceiptDestinationScreen(
            attachments: [
              pdfAttachment(
                'manual-share',
                File('/tmp/manual_document.pdf'),
              ).copyWith(
                storageState: ReceiptAttachmentStorageState.staged,
                sourceLabel: 'Shared',
              ),
            ],
            importedText: 'warranty policy manual terms and certificate',
          ),
        ),
      );

      expect(
        find.textContaining('What are you sharing to Maintainiac?'),
        findsOneWidget,
      );
      expect(find.text('Suggested: Other Document'), findsOneWidget);
      expect(find.text('Receipt / Expense'), findsOneWidget);
      expect(find.text('Fuel Receipt'), findsOneWidget);
      expect(find.text('Maintenance Record'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -550));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other Document').last);
      await tester.pumpAndSettle();

      expect(find.text('Other document'), findsOneWidget);
      expect(find.text('Save As Document Proof'), findsOneWidget);
      expect(find.text('Choose Expense Category'), findsWidgets);
    });

    test(
      'incoming shared duplicates are removed from staged import batch',
      () async {
        final documentsDirectory = await Directory.systemTemp.createTemp(
          'incoming_duplicate_torture_docs_',
        );
        final fixtures = await PdfTortureFixtures.create();
        mockDocumentsDirectory(documentsDirectory);
        addTearDown(() async {
          clearDocumentsDirectoryMock();
          await fixtures.dispose();
          if (await documentsDirectory.exists()) {
            await documentsDirectory.delete(recursive: true);
          }
        });

        final prepared = await prepareIncomingReceiptShareForStorage(
          IncomingReceiptShare(
            attachments: receiptAttachmentsFromSharedMedia([
              SharedMediaFile(
                path: fixtures['duplicate_original'].path,
                type: SharedMediaType.file,
                mimeType: 'application/pdf',
              ),
              SharedMediaFile(
                path: fixtures['duplicate_different_filename'].path,
                type: SharedMediaType.file,
                mimeType: 'application/pdf',
              ),
            ]),
            receivedAt: DateTime(2026, 6, 14),
          ),
        );

        expect(prepared.attachments, hasLength(1));
        expect(prepared.messages.join('\n'), contains('already included'));
        expect(
          prepared.attachments.single.storageState,
          ReceiptAttachmentStorageState.staged,
        );
        expect(await File(prepared.attachments.single.path).exists(), isTrue);
      },
    );
  });
}

List<File> _partialProofFiles(Directory root) {
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.partial'))
      .toList(growable: false);
}
