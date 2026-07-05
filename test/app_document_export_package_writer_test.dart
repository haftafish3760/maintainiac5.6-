import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_export_manifest.dart';
import 'package:maintaniac/shared/documents/app_document_export_package_writer.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_document_export_package_writer_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'document export writer creates deterministic verified zip package',
    () async {
      final pdf = await _writeProof(
        tempDirectory,
        name: 'invoice-proof.pdf',
        bytes: utf8.encode('%PDF-1.7\nConfirmed invoice proof\n%%EOF'),
      );
      final photo = await _writeProof(
        tempDirectory,
        name: 'receipt-photo.jpg',
        bytes: List<int>.generate(96, (index) => index % 251),
      );
      final record = _documentRecord(
        attachments: [
          _pdfAttachment(
            path: pdf.path,
            byteSize: await pdf.length(),
            fileHash: await _fileHash(pdf),
            displayName: 'invoice-proof.pdf',
          ),
          _photoAttachment(
            path: photo.path,
            byteSize: await photo.length(),
            fileHash: await _fileHash(photo),
            displayName: 'receipt-photo.jpg',
          ),
        ],
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final writer = AppDocumentExportPackageWriter();

      final first = await writer.writeZipPackage(
        record: record,
        outputDirectory: outputDirectory,
        freeStorageReader: () async => 500,
      );
      final second = await writer.writeZipPackage(
        record: record,
        outputDirectory: outputDirectory,
        freeStorageReader: () async => 500,
      );
      final firstBytes = await File(first.filePath).readAsBytes();
      final secondBytes = await File(second.filePath).readAsBytes();

      expect(firstBytes, secondBytes);
      expect(first.fileName, startsWith('maintainiac-'));
      expect(first.fileName, endsWith('.zip'));
      expect(second.fileName, contains('-copy-2.zip'));
      expect(first.manifestEntryName, 'maintainiac_document_manifest.json');
      expect(first.fileEntries, ['invoice-proof.pdf', 'receipt-photo.jpg']);
      expect(first.byteSize, firstBytes.length);
      expect(first.sha256, sha256.convert(firstBytes).toString());
      expect(first.manifestSha256, isNotEmpty);
      expect(first.toMap().toString(), isNot(contains(tempDirectory.path)));
      expect(await pdf.exists(), isTrue);
      expect(await photo.exists(), isTrue);

      final decoded = ZipDecoder().decodeBytes(firstBytes);
      final entries = <String, ArchiveFile>{
        for (final entry in decoded.files) entry.name: entry,
      };
      expect(entries.keys, contains('maintainiac_document_manifest.json'));
      expect(entries.keys, contains('invoice-proof.pdf'));
      expect(entries.keys, contains('receipt-photo.jpg'));
      final manifestBytes = entries['maintainiac_document_manifest.json']!
          .readBytes()!;
      final manifestJson = utf8.decode(manifestBytes);
      expect(
        sha256.convert(utf8.encode(manifestJson)).toString(),
        first.manifestSha256,
      );
      expect(manifestJson, contains('"kind": "jobContractorDocument"'));
      expect(manifestJson, isNot(contains(tempDirectory.path)));
      expect(
        sha256.convert(entries['invoice-proof.pdf']!.readBytes()!).toString(),
        await _fileHash(pdf),
      );
      expect(
        sha256.convert(entries['receipt-photo.jpg']!.readBytes()!).toString(),
        await _fileHash(photo),
      );
    },
  );

  test(
    'document export writer rolls back partial package on rename failure',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nRollback proof\n%%EOF'),
      );
      final record = _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
          displayName: 'job-packet.pdf',
        ),
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final plan = await AppDocumentExportManager.buildPackagePlan(
        record,
        freeStorageReader: () async => 500,
      );
      final blockingDirectory = Directory(
        '${outputDirectory.path}/'
        'maintainiac-${plan.manifest.kind.name}-'
        '${plan.manifestSha256.substring(0, 12)}.zip',
      );
      await blockingDirectory.create(recursive: true);

      await expectLater(
        AppDocumentExportPackageWriter().writeZipPackage(
          record: record,
          outputDirectory: outputDirectory,
          freeStorageReader: () async => 500,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('No source records or proof files were changed'),
          ),
        ),
      );

      expect(await File('${blockingDirectory.path}.partial').exists(), isFalse);
      expect(await blockingDirectory.exists(), isTrue);
      expect(await proof.exists(), isTrue);
      expect(await _fileHash(proof), plan.files.single.sha256);
    },
  );

  test(
    'document export writer rejects tampered zip bytes before writing',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nVerified proof\n%%EOF'),
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final writer = AppDocumentExportPackageWriter(
        zipBytesBuilder: (plan) async {
          final archive = Archive()
            ..addFile(
              ArchiveFile.string(
                AppDocumentExportPackageWriter.manifestEntryName,
                plan.manifestJson,
              ),
            );
          return ZipEncoder().encode(archive, modified: DateTime.utc(2026));
        },
      );

      await expectLater(
        writer.writeZipPackage(
          record: _documentRecord(
            attachment: _pdfAttachment(
              path: proof.path,
              byteSize: await proof.length(),
              fileHash: await _fileHash(proof),
            ),
          ),
          outputDirectory: outputDirectory,
          freeStorageReader: () async => 500,
        ),
        throwsA(isA<AppDocumentExportPackageException>()),
      );

      expect(await outputDirectory.exists(), isFalse);
      expect(await proof.exists(), isTrue);
    },
  );

  test(
    'document export writer preserves safe duplicate package entries',
    () async {
      final first = await _writeProof(
        tempDirectory,
        name: 'first.pdf',
        bytes: utf8.encode('%PDF-1.7\nFirst duplicate\n%%EOF'),
      );
      final second = await _writeProof(
        tempDirectory,
        name: 'second.pdf',
        bytes: utf8.encode('%PDF-1.7\nSecond duplicate\n%%EOF'),
      );
      final record = _documentRecord(
        attachments: [
          _pdfAttachment(
            id: 'first',
            path: first.path,
            displayName: r'C:\Users\Owner\Downloads\packet?.pdf',
            byteSize: await first.length(),
            fileHash: await _fileHash(first),
          ),
          _pdfAttachment(
            id: 'second',
            path: second.path,
            displayName: '/Users/owner/Desktop/packet?.pdf',
            byteSize: await second.length(),
            fileHash: await _fileHash(second),
          ),
        ],
      );

      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: record,
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final decoded = ZipDecoder().decodeBytes(
        await File(result.filePath).readAsBytes(),
      );
      final names = decoded.files.map((entry) => entry.name).toList();

      expect(result.fileEntries, ['packet-.pdf', 'packet--copy-2.pdf']);
      expect(names, contains('packet-.pdf'));
      expect(names, contains('packet--copy-2.pdf'));
      expect(names.join('\n'), isNot(contains('/Users')));
      expect(names.join('\n'), isNot(contains(r'C:\Users')));
      expect(names.join('\n'), isNot(contains('..')));
    },
  );
}

