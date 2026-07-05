import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../pdf/app_pdf_privacy_policy.dart';
import '../storage/app_storage_guard.dart';
import 'app_document_export_manifest.dart';
import 'app_document_models.dart';

typedef AppDocumentExportZipBytesBuilder =
    Future<List<int>> Function(AppDocumentExportPackagePlan plan);
typedef AppDocumentExportShareInvoker =
    Future<ShareResultStatus> Function(AppDocumentExportPackageSharePlan plan);

class AppDocumentExportPackageWriteResult {
  const AppDocumentExportPackageWriteResult({
    required this.filePath,
    required this.fileName,
    required this.byteSize,
    required this.sha256,
    required this.manifestSha256,
    required this.manifestEntryName,
    required this.packageIndexEntryName,
    required this.fileEntries,
    required this.storageWarningMessage,
  });

  final String filePath;
  final String fileName;
  final int byteSize;
  final String sha256;
  final String manifestSha256;
  final String manifestEntryName;
  final String packageIndexEntryName;
  final List<String> fileEntries;
  final String storageWarningMessage;

  Map<String, Object?> toMap() {
    return {
      'fileName': fileName,
      'byteSize': byteSize,
      'sha256': sha256,
      'manifestSha256': manifestSha256,
      'manifestEntryName': manifestEntryName,
      'packageIndexEntryName': packageIndexEntryName,
      'fileEntries': fileEntries,
      'storageWarningMessage': storageWarningMessage,
    };
  }
}

class AppDocumentExportPackageReadResult {
  const AppDocumentExportPackageReadResult({
    required this.fileName,
    required this.byteSize,
    required this.sha256,
    required this.manifestSha256,
    required this.documentId,
    required this.kindName,
    required this.fileEntries,
    required this.totalProofBytes,
  });

  final String fileName;
  final int byteSize;
  final String sha256;
  final String manifestSha256;
  final String documentId;
  final String kindName;
  final List<String> fileEntries;
  final int totalProofBytes;

  Map<String, Object?> toMap() {
    return {
      'fileName': fileName,
      'byteSize': byteSize,
      'sha256': sha256,
      'manifestSha256': manifestSha256,
      'documentId': documentId,
      'kindName': kindName,
      'fileEntries': fileEntries,
      'totalProofBytes': totalProofBytes,
    };
  }
}

class AppDocumentExportPackageSharePlan {
  const AppDocumentExportPackageSharePlan({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.subject,
    required this.message,
    required this.byteSize,
    required this.sha256,
    required this.manifestSha256,
    required this.documentId,
    required this.kindName,
    required this.fileEntries,
  });

  final String filePath;
  final String fileName;
  final String mimeType;
  final String subject;
  final String message;
  final int byteSize;
  final String sha256;
  final String manifestSha256;
  final String documentId;
  final String kindName;
  final List<String> fileEntries;

  Map<String, Object?> toMap() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'subject': subject,
      'message': message,
      'byteSize': byteSize,
      'sha256': sha256,
      'manifestSha256': manifestSha256,
      'documentId': documentId,
      'kindName': kindName,
      'fileEntries': fileEntries,
    };
  }
}

class AppDocumentExportPackageExtractResult {
  const AppDocumentExportPackageExtractResult({
    required this.directoryName,
    required this.packageFileName,
    required this.packageSha256,
    required this.manifestSha256,
    required this.documentId,
    required this.kindName,
    required this.fileEntries,
    required this.totalBytes,
  });

  final String directoryName;
  final String packageFileName;
  final String packageSha256;
  final String manifestSha256;
  final String documentId;
  final String kindName;
  final List<String> fileEntries;
  final int totalBytes;

  Map<String, Object?> toMap() {
    return {
      'directoryName': directoryName,
      'packageFileName': packageFileName,
      'packageSha256': packageSha256,
      'manifestSha256': manifestSha256,
      'documentId': documentId,
      'kindName': kindName,
      'fileEntries': fileEntries,
      'totalBytes': totalBytes,
    };
  }
}

class AppDocumentExportPackageImportAttachment {
  const AppDocumentExportPackageImportAttachment({
    required this.packageEntryName,
    required this.displayName,
    required this.kindName,
    required this.mimeType,
    required this.byteSize,
    required this.sha256,
    required this.readOnlyProof,
  });

