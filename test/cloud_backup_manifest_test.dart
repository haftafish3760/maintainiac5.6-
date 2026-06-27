import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_manifest.dart';
import 'package:maintaniac/shared/backup/cloud_backup_pdf_policy.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/media/app_media_asset.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('document backup manifest excludes invoice documents by default', () {
    final manifest = CloudBackupManifest.fromDocuments(
      documents: [
        _document(
          id: 'DOC-invoice-1',
          kind: AppDocumentKind.invoiceDocument,
          attachment: _attachment(id: 'invoice-pdf', bytes: 4000),
        ),
        _document(
          id: 'DOC-job-1',
          kind: AppDocumentKind.jobContractorDocument,
          attachment: _attachment(id: 'job-pdf', bytes: 2000),
        ),
      ],
      createdAt: DateTime(2026, 6, 16),
    );

    expect(manifest.entryCount, 1);
    expect(manifest.pendingBytes, 2000);
    expect(manifest.estimatedCloudBytes, 2000);
    expect(manifest.entries.single.recordId, 'DOC-job-1');
    expect(manifest.entries.single.isCustomerProtected, isFalse);
  });

  test(
    'document backup manifest includes invoice documents with explicit opt in',
    () {
      final manifest = CloudBackupManifest.fromDocuments(
        documents: [
          _document(
            id: 'DOC-invoice-1',
            kind: AppDocumentKind.invoiceDocument,
            attachment: _attachment(id: 'invoice-pdf', bytes: 4000),
          ),
        ],
        includeCustomerProtected: true,
        createdAt: DateTime(2026, 6, 16),
      );

      expect(manifest.entryCount, 1);
      expect(manifest.pendingBytes, 4000);
      expect(manifest.estimatedCloudBytes, 4000);
      expect(manifest.entries.single.isCustomerProtected, isTrue);
      expect(
        manifest.entries.single.toMap()['privacyScope'],
        'customerProtected',
      );
    },
  );

  test(
    'document backup manifest includes only cloud eligible media assets',
    () {
      final manifest = CloudBackupManifest.fromDocuments(
        documents: const [],
        mediaAssets: [
          AppMediaAsset(
            id: 'MEDIA-logo',
            path: '/app/logo.png',
            purpose: AppMediaAssetPurpose.companyLogo,
            createdAt: DateTime(2026, 6, 16),
            displayName: 'logo.png',
            mimeType: 'image/png',
            byteSize: 1500,
            fileHash: 'logo-hash',
            backupPolicy: AppMediaAssetBackupPolicy.cloudEligible,
          ),
          AppMediaAsset(
            id: 'MEDIA-local',
            path: '/app/local.png',
            purpose: AppMediaAssetPurpose.companyLogo,
            createdAt: DateTime(2026, 6, 16),
            byteSize: 1500,
            fileHash: 'local-hash',
            backupPolicy: AppMediaAssetBackupPolicy.localOnly,
          ),
        ],
        createdAt: DateTime(2026, 6, 16),
      );

      expect(manifest.entryCount, 1);
      expect(manifest.pendingBytes, 1500);
      expect(manifest.estimatedCloudBytes, 1500);
      expect(manifest.entries.single.id, 'MEDIA-logo');
      expect(manifest.entries.single.module, 'company');
    },
  );

  test('large scanned receipt PDFs are deferred before cloud backup', () {
    final manifest = CloudBackupManifest.fromDocuments(
      documents: [
        _document(
          id: 'DOC-receipt-1',
          kind: AppDocumentKind.otherDocument,
          attachment: _attachment(
            id: 'large-receipt-pdf',
            bytes: 14 * 1024 * 1024,
            pageCount: 18,
          ),
        ),
      ],
      createdAt: DateTime(2026, 6, 16),
    );

    final entry = manifest.entries.single;
    expect(entry.cloudBackupAction, CloudBackupFileAction.deferUntilOptimized);
    expect(entry.estimatedCloudBytes, lessThan(entry.byteSize));
    expect(entry.cloudBackupReason, contains('optimized'));
    expect(manifest.estimatedCloudBytes, entry.estimatedCloudBytes);
  });

  test('very large receipt PDFs stay local for free-tier backup', () {
    final manifest = CloudBackupManifest.fromDocuments(
      documents: [
        _document(
          id: 'DOC-receipt-2',
          kind: AppDocumentKind.otherDocument,
          attachment: _attachment(
            id: 'huge-receipt-pdf',
            bytes: 24 * 1024 * 1024,
            pageCount: 40,
          ),
        ),
      ],
      createdAt: DateTime(2026, 6, 16),
    );

    final entry = manifest.entries.single;
    expect(entry.cloudBackupAction, CloudBackupFileAction.localOnlyTooLarge);
    expect(entry.cloudBackupReason, contains('too large'));
  });

  test('generated invoice PDFs are eligible but still customer protected', () {
    final manifest = CloudBackupManifest.fromDocuments(
      documents: [
        _document(
          id: 'DOC-invoice-generated',
          kind: AppDocumentKind.invoiceDocument,
          sourceLabel: 'Generated PDF',
          attachment: _attachment(
            id: 'generated-invoice-pdf',
            bytes: 5 * 1024 * 1024,
            pageCount: 3,
          ),
        ),
      ],
      includeCustomerProtected: true,
      createdAt: DateTime(2026, 6, 16),
    );

    final entry = manifest.entries.single;
    expect(entry.isCustomerProtected, isTrue);
    expect(entry.cloudBackupAction, CloudBackupFileAction.useOptimizedCopy);
    expect(entry.estimatedCloudBytes, lessThan(entry.byteSize));
    expect(entry.toMap()['cloudBackupAction'], 'useOptimizedCopy');
  });
}

AppDocumentRecord _document({
  required String id,
  required AppDocumentKind kind,
  required ReceiptAttachmentRecord attachment,
  String sourceLabel = '',
}) {
  return AppDocumentRecord(
    id: id,
    kind: kind,
    title: id,
    sourceLabel: sourceLabel,
    createdAt: DateTime(2026, 6, 16),
    updatedAt: DateTime(2026, 6, 16),
    attachments: [attachment],
  );
}

ReceiptAttachmentRecord _attachment({
  required String id,
  required int bytes,
  int? pageCount,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '/app/$id.pdf',
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime(2026, 6, 16),
    displayName: '$id.pdf',
    mimeType: 'application/pdf',
    byteSize: bytes,
    fileHash: '$id-hash',
    pageCount: pageCount,
  );
}
