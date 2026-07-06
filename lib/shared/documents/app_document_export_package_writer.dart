import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../pdf/app_pdf_privacy_policy.dart';
import '../pdf/app_pdf_security_policy.dart';
import '../storage/app_storage_guard.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
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

  Map<String, Object?> toSupportDiagnosticsMap({
    String operation = 'read_package',
  }) {
    return AppDocumentExportPackageDiagnostics.success(
      operation: operation,
      packageFileName: fileName,
      byteSize: byteSize,
      manifestSha256: manifestSha256,
      packageSha256: sha256,
      kindName: kindName,
      fileCount: fileEntries.length,
      totalProofBytes: totalProofBytes,
    ).toMap();
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

  Map<String, Object?> toSupportDiagnosticsMap({
    String operation = 'share_package',
  }) {
    return AppDocumentExportPackageDiagnostics.success(
      operation: operation,
      packageFileName: fileName,
      byteSize: byteSize,
      manifestSha256: manifestSha256,
      packageSha256: sha256,
      kindName: kindName,
      fileCount: fileEntries.length,
    ).toMap();
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

  Map<String, Object?> toSupportDiagnosticsMap({
    String operation = 'extract_package',
  }) {
    return AppDocumentExportPackageDiagnostics.success(
      operation: operation,
      packageFileName: packageFileName,
      byteSize: totalBytes,
      manifestSha256: manifestSha256,
      packageSha256: packageSha256,
      kindName: kindName,
      fileCount: fileEntries.length,
      totalProofBytes: totalBytes,
    ).toMap();
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

  Map<String, Object?> toSupportDiagnosticsMap({
    String operation = 'preview_import',
  }) {
    return AppDocumentExportPackageDiagnostics.success(
      operation: operation,
      packageFileName: fileName,
      byteSize: byteSize,
      manifestSha256: manifestSha256,
      packageSha256: sha256,
      kindName: kindName,
      fileCount: attachments.length,
      totalProofBytes: attachments.fold<int>(
        0,
        (total, attachment) => total + attachment.byteSize,
      ),
    ).toMap();
  }
}

class AppDocumentExportPackageDiagnostics {
  const AppDocumentExportPackageDiagnostics({
    required this.operation,
    required this.status,
    required this.packageExtension,
    required this.byteSizeBucket,
    required this.kindName,
    required this.fileCount,
    required this.totalProofBytesBucket,
    required this.manifestHashPrefix,
    required this.packageHashPrefix,
    this.issueCode = '',
  });

  factory AppDocumentExportPackageDiagnostics.success({
    required String operation,
    required String packageFileName,
    required int byteSize,
    required String manifestSha256,
    required String packageSha256,
    required String kindName,
    required int fileCount,
    int totalProofBytes = 0,
  }) {
    return AppDocumentExportPackageDiagnostics(
      operation: _safeOperation(operation),
      status: 'success',
      packageExtension: _safePackageExtension(packageFileName),
      byteSizeBucket: _byteSizeBucket(byteSize),
      kindName: _safeKindName(kindName),
      fileCount: fileCount < 0 ? 0 : fileCount,
      totalProofBytesBucket: _byteSizeBucket(totalProofBytes),
      manifestHashPrefix: _hashPrefix(manifestSha256),
      packageHashPrefix: _hashPrefix(packageSha256),
    );
  }

  factory AppDocumentExportPackageDiagnostics.blocked({
    required String operation,
    required String issueCode,
    String packageFileName = '',
    int byteSize = 0,
    String kindName = '',
    int fileCount = 0,
  }) {
    return AppDocumentExportPackageDiagnostics(
      operation: _safeOperation(operation),
      status: 'blocked',
      packageExtension: _safePackageExtension(packageFileName),
      byteSizeBucket: _byteSizeBucket(byteSize),
      kindName: _safeKindName(kindName),
      fileCount: fileCount < 0 ? 0 : fileCount,
      totalProofBytesBucket: _byteSizeBucket(0),
      manifestHashPrefix: '',
      packageHashPrefix: '',
      issueCode: _safeIssueCode(issueCode),
    );
  }

  final String operation;
  final String status;
  final String packageExtension;
  final String byteSizeBucket;
  final String kindName;
  final int fileCount;
  final String totalProofBytesBucket;
  final String manifestHashPrefix;
  final String packageHashPrefix;
  final String issueCode;

  Map<String, Object?> toMap() {
    return {
      'schema': 'document_export_package_diagnostics_v1',
      'operation': operation,
      'status': status,
      if (issueCode.isNotEmpty) 'issueCode': issueCode,
      if (packageExtension.isNotEmpty) 'packageExtension': packageExtension,
      'byteSizeBucket': byteSizeBucket,
      if (kindName.isNotEmpty) 'kindName': kindName,
      'fileCountBucket': _fileCountBucket(fileCount),
      'totalProofBytesBucket': totalProofBytesBucket,
      if (manifestHashPrefix.isNotEmpty)
        'manifestHashPrefix': manifestHashPrefix,
      if (packageHashPrefix.isNotEmpty) 'packageHashPrefix': packageHashPrefix,
    };
  }

  static String _safeOperation(String value) {
    final token = _safeToken(value);
    const allowed = {
      'read_package',
      'share_package',
      'preview_import',
      'extract_package',
      'write_package',
      'import_package',
    };
    return allowed.contains(token) ? token : 'custom_operation';
  }

  static String _safeIssueCode(String value) {
    final token = _safeToken(value);
    const allowedWords = {
      'active',
      'appended',
      'byte',
      'content',
      'directory',
      'duplicate',
      'encrypted',
      'entry',
      'hash',
      'index',
      'manifest',
      'metadata',
      'missing',
      'package',
      'pdf',
      'private',
      'proof',
      'revision',
      'size',
      'storage',
      'tamper',
      'unsafe',
      'zip',
    };
    final words = token.split('_').where((word) => word.isNotEmpty);
    if (words.isEmpty) return 'custom_issue';
    return words.every(allowedWords.contains) ? token : 'custom_issue';
  }

  static String _safeKindName(String value) {
    final token = _safeToken(value);
    const allowed = {
      'expense_document',
      'invoice_document',
      'job_contractor_document',
      'maintenance_document',
      'other_document',
      'receipt_document',
      'vehicle_document',
      'jobcontractordocument',
      'invoicedocument',
      'otherdocument',
    };
    return allowed.contains(token) ? token : '';
  }

  static String _safePackageExtension(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    if (extension == '.zip') return 'zip';
    if (extension == '.pdf') return 'pdf';
    return '';
  }

  static String _safeToken(String value) {
    final lowered = value.toLowerCase();
    if (AppPdfPrivacyPolicy.issueCodesForExport(
      metadata: [lowered],
      bytes: const [],
    ).isNotEmpty) {
      return 'private_signal';
    }
    return lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _hashPrefix(String hash) {
    final normalized = hash.toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized)) return '';
    return normalized.substring(0, 12);
  }

  static String _byteSizeBucket(int bytes) {
    if (bytes <= 0) return 'empty';
    if (bytes < 100 * 1024) return 'under_100kb';
    if (bytes < 1024 * 1024) return 'under_1mb';
    if (bytes < 10 * 1024 * 1024) return 'under_10mb';
    if (bytes < 100 * 1024 * 1024) return 'under_100mb';
    return 'over_100mb';
  }

  static String _fileCountBucket(int count) {
    if (count <= 0) return 'none';
    if (count == 1) return 'one';
    if (count <= 5) return 'two_to_five';
    if (count <= 20) return 'six_to_twenty';
    return 'over_twenty';
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
      final bytes = await _readVerifiedPackageSourceBytes(file);
      archive.addFile(
        ArchiveFile.bytes(file.packageEntryName, bytes)..lastModTime = 0,
      );
    }
    return ZipEncoder().encode(archive, modified: _fixedZipModified);
  }

  static Future<List<int>> _readVerifiedPackageSourceBytes(
    AppDocumentExportPackageFile file,
  ) async {
    try {
      await _requireRegularPackageSource(file.path);
      final bytes = await File(file.path).readAsBytes();
      await _requireRegularPackageSource(file.path);
      if (bytes.length != file.byteSize ||
          sha256.convert(bytes).toString() != file.sha256) {
        throw const AppDocumentExportPackageException(
          'Maintainiac could not verify a proof file for this document export package.',
        );
      }
      return bytes;
    } on AppDocumentExportPackageException {
      rethrow;
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not read a verified proof file for this document export package.',
      );
    }
  }

  static Future<void> _requireRegularPackageSource(String filePath) async {
    final type = await FileSystemEntity.type(filePath, followLinks: false);
    if (type == FileSystemEntityType.file) return;
    if (type == FileSystemEntityType.notFound) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not read a verified proof file for this document export package.',
      );
    }
    throw const AppDocumentExportPackageException(
      'Maintainiac could not verify a proof file for this document export package.',
    );
  }

  static void _verifyZipBytes(
    AppDocumentExportPackagePlan plan,
    List<int> zipBytes,
  ) {
    final archive = _decodeGeneratedZipBytes(zipBytes);
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

  static Archive _decodeGeneratedZipBytes(List<int> zipBytes) {
    try {
      return ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Document export package ZIP verification failed.',
      );
    }
  }

  static Future<List<int>> _readVerifiedPackageBytes(
    File packageFile, {
    int maxPackageBytes = maxReadablePackageBytes,
  }) async {
    try {
      await _requireRegularPackageFile(packageFile);
      final bytes = await packageFile.readAsBytes();
      await _requireRegularPackageFile(packageFile);
      final currentSize = await packageFile.length();
      if (currentSize != bytes.length ||
          bytes.isEmpty ||
          bytes.length > maxPackageBytes) {
        throw const AppDocumentExportPackageException(
          'Maintainiac stopped reading this document export package because its size is unsafe.',
        );
      }
      return bytes;
    } on AppDocumentExportPackageException {
      rethrow;
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not read this document export package.',
      );
    }
  }

  static Future<void> _requireRegularPackageFile(File packageFile) async {
    final type = await FileSystemEntity.type(
      packageFile.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.file) return;
    throw const AppDocumentExportPackageException(
      'Maintainiac could not find this document export package.',
    );
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
    final zipBytes = await _readVerifiedPackageBytes(
      packageFile,
      maxPackageBytes: maxPackageBytes,
    );
    if (zipBytes.isEmpty || zipBytes.length > maxPackageBytes) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped reading this document export package because its size is unsafe.',
      );
    }
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
    final indexedTotalBytes = _intValue(index, 'totalBytes');
    final expectedTotalBytes = utf8.encode(manifest).length + totalProofBytes;
    if (indexedTotalBytes != expectedTotalBytes) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata does not match Maintainiac format.',
      );
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
    await previewZipPackageImport(packageFile);
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
    final packageBytes = await _readVerifiedPackageBytes(packageFile);
    final entries = _entryMap(ZipDecoder().decodeBytes(packageBytes));
    _verifyReadableEntryNames(entries.keys);
    final manifest = _decodeObject(
      _requiredTextEntry(entries, manifestEntryName),
    );
    final index = _decodeIndex(
      _requiredTextEntry(entries, packageIndexEntryName),
    );
    _verifyImportMetadataPrivacy(manifest: manifest, index: index);
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
      _verifyImportProofContent(entries: entries, attachment: attachment);
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
    await previewZipPackageImport(packageFile);
    final readResult = await readZipPackage(packageFile);
    await _createDirectory(outputDirectory);

    final packageBytes = await _readVerifiedPackageBytes(packageFile);
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

  static void _verifyImportMetadataPrivacy({
    required Map<String, Object?> manifest,
    required Map<String, Object?> index,
  }) {
    final metadata = <String>[
      ..._metadataStringValues(manifest),
      ..._metadataStringValues(index),
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

  static Iterable<String> _metadataStringValues(Object? value) sync* {
    if (value is String) {
      yield value;
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        yield entry.key.toString();
        yield* _metadataStringValues(entry.value);
      }
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        yield* _metadataStringValues(item);
      }
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
    final mimeType = _stringValue(manifestAttachment, 'mimeType');
    if (fileDisplayName != manifestDisplayName ||
        fileKind != manifestKind ||
        fileByteSize != manifestByteSize ||
        fileHash != manifestHash ||
        readOnlyProof != true ||
        indexedReadOnlyProof != true ||
        !_isSupportedImportAttachment(fileKind, mimeType)) {
      throw const AppDocumentExportPackageException(
        'Document export package metadata has invalid file entries.',
      );
    }
    return AppDocumentExportPackageImportAttachment(
      packageEntryName: _stringValue(file, 'packageEntryName'),
      displayName: manifestDisplayName,
      kindName: manifestKind,
      mimeType: mimeType,
      byteSize: fileByteSize,
      sha256: fileHash,
      readOnlyProof: true,
    );
  }

  static bool _isSupportedImportAttachment(String kindName, String mimeType) {
    final normalizedKind = kindName.trim().toLowerCase();
    final normalizedMime = mimeType.trim().toLowerCase();
    if (normalizedKind == ReceiptAttachmentKind.pdf.name) {
      return normalizedMime == 'application/pdf' ||
          normalizedMime == 'application/x-pdf' ||
          normalizedMime == 'application/acrobat' ||
          normalizedMime == 'application/vnd.pdf';
    }
    if (normalizedKind == ReceiptAttachmentKind.photo.name) {
      return normalizedMime == 'image/*' || normalizedMime.startsWith('image/');
    }
    return false;
  }

  static void _verifyImportProofContent({
    required Map<String, ArchiveFile> entries,
    required AppDocumentExportPackageImportAttachment attachment,
  }) {
    final entryBytes = entries[attachment.packageEntryName]?.readBytes();
    if (entryBytes == null ||
        entryBytes.length != attachment.byteSize ||
        sha256.convert(entryBytes).toString() != attachment.sha256) {
      throw const AppDocumentExportPackageException(
        'Document export package file verification failed.',
      );
    }
    if (attachment.kindName != ReceiptAttachmentKind.pdf.name) return;
    final pdfText = latin1.decode(entryBytes, allowInvalid: true);
    if (AppPdfSecurityPolicy.containsPdfName(pdfText, 'encrypt')) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped this document package import because a PDF proof is encrypted.',
      );
    }
    if (RegExp('%%EOF').allMatches(pdfText).length > 1) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped this document package import because a PDF proof includes appended PDF revisions.',
      );
    }
    final securityIssues = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      entryBytes,
    );
    if (securityIssues.isNotEmpty) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped this document package import because a PDF proof includes unsupported active content.',
      );
    }
    final privacyIssues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: entryBytes,
    );
    if (privacyIssues.isNotEmpty) {
      throw const AppDocumentExportPackageException(
        'Maintainiac stopped this document package import because a PDF proof includes private information.',
      );
    }
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
      if (entity is! File && entity is! Link) continue;
      final fileName = path.basename(entity.path);
      if (!_isAppOwnedPartialName(fileName)) continue;
      FileStat stat;
      try {
        final type = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );
        if (type == FileSystemEntityType.link) {
          await _deleteLink(entity.path);
          deleted.add(fileName);
          continue;
        }
        if (type != FileSystemEntityType.file) continue;
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
          name.contains(RegExp(r'[\x00-\x1F\x7F]')) ||
          _hasDangerousTrailingExtension(name)) {
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
    if (_intValue(index, 'totalBytes') != plan.totalBytes) {
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
    await _requireRegularWrittenPackageFile(file);
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size != expectedBytes.length) {
      throw const AppDocumentExportPackageException(
        'Document export package write verification failed.',
      );
    }
    await _requireRegularWrittenPackageFile(file);
    final actualHash = (await sha256.bind(file.openRead()).first).toString();
    await _requireRegularWrittenPackageFile(file);
    final expectedHash = sha256.convert(expectedBytes).toString();
    if (actualHash != expectedHash) {
      throw const AppDocumentExportPackageException(
        'Document export package write verification failed.',
      );
    }
  }

  static Future<void> _requireRegularWrittenPackageFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.file) return;
    throw const AppDocumentExportPackageException(
      'Document export package write verification failed.',
    );
  }

  static Future<File> _destinationFile(
    Directory outputDirectory,
    AppDocumentExportPackagePlan plan,
  ) async {
    final baseName =
        'maintainiac-${plan.manifest.kind.name}-${plan.manifestSha256.substring(0, 12)}';
    var candidate = File('${outputDirectory.path}/$baseName.zip');
    var index = 2;
    while (await _fileOrLinkExistsNoFollow(candidate.path) ||
        await _fileOrLinkExistsNoFollow('${candidate.path}.partial')) {
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
    while (await _entityExistsNoFollow(candidate.path)) {
      candidate = Directory('${outputDirectory.path}/$baseName-copy-$index');
      index += 1;
    }
    return candidate;
  }

  static void _verifyExtractionEntryName(String entryName) {
    if (entryName.isEmpty ||
        path.basename(entryName) != entryName ||
        entryName.endsWith('.partial') ||
        _hasDangerousTrailingExtension(entryName)) {
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

  static bool _hasDangerousTrailingExtension(String fileName) {
    final extension = path.extension(fileName);
    if (extension.length <= 1) return false;
    return AppDocumentExportManager.dangerousPackageEntryExtensions.contains(
      extension.substring(1).toLowerCase(),
    );
  }

  static Future<void> _writeVerifiedExtractionFile({
    required File partialFile,
    required File destination,
    required List<int> expectedBytes,
  }) async {
    if (await _entityExistsNoFollow(destination.path) ||
        await _entityExistsNoFollow(partialFile.path)) {
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
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.directory) {
        throw const FileSystemException('Document export directory is unsafe.');
      }
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not prepare the document export folder.',
      );
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        await _deleteLink(file.path);
      } else if (type == FileSystemEntityType.file) {
        await file.delete();
      }
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not clean up a failed document export package.',
      );
    }
  }

  static Future<void> _deleteLink(String linkPath) {
    return Link(linkPath).delete();
  }

  static Future<void> _deleteDirectoryIfExists(Directory directory) async {
    try {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.directory) {
        await directory.delete(recursive: true);
      } else if (type == FileSystemEntityType.link) {
        await Link(directory.path).delete();
      }
    } catch (_) {
      throw const AppDocumentExportPackageException(
        'Maintainiac could not clean up a failed document export package.',
      );
    }
  }

  static Future<bool> _entityExistsNoFollow(String entityPath) async {
    final type = await FileSystemEntity.type(entityPath, followLinks: false);
    return type != FileSystemEntityType.notFound;
  }

  static Future<bool> _fileOrLinkExistsNoFollow(String entityPath) async {
    final type = await FileSystemEntity.type(entityPath, followLinks: false);
    return type == FileSystemEntityType.file ||
        type == FileSystemEntityType.link;
  }
}