  final String packageEntryName;
  final String displayName;
  final String kindName;
  final String mimeType;
  final int byteSize;
  final String sha256;
  final bool readOnlyProof;

  Map<String, Object?> toMap() {
    return {
      'packageEntryName': packageEntryName,
      'displayName': displayName,
      'kindName': kindName,
      'mimeType': mimeType,
      'byteSize': byteSize,
      'sha256': sha256,
      'readOnlyProof': readOnlyProof,
    };
  }
}

class AppDocumentExportPackageImportPreview {
  const AppDocumentExportPackageImportPreview({
    required this.fileName,
    required this.byteSize,
    required this.sha256,
    required this.manifestSha256,
    required this.documentId,
    required this.kindName,
    required this.title,
    required this.sourceLabel,
    required this.createdAtIso8601,
    required this.updatedAtIso8601,
    required this.attachments,
  });

  final String fileName;
  final int byteSize;
  final String sha256;
  final String manifestSha256;
  final String documentId;
  final String kindName;
  final String title;
  final String sourceLabel;
  final String createdAtIso8601;
  final String updatedAtIso8601;
  final List<AppDocumentExportPackageImportAttachment> attachments;

  Map<String, Object?> toMap() {
    return {
      'fileName': fileName,
      'byteSize': byteSize,
      'sha256': sha256,
      'manifestSha256': manifestSha256,
      'documentId': documentId,
      'kindName': kindName,
      'title': title,
      'sourceLabel': sourceLabel,
      'createdAtIso8601': createdAtIso8601,
      'updatedAtIso8601': updatedAtIso8601,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
    };
  }
}

class AppDocumentExportPackageWriter {
  const AppDocumentExportPackageWriter({
    this.zipBytesBuilder,
    this.shareInvoker,
  });

  static const String manifestEntryName = 'maintainiac_document_manifest.json';
  static const String packageIndexEntryName =
      'maintainiac_document_package_index.json';
  static const String packageMimeType = 'application/zip';
  static const int maxReadablePackageBytes = 500 * 1024 * 1024;
  static const int maxPackageEntries = 200;
  static const int maxPackageMetadataEntryBytes = 2 * 1024 * 1024;
  static const int maxPackageProofEntryBytes = 200 * 1024 * 1024;
  static const int maxTotalUncompressedPackageBytes = 750 * 1024 * 1024;
  static const Duration stalePartialAge = Duration(hours: 12);
  static final DateTime _fixedZipModified = DateTime.utc(2026);

