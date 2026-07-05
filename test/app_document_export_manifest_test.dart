import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_export_manifest.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('document export manifest is deterministic and pathless', () {
    final record = _documentRecord(
      title: 'Signed customer packet',
      notes: 'Customer approved final work order.',
      importedText: 'Confirmed text layer only.',
      attachment: _pdfAttachment(
        displayName: '/Users/owner/private/customer-packet.pdf',
        originalFileName: r'C:\Users\Owner\Downloads\customer-packet.pdf',
      ),
    );

    final first = AppDocumentExportManager.requireManifest(record).toMap();
    final second = AppDocumentExportManager.requireManifest(record).toMap();
    final exported = first.toString().toLowerCase();

    expect(first, second);
    expect(first['documentId'], startsWith('document-'));
    expect(exported, isNot(contains('/users/owner')));
    expect(exported, isNot(contains(r'c:\users')));
    expect(exported, isNot(contains('doc-job-123')));
    expect(exported, isNot(contains('pdf-local-id')));
    expect(exported, contains('customer-packet.pdf'));
  });

  test('document export blocks private metadata before manifest creation', () {
    final review = AppDocumentExportManager.review(
      _documentRecord(
        title: 'Invoice for license plate ABC 123',
        importedText: 'Unconfirmed OCR suggestion subtotal 45.00',
        attachment: _pdfAttachment(
          displayName: 'receipt.pdf',
          originalFileName: 'receipt.pdf',
        ),
      ),
    );

    expect(review.canExport, isFalse);
    expect(review.manifest, isNull);
    expect(review.issues, contains(AppPdfPrivacyPolicy.licensePlate));
    expect(
      review.issues,
      contains(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion),
    );
    expect(review.userMessage, contains('unconfirmed OCR suggestions'));
  });

  test('document export blocks private attachment names and signals', () {
    final review = AppDocumentExportManager.review(
      _documentRecord(
        attachment: _pdfAttachment(
          displayName: 'Passenger: Jane receipt.pdf',
          originalFileName: '/Users/owner/Documents/receipt.pdf',
          sourceLabel: '/Users/owner/Documents/receipt.pdf',
          documentSignals: const ['Patient MRN 445566'],
        ),
      ),
    );

    expect(review.canExport, isFalse);
    expect(review.issues, contains(AppPdfPrivacyPolicy.privateSourcePath));
    expect(review.issues, contains(AppPdfPrivacyPolicy.patientData));
    expect(review.issues, contains(AppPdfPrivacyPolicy.passengerData));
  });

  test('document export never exposes source file path or internal ids', () {
    final manifest = AppDocumentExportManager.requireManifest(
      _documentRecord(
        attachment: _pdfAttachment(
          id: 'ATTACH-internal-456',
          path: '/storage/emulated/0/Download/customer-packet.pdf',
          displayName: 'customer-packet.pdf',
          originalFileName: 'customer-packet.pdf',
        ),
      ),
    );
    final map = manifest.toMap();
    final exported = map.toString();

    expect(exported, isNot(contains('/storage/emulated')));
    expect(exported, isNot(contains('ATTACH-internal-456')));
    expect(exported, isNot(contains('DOC-job-123')));
    expect(map['attachments'].toString(), contains('attachment-'));
    expect(map['attachments'].toString(), contains('readState'));
    expect(map['attachments'].toString(), contains('isReadOnlyProof'));
  });

  test('document export throws a typed failure for blocked documents', () {
    expect(
      () => AppDocumentExportManager.requireManifest(
        _documentRecord(notes: 'VIN 1HGCM82633A004352'),
      ),
      throwsA(
        isA<AppDocumentExportBlockedException>()
            .having(
              (error) => error.issues,
              'issues',
              contains(AppPdfPrivacyPolicy.vin),
            )
            .having(
              (error) => error.message,
              'message',
              contains('private information'),
            ),
      ),
    );
  });
}

AppDocumentRecord _documentRecord({
  String title = 'Job packet',
  String importedText = '',
  String notes = '',
  ReceiptAttachmentRecord? attachment,
}) {
  return AppDocumentRecord(
    id: 'DOC-job-123',
    kind: AppDocumentKind.jobContractorDocument,
    title: title,
    importedText: importedText,
    notes: notes,
    sourceLabel: 'Shared import',
    createdAt: DateTime.utc(2026, 7, 5, 9),
    updatedAt: DateTime.utc(2026, 7, 5, 9, 30),
    attachments: [attachment ?? _pdfAttachment()],
  );
}

ReceiptAttachmentRecord _pdfAttachment({
  String id = 'pdf-local-id',
  String path = '/private/var/mobile/Containers/Data/Application/app/file.pdf',
  String displayName = 'job-packet.pdf',
  String originalFileName = 'job-packet.pdf',
  String sourceLabel = '',
  List<String> documentSignals = const ['invoice', 'job'],
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: path,
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime.utc(2026, 7, 5, 9),
    displayName: displayName,
    originalFileName: originalFileName,
    mimeType: 'application/pdf',
    byteSize: 1024,
    fileHash: 'abc123',
    pageCount: 3,
    documentSignals: documentSignals,
    sourceLabel: sourceLabel,
    linkedModule: 'jobs',
    linkedRecordId: 'DOC-job-123',
    readState: ReceiptAttachmentReadState.notRead,
  );
}
