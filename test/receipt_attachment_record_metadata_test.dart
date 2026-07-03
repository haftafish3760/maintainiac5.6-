import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('receipt attachment labels identify imported sources', () {
    final email = ReceiptAttachmentRecord(
      id: 'email-1',
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      importedText: 'TOTAL 12.99',
    );
    final pdf = ReceiptAttachmentRecord(
      id: 'pdf-1',
      path: '/tmp/receipt.pdf',
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      displayName: 'Advance Auto receipt.pdf',
    );

    expect(email.label, 'Receipt text');
    expect(email.isImportedText, isTrue);
    expect(pdf.label, 'Advance Auto receipt.pdf');
    expect(pdf.isImportedText, isFalse);
  });

  test('receipt attachment copy keeps source identity while editing text', () {
    final original = ReceiptAttachmentRecord(
      id: 'email-1',
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      displayName: 'Advance Auto email',
      importedText: 'TOTAL 12.99',
      byteSize: 11,
      sourceLabel: 'SMS/Text',
    );

    final edited = original.copyWith(
      displayName: 'Advance Auto corrected',
      importedText: 'OIL FILTER 12.99\nTOTAL 12.99',
      byteSize: 29,
    );

    expect(edited.id, original.id);
    expect(edited.kind, ReceiptAttachmentKind.emailText);
    expect(edited.createdAt, original.createdAt);
    expect(edited.label, 'Advance Auto corrected');
    expect(edited.importedText, contains('OIL FILTER'));
    expect(edited.byteSize, 29);
  });

  test('receipt attachment metadata survives storage maps', () {
    final attachment = ReceiptAttachmentRecord(
      id: 'pdf-1',
      path: '/tmp/receipt.pdf',
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: DateTime(2026, 6, 13),
      displayName: 'fuel.pdf',
      byteSize: 1200,
      fileHash: 'abc123',
      pageCount: 3,
      sourceLabel: 'Files/PDF',
      readState: ReceiptAttachmentReadState.readIntoForm,
    );

    final restored = ReceiptAttachmentRecord.fromMap(attachment.toMap());

    expect(restored.fileHash, 'abc123');
    expect(restored.pageCount, 3);
    expect(restored.sourceLabel, 'Files/PDF');
    expect(restored.originalFileName, '');
    expect(restored.mimeType, '');
    expect(restored.linkedModule, '');
    expect(restored.linkedRecordId, '');
    expect(restored.isOriginalImmutable, isTrue);
    expect(restored.readState, ReceiptAttachmentReadState.readIntoForm);
    expect(restored.isReadOnlyProof, isTrue);
    expect(restored.canEditProofFileInApp, isFalse);
    expect(restored.proofAccessLabel, 'read-only PDF proof');
  });

  test('receipt attachment enum names tolerate padded storage values', () {
    final restored = ReceiptAttachmentRecord.fromMap({
      'id': 'pdf-padded',
      'path': '/tmp/receipt.pdf',
      'kind': ' pdf ',
      'dataSaverLevel': ' original ',
      'createdAt': DateTime(2026, 6, 13).toIso8601String(),
      'pageCountStatus': ' verified ',
      'validationStatus': ' valid ',
      'storageState': ' staged ',
      'readState': ' readIntoForm ',
    });

    expect(restored.kind, ReceiptAttachmentKind.pdf);
    expect(restored.dataSaverLevel, ReceiptDataSaverLevel.original);
    expect(restored.pageCountStatus, ReceiptPdfPageCountStatus.verified);
    expect(restored.validationStatus, ReceiptPdfValidationStatus.valid);
    expect(restored.storageState, ReceiptAttachmentStorageState.staged);
    expect(restored.readState, ReceiptAttachmentReadState.readIntoForm);
  });

  test('receipt photo quality metadata survives storage maps', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 148,
      contrast: 40,
      cropScore: .78,
      textBandScore: 14,
      isLikelyReadable: true,
    );
    final attachment = ReceiptAttachmentRecord(
      id: 'photo-1',
      path: '/tmp/receipt.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 13),
      byteSize: 2200,
    ).withPhotoQuality(quality);

    final restored = ReceiptAttachmentRecord.fromMap(attachment.toMap());

    expect(restored.hasPhotoQualityReview, isTrue);
    expect(restored.photoQualityNeedsReview, isFalse);
    expect(restored.photoQualityScore, quality.reviewScore);
    expect(restored.photoQualityIssueLabel, 'looks readable');
    expect(restored.photoQualityWarnings, isEmpty);
    expect(restored.photoWidth, 1800);
    expect(restored.photoHeight, 2400);
    expect(restored.photoBrightness, 148);
    expect(restored.photoContrast, 40);
    expect(restored.photoFocusScore, 15);
    expect(restored.photoCropScore, .78);
    expect(restored.photoTextBandScore, 14);
    expect(restored.photoQualityLabel, contains('Photo quality'));
  });

  test('photo quality warning does not erase read-into-form proof state', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 900,
      height: 1200,
      focusScore: 5,
      brightness: 84,
      contrast: 18,
      cropScore: .45,
      textBandScore: 4,
      isLikelyReadable: false,
    );
    final attachment = ReceiptAttachmentRecord(
      id: 'photo-read',
      path: '/tmp/read.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 13),
      readState: ReceiptAttachmentReadState.readIntoForm,
    ).withPhotoQuality(quality);

    expect(attachment.photoQualityNeedsReview, isTrue);
    expect(attachment.readState, ReceiptAttachmentReadState.readIntoForm);
  });

  test(
    'imported text remains editable while original proof files stay locked',
    () {
      final text = ReceiptAttachmentRecord(
        id: 'sms-1',
        path: '',
        kind: ReceiptAttachmentKind.textMessageText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 13),
        importedText: 'TOTAL 24.50',
      );
      final photo = ReceiptAttachmentRecord(
        id: 'photo-1',
        path: '/tmp/receipt.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 13),
      );

      expect(text.isReadOnlyProof, isFalse);
      expect(text.proofAccessLabel, 'editable receipt text');
      expect(photo.isReadOnlyProof, isTrue);
      expect(photo.proofAccessLabel, 'read-only receipt photo');
      expect(photo.canEditProofFileInApp, isFalse);
    },
  );
}
