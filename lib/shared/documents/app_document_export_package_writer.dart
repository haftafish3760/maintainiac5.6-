import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../storage/app_storage_guard.dart';
import 'app_document_export_manifest.dart';
import 'app_document_models.dart';

typedef AppDocumentExportZipBytesBuilder =
    Future<List<int>> Function(AppDocumentExportPackagePlan plan);

class AppDocumentExportPackageWriteResult {
  const AppDocumentExportPackageWriteResult({
    required this.filePath,
    required this.fileName,
    required this.byteSize,
    required this.sha256,
    required this.manifestSha256,
    required this.manifestEntryName,
    required this.fileEntries,
    required this.storageWarningMessage,
  });

  final String filePath;
  final String fileName;
  final int byteSize;
  final String sha256;
  final String manifestSha256;
  final String manifestEntryName;
  final List<String> fileEntries;
  final String storageWarningMessage;

  Map<String, Object?> toMap() {
    return {
      'fileName': fileName,
      'byteSize': byteSize,
      'sha256': sha256,
      'manifestSha256': manifestSha256,
      'manifestEntryName': manifestEntryName,
      'fileEntries': fileEntries,
      'storageWarningMessage': storageWarningMessage,
    };
  }
}

class AppDocumentExportPackageWriter {
  const AppDocumentExportPackageWriter({this.zipBytesBuilder});

  static const String manifestEntryName = 'maintainiac_document_manifest.json';
  static final DateTime _fixedZipModified = DateTime.utc(2026);

  final AppDocumentExportZipBytesBuilder? zipBytesBuilder;

  Future<AppDocumentExportPackageWriteResult> writeZipPackage({
    required AppDocumentRecord record,
    required Directory outputDirectory,
    AppFreeStorageReader? freeStorageReader,
  }) async {
    final plan = await AppDocumentExportManager.buildPackagePlan(
      record,
      freeStorageReader: freeStorageReader,
    );
    final zipBytes = await (zipBytesBuilder ?? buildZipBytes)(plan);
    _verifyZipBytes(plan, zipBytes);
    await _createDirectory(outputDirectory);

    final destination = await _destinationFile(outputDirectory, plan);
    final partial = File('${destination.path}.partial');
    try {
      await _deleteIfExists(partial);
      await partial.writeAsBytes(zipBytes, flush: true);
      await _verifyWrittenFile(partial, zipBytes);
      await partial.rename(destination.path);
      await _verifyWrittenFile(destination, zipBytes);
      return AppDocumentExportPackageWriteResult(
        filePath: destination.path,
        fileName: path.basename(destination.path),
        byteSize: zipBytes.length,
        sha256: sha256.convert(zipBytes).toString(),
        manifestSha256: plan.manifestSha256,
        manifestEntryName: manifestEntryName,
        fileEntries: [for (final file in plan.files) file.packageEntryName],
        storageWarningMessage: plan.storageWarningMessage,
      );
    } catch (error) {
      await _deleteIfExists(partial);
      await _deleteIfExists(destination);
      throw AppDocumentExportPackageException(
        'Maintainiac could not create this document export package. '
        'No source records or proof files were changed.',
      );
    }
  }

  static Future<List<int>> buildZipBytes(
    AppDocumentExportPackagePlan plan,
  ) async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(manifestEntryName, plan.manifestJson)..lastModTime = 0,
    );
    for (final file in plan.files) {
      final bytes = await File(file.path).readAsBytes();
      archive.addFile(
        ArchiveFile.bytes(file.packageEntryName, bytes)..lastModTime = 0,
      );
    }
    return ZipEncoder().encode(archive, modified: _fixedZipModified);
  }

  static void _verifyZipBytes(
    AppDocumentExportPackagePlan plan,
    List<int> zipBytes,
  ) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final entries = <String, ArchiveFile>{
      for (final file in archive.files) file.name: file,
    };
    final expectedNames = <String>[
      manifestEntryName,
      for (final file in plan.files) file.packageEntryName,
    ];
    if (entries.length != expectedNames.length) {
      throw const AppDocumentExportPackageException(
        'Document export package contains unexpected entries.',
      );
    }
    for (final name in expectedNames) {
      if (!entries.containsKey(name)) {
        throw const AppDocumentExportPackageException(
          'Document export package is missing a verified file.',
        );
      }
    }
    final manifestBytes = entries[manifestEntryName]!.readBytes();
    final manifestJson = manifestBytes == null
        ? ''
        : utf8.decode(manifestBytes, allowMalformed: false);
    final manifestHash = sha256.convert(utf8.encode(manifestJson)).toString();
    if (manifestJson != plan.manifestJson ||
        manifestHash != plan.manifestSha256) {
      throw const AppDocumentExportPackageException(
        'Document export package manifest verification failed.',
      );
    }
    for (final file in plan.files) {
      final entryBytes = entries[file.packageEntryName]!.readBytes();
      if (entryBytes == null) {
        throw const AppDocumentExportPackageException(
          'Document export package file verification failed.',
        );
      }
      final actualHash = sha256.convert(entryBytes).toString();
      if (entryBytes.length != file.byteSize || actualHash != file.sha256) {
        throw const AppDocumentExportPackageException(
          'Document export package file verification failed.',
        );
      }
    }
  }

  static Future<void> _verifyWrittenFile(
    File file,
    List<int> expectedBytes,
  ) async {
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size != expectedBytes.length) {
      throw const AppDocumentExportPackageException(
        'Document export package write verification failed.',
      );
    }
    final actualHash = (await sha256.bind(file.openRead()).first).toString();
    final expectedHash = sha256.convert(expectedBytes).toString();
    if (actualHash != expectedHash) {
      throw const AppDocumentExportPackageException(
        'Document export package write verification failed.',
      );
    }
  }

  static Future<File> _destinationFile(
    Directory outputDirectory,
    AppDocumentExportPackagePlan plan,
  ) async {
    final baseName =
        'maintainiac-${plan.manifest.kind.name}-${plan.manifestSha256.substring(0, 12)}';
    var candidate = File('${outputDirectory.path}/$baseName.zip');
    var index = 2;
    while (await candidate.exists() ||
        await File('${candidate.path}.partial').exists()) {
      candidate = File('${outputDirectory.path}/$baseName-copy-$index.zip');
      index += 1;
    }
    return candidate;
  }

  static Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not prepare the document export folder.',
      );
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not clean up a failed document export package.',
      );
    }
  }
}
