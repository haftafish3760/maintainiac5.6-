import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_export_manifest.dart';
import 'package:maintaniac/shared/documents/app_document_export_package_writer.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

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
      expect(
        first.packageIndexEntryName,
        'maintainiac_document_package_index.json',
      );
      expect(first.toMap().toString(), isNot(contains(tempDirectory.path)));
      expect(await pdf.exists(), isTrue);
      expect(await photo.exists(), isTrue);

      final decoded = ZipDecoder().decodeBytes(firstBytes);
      final entries = <String, ArchiveFile>{
        for (final entry in decoded.files) entry.name: entry,
      };
      expect(entries.keys, contains('maintainiac_document_manifest.json'));
      expect(entries.keys, contains('maintainiac_document_package_index.json'));
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
      final readResult = await AppDocumentExportPackageWriter.readZipPackage(
        File(first.filePath),
      );
      expect(readResult.fileName, first.fileName);
      expect(readResult.byteSize, first.byteSize);
      expect(readResult.sha256, first.sha256);
      expect(readResult.manifestSha256, first.manifestSha256);
      expect(readResult.kindName, 'jobContractorDocument');
      expect(readResult.fileEntries, first.fileEntries);
      expect(
        readResult.totalProofBytes,
        await pdf.length() + await photo.length(),
      );
      expect(
        readResult.toMap().toString(),
        isNot(contains(tempDirectory.path)),
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
    'document export writer removes stale app-owned partial packages only',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nStale partial proof\n%%EOF'),
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
      await outputDirectory.create(recursive: true);
      final plan = await AppDocumentExportManager.buildPackagePlan(
        record,
        freeStorageReader: () async => 500,
      );
      final baseName =
          'maintainiac-${plan.manifest.kind.name}-'
          '${plan.manifestSha256.substring(0, 12)}.zip';
      final stalePartial = File('${outputDirectory.path}/$baseName.partial');
      final freshPartial = File('${outputDirectory.path}/fresh.zip.partial');
      final hostilePartial = File(
        '${outputDirectory.path}/customer-export.zip.partial',
      );
      final completePackage = File('${outputDirectory.path}/$baseName');
      await stalePartial.writeAsString('stale partial', flush: true);
      await freshPartial.writeAsString('fresh partial', flush: true);
      await hostilePartial.writeAsString('not app owned', flush: true);
      await completePackage.writeAsString('complete package', flush: true);
      final oldTime = DateTime.now().subtract(const Duration(hours: 13));
      await stalePartial.setLastModified(oldTime);
      await hostilePartial.setLastModified(oldTime);

      final deleted = await AppDocumentExportPackageWriter.cleanupStalePartials(
        outputDirectory,
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: record,
        outputDirectory: outputDirectory,
        freeStorageReader: () async => 500,
      );

      expect(deleted, [path.basename(stalePartial.path)]);
      expect(await stalePartial.exists(), isFalse);
      expect(await freshPartial.exists(), isTrue);
      expect(await hostilePartial.exists(), isTrue);
      expect(await completePackage.exists(), isTrue);
      expect(result.fileName, contains('-copy-2.zip'));
      expect(await proof.exists(), isTrue);
    },
  );

  test(
    'document export writer removes app-owned symlink partial only',
    () async {
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      await outputDirectory.create(recursive: true);
      final outsideTarget = File('${tempDirectory.path}/outside-partial.zip');
      await outsideTarget.writeAsString('outside partial target', flush: true);
      final partialLink = Link(
        '${outputDirectory.path}/maintainiac-job-abcdef123456.zip.partial',
      );
      await partialLink.create(outsideTarget.path);

      final deleted = await AppDocumentExportPackageWriter.cleanupStalePartials(
        outputDirectory,
      );

      expect(deleted, [path.basename(partialLink.path)]);
      expect(await partialLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document export writer refuses symlinked output directory',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nSymlinked export proof\n%%EOF'),
      );
      final outside = Directory('${tempDirectory.path}/outside-exports');
      await outside.create(recursive: true);
      final outputLink = Link('${tempDirectory.path}/exports-link');
      await outputLink.create(outside.path);

      await expectLater(
        AppDocumentExportPackageWriter().writeZipPackage(
          record: _documentRecord(
            attachment: _pdfAttachment(
              path: proof.path,
              byteSize: await proof.length(),
              fileHash: await _fileHash(proof),
            ),
          ),
          outputDirectory: Directory(outputLink.path),
          freeStorageReader: () async => 500,
        ),
        throwsA(isA<AppDocumentExportPackageException>()),
      );

      expect(await outside.list().isEmpty, isTrue);
      expect(await proof.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document export package reader refuses symlinked package file',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nSymlinked package proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final packageLink = Link('${tempDirectory.path}/package-link.zip');
      await packageLink.create(result.filePath);

      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(File(packageLink.path)),
        throwsA(isA<AppDocumentExportPackageException>()),
      );

      expect(await packageLink.exists(), isTrue);
      expect(await File(result.filePath).exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('document export package reader rechecks package files safely', () {
    final source = File(
      'lib/shared/documents/app_document_export_package_writer.dart',
    ).readAsStringSync();

    expect(source, contains('Future<List<int>> _readVerifiedPackageBytes('));
    expect(source, contains('await _requireRegularPackageFile(packageFile);'));
    expect(source, contains('final bytes = await packageFile.readAsBytes();'));
    expect(source, contains('final currentSize = await packageFile.length();'));
    expect(source, contains('currentSize != bytes.length'));
    expect(source, contains('followLinks: false'));
    expect(
      source,
      contains('final packageBytes = await _readVerifiedPackageBytes'),
    );
  });

  test(
    'document export writer keeps fresh matching partial and writes copy',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nFresh partial proof\n%%EOF'),
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
      await outputDirectory.create(recursive: true);
      final plan = await AppDocumentExportManager.buildPackagePlan(
        record,
        freeStorageReader: () async => 500,
      );
      final baseName =
          'maintainiac-${plan.manifest.kind.name}-'
          '${plan.manifestSha256.substring(0, 12)}.zip';
      final freshPartial = File('${outputDirectory.path}/$baseName.partial');
      await freshPartial.writeAsString('fresh partial', flush: true);

      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: record,
        outputDirectory: outputDirectory,
        freeStorageReader: () async => 500,
      );

      expect(await freshPartial.exists(), isTrue);
      expect(result.fileName, contains('-copy-2.zip'));
      expect(
        await AppDocumentExportPackageWriter.readZipPackage(
          File(result.filePath),
        ),
        isA<AppDocumentExportPackageReadResult>(),
      );
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
    'document export writer rejects malformed generated zip bytes safely',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nMalformed builder proof\n%%EOF'),
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final writer = AppDocumentExportPackageWriter(
        zipBytesBuilder: (_) async => const [0, 1, 2, 3, 4, 5],
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
        throwsA(
          isA<AppDocumentExportPackageException>()
              .having(
                (error) => error.message,
                'message',
                anyOf(
                  contains('ZIP verification failed'),
                  contains('unexpected entries'),
                ),
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains(tempDirectory.path)),
              ),
        ),
      );

      expect(await outputDirectory.exists(), isFalse);
      expect(await proof.exists(), isTrue);
    },
  );

  test(
    'document export writer rejects source proof changed after planning',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nOriginal planned proof\n%%EOF'),
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final writer = AppDocumentExportPackageWriter(
        zipBytesBuilder: (plan) async {
          await proof.writeAsBytes(
            utf8.encode('%PDF-1.7\nChanged after planning\n%%EOF'),
            flush: true,
          );
          return AppDocumentExportPackageWriter.buildZipBytes(plan);
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
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('verify a proof file'),
          ),
        ),
      );

      expect(await outputDirectory.exists(), isFalse);
    },
  );

  test(
    'document export writer rejects source proof replaced by symlink',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nOriginal file proof\n%%EOF'),
      );
      final outside = await _writeProof(
        tempDirectory,
        name: 'outside-proof.pdf',
        bytes: utf8.encode('%PDF-1.7\nOriginal file proof\n%%EOF'),
      );
      final outputDirectory = Directory('${tempDirectory.path}/exports');
      final writer = AppDocumentExportPackageWriter(
        zipBytesBuilder: (plan) async {
          await proof.delete();
          await Link(proof.path).create(outside.path);
          return AppDocumentExportPackageWriter.buildZipBytes(plan);
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

      expect(await Link(proof.path).exists(), isTrue);
      expect(await outside.exists(), isTrue);
      expect(await outputDirectory.exists(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document export writer rejects generated index byte total mismatch',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nBad generated total proof\n%%EOF'),
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
            )
            ..addFile(
              ArchiveFile.string(
                AppDocumentExportPackageWriter.packageIndexEntryName,
                const JsonEncoder.withIndent('  ').convert({
                  'schema': 'maintainiac_document_export_package_index_v1',
                  'manifestEntryName':
                      AppDocumentExportPackageWriter.manifestEntryName,
                  'packageIndexEntryName':
                      AppDocumentExportPackageWriter.packageIndexEntryName,
                  'manifestSha256': plan.manifestSha256,
                  'totalBytes': 1,
                  'files': [for (final file in plan.files) file.toMap()],
                }),
              ),
            );
          for (final file in plan.files) {
            archive.addFile(
              ArchiveFile.bytes(
                file.packageEntryName,
                await File(file.path).readAsBytes(),
              ),
            );
          }
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
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('index verification failed'),
          ),
        ),
      );

      expect(await outputDirectory.exists(), isFalse);
      expect(await proof.exists(), isTrue);
    },
  );

  test(
    'document export package build hides source paths when proof read fails',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'missing-during-build.pdf',
        bytes: utf8.encode('%PDF-1.7\nRead failure proof\n%%EOF'),
      );
      final plan = await AppDocumentExportManager.buildPackagePlan(
        _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
            displayName: 'missing-during-build.pdf',
          ),
        ),
        freeStorageReader: () async => 500,
      );
      await proof.delete();

      await expectLater(
        AppDocumentExportPackageWriter.buildZipBytes(plan),
        throwsA(
          isA<AppDocumentExportPackageException>()
              .having(
                (error) => error.message,
                'message',
                contains('could not read a verified proof file'),
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains(tempDirectory.path)),
              ),
        ),
      );
    },
  );

  test(
    'document export package reader blocks unsafe or malformed packages',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nVerified proof\n%%EOF'),
      );
      final record = _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      );
      final valid = await AppDocumentExportPackageWriter().writeZipPackage(
        record: record,
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final validBytes = await File(valid.filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(validBytes);
      final unsafeArchive = Archive();
      for (final entry in archive.files) {
        unsafeArchive.addFile(
          ArchiveFile.bytes(
            entry.name == 'job-packet.pdf' ? '../job-packet.pdf' : entry.name,
            entry.readBytes()!,
          ),
        );
      }
      final unsafePackage = File('${tempDirectory.path}/unsafe.zip');
      await unsafePackage.writeAsBytes(
        ZipEncoder().encode(unsafeArchive, modified: DateTime.utc(2026)),
        flush: true,
      );

      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(unsafePackage),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('unsafe file name'),
          ),
        ),
      );

      final dangerousArchive = Archive();
      for (final entry in archive.files) {
        dangerousArchive.addFile(
          ArchiveFile.bytes(
            entry.name == 'job-packet.pdf' ? 'job-packet.pdf.exe' : entry.name,
            entry.readBytes()!,
          ),
        );
      }
      final dangerousPackage = File(
        '${tempDirectory.path}/dangerous-entry.zip',
      );
      await dangerousPackage.writeAsBytes(
        ZipEncoder().encode(dangerousArchive, modified: DateTime.utc(2026)),
        flush: true,
      );
      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(dangerousPackage),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('unsafe file name'),
          ),
        ),
      );

      final malformed = File('${tempDirectory.path}/malformed.zip');
      await malformed.writeAsString('not a zip', flush: true);
      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(malformed),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('could not read'),
          ),
        ),
      );
    },
  );

  test('document export package reader enforces zip bomb budgets', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nBudget proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final packageFile = File(result.filePath);

    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(packageFile, maxEntries: 2),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('too many files'),
        ),
      ),
    );
    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(
        packageFile,
        maxMetadataEntryBytes: 20,
      ),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('metadata is too large'),
        ),
      ),
    );
    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(
        packageFile,
        maxProofEntryBytes: 4,
      ),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('proof file is too large'),
        ),
      ),
    );
    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(
        packageFile,
        maxTotalUncompressedBytes: 40,
      ),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('uncompressed size is unsafe'),
        ),
      ),
    );
  });

  test('document export package share plan is verified and pathless', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nShare plan proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );

    final sharePlan = await AppDocumentExportPackageWriter.buildSharePlan(
      File(result.filePath),
      appName: ' Maintainiac \n Documents ',
    );

    expect(sharePlan.filePath, result.filePath);
    expect(sharePlan.fileName, result.fileName);
    expect(sharePlan.mimeType, 'application/zip');
    expect(
      sharePlan.subject,
      startsWith('Maintainiac Documents document export'),
    );
    expect(sharePlan.message, contains('Document type: jobContractorDocument'));
    expect(sharePlan.message, contains('Files: 1'));
    expect(sharePlan.message, contains(sharePlan.sha256));
    expect(sharePlan.sha256, result.sha256);
    expect(sharePlan.manifestSha256, result.manifestSha256);
    expect(sharePlan.fileEntries, ['job-packet.pdf']);
    expect(sharePlan.toMap().toString(), isNot(contains(tempDirectory.path)));
    expect(sharePlan.toMap().toString(), isNot(contains('filePath')));
  });

  test('document export package share plan preflights private proof', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nShare preflight proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final privatePackage = await _rewritePackageProof(
      sourcePackage: File(result.filePath),
      destinationName: 'private-share-preflight.zip',
      entryName: 'job-packet.pdf',
      replacementBytes: utf8.encode(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page >> stream\n'
        'Passenger: Jane Customer\n'
        'VIN 1HGCM82633A004352\n'
        'endstream endobj\n'
        '%%EOF',
      ),
    );

    await expectLater(
      AppDocumentExportPackageWriter.buildSharePlan(privatePackage),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('private information'),
        ),
      ),
    );
  });

  test('document export package share plan preflights active proof', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nShare preflight proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final activePackage = await _rewritePackageProof(
      sourcePackage: File(result.filePath),
      destinationName: 'active-share-preflight.zip',
      entryName: 'job-packet.pdf',
      replacementBytes: utf8.encode(
        '%PDF-1.7\n'
        '1 0 obj << /OpenAction 2 0 R >> endobj\n'
        '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
        '%%EOF',
      ),
    );

    await expectLater(
      AppDocumentExportPackageWriter.buildSharePlan(activePackage),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('unsupported active content'),
        ),
      ),
    );
  });

  test(
    'document export package import preview validates manifest safely',
    () async {
      final pdf = await _writeProof(
        tempDirectory,
        name: 'invoice-proof.pdf',
        bytes: utf8.encode('%PDF-1.7\nImport preview invoice\n%%EOF'),
      );
      final photo = await _writeProof(
        tempDirectory,
        name: 'receipt-photo.jpg',
        bytes: List<int>.generate(64, (index) => (index * 11) % 251),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          title: 'Shared job packet',
          attachments: [
            _pdfAttachment(
              id: 'invoice',
              path: pdf.path,
              displayName: 'invoice-proof.pdf',
              byteSize: await pdf.length(),
              fileHash: await _fileHash(pdf),
            ),
            _photoAttachment(
              id: 'photo',
              path: photo.path,
              displayName: 'receipt-photo.jpg',
              byteSize: await photo.length(),
              fileHash: await _fileHash(photo),
            ),
          ],
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );

      final preview =
          await AppDocumentExportPackageWriter.previewZipPackageImport(
            File(result.filePath),
          );

      expect(preview.fileName, result.fileName);
      expect(preview.sha256, result.sha256);
      expect(preview.manifestSha256, result.manifestSha256);
      expect(preview.title, 'Shared job packet');
      expect(preview.kindName, 'jobContractorDocument');
      expect(preview.attachments, hasLength(2));
      expect(preview.attachments.first.packageEntryName, 'invoice-proof.pdf');
      expect(preview.attachments.first.displayName, 'invoice-proof.pdf');
      expect(preview.attachments.first.kindName, 'pdf');
      expect(preview.attachments.first.readOnlyProof, isTrue);
      expect(preview.attachments.last.packageEntryName, 'receipt-photo.jpg');
      expect(preview.toMap().toString(), isNot(contains(tempDirectory.path)));
      expect(preview.toMap().toString(), isNot(contains('filePath')));
    },
  );

  test(
    'document export package import preview blocks private manifest data',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nImport private proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final privatePackage = await _rewritePackageManifest(
        sourcePackage: File(result.filePath),
        destinationName: 'private-import.zip',
        mutateManifest: (manifest) {
          manifest['title'] = 'Invoice for VIN 1HGCM82633A004352';
        },
      );

      await expectLater(
        AppDocumentExportPackageWriter.previewZipPackageImport(privatePackage),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('private information'),
          ),
        ),
      );
    },
  );

  test(
    'document export package import preview blocks private PDF proof content',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nImport proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final privateBytes = utf8.encode(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page >> stream\n'
        'Passenger: Jane Customer\n'
        'VIN 1HGCM82633A004352\n'
        'endstream endobj\n'
        '%%EOF',
      );
      final privatePackage = await _rewritePackageProof(
        sourcePackage: File(result.filePath),
        destinationName: 'private-proof-import.zip',
        entryName: 'job-packet.pdf',
        replacementBytes: privateBytes,
      );

      await expectLater(
        AppDocumentExportPackageWriter.previewZipPackageImport(privatePackage),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('private information'),
          ),
        ),
      );
    },
  );

  test(
    'document export package import preview blocks active PDF proof content',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nImport proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final activeBytes = utf8.encode(
        '%PDF-1.7\n'
        '1 0 obj << /OpenAction 2 0 R >> endobj\n'
        '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
        '%%EOF',
      );
      final activePackage = await _rewritePackageProof(
        sourcePackage: File(result.filePath),
        destinationName: 'active-proof-import.zip',
        entryName: 'job-packet.pdf',
        replacementBytes: activeBytes,
      );

      await expectLater(
        AppDocumentExportPackageWriter.previewZipPackageImport(activePackage),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('unsupported active content'),
          ),
        ),
      );
    },
  );

  test(
    'document export package import preview blocks unsupported proof kinds',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nUnsupported import proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final unsupportedPackage = await _rewritePackageManifestAndIndex(
        sourcePackage: File(result.filePath),
        destinationName: 'unsupported-proof-kind.zip',
        mutateManifest: (manifest) {
          final attachments = manifest['attachments']! as List;
          final first = attachments.first! as Map<String, Object?>;
          first['kind'] = 'textMessageText';
          first['mimeType'] = 'text/plain';
        },
        mutateIndex: (index) {
          final files = index['files']! as List;
          final first = files.first! as Map<String, Object?>;
          first['kind'] = 'textMessageText';
        },
      );

      await expectLater(
        AppDocumentExportPackageWriter.previewZipPackageImport(
          unsupportedPackage,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('invalid file entries'),
          ),
        ),
      );
    },
  );

  test(
    'document export package import preview blocks manifest index mismatch',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nImport mismatch proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final mismatchedPackage = await _rewritePackageManifest(
        sourcePackage: File(result.filePath),
        destinationName: 'mismatched-import.zip',
        mutateManifest: (manifest) {
          final attachments = manifest['attachments']! as List;
          final first = attachments.first! as Map<String, Object?>;
          first['fileHash'] = 'bad${first['fileHash']}';
        },
      );

      await expectLater(
        AppDocumentExportPackageWriter.previewZipPackageImport(
          mismatchedPackage,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('invalid file entries'),
          ),
        ),
      );
    },
  );

  test('document export package share plan refuses tampered package', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nShare tamper proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final archive = ZipDecoder().decodeBytes(
      await File(result.filePath).readAsBytes(),
    );
    final tampered = Archive();
    for (final entry in archive.files) {
      tampered.addFile(
        ArchiveFile.bytes(
          entry.name,
          entry.name == 'job-packet.pdf'
              ? utf8.encode('%PDF-1.7\nChanged before share\n%%EOF')
              : entry.readBytes()!,
        ),
      );
    }
    final tamperedFile = File('${tempDirectory.path}/share-tampered.zip');
    await tamperedFile.writeAsBytes(
      ZipEncoder().encode(tampered, modified: DateTime.utc(2026)),
      flush: true,
    );

    await expectLater(
      AppDocumentExportPackageWriter.buildSharePlan(tamperedFile),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('file verification failed'),
        ),
      ),
    );
  });

  test(
    'document export package share verifies before invoking platform share',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nVerified platform share\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final invokedPlans = <AppDocumentExportPackageSharePlan>[];
      final writer = AppDocumentExportPackageWriter(
        shareInvoker: (plan) async {
          invokedPlans.add(plan);
          return ShareResultStatus.success;
        },
      );

      final status = await writer.shareZipPackage(
        File(result.filePath),
        appName: 'Maintainiac',
      );

      expect(status, ShareResultStatus.success);
      expect(invokedPlans, hasLength(1));
      expect(invokedPlans.single.filePath, result.filePath);
      expect(invokedPlans.single.sha256, result.sha256);
      expect(invokedPlans.single.mimeType, 'application/zip');
      expect(
        invokedPlans.single.toMap().toString(),
        isNot(contains('filePath')),
      );
    },
  );

  test(
    'document export package share refuses tampered file before invocation',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nBlocked platform share\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final archive = ZipDecoder().decodeBytes(
        await File(result.filePath).readAsBytes(),
      );
      final tampered = Archive();
      for (final entry in archive.files) {
        tampered.addFile(
          ArchiveFile.bytes(
            entry.name,
            entry.name == 'job-packet.pdf'
                ? utf8.encode('%PDF-1.7\nChanged before invoke\n%%EOF')
                : entry.readBytes()!,
          ),
        );
      }
      final tamperedFile = File('${tempDirectory.path}/invoke-tampered.zip');
      await tamperedFile.writeAsBytes(
        ZipEncoder().encode(tampered, modified: DateTime.utc(2026)),
        flush: true,
      );
      var invoked = false;
      final writer = AppDocumentExportPackageWriter(
        shareInvoker: (_) async {
          invoked = true;
          return ShareResultStatus.success;
        },
      );

      await expectLater(
        writer.shareZipPackage(tamperedFile),
        throwsA(isA<AppDocumentExportPackageException>()),
      );
      expect(invoked, isFalse);
    },
  );

  test('document export package extraction is verified and pathless', () async {
    final pdf = await _writeProof(
      tempDirectory,
      name: 'invoice-proof.pdf',
      bytes: utf8.encode('%PDF-1.7\nExtract invoice proof\n%%EOF'),
    );
    final photo = await _writeProof(
      tempDirectory,
      name: 'receipt-photo.jpg',
      bytes: List<int>.generate(128, (index) => (index * 7) % 251),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachments: [
          _pdfAttachment(
            id: 'invoice',
            path: pdf.path,
            displayName: 'invoice-proof.pdf',
            byteSize: await pdf.length(),
            fileHash: await _fileHash(pdf),
          ),
          _photoAttachment(
            id: 'receipt',
            path: photo.path,
            displayName: 'receipt-photo.jpg',
            byteSize: await photo.length(),
            fileHash: await _fileHash(photo),
          ),
        ],
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final extraction = await AppDocumentExportPackageWriter.extractZipPackage(
      File(result.filePath),
      outputDirectory: Directory('${tempDirectory.path}/imports'),
    );
    final extractedDirectory = Directory(
      '${tempDirectory.path}/imports/${extraction.directoryName}',
    );

    expect(await extractedDirectory.exists(), isTrue);
    expect(extraction.fileEntries, [
      'maintainiac_document_manifest.json',
      'maintainiac_document_package_index.json',
      'invoice-proof.pdf',
      'receipt-photo.jpg',
    ]);
    expect(extraction.packageFileName, result.fileName);
    expect(extraction.packageSha256, result.sha256);
    expect(extraction.manifestSha256, result.manifestSha256);
    expect(extraction.kindName, 'jobContractorDocument');
    expect(
      extraction.totalBytes,
      greaterThan(await pdf.length() + await photo.length()),
    );
    expect(extraction.toMap().toString(), isNot(contains(tempDirectory.path)));
    expect(
      await _fileHash(File('${extractedDirectory.path}/invoice-proof.pdf')),
      await _fileHash(pdf),
    );
    expect(
      await _fileHash(File('${extractedDirectory.path}/receipt-photo.jpg')),
      await _fileHash(photo),
    );
    expect(
      await File(
        '${extractedDirectory.path}/maintainiac_document_manifest.json',
      ).readAsString(),
      contains('"documentId": "${extraction.documentId}"'),
    );
  });

  test(
    'document export package extraction refuses tampering before writing',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nExtract tamper proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final archive = ZipDecoder().decodeBytes(
        await File(result.filePath).readAsBytes(),
      );
      final tampered = Archive();
      for (final entry in archive.files) {
        tampered.addFile(
          ArchiveFile.bytes(
            entry.name,
            entry.name == 'job-packet.pdf'
                ? utf8.encode('%PDF-1.7\nChanged before extract\n%%EOF')
                : entry.readBytes()!,
          ),
        );
      }
      final tamperedFile = File('${tempDirectory.path}/extract-tampered.zip');
      await tamperedFile.writeAsBytes(
        ZipEncoder().encode(tampered, modified: DateTime.utc(2026)),
        flush: true,
      );
      final importDirectory = Directory('${tempDirectory.path}/imports');

      await expectLater(
        AppDocumentExportPackageWriter.extractZipPackage(
          tamperedFile,
          outputDirectory: importDirectory,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('file verification failed'),
          ),
        ),
      );

      expect(await importDirectory.exists(), isFalse);
      expect(await tamperedFile.exists(), isTrue);
    },
  );

  test(
    'document export package extraction preflights private proof content',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nExtract preflight proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final privatePackage = await _rewritePackageProof(
        sourcePackage: File(result.filePath),
        destinationName: 'private-extract-preflight.zip',
        entryName: 'job-packet.pdf',
        replacementBytes: utf8.encode(
          '%PDF-1.7\n'
          '1 0 obj << /Type /Page >> stream\n'
          'VIN 1HGCM82633A004352\n'
          'Passenger: Jane Customer\n'
          'endstream endobj\n'
          '%%EOF',
        ),
      );
      final importDirectory = Directory('${tempDirectory.path}/imports');

      await expectLater(
        AppDocumentExportPackageWriter.extractZipPackage(
          privatePackage,
          outputDirectory: importDirectory,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('private information'),
          ),
        ),
      );

      expect(await importDirectory.exists(), isFalse);
      expect(await privatePackage.exists(), isTrue);
    },
  );

  test(
    'document export package extraction preflights active proof content',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nExtract preflight proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final activePackage = await _rewritePackageProof(
        sourcePackage: File(result.filePath),
        destinationName: 'active-extract-preflight.zip',
        entryName: 'job-packet.pdf',
        replacementBytes: utf8.encode(
          '%PDF-1.7\n'
          '1 0 obj << /OpenAction 2 0 R >> endobj\n'
          '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
          '%%EOF',
        ),
      );
      final importDirectory = Directory('${tempDirectory.path}/imports');

      await expectLater(
        AppDocumentExportPackageWriter.extractZipPackage(
          activePackage,
          outputDirectory: importDirectory,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('unsupported active content'),
          ),
        ),
      );

      expect(await importDirectory.exists(), isFalse);
      expect(await activePackage.exists(), isTrue);
    },
  );

  test(
    'document export package extraction preserves source on folder failures',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nExtract rollback proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final importDirectory = Directory('${tempDirectory.path}/imports');
      final blockingFile = File(importDirectory.path);
      await blockingFile.writeAsString('not a directory', flush: true);

      await expectLater(
        AppDocumentExportPackageWriter.extractZipPackage(
          File(result.filePath),
          outputDirectory: importDirectory,
        ),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('could not prepare'),
          ),
        ),
      );

      expect(await blockingFile.exists(), isTrue);
      expect(
        await Directory(
          '${importDirectory.path}/'
          'maintainiac-document-export-${result.manifestSha256.substring(0, 12)}',
        ).exists(),
        isFalse,
      );
      expect(await File(result.filePath).exists(), isTrue);
      expect(await proof.exists(), isTrue);
    },
  );

  test('document export package extraction writes copy directories', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nExtract copy proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final importDirectory = Directory('${tempDirectory.path}/imports');

    final first = await AppDocumentExportPackageWriter.extractZipPackage(
      File(result.filePath),
      outputDirectory: importDirectory,
    );
    final second = await AppDocumentExportPackageWriter.extractZipPackage(
      File(result.filePath),
      outputDirectory: importDirectory,
    );

    expect(first.directoryName, startsWith('maintainiac-document-export-'));
    expect(second.directoryName, '${first.directoryName}-copy-2');
    expect(
      await File(
        '${importDirectory.path}/${second.directoryName}/job-packet.pdf',
      ).exists(),
      isTrue,
    );
    expect(await File(result.filePath).exists(), isTrue);
  });

  test(
    'document export package extraction cleanup removes symlink only',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nExtract symlink cleanup proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final importDirectory = Directory('${tempDirectory.path}/imports');
      await importDirectory.create(recursive: true);
      final outsideTarget = Directory(
        '${tempDirectory.path}/outside-extraction-target',
      );
      await outsideTarget.create(recursive: true);
      final targetFile = File('${outsideTarget.path}/private-proof.pdf');
      await targetFile.writeAsString(
        '%PDF-1.7\nOutside extraction target\n%%EOF',
        flush: true,
      );
      final partialLink = Link(
        '${importDirectory.path}/'
        'maintainiac-document-export-${result.manifestSha256.substring(0, 12)}'
        '.partial',
      );
      await partialLink.create(outsideTarget.path);

      final extraction = await AppDocumentExportPackageWriter.extractZipPackage(
        File(result.filePath),
        outputDirectory: importDirectory,
      );

      expect(await partialLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
      expect(await targetFile.exists(), isTrue);
      expect(
        await File(
          '${importDirectory.path}/${extraction.directoryName}/job-packet.pdf',
        ).exists(),
        isTrue,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('document export package reader blocks directory entries', () async {
    final directoryArchive = Archive()
      ..addFile(ArchiveFile.directory('proofs'));
    final directoryPackage = File('${tempDirectory.path}/directory.zip');
    await directoryPackage.writeAsBytes(
      ZipEncoder().encode(directoryArchive, modified: DateTime.utc(2026)),
      flush: true,
    );

    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(directoryPackage),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('unsupported entries'),
        ),
      ),
    );
  });

  test(
    'document export package reader blocks missing index and file tampering',
    () async {
      final proof = await _writeProof(
        tempDirectory,
        name: 'job-packet.pdf',
        bytes: utf8.encode('%PDF-1.7\nVerified proof\n%%EOF'),
      );
      final result = await AppDocumentExportPackageWriter().writeZipPackage(
        record: _documentRecord(
          attachment: _pdfAttachment(
            path: proof.path,
            byteSize: await proof.length(),
            fileHash: await _fileHash(proof),
          ),
        ),
        outputDirectory: Directory('${tempDirectory.path}/exports'),
        freeStorageReader: () async => 500,
      );
      final archive = ZipDecoder().decodeBytes(
        await File(result.filePath).readAsBytes(),
      );
      final missingIndex = Archive();
      final tampered = Archive();
      for (final entry in archive.files) {
        if (entry.name != 'maintainiac_document_package_index.json') {
          missingIndex.addFile(
            ArchiveFile.bytes(entry.name, entry.readBytes()!),
          );
        }
        tampered.addFile(
          ArchiveFile.bytes(
            entry.name,
            entry.name == 'job-packet.pdf'
                ? utf8.encode('%PDF-1.7\nChanged proof\n%%EOF')
                : entry.readBytes()!,
          ),
        );
      }
      final missingIndexFile = File('${tempDirectory.path}/missing-index.zip');
      final tamperedFile = File('${tempDirectory.path}/tampered.zip');
      await missingIndexFile.writeAsBytes(
        ZipEncoder().encode(missingIndex, modified: DateTime.utc(2026)),
        flush: true,
      );
      await tamperedFile.writeAsBytes(
        ZipEncoder().encode(tampered, modified: DateTime.utc(2026)),
        flush: true,
      );

      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(missingIndexFile),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('missing required metadata'),
          ),
        ),
      );
      await expectLater(
        AppDocumentExportPackageWriter.readZipPackage(tamperedFile),
        throwsA(
          isA<AppDocumentExportPackageException>().having(
            (error) => error.message,
            'message',
            contains('file verification failed'),
          ),
        ),
      );
    },
  );

  test('document export package reader blocks tampered byte totals', () async {
    final proof = await _writeProof(
      tempDirectory,
      name: 'job-packet.pdf',
      bytes: utf8.encode('%PDF-1.7\nByte total proof\n%%EOF'),
    );
    final result = await AppDocumentExportPackageWriter().writeZipPackage(
      record: _documentRecord(
        attachment: _pdfAttachment(
          path: proof.path,
          byteSize: await proof.length(),
          fileHash: await _fileHash(proof),
        ),
      ),
      outputDirectory: Directory('${tempDirectory.path}/exports'),
      freeStorageReader: () async => 500,
    );
    final tamperedPackage = await _rewritePackageManifestAndIndex(
      sourcePackage: File(result.filePath),
      destinationName: 'bad-byte-total.zip',
      mutateManifest: (_) {},
      mutateIndex: (index) {
        index['totalBytes'] = 1;
      },
      recalculateTotalBytes: false,
    );

    await expectLater(
      AppDocumentExportPackageWriter.readZipPackage(tamperedPackage),
      throwsA(
        isA<AppDocumentExportPackageException>().having(
          (error) => error.message,
          'message',
          contains('metadata does not match'),
        ),
      ),
    );
  });

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

  test(
    'document export writer strips dangerous proof entry extensions',
    () async {
      final pdf = await _writeProof(
        tempDirectory,
        name: 'invoice-source.pdf',
        bytes: utf8.encode('%PDF-1.7\nDisguised invoice proof\n%%EOF'),
      );
      final photo = await _writeProof(
        tempDirectory,
        name: 'receipt-source.jpg',
        bytes: List<int>.generate(128, (index) => (index * 7) % 251),
      );
      final record = _documentRecord(
        attachments: [
          _pdfAttachment(
            id: 'invoice',
            path: pdf.path,
            displayName: 'invoice.pdf.exe',
            byteSize: await pdf.length(),
            fileHash: await _fileHash(pdf),
          ),
          _photoAttachment(
            id: 'receipt',
            path: photo.path,
            displayName: 'receipt-photo.jpg.scr',
            byteSize: await photo.length(),
            fileHash: await _fileHash(photo),
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

      expect(result.fileEntries, ['invoice.pdf', 'receipt-photo.jpg']);
      expect(names, contains('invoice.pdf'));
      expect(names, contains('receipt-photo.jpg'));
      expect(names.join('\n').toLowerCase(), isNot(contains('.exe')));
      expect(names.join('\n').toLowerCase(), isNot(contains('.scr')));
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

Future<File> _rewritePackageManifest({
  required File sourcePackage,
  required String destinationName,
  required void Function(Map<String, Object?> manifest) mutateManifest,
}) async {
  final archive = ZipDecoder().decodeBytes(await sourcePackage.readAsBytes());
  final entries = <String, ArchiveFile>{
    for (final entry in archive.files) entry.name: entry,
  };
  final manifest =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.manifestEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  final index =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.packageIndexEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  mutateManifest(manifest);
  final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
  _syncPackageIndexManifestHashAndTotal(index, manifestJson);
  final indexJson = const JsonEncoder.withIndent('  ').convert(index);
  final rewritten = Archive();
  for (final entry in archive.files) {
    final bytes = switch (entry.name) {
      AppDocumentExportPackageWriter.manifestEntryName => utf8.encode(
        manifestJson,
      ),
      AppDocumentExportPackageWriter.packageIndexEntryName => utf8.encode(
        indexJson,
      ),
      _ => entry.readBytes()!,
    };
    rewritten.addFile(ArchiveFile.bytes(entry.name, bytes));
  }
  final destination = File('${sourcePackage.parent.path}/$destinationName');
  await destination.writeAsBytes(
    ZipEncoder().encode(rewritten, modified: DateTime.utc(2026)),
    flush: true,
  );
  return destination;
}

Future<File> _rewritePackageManifestAndIndex({
  required File sourcePackage,
  required String destinationName,
  required void Function(Map<String, Object?> manifest) mutateManifest,
  required void Function(Map<String, Object?> index) mutateIndex,
  bool recalculateTotalBytes = true,
}) async {
  final archive = ZipDecoder().decodeBytes(await sourcePackage.readAsBytes());
  final entries = <String, ArchiveFile>{
    for (final entry in archive.files) entry.name: entry,
  };
  final manifest =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.manifestEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  final index =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.packageIndexEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  mutateManifest(manifest);
  mutateIndex(index);
  final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
  _syncPackageIndexManifestHashAndTotal(
    index,
    manifestJson,
    recalculateTotalBytes: recalculateTotalBytes,
  );
  final indexJson = const JsonEncoder.withIndent('  ').convert(index);
  final rewritten = Archive();
  for (final entry in archive.files) {
    final bytes = switch (entry.name) {
      AppDocumentExportPackageWriter.manifestEntryName => utf8.encode(
        manifestJson,
      ),
      AppDocumentExportPackageWriter.packageIndexEntryName => utf8.encode(
        indexJson,
      ),
      _ => entry.readBytes()!,
    };
    rewritten.addFile(ArchiveFile.bytes(entry.name, bytes));
  }
  final destination = File('${sourcePackage.parent.path}/$destinationName');
  await destination.writeAsBytes(
    ZipEncoder().encode(rewritten, modified: DateTime.utc(2026)),
    flush: true,
  );
  return destination;
}

Future<File> _rewritePackageProof({
  required File sourcePackage,
  required String destinationName,
  required String entryName,
  required List<int> replacementBytes,
}) async {
  final replacementHash = sha256.convert(replacementBytes).toString();
  final archive = ZipDecoder().decodeBytes(await sourcePackage.readAsBytes());
  final entries = <String, ArchiveFile>{
    for (final entry in archive.files) entry.name: entry,
  };
  final manifest =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.manifestEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  final index =
      (jsonDecode(
                utf8.decode(
                  entries[AppDocumentExportPackageWriter.packageIndexEntryName]!
                      .readBytes()!,
                ),
              )
              as Map)
          .cast<String, Object?>();
  final files = index['files']! as List;
  final indexedFile = files
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .firstWhere((item) => item['packageEntryName'] == entryName);
  indexedFile['byteSize'] = replacementBytes.length;
  indexedFile['sha256'] = replacementHash;
  final attachmentId = indexedFile['attachmentId'];
  final attachments = manifest['attachments']! as List;
  final manifestAttachment = attachments
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .firstWhere((item) => item['id'] == attachmentId);
  manifestAttachment['byteSize'] = replacementBytes.length;
  manifestAttachment['fileHash'] = replacementHash;
  final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
  _syncPackageIndexManifestHashAndTotal(index, manifestJson);
  final indexJson = const JsonEncoder.withIndent('  ').convert(index);
  final rewritten = Archive();
  for (final entry in archive.files) {
    final bytes = switch (entry.name) {
      AppDocumentExportPackageWriter.manifestEntryName => utf8.encode(
        manifestJson,
      ),
      AppDocumentExportPackageWriter.packageIndexEntryName => utf8.encode(
        indexJson,
      ),
      _ when entry.name == entryName => replacementBytes,
      _ => entry.readBytes()!,
    };
    rewritten.addFile(ArchiveFile.bytes(entry.name, bytes));
  }
  final destination = File('${sourcePackage.parent.path}/$destinationName');
  await destination.writeAsBytes(
    ZipEncoder().encode(rewritten, modified: DateTime.utc(2026)),
    flush: true,
  );
  return destination;
}

void _syncPackageIndexManifestHashAndTotal(
  Map<String, Object?> index,
  String manifestJson, {
  bool recalculateTotalBytes = true,
}) {
  index['manifestSha256'] = sha256
      .convert(utf8.encode(manifestJson))
      .toString();
  if (!recalculateTotalBytes) return;
  final files = index['files']! as List;
  final proofBytes = files
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .fold<int>(0, (total, item) => total + (item['byteSize']! as int));
  index['totalBytes'] = utf8.encode(manifestJson).length + proofBytes;
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
