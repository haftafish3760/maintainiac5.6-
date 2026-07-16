import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_store.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/media/app_media_asset.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';

void main() {
  test(
    'never claims invoice persistence when local storage is unavailable',
    () async {
      final store = InvoiceLedgerStore.memory(canPersist: false);

      await expectLater(
        () => store.createDraft(type: InvoiceDocumentType.invoice),
        throwsStateError,
      );
      expect(store.records, isEmpty);
      expect(store.numberSettings.nextInvoiceNumber, 1);
    },
  );

  test(
    'automatic numbering uses internal id separate from invoice number',
    () async {
      final store = InvoiceLedgerStore.memory(
        settings: const InvoiceNumberSettings(
          invoicePrefix: 'INV',
          nextInvoiceNumber: 42,
          padding: 5,
        ),
      );
      final now = DateTime(2026, 6, 15, 9);

      final draft = await store.createDraft(
        type: InvoiceDocumentType.invoice,
        now: now,
        title: 'Kitchen repair',
      );

      expect(draft.id, isNot(draft.invoiceNumber));
      expect(draft.id, startsWith('invoice_'));
      expect(draft.invoiceNumber, 'INV-00042');
      expect(draft.numberMode, InvoiceNumberMode.automatic);
      expect(store.numberSettings.nextInvoiceNumber, 43);
    },
  );

  test(
    'concurrent automatic drafts reserve distinct durable numbers',
    () async {
      final store = InvoiceLedgerStore.memory(
        settings: const InvoiceNumberSettings(
          invoicePrefix: 'INV',
          nextInvoiceNumber: 42,
          padding: 5,
        ),
      );
      final now = DateTime(2026, 7, 16, 9);

      final drafts = await Future.wait([
        store.createDraft(type: InvoiceDocumentType.invoice, now: now),
        store.createDraft(type: InvoiceDocumentType.invoice, now: now),
      ]);

      expect(drafts.map((draft) => draft.invoiceNumber).toSet(), {
        'INV-00042',
        'INV-00043',
      });
      expect(store.numberSettings.nextInvoiceNumber, 44);
      expect(store.records, hasLength(2));
    },
  );

  test(
    'manual invoice number is saved without advancing automatic counter',
    () async {
      final store = InvoiceLedgerStore.memory(
        settings: const InvoiceNumberSettings(nextInvoiceNumber: 7),
      );

      final draft = await store.createDraft(
        type: InvoiceDocumentType.invoice,
        manualNumber: 'ROB-2026-A',
        now: DateTime(2026, 6, 15),
      );

      expect(draft.invoiceNumber, 'ROB-2026-A');
      expect(draft.numberMode, InvoiceNumberMode.manual);
      expect(store.numberSettings.nextInvoiceNumber, 7);
    },
  );

  test('stores invoice as structured data and calculates totals', () async {
    final store = InvoiceLedgerStore.memory();
    final draft = await store.createDraft(
      type: InvoiceDocumentType.invoice,
      now: DateTime(2026, 6, 15),
    );
    final saved = await store.saveRecord(
      draft.copyWith(
        client: const InvoicePartySnapshot(
          displayName: 'Alex Customer',
          street: '987 Oak Road',
        ),
        lines: const [
          InvoiceLineItemRecord(
            id: 'labor',
            name: 'Labor',
            quantity: 2,
            unit: 'hour',
            unitPrice: 85,
            taxRate: 0,
            taxable: false,
          ),
          InvoiceLineItemRecord(
            id: 'materials',
            name: 'Materials',
            quantity: 4,
            unit: 'item',
            unitPrice: 10,
            taxRate: 5,
          ),
        ],
        discount: const InvoiceDiscountRecord(
          type: InvoiceDiscountType.amount,
          value: 10,
        ),
        payments: [
          InvoicePaymentRecord(
            id: 'payment-1',
            amount: 50,
            paidAt: DateTime(2026, 6, 15, 10),
            method: 'Cash',
          ),
        ],
      ),
    );

    expect(saved.subtotal, 210);
    expect(saved.discountAmount, 10);
    expect(saved.taxTotal, 2);
    expect(saved.total, 202);
    expect(saved.balanceDue, 152);
    expect(saved.toMap().containsKey('pdfBytes'), isFalse);
    expect(saved.toMap().containsKey('pdfPath'), isFalse);
  });

  test(
    'serializes snapshots for invoice backup without saved contact list',
    () {
      final logo = AppMediaAsset(
        id: 'MEDIA-1',
        path: '/app/company-logo.png',
        purpose: AppMediaAssetPurpose.companyLogo,
        createdAt: DateTime(2026, 6, 15, 9),
        displayName: 'company-logo.png',
        originalFileName: 'logo.png',
        mimeType: 'image/png',
        byteSize: 2048,
        fileHash: 'abc123',
        backupPolicy: AppMediaAssetBackupPolicy.cloudEligible,
      );
      final record = _record().copyWith(
        company: InvoicePartySnapshot(
          companyName: 'Jane Doe Services',
          logoPath: logo.path,
          logoAsset: logo,
        ),
        client: const InvoicePartySnapshot(
          displayName: 'Alex Customer',
          phone: '(555) 123-5512',
        ),
      );

      final reloaded = InvoiceRecord.fromMap(record.toMap());

      expect(reloaded.client.displayName, 'Alex Customer');
      expect(reloaded.client.phone, '(555) 123-5512');
      expect(reloaded.company.companyName, 'Jane Doe Services');
      expect(reloaded.company.logoPath, '/app/company-logo.png');
      expect(reloaded.company.logoAsset.fileHash, 'abc123');
      expect(reloaded.company.logoAsset.canAttemptCloudBackup, isTrue);
      expect(reloaded.toMap().containsKey('savedClientId'), isFalse);
    },
  );

  test('groups dirty records into daily backup batches', () async {
    final store = InvoiceLedgerStore.memory();
    final first = await store.createDraft(
      type: InvoiceDocumentType.invoice,
      now: DateTime(2026, 6, 15, 8),
    );
    await store.createDraft(
      type: InvoiceDocumentType.estimate,
      now: DateTime(2026, 6, 15, 13),
    );
    await store.createDraft(
      type: InvoiceDocumentType.invoice,
      now: DateTime(2026, 6, 16, 9),
    );
    await store.markSynced(id: first.id, syncedAt: DateTime(2026, 6, 15, 9));

    final batches = store.dirtyDailyBatches();

    expect(batches.map((batch) => batch.dayKey), ['2026-06-15', '2026-06-16']);
    expect(batches.first.records, hasLength(1));
    expect(batches.last.records, hasLength(1));
  });

  test(
    'delete marks pending delete for sync instead of hard deletion',
    () async {
      final store = InvoiceLedgerStore.memory();
      final draft = await store.createDraft(
        type: InvoiceDocumentType.invoice,
        now: DateTime(2026, 6, 15),
      );

      await store.deleteRecord(draft.id, now: DateTime(2026, 6, 16));

      final deleted = store.recordById(draft.id)!;
      expect(deleted.status, InvoiceRecordStatus.voided);
      expect(deleted.meta.syncStatus, InvoiceSyncStatus.pendingDelete);
      expect(deleted.meta.deletedAt, DateTime(2026, 6, 16));
    },
  );

  test(
    'pdf delivery events store structured metadata without private pdf content',
    () {
      const hash =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final record = _record().copyWith(
        client: const InvoicePartySnapshot(
          displayName: 'Alex Customer',
          street: '987 Oak Road',
          email: 'alex@example.com',
          notes: 'Gate code 1234',
        ),
        terms: 'Payment due on receipt for Alex Customer.',
      );
      final pdf = AppGeneratedPdfDocument(
        kind: AppGeneratedPdfKind.invoice,
        title: 'Invoice for Alex Customer at 987 Oak Road',
        fileName: 'invoice_INV-0001.pdf',
        bytes: Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits),
        createdAt: DateTime(2026, 6, 15, 10),
        sourceModule: 'invoices',
        sourceRecordId: record.id,
        shareSubject: 'Invoice for Alex Customer',
        shareText: 'Please pay the attached invoice for 987 Oak Road.',
        documentRevisionHashSha256: hash,
        signatureState: AppGeneratedPdfSignatureState.unsigned,
      );

      final updated = record
          .recordPdfGenerated(pdf, fileHashSha256: hash)
          .recordPdfShared(
            pdfKind: pdf.kind.name,
            fileName: pdf.safeFileName,
            byteSize: pdf.byteSize,
            documentRevisionHashSha256: pdf.documentRevisionHashSha256,
            signatureState: pdf.signatureState.name,
            at: DateTime(2026, 6, 15, 10, 5),
          )
          .recordPdfDeliveryFailed(
            reasonCode: 'share_sheet_unavailable',
            pdfKind: pdf.kind.name,
            fileName: pdf.safeFileName,
            at: DateTime(2026, 6, 15, 10, 6),
          );

      final eventMaps = updated.pdfEvents
          .map((event) => event.toMap())
          .toList(growable: false);
      final encodedEvents = jsonEncode(eventMaps);

      expect(updated.documentHashSha256, hash);
      expect(updated.pdfEvents.map((event) => event.type), [
        InvoicePdfDeliveryEventType.generated,
        InvoicePdfDeliveryEventType.shared,
        InvoicePdfDeliveryEventType.failed,
      ]);
      expect(eventMaps.first['byteSize'], pdf.byteSize);
      expect(eventMaps.first['fileHashSha256'], hash);
      expect(eventMaps.first['documentRevisionHashSha256'], hash);
      expect(eventMaps[1]['signatureState'], 'unsigned');
      expect(eventMaps.last['reasonCode'], 'share_sheet_unavailable');
      expect(encodedEvents, isNot(contains('Alex Customer')));
      expect(encodedEvents, isNot(contains('987 Oak Road')));
      expect(encodedEvents, isNot(contains('alex@example.com')));
      expect(encodedEvents, isNot(contains('Gate code')));
      expect(encodedEvents, isNot(contains('Please pay')));
      expect(updated.toMap().containsKey('pdfBytes'), isFalse);
      expect(updated.toMap().containsKey('pdfPath'), isFalse);

      final reloaded = InvoiceRecord.fromMap(updated.toMap());
      expect(reloaded.pdfEvents, hasLength(3));
      expect(
        reloaded.pdfEvents.first.type,
        InvoicePdfDeliveryEventType.generated,
      );
      expect(reloaded.pdfEvents.first.fileHashSha256, hash);
    },
  );

  test(
    'invoice backup batches keep pdf metadata bounded and cloud safe',
    () async {
      final store = InvoiceLedgerStore.memory();
      final draft = await store.createDraft(
        type: InvoiceDocumentType.invoice,
        now: DateTime(2026, 6, 15, 8),
      );
      var record = draft;
      for (
        var index = 0;
        index < invoicePdfDeliveryEventHistoryLimit + 7;
        index++
      ) {
        record = record.recordPdfShared(
          pdfKind: 'invoice',
          fileName: 'invoice_INV-0001.pdf',
          byteSize: 45000 + index,
          at: DateTime(2026, 6, 15, 9).add(Duration(minutes: index)),
        );
      }
      await store.saveRecord(record, now: DateTime(2026, 6, 15, 10));

      final batchMap = store.dirtyDailyBatches().single.toMap();
      final recordMap = (batchMap['records'] as List).whereType<Map>().single;
      final pdfEvents = (recordMap['pdfEvents'] as List).whereType<Map>();
      final encodedBatch = jsonEncode(batchMap);

      expect(pdfEvents, hasLength(invoicePdfDeliveryEventHistoryLimit));
      expect(pdfEvents.first['byteSize'], 45007);
      expect(pdfEvents.last['byteSize'], 45056);
      expect(encodedBatch, contains('"pdfEvents"'));
      expect(encodedBatch, isNot(contains('pdfBytes')));
      expect(encodedBatch, isNot(contains('pdfPath')));
      expect(encodedBatch, isNot(contains('/var/mobile')));
      expect(encodedBatch, isNot(contains('/Users/')));
    },
  );

  test('invoice lifecycle timestamps never move backward', () async {
    final store = InvoiceLedgerStore.memory();
    final future = DateTime(2026, 6, 16, 12);
    final draft = await store.createDraft(
      type: InvoiceDocumentType.invoice,
      now: future,
    );

    final saved = await store.saveRecord(
      draft.copyWith(title: 'Corrected title'),
      now: DateTime(2026, 6, 15),
    );

    expect(saved.meta.updatedAt, future);
  });
}

InvoiceRecord _record() {
  final now = DateTime(2026, 6, 15);
  return InvoiceRecord(
    id: 'invoice_1',
    documentType: InvoiceDocumentType.invoice,
    invoiceNumber: 'INV-0001',
    numberMode: InvoiceNumberMode.automatic,
    status: InvoiceRecordStatus.draft,
    issueDate: now,
    meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
  );
}
