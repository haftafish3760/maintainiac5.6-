import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_export_manifest.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_document_export_manifest_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

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

  test('document export package verifies file size and hash', () async {
    final pdf = File('${tempDirectory.path}/job-packet.pdf');
    final bytes = utf8.encode('%PDF-1.7\nConfirmed job packet\n%%EOF');
    await pdf.writeAsBytes(bytes, flush: true);
    final hash = sha256.convert(bytes).toString();
    final record = _documentRecord(
      attachment: _pdfAttachment(
        path: pdf.path,
        displayName: 'job-packet.pdf',
        originalFileName: 'job-packet.pdf',
        byteSize: bytes.length,
        fileHash: hash,
      ),
    );

    final first = await AppDocumentExportManager.buildPackagePlan(
      record,
      freeStorageReader: () async => 2048,
    );
    final second = await AppDocumentExportManager.buildPackagePlan(
      record,
      freeStorageReader: () async => 2048,
    );

    expect(first.manifestJson, second.manifestJson);
    expect(
      first.manifestSha256,
      sha256.convert(utf8.encode(first.manifestJson)).toString(),
    );
    expect(first.files.single.byteSize, bytes.length);
    expect(first.files.single.sha256, hash);
    expect(first.files.single.path, pdf.path);
    expect(first.files.single.packageEntryName, 'job-packet.pdf');
    expect(first.files.single.toMap().toString(), isNot(contains(pdf.path)));
    expect(first.storageWarningMessage, isEmpty);
    expect(
      first.totalBytes,
      bytes.length + utf8.encode(first.manifestJson).length,
    );
  });

  test('document export package rejects tampered proof hash', () async {
    final pdf = File('${tempDirectory.path}/tampered.pdf');
    final bytes = utf8.encode('%PDF-1.7\nOriginal text\n%%EOF');
    await pdf.writeAsBytes(bytes, flush: true);
    final record = _documentRecord(
      attachment: _pdfAttachment(
        path: pdf.path,
        displayName: 'tampered.pdf',
        originalFileName: 'tampered.pdf',
        byteSize: bytes.length,
        fileHash: sha256.convert(bytes).toString(),
      ),
    );
    await pdf.writeAsBytes(
      utf8.encode('%PDF-1.7\nChanged text!\n%%EOF'),
      flush: true,
    );

    await expectLater(
      AppDocumentExportManager.buildPackagePlan(record),
      throwsA(
        isA<AppDocumentExportIntegrityException>()
            .having(
              (error) => error.issues.map((issue) => issue.code),
              'issue codes',
              contains(AppDocumentExportIntegrityIssue.hashMismatch),
            )
            .having(
              (error) => error.message,
              'message',
              contains('proof file changed'),
            ),
      ),
    );
  });

  test('document export package rejects stale partial files', () async {
    final partial = File('${tempDirectory.path}/job-packet.pdf.partial');
    final bytes = utf8.encode('%PDF-1.7\nStill writing\n%%EOF');
    await partial.writeAsBytes(bytes, flush: true);

    await expectLater(
      AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachment: _pdfAttachment(
            path: partial.path,
            displayName: 'job-packet.pdf',
            originalFileName: 'job-packet.pdf',
            byteSize: bytes.length,
            fileHash: sha256.convert(bytes).toString(),
          ),
        ),
      ),
      throwsA(
        isA<AppDocumentExportIntegrityException>().having(
          (error) => error.issues.map((issue) => issue.code),
          'issue codes',
          contains(AppDocumentExportIntegrityIssue.partialFile),
        ),
      ),
    );
  });

  test(
    'document export package rejects symlinked PDF proof files',
    () async {
      final outsidePdf = File('${tempDirectory.path}/outside-proof.pdf');
      final bytes = utf8.encode('%PDF-1.7\nOutside proof\n%%EOF');
      await outsidePdf.writeAsBytes(bytes, flush: true);
      final proofLink = Link('${tempDirectory.path}/linked-proof.pdf');
      await proofLink.create(outsidePdf.path);

      await expectLater(
        AppDocumentExportManager.buildPackagePlan(
          _documentRecord(
            attachment: _pdfAttachment(
              path: proofLink.path,
              displayName: 'linked-proof.pdf',
              originalFileName: 'linked-proof.pdf',
              byteSize: bytes.length,
              fileHash: sha256.convert(bytes).toString(),
            ),
          ),
        ),
        throwsA(
          isA<AppDocumentExportIntegrityException>()
              .having(
                (error) => error.issues.map((issue) => issue.code),
                'issue codes',
                contains(AppDocumentExportIntegrityIssue.symlinkProof),
              )
              .having(
                (error) => error.message,
                'message',
                contains('storage link'),
              ),
        ),
      );

      expect(await proofLink.exists(), isTrue);
      expect(await outsidePdf.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('document export package planning rechecks proof files safely', () {
    final source = File(
      'lib/shared/documents/app_document_export_manifest.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('Future<AppDocumentExportIntegrityIssue?> _regularProofIssue('),
    );
    expect(source, contains('followLinks: false'));
    expect(
      RegExp(
        r'await _regularProofIssue\(sourcePath, label\);',
      ).allMatches(source),
      hasLength(greaterThanOrEqualTo(5)),
    );
    expect(source, contains('final actualHash = await _safeFileHash(file);'));
    expect(source, contains('final pdfBytes = await _safeReadBytes(file);'));
  });

  test(
    'document export package rejects symlinked photo proof files',
    () async {
      final outsidePhoto = File('${tempDirectory.path}/outside-photo.jpg');
      final bytes = List<int>.generate(256, (index) => index % 251);
      await outsidePhoto.writeAsBytes(bytes, flush: true);
      final photoLink = Link('${tempDirectory.path}/linked-photo.jpg');
      await photoLink.create(outsidePhoto.path);

      await expectLater(
        AppDocumentExportManager.buildPackagePlan(
          _documentRecord(
            attachment: _photoAttachment(
              path: photoLink.path,
              byteSize: bytes.length,
              fileHash: sha256.convert(bytes).toString(),
            ),
          ),
        ),
        throwsA(
          isA<AppDocumentExportIntegrityException>().having(
            (error) => error.issues.map((issue) => issue.code),
            'issue codes',
            contains(AppDocumentExportIntegrityIssue.symlinkProof),
          ),
        ),
      );

      expect(await photoLink.exists(), isTrue);
      expect(await outsidePhoto.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document export package rejects missing and wrong-size files',
    () async {
      final missing = File('${tempDirectory.path}/missing.pdf');
      await expectLater(
        AppDocumentExportManager.buildPackagePlan(
          _documentRecord(
            attachment: _pdfAttachment(path: missing.path, byteSize: 12),
          ),
        ),
        throwsA(
          isA<AppDocumentExportIntegrityException>().having(
            (error) => error.issues.map((issue) => issue.code),
            'issue codes',
            contains(AppDocumentExportIntegrityIssue.missingFile),
          ),
        ),
      );

      final wrongSize = File('${tempDirectory.path}/wrong-size.pdf');
      await wrongSize.writeAsString('%PDF-1.7\n%%EOF', flush: true);
      await expectLater(
        AppDocumentExportManager.buildPackagePlan(
          _documentRecord(
            attachment: _pdfAttachment(
              path: wrongSize.path,
              byteSize: 999,
              fileHash: sha256
                  .convert(await wrongSize.readAsBytes())
                  .toString(),
            ),
          ),
        ),
        throwsA(
          isA<AppDocumentExportIntegrityException>().having(
            (error) => error.issues.map((issue) => issue.code),
            'issue codes',
            contains(AppDocumentExportIntegrityIssue.byteSizeMismatch),
          ),
        ),
      );
    },
  );

  test('document export package blocks active PDF proof content', () async {
    final pdf = File('${tempDirectory.path}/active-proof.pdf');
    final bytes = utf8.encode(
      '%PDF-1.7\n'
      '1 0 obj << /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
      '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
      '%%EOF',
    );
    await pdf.writeAsBytes(bytes, flush: true);

    await expectLater(
      AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachment: _pdfAttachment(
            path: pdf.path,
            displayName: 'active-proof.pdf',
            originalFileName: 'active-proof.pdf',
            byteSize: bytes.length,
            fileHash: sha256.convert(bytes).toString(),
          ),
        ),
      ),
      throwsA(
        isA<AppDocumentExportIntegrityException>()
            .having(
              (error) => error.issues.map((issue) => issue.code),
              'issue codes',
              contains(AppDocumentExportIntegrityIssue.unsafePdfContent),
            )
            .having(
              (error) => error.message,
              'message',
              contains('unsupported active content'),
            ),
      ),
    );
  });

  test('document export package blocks private PDF proof content', () async {
    final pdf = File('${tempDirectory.path}/private-proof.pdf');
    final bytes = utf8.encode(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page >> stream\n'
      'VIN 1HGCM82633A004352\n'
      'Passenger: Jane Customer\n'
      'endstream endobj\n'
      '%%EOF',
    );
    await pdf.writeAsBytes(bytes, flush: true);

    await expectLater(
      AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachment: _pdfAttachment(
            path: pdf.path,
            displayName: 'private-proof.pdf',
            originalFileName: 'private-proof.pdf',
            byteSize: bytes.length,
            fileHash: sha256.convert(bytes).toString(),
          ),
        ),
      ),
      throwsA(
        isA<AppDocumentExportIntegrityException>()
            .having(
              (error) => error.issues.map((issue) => issue.code),
              'issue codes',
              contains(AppDocumentExportIntegrityIssue.privatePdfContent),
            )
            .having(
              (error) => error.message,
              'message',
              contains('private information'),
            ),
      ),
    );
  });

  test('document export package allows verified photo proof files', () async {
    final photo = File('${tempDirectory.path}/receipt-photo.jpg');
    final bytes = List<int>.generate(256, (index) => index % 255);
    await photo.writeAsBytes(bytes, flush: true);

    final plan = await AppDocumentExportManager.buildPackagePlan(
      _documentRecord(
        attachment: _photoAttachment(
          path: photo.path,
          byteSize: bytes.length,
          fileHash: sha256.convert(bytes).toString(),
        ),
      ),
      freeStorageReader: () async => 500,
    );

    expect(plan.files.single.kind, ReceiptAttachmentKind.photo);
    expect(plan.files.single.sha256, sha256.convert(bytes).toString());
    expect(plan.files.single.toMap().toString(), isNot(contains(photo.path)));
  });

  test('document export package blocks when storage is too low', () async {
    final pdf = File('${tempDirectory.path}/low-storage.pdf');
    final bytes = utf8.encode('%PDF-1.7\nLow storage export\n%%EOF');
    await pdf.writeAsBytes(bytes, flush: true);

    await expectLater(
      AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachment: _pdfAttachment(
            path: pdf.path,
            displayName: 'low-storage.pdf',
            originalFileName: 'low-storage.pdf',
            byteSize: bytes.length,
            fileHash: sha256.convert(bytes).toString(),
          ),
        ),
        freeStorageReader: () async => 1,
      ),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('not enough free storage'),
        ),
      ),
    );
  });

  test('document export package carries low-storage warning', () async {
    final pdf = File('${tempDirectory.path}/low-warning.pdf');
    final bytes = utf8.encode('%PDF-1.7\nLow warning export\n%%EOF');
    await pdf.writeAsBytes(bytes, flush: true);

    final plan = await AppDocumentExportManager.buildPackagePlan(
      _documentRecord(
        attachment: _pdfAttachment(
          path: pdf.path,
          displayName: 'low-warning.pdf',
          originalFileName: 'low-warning.pdf',
          byteSize: bytes.length,
          fileHash: sha256.convert(bytes).toString(),
        ),
      ),
      freeStorageReader: () async => 75,
    );

    expect(plan.storageWarningMessage, contains('low on storage'));
    expect(plan.toMap()['storageWarningMessage'], plan.storageWarningMessage);
  });

  test('document export package records unknown storage warning', () async {
    final pdf = File('${tempDirectory.path}/unknown-storage.pdf');
    final bytes = utf8.encode('%PDF-1.7\nUnknown storage export\n%%EOF');
    await pdf.writeAsBytes(bytes, flush: true);

    final plan = await AppDocumentExportManager.buildPackagePlan(
      _documentRecord(
        attachment: _pdfAttachment(
          path: pdf.path,
          displayName: 'unknown-storage.pdf',
          originalFileName: 'unknown-storage.pdf',
          byteSize: bytes.length,
          fileHash: sha256.convert(bytes).toString(),
        ),
      ),
      freeStorageReader: () async => null,
    );

    expect(plan.storageWarningMessage, contains('could not verify'));
    expect(plan.toMap().toString(), isNot(contains(pdf.path)));
  });

  test('document export package creates unique safe entry names', () async {
    final firstPdf = File('${tempDirectory.path}/first.pdf');
    final secondPdf = File('${tempDirectory.path}/second.pdf');
    final photo = File('${tempDirectory.path}/photo.jpg');
    final firstBytes = utf8.encode('%PDF-1.7\nFirst\n%%EOF');
    final secondBytes = utf8.encode('%PDF-1.7\nSecond\n%%EOF');
    final photoBytes = List<int>.generate(128, (index) => index % 251);
    await firstPdf.writeAsBytes(firstBytes, flush: true);
    await secondPdf.writeAsBytes(secondBytes, flush: true);
    await photo.writeAsBytes(photoBytes, flush: true);

    final plan = await AppDocumentExportManager.buildPackagePlan(
      _documentRecord(
        attachments: [
          _pdfAttachment(
            id: 'first',
            path: firstPdf.path,
            displayName: r'C:\Users\Owner\Downloads\packet?.pdf',
            originalFileName: 'packet.pdf',
            byteSize: firstBytes.length,
            fileHash: sha256.convert(firstBytes).toString(),
          ),
          _pdfAttachment(
            id: 'second',
            path: secondPdf.path,
            displayName: '/Users/owner/Desktop/packet?.pdf',
            originalFileName: 'packet.pdf',
            byteSize: secondBytes.length,
            fileHash: sha256.convert(secondBytes).toString(),
          ),
          _photoAttachment(
            id: 'photo',
            path: photo.path,
            byteSize: photoBytes.length,
            fileHash: sha256.convert(photoBytes).toString(),
            displayName: '../../proof/photo:name',
          ),
        ],
      ),
      freeStorageReader: () async => 500,
    );

    final entryNames = plan.files
        .map((file) => file.packageEntryName)
        .toList(growable: false);
    expect(entryNames, ['packet-.pdf', 'packet--copy-2.pdf', 'photo-name.bin']);
    expect(entryNames.toSet(), hasLength(entryNames.length));
    expect(entryNames.join('\n'), isNot(contains('/Users')));
    expect(entryNames.join('\n'), isNot(contains(r'C:\Users')));
    expect(entryNames.join('\n'), isNot(contains('..')));
    expect(plan.toMap().toString(), contains('packageEntryName'));
  });

  test(
    'document export package entry names are safe on every platform',
    () async {
      final firstPdf = File('${tempDirectory.path}/first.pdf');
      final secondPdf = File('${tempDirectory.path}/second.pdf');
      final thirdPhoto = File('${tempDirectory.path}/third.jpg');
      final firstBytes = utf8.encode('%PDF-1.7\nReserved name\n%%EOF');
      final secondBytes = utf8.encode('%PDF-1.7\nDangerous extension\n%%EOF');
      final thirdBytes = List<int>.generate(64, (index) => 255 - index);
      await firstPdf.writeAsBytes(firstBytes, flush: true);
      await secondPdf.writeAsBytes(secondBytes, flush: true);
      await thirdPhoto.writeAsBytes(thirdBytes, flush: true);

      final plan = await AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachments: [
            _pdfAttachment(
              id: 'reserved-name',
              path: firstPdf.path,
              displayName: 'CON.pdf',
              originalFileName: 'CON.pdf',
              byteSize: firstBytes.length,
              fileHash: sha256.convert(firstBytes).toString(),
            ),
            _pdfAttachment(
              id: 'dangerous-extension',
              path: secondPdf.path,
              displayName: 'customer-packet.pdf.exe.scr',
              originalFileName: 'customer-packet.pdf.exe.scr',
              byteSize: secondBytes.length,
              fileHash: sha256.convert(secondBytes).toString(),
            ),
            _photoAttachment(
              id: 'empty-name',
              path: thirdPhoto.path,
              byteSize: thirdBytes.length,
              fileHash: sha256.convert(thirdBytes).toString(),
              displayName: '...',
            ),
          ],
        ),
        freeStorageReader: () async => 500,
      );

      final entryNames = plan.files
          .map((file) => file.packageEntryName)
          .toList(growable: false);
      expect(entryNames, [
        'maintainiac-CON.pdf',
        'customer-packet.pdf',
        'document-proof.bin',
      ]);
      expect(
        entryNames.map((entry) => path.basenameWithoutExtension(entry)),
        isNot(contains('CON')),
      );
      expect(entryNames.join('\n'), isNot(contains('.exe')));
      expect(entryNames.join('\n'), isNot(contains('.scr')));
    },
  );
}