  final AppDocumentExportZipBytesBuilder? zipBytesBuilder;
  final AppDocumentExportShareInvoker? shareInvoker;

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
    await cleanupStalePartials(outputDirectory);

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
        packageIndexEntryName: packageIndexEntryName,
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
    archive.addFile(
      ArchiveFile.string(packageIndexEntryName, _packageIndexJson(plan))
        ..lastModTime = 0,
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
    final entries = _entryMap(archive);
    final expectedNames = <String>[
      manifestEntryName,
      packageIndexEntryName,
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
    final indexBytes = entries[packageIndexEntryName]!.readBytes();
    final indexJson = indexBytes == null
        ? ''
        : utf8.decode(indexBytes, allowMalformed: false);
    _verifyPackageIndexJson(plan, indexJson);
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

  static Future<AppDocumentExportPackageReadResult> readZipPackage(
    File packageFile, {
    int maxPackageBytes = maxReadablePackageBytes,
    int maxEntries = maxPackageEntries,
    int maxMetadataEntryBytes = maxPackageMetadataEntryBytes,
    int maxProofEntryBytes = maxPackageProofEntryBytes,
    int maxTotalUncompressedBytes = maxTotalUncompressedPackageBytes,
  }) async {
    final fileName = path.basename(packageFile.path);
    if (packageFile.path.toLowerCase().endsWith('.partial')) {
      throw const AppDocumentExportPackageException(
        'Maintainiac cannot read a document export package that is still being written.',
      );
    }
    final stat = await packageFile.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not find this document export package.',
      );
    }
    if (stat.size <= 0 || stat.size > maxPackageBytes) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped reading this document export package because its size is unsafe.',
      );
    }
    final zipBytes = await packageFile.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not read this document export package.',
      );
    }
    if (archive.files.isEmpty) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not read this document export package.',
      );
    }
    final entries = _entryMap(archive);
    _verifyEntryBudget(
      entries,
      maxEntries: maxEntries,
      maxMetadataEntryBytes: maxMetadataEntryBytes,
      maxProofEntryBytes: maxProofEntryBytes,
      maxTotalUncompressedBytes: maxTotalUncompressedBytes,
    );
    _verifyReadableEntryNames(entries.keys);
    final manifest = _requiredTextEntry(entries, manifestEntryName);
    final indexJson = _requiredTextEntry(entries, packageIndexEntryName);
    final index = _decodeIndex(indexJson);
    final manifestHash = sha256.convert(utf8.encode(manifest)).toString();
    final indexedManifestHash = _stringValue(index, 'manifestSha256');
    if (indexedManifestHash != manifestHash) {
      throw const AppDocumentExportPackageException(
        'Document export package manifest verification failed.',
      );
    }
    final manifestMap = _decodeObject(manifest);
    final files = _fileIndexList(index);
    final expectedNames = <String>{
      manifestEntryName,
      packageIndexEntryName,
      for (final file in files) _stringValue(file, 'packageEntryName'),
    };
    if (expectedNames.length != entries.length ||
        !entries.keys.every(expectedNames.contains)) {
      throw const AppDocumentExportPackageException(
        'Document export package contains unexpected entries.',
      );
    }
    var totalProofBytes = 0;
    final fileEntries = <String>[];
    for (final file in files) {
      final entryName = _stringValue(file, 'packageEntryName');
      final entryBytes = entries[entryName]?.readBytes();
      if (entryBytes == null) {
        throw const AppDocumentExportPackageException(
          'Document export package is missing a verified file.',
        );
      }
      final byteSize = _intValue(file, 'byteSize');
      final fileHash = _stringValue(file, 'sha256');
      if (entryBytes.length != byteSize ||
          sha256.convert(entryBytes).toString() != fileHash) {
        throw const AppDocumentExportPackageException(
          'Document export package file verification failed.',
        );
      }
      totalProofBytes += byteSize;
      fileEntries.add(entryName);
    }
    return AppDocumentExportPackageReadResult(
      fileName: fileName,
      byteSize: zipBytes.length,
      sha256: sha256.convert(zipBytes).toString(),
      manifestSha256: manifestHash,
      documentId: _stringValue(manifestMap, 'documentId'),
      kindName: _stringValue(manifestMap, 'kind'),
      fileEntries: List.unmodifiable(fileEntries),
      totalProofBytes: totalProofBytes,
    );
  }

  static Future<AppDocumentExportPackageSharePlan> buildSharePlan(
    File packageFile, {
    String appName = 'Maintainiac',
  }) async {
    final readResult = await readZipPackage(packageFile);
    final cleanAppName = _cleanShareText(appName).isEmpty
        ? 'Maintainiac'
        : _cleanShareText(appName);
    return AppDocumentExportPackageSharePlan(
      filePath: packageFile.path,
      fileName: readResult.fileName,
      mimeType: packageMimeType,
      subject:
          '$cleanAppName document export ${readResult.manifestSha256.substring(0, 12)}',
      message:
          '$cleanAppName document export package. '
          'Document type: ${readResult.kindName}. '
          'Files: ${readResult.fileEntries.length}. '
          'Package SHA-256: ${readResult.sha256}.',
      byteSize: readResult.byteSize,
      sha256: readResult.sha256,
      manifestSha256: readResult.manifestSha256,
      documentId: readResult.documentId,
      kindName: readResult.kindName,
      fileEntries: readResult.fileEntries,
    );
  }

  Future<ShareResultStatus> shareZipPackage(
    File packageFile, {
    String appName = 'Maintainiac',
  }) async {
    final plan = await buildSharePlan(packageFile, appName: appName);
    final invoker = shareInvoker ?? _shareWithPlatform;
    return invoker(plan);
  }

  static Future<AppDocumentExportPackageImportPreview> previewZipPackageImport(
    File packageFile,
  ) async {
    final readResult = await readZipPackage(packageFile);
    final packageBytes = await packageFile.readAsBytes();
    final entries = _entryMap(ZipDecoder().decodeBytes(packageBytes));
    _verifyReadableEntryNames(entries.keys);
    final manifest = _decodeObject(
      _requiredTextEntry(entries, manifestEntryName),
    );
    final index = _decodeIndex(
      _requiredTextEntry(entries, packageIndexEntryName),
    );
    _verifyImportManifestPrivacy(manifest);
    _verifyImportDates(manifest);
    final indexedFiles = _fileIndexList(index);
    final manifestAttachments = _manifestAttachmentMap(manifest);
    final attachments = <AppDocumentExportPackageImportAttachment>[];
    for (final file in indexedFiles) {
      final attachmentId = _stringValue(file, 'attachmentId');
      final manifestAttachment = manifestAttachments[attachmentId];
      if (manifestAttachment == null) {
        throw const AppDocumentExportPackageException(
          'Document export package metadata has invalid file entries.',
        );
      }
      final attachment = _importAttachment(file, manifestAttachment);
      attachments.add(attachment);
    }
    if (_stringValue(manifest, 'documentId') != readResult.documentId ||
        _stringValue(manifest, 'kind') != readResult.kindName ||
        attachments.length != readResult.fileEntries.length) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata does not match Maintainiac format.',
      );
    }
    return AppDocumentExportPackageImportPreview(
      fileName: readResult.fileName,
      byteSize: readResult.byteSize,
      sha256: readResult.sha256,
      manifestSha256: readResult.manifestSha256,
      documentId: readResult.documentId,
      kindName: readResult.kindName,
      title: _stringValue(manifest, 'title'),
      sourceLabel: _stringValue(manifest, 'sourceLabel'),
      createdAtIso8601: _stringValue(manifest, 'createdAt'),
      updatedAtIso8601: _stringValue(manifest, 'updatedAt'),
      attachments: List.unmodifiable(attachments),
    );
  }

  static Future<AppDocumentExportPackageExtractResult> extractZipPackage(
    File packageFile, {
    required Directory outputDirectory,
  }) async {
    final readResult = await readZipPackage(packageFile);
    await _createDirectory(outputDirectory);

    final packageBytes = await packageFile.readAsBytes();
    final entries = _entryMap(ZipDecoder().decodeBytes(packageBytes));
    _verifyReadableEntryNames(entries.keys);
    final index = _decodeIndex(
      _requiredTextEntry(entries, packageIndexEntryName),
    );
    final files = _fileIndexList(index);
    final extractionDirectory = await _extractionDirectory(
      outputDirectory,
      readResult,
    );
    final partialDirectory = Directory('${extractionDirectory.path}.partial');
    final extractedEntryNames = <String>[
      manifestEntryName,
      packageIndexEntryName,
      for (final file in files) _stringValue(file, 'packageEntryName'),
    ];
    var totalBytes = 0;

    try {
      await _deleteDirectoryIfExists(partialDirectory);
      await partialDirectory.create(recursive: true);
      for (final entryName in extractedEntryNames) {
        _verifyExtractionEntryName(entryName);
        final entryBytes = entries[entryName]?.readBytes();
        if (entryBytes == null) {
          throw const AppDocumentExportPackageException(
            'Document export package is missing a verified file.',
          );
        }
        final destination = _extractedDestinationFile(
          partialDirectory,
          entryName,
        );
        final partialFile = File('${destination.path}.partial');
        await _writeVerifiedExtractionFile(
          partialFile: partialFile,
          destination: destination,
          expectedBytes: entryBytes,
        );
        totalBytes += entryBytes.length;
      }
      await partialDirectory.rename(extractionDirectory.path);
      return AppDocumentExportPackageExtractResult(
        directoryName: path.basename(extractionDirectory.path),
        packageFileName: readResult.fileName,
        packageSha256: readResult.sha256,
        manifestSha256: readResult.manifestSha256,
        documentId: readResult.documentId,
        kindName: readResult.kindName,
        fileEntries: List.unmodifiable(extractedEntryNames),
        totalBytes: totalBytes,
      );
    } catch (_) {
      await _deleteDirectoryIfExists(partialDirectory);
      await _deleteDirectoryIfExists(extractionDirectory);
      throw const AppDocumentExportPackageException(
        'Maintainiac could not extract this document export package. '
        'The original package was preserved.',
      );
    }
  }

  static Future<ShareResultStatus> _shareWithPlatform(
    AppDocumentExportPackageSharePlan plan,
  ) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        title: plan.subject,
        subject: plan.subject,
        text: plan.message,
        files: [
          XFile(plan.filePath, name: plan.fileName, mimeType: plan.mimeType),
        ],
      ),
    );
    return result.status;
  }

  static String _cleanShareText(String value) {
    return value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _verifyImportManifestPrivacy(Map<String, Object?> manifest) {
    final attachmentMaps = _manifestAttachmentList(manifest);
    final metadata = <String>[
      _stringValue(manifest, 'documentId'),
      _stringValue(manifest, 'kind'),
      _stringValue(manifest, 'title'),
      _stringValue(manifest, 'sourceLabel'),
      manifest['importedText'] as String? ?? '',
      manifest['notes'] as String? ?? '',
      for (final attachment in attachmentMaps) ...[
        _stringValue(attachment, 'id'),
        _stringValue(attachment, 'displayName'),
        _stringValue(attachment, 'mimeType'),
        ..._stringListValue(attachment, 'riskFlags'),
        ..._stringListValue(attachment, 'documentSignals'),
      ],
    ];
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: metadata,
    );
    if (issues.isNotEmpty) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped this document package import because it may include private information.',
      );
    }
  }

  static void _verifyImportDates(Map<String, Object?> manifest) {
    for (final key in ['createdAt', 'updatedAt']) {
      final value = _stringValue(manifest, key);
      if (DateTime.tryParse(value) == null) {
        throw const AppDocumentExportPackageException(
          'Document export package metadata does not match Maintainiac format.',
        );
      }
    }
  }

  static List<Map<String, Object?>> _manifestAttachmentList(
    Map<String, Object?> manifest,
  ) {
    final attachments = manifest['attachments'];
    if (attachments is! List) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata is missing file entries.',
      );
    }
    return [
      for (final attachment in attachments)
        if (attachment is Map<String, Object?>)
          attachment
        else
          throw const AppDocumentExportPackageException(
            'Document export package metadata has invalid file entries.',
          ),
    ];
  }

  static Map<String, Map<String, Object?>> _manifestAttachmentMap(
    Map<String, Object?> manifest,
  ) {
    final map = <String, Map<String, Object?>>{};
    for (final attachment in _manifestAttachmentList(manifest)) {
      final id = _stringValue(attachment, 'id');
      if (map.containsKey(id)) {
        throw const AppDocumentExportPackageException(
          'Document export package metadata has invalid file entries.',
        );
      }
      map[id] = attachment;
    }
    return map;
  }

  static List<String> _stringListValue(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata has invalid file entries.',
      );
    }
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw const AppDocumentExportPackageException(
            'Document export package metadata has invalid file entries.',
          ),
    ];
  }

  static AppDocumentExportPackageImportAttachment _importAttachment(
    Map<String, Object?> file,
    Map<String, Object?> manifestAttachment,
  ) {
    final fileDisplayName = _stringValue(file, 'displayName');
    final manifestDisplayName = _stringValue(manifestAttachment, 'displayName');
    final fileKind = _stringValue(file, 'kind');
    final manifestKind = _stringValue(manifestAttachment, 'kind');
    final fileByteSize = _intValue(file, 'byteSize');
    final manifestByteSize = _intValue(manifestAttachment, 'byteSize');
    final fileHash = _stringValue(file, 'sha256');
    final manifestHash = _stringValue(manifestAttachment, 'fileHash');
    final readOnlyProof = manifestAttachment['isReadOnlyProof'];
    final indexedReadOnlyProof = file['readOnlyProof'];
    if (fileDisplayName != manifestDisplayName ||
        fileKind != manifestKind ||
        fileByteSize != manifestByteSize ||
        fileHash != manifestHash ||
        readOnlyProof != true ||
        indexedReadOnlyProof != true) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata has invalid file entries.',
      );
    }
    return AppDocumentExportPackageImportAttachment(
      packageEntryName: _stringValue(file, 'packageEntryName'),
      displayName: manifestDisplayName,
      kindName: manifestKind,
      mimeType: _stringValue(manifestAttachment, 'mimeType'),
      byteSize: fileByteSize,
      sha256: fileHash,
      readOnlyProof: true,
    );
  }

  static void _verifyEntryBudget(
    Map<String, ArchiveFile> entries, {
    required int maxEntries,
    required int maxMetadataEntryBytes,
    required int maxProofEntryBytes,
    required int maxTotalUncompressedBytes,
  }) {
    if (entries.length > maxEntries) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped reading this document export package because it contains too many files.',
      );
    }
    var totalBytes = 0;
    for (final entry in entries.values) {
      if (!entry.isFile || entry.isSymbolicLink) {
        throw const AppDocumentExportPackageException(
          'Maintainiac stopped reading this document export package because it contains unsupported entries.',
        );
      }
      final entrySize = entry.size;
      if (entrySize < 0) {
        throw const AppDocumentExportPackageException(
          'Maintainiac stopped reading this document export package because an entry size is invalid.',
        );
      }
      totalBytes += entrySize;
      if (totalBytes > maxTotalUncompressedBytes) {
        throw const AppDocumentExportPackageException(
          'Maintainiac stopped reading this document export package because its uncompressed size is unsafe.',
        );
      }
      final isMetadata =
          entry.name == manifestEntryName ||
          entry.name == packageIndexEntryName;
      final entryLimit = isMetadata
          ? maxMetadataEntryBytes
          : maxProofEntryBytes;
      if (entrySize > entryLimit) {
        throw AppDocumentExportPackageException(
          isMetadata
              ? 'Maintainiac stopped reading this document export package because its metadata is too large.'
              : 'Maintainiac stopped reading this document export package because a proof file is too large.',
        );
      }
    }
  }

  static Future<List<String>> cleanupStalePartials(
    Directory outputDirectory, {
    DateTime? now,
  }) async {
    if (!await outputDirectory.exists()) return const [];
    final cutoff = (now ?? DateTime.now()).subtract(stalePartialAge);
    final deleted = <String>[];
    await for (final entity in outputDirectory.list(followLinks: false)) {
      if (entity is! File) continue;
      final fileName = path.basename(entity.path);
      if (!_isAppOwnedPartialName(fileName)) continue;
      FileStat stat;
      try {
        stat = await entity.stat();
      } catch (_) {
        continue;
      }
      if (stat.type != FileSystemEntityType.file) continue;
      if (!stat.modified.isBefore(cutoff)) continue;
      try {
        await entity.delete();
        deleted.add(fileName);
      } catch (_) {
        throw const AppDocumentExportPackageException(
          'Maintainiac could not clean up a stale document export package.',
        );
      }
    }
    deleted.sort();
    return List.unmodifiable(deleted);
  }

  static bool _isAppOwnedPartialName(String fileName) {
    return fileName.startsWith('maintainiac-') &&
        fileName.endsWith('.zip.partial') &&
        !fileName.contains('..') &&
        !fileName.contains('/') &&
        !fileName.contains('\\') &&
        !fileName.contains(RegExp(r'[\x00-\x1F\x7F]'));
  }

  static Map<String, ArchiveFile> _entryMap(Archive archive) {
    final entries = <String, ArchiveFile>{};
    for (final file in archive.files) {
      final name = file.name;
      if (entries.containsKey(name)) {
        throw const AppDocumentExportPackageException(
          'Document export package contains duplicate entries.',
        );
      }
      entries[name] = file;
    }
    return entries;
  }

  static void _verifyReadableEntryNames(Iterable<String> names) {
    for (final name in names) {
      if (name.isEmpty ||
          name.startsWith('/') ||
          name.startsWith('\\') ||
          name.contains('..') ||
          name.contains('/') ||
          name.contains(RegExp(r'[\\:*?"<>|]')) ||
          name.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
        throw const AppDocumentExportPackageException(
          'Document export package contains an unsafe file name.',
        );
      }
    }
  }

  static String _requiredTextEntry(
    Map<String, ArchiveFile> entries,
    String name,
  ) {
    final bytes = entries[name]?.readBytes();
    if (bytes == null) {
      throw const AppDocumentExportPackageException(
        'Document export package is missing required metadata.',
      );
    }
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata is not valid text.',
      );
    }
  }

  static Map<String, Object?> _decodeIndex(String indexJson) {
    final index = _decodeObject(indexJson);
    if (_stringValue(index, 'manifestEntryName') != manifestEntryName ||
        _stringValue(index, 'packageIndexEntryName') != packageIndexEntryName) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata does not match Maintainiac format.',
      );
    }
    return index;
  }

  static Map<String, Object?> _decodeObject(String jsonText) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata is not valid JSON.',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata is not valid JSON.',
      );
    }
    return decoded;
  }

  static List<Map<String, Object?>> _fileIndexList(Map<String, Object?> index) {
    final files = index['files'];
    if (files is! List) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata is missing file entries.',
      );
    }
    return [
      for (final file in files)
        if (file is Map<String, Object?>)
          file
        else
          throw const AppDocumentExportPackageException(
            'Document export package metadata has invalid file entries.',
          ),
    ];
  }

  static String _stringValue(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw const AppDocumentExportPackageException(
      'Document export package metadata is missing required text.',
    );
  }

  static int _intValue(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int && value >= 0) return value;
    throw const AppDocumentExportPackageException(
      'Document export package metadata is missing required byte counts.',
    );
  }

  static String _packageIndexJson(AppDocumentExportPackagePlan plan) {
    return const JsonEncoder.withIndent('  ').convert({
      'schema': 'maintainiac_document_export_package_index_v1',
      'manifestEntryName': manifestEntryName,
      'packageIndexEntryName': packageIndexEntryName,
      'manifestSha256': plan.manifestSha256,
      'totalBytes': plan.totalBytes,
      'files': [for (final file in plan.files) file.toMap()],
    });
  }

  static void _verifyPackageIndexJson(
    AppDocumentExportPackagePlan plan,
    String indexJson,
  ) {
    final index = _decodeIndex(indexJson);
    if (_stringValue(index, 'manifestSha256') != plan.manifestSha256) {
      throw const AppDocumentExportPackageException(
        'Document export package index verification failed.',
      );
    }
    final files = _fileIndexList(index);
    if (files.length != plan.files.length) {
      throw const AppDocumentExportPackageException(
        'Document export package index verification failed.',
      );
    }
    for (var index = 0; index < files.length; index += 1) {
      final indexed = files[index];
      final planned = plan.files[index];
      if (_stringValue(indexed, 'packageEntryName') !=
              planned.packageEntryName ||
          _intValue(indexed, 'byteSize') != planned.byteSize ||
          _stringValue(indexed, 'sha256') != planned.sha256 ||
          _stringValue(indexed, 'attachmentId') != planned.attachmentId) {
        throw const AppDocumentExportPackageException(
          'Document export package index verification failed.',
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

  static Future<Directory> _extractionDirectory(
    Directory outputDirectory,
    AppDocumentExportPackageReadResult readResult,
  ) async {
    final baseName =
        'maintainiac-document-export-${readResult.manifestSha256.substring(0, 12)}';
    var candidate = Directory('${outputDirectory.path}/$baseName');
    var index = 2;
    while (await candidate.exists() ||
        await Directory('${candidate.path}.partial').exists()) {
      candidate = Directory('${outputDirectory.path}/$baseName-copy-$index');
      index += 1;
    }
    return candidate;
  }

  static void _verifyExtractionEntryName(String entryName) {
    if (entryName.isEmpty ||
        path.basename(entryName) != entryName ||
        entryName.endsWith('.partial')) {
      throw const AppDocumentExportPackageException(
        'Document export package contains an unsafe file name.',
      );
    }
  }

  static File _extractedDestinationFile(
    Directory extractionDirectory,
    String entryName,
  ) {
    final basePath = path.normalize(extractionDirectory.absolute.path);
    final destinationPath = path.normalize(
      path.join(extractionDirectory.absolute.path, entryName),
    );
    if (destinationPath != path.join(basePath, path.basename(entryName))) {
      throw const AppDocumentExportPackageException(
        'Document export package contains an unsafe file name.',
      );
    }
    return File(destinationPath);
  }

  static Future<void> _writeVerifiedExtractionFile({
    required File partialFile,
    required File destination,
    required List<int> expectedBytes,
  }) async {
    if (await destination.exists() || await partialFile.exists()) {
      throw const AppDocumentExportPackageException(
        'Document export package extraction would overwrite a file.',
      );
    }
    await partialFile.writeAsBytes(expectedBytes, flush: true);
    await _verifyWrittenFile(partialFile, expectedBytes);
    await partialFile.rename(destination.path);
    await _verifyWrittenFile(destination, expectedBytes);
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

  static Future<void> _deleteDirectoryIfExists(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not clean up a failed document export package.',
      );
    }
  }
}
