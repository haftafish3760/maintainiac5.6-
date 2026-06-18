import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_store.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/media/app_media_asset.dart';

void main() {
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