AppDocumentRecord _documentRecord({
  String title = 'Job packet',
  String importedText = '',
  String notes = '',
  ReceiptAttachmentRecord? attachment,
  List<ReceiptAttachmentRecord>? attachments,
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
    attachments: attachments ?? [attachment ?? _pdfAttachment()],
  );
}

ReceiptAttachmentRecord _pdfAttachment({
  String id = 'pdf-local-id',
  String path = '/private/var/mobile/Containers/Data/Application/app/file.pdf',
  String displayName = 'job-packet.pdf',
  String originalFileName = 'job-packet.pdf',
  String sourceLabel = '',
  int? byteSize,
  String fileHash = 'abc123',
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
    byteSize: byteSize ?? 1024,
    fileHash: fileHash,
    pageCount: 3,
    documentSignals: documentSignals,
    sourceLabel: sourceLabel,
    linkedModule: 'jobs',
    linkedRecordId: 'DOC-job-123',
    readState: ReceiptAttachmentReadState.notRead,
  );
}

ReceiptAttachmentRecord _photoAttachment({
  String id = 'photo-local-id',
  required String path,
  required int byteSize,
  required String fileHash,
  String displayName = 'receipt-photo.jpg',
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: path,
    kind: ReceiptAttachmentKind.photo,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime.utc(2026, 7, 5, 9),
    displayName: displayName,
    originalFileName: displayName,
    mimeType: 'image/jpeg',
    byteSize: byteSize,
    fileHash: fileHash,
    documentSignals: const ['receipt'],
    linkedModule: 'jobs',
    linkedRecordId: 'DOC-job-123',
    readState: ReceiptAttachmentReadState.notRead,
  );
}