Future<File> _writeProof(
  Directory directory, {
  required String name,
  required List<int> bytes,
}) async {
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<String> _fileHash(File file) async {
  return (await sha256.bind(file.openRead()).first).toString();
}

AppDocumentRecord _documentRecord({
  String title = 'Job packet',
  ReceiptAttachmentRecord? attachment,
  List<ReceiptAttachmentRecord>? attachments,
}) {
  return AppDocumentRecord(
    id: 'DOC-job-123',
    kind: AppDocumentKind.jobContractorDocument,
    title: title,
    sourceLabel: 'Shared import',
    createdAt: DateTime.utc(2026, 7, 5, 9),
    updatedAt: DateTime.utc(2026, 7, 5, 9, 30),
    attachments: attachments ?? [attachment ?? _pdfAttachment()],
  );
}

ReceiptAttachmentRecord _pdfAttachment({
  String id = 'pdf-local-id',
  String path = '/private/app/file.pdf',
  String displayName = 'job-packet.pdf',
  int? byteSize,
  String fileHash = 'abc123',
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: path,
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime.utc(2026, 7, 5, 9),
    displayName: displayName,
    originalFileName: displayName,
    mimeType: 'application/pdf',
    byteSize: byteSize ?? 1024,
    fileHash: fileHash,
    pageCount: 2,
    documentSignals: const ['job'],
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
