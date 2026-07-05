import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../pdf/app_pdf_privacy_policy.dart';
import '../pdf/app_pdf_security_policy.dart';
import '../storage/app_storage_guard.dart';
import '../widgets/receipt_capture/receipt_capture_models.dart';
import 'app_document_models.dart';

class AppDocumentExportManifest {
  const AppDocumentExportManifest({
    required this.documentId,
    required this.kind,
    required this.title,
    required this.sourceLabel,
    required this.createdAtIso8601,
    required this.updatedAtIso8601,
    required this.attachments,
    this.importedText = '',
    this.notes = '',
  });

  final String documentId;
  final AppDocumentKind kind;
  final String title;
  final String sourceLabel;
  final String createdAtIso8601;
  final String updatedAtIso8601;
  final List<AppDocumentExportAttachment> attachments;
  final String importedText;
  final String notes;

  Map<String, Object?> toMap() {
    return {
      'documentId': documentId,
      'kind': kind.name,
      'kindLabel': kind.label,
      'title': title,
      'sourceLabel': sourceLabel,
      'createdAt': createdAtIso8601,
      'updatedAt': updatedAtIso8601,
      'importedText': importedText,
      'notes': notes,
      'attachments': [for (final attachment in attachments) attachment.toMap()],
    };
  }
}

class AppDocumentExportPackagePlan {
  const AppDocumentExportPackagePlan({
    required this.manifest,
    required this.manifestJson,
    required this.manifestSha256,
    required this.files,
    required this.totalBytes,
    this.storageWarningMessage = '',
  });

  final AppDocumentExportManifest manifest;
  final String manifestJson;
  final String manifestSha256;
  final List<AppDocumentExportPackageFile> files;
  final int totalBytes;
  final String storageWarningMessage;

  Map<String, Object?> toMap() {
    return {
      'manifestSha256': manifestSha256,
      'totalBytes': totalBytes,
      'storageWarningMessage': storageWarningMessage,
      'files': [for (final file in files) file.toMap()],
      'manifest': manifest.toMap(),
    };
  }
}

class AppDocumentExportPackageFile {
  const AppDocumentExportPackageFile({
    required this.attachmentId,
    required this.displayName,
    required this.packageEntryName,
    required this.path,
    required this.kind,
    required this.byteSize,
    required this.sha256,
    required this.readOnlyProof,
  });

  final String attachmentId;
  final String displayName;
  final String packageEntryName;
  final String path;
  final ReceiptAttachmentKind kind;
  final int byteSize;
  final String sha256;
  final bool readOnlyProof;

  Map<String, Object?> toMap() {
    return {
      'attachmentId': attachmentId,
      'displayName': displayName,
      'packageEntryName': packageEntryName,
      'kind': kind.name,
      'byteSize': byteSize,
      'sha256': sha256,
      'readOnlyProof': readOnlyProof,
    };
  }
}

class AppDocumentExportAttachment {
  const AppDocumentExportAttachment({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.mimeType,
    required this.byteSize,
    required this.fileHash,
    required this.pageCount,
    required this.readState,
    required this.storageState,
    required this.isReadOnlyProof,
    required this.riskFlags,
    required this.documentSignals,
  });

  final String id;
  final ReceiptAttachmentKind kind;
  final String displayName;
  final String mimeType;
  final int? byteSize;
  final String fileHash;
  final int? pageCount;
  final ReceiptAttachmentReadState readState;
  final ReceiptAttachmentStorageState storageState;
  final bool isReadOnlyProof;
  final List<String> riskFlags;
  final List<String> documentSignals;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kind': kind.name,
      'displayName': displayName,
      'mimeType': mimeType,
      'byteSize': byteSize,
      'fileHash': fileHash,
      'pageCount': pageCount,
      'readState': readState.name,
      'storageState': storageState.name,
      'isReadOnlyProof': isReadOnlyProof,
      'riskFlags': riskFlags,
      'documentSignals': documentSignals,
    };
  }
}

class AppDocumentExportReview {
  const AppDocumentExportReview({
    required this.canExport,
    required this.issues,
    required this.manifest,
  });

  final bool canExport;
  final List<String> issues;
  final AppDocumentExportManifest? manifest;

  String get userMessage {
    if (canExport) return 'Document export is ready.';
    if (issues.contains(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion)) {
      return 'Maintainiac stopped this document export because it includes unconfirmed OCR suggestions.';
    }
    if (issues.contains(AppPdfPrivacyPolicy.privateSourcePath)) {
      return 'Maintainiac stopped this document export because it includes private device paths.';
    }
    if (issues.contains(AppPdfPrivacyPolicy.internalId)) {
      return 'Maintainiac stopped this document export because it includes internal record IDs.';
    }
    return 'Maintainiac stopped this document export because it may include private information.';
  }
}

class AppDocumentExportIntegrityIssue {
  const AppDocumentExportIntegrityIssue({
    required this.code,
    required this.attachmentLabel,
  });

  static const missingFile = 'missing_file';
  static const partialFile = 'partial_file';
  static const unreadableFile = 'unreadable_file';
  static const byteSizeMismatch = 'byte_size_mismatch';
  static const hashMismatch = 'hash_mismatch';
  static const mutableProof = 'mutable_proof';
  static const unsupportedAttachment = 'unsupported_attachment';
  static const unsafePdfContent = 'unsafe_pdf_content';
  static const privatePdfContent = 'private_pdf_content';

  final String code;
  final String attachmentLabel;

  Map<String, Object?> toMap() {
    return {'code': code, 'attachmentLabel': attachmentLabel};
  }
}

class AppDocumentExportIntegrityException implements Exception {
  const AppDocumentExportIntegrityException(this.message, this.issues);

  final String message;
  final List<AppDocumentExportIntegrityIssue> issues;

  @override
  String toString() => message;
}

class AppDocumentExportPackageException implements Exception {
  const AppDocumentExportPackageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppDocumentExportManager {
  const AppDocumentExportManager._();

  static const int packageScratchBytes = 1024 * 1024;

  static AppDocumentExportReview review(AppDocumentRecord record) {
    final privacyIssues = _privacyIssues(record);
    if (privacyIssues.isNotEmpty) {
      return AppDocumentExportReview(
        canExport: false,
        issues: privacyIssues,
        manifest: null,
      );
    }

    return AppDocumentExportReview(
      canExport: true,
      issues: const [],
      manifest: _manifestFor(record),
    );
  }

  static AppDocumentExportManifest requireManifest(AppDocumentRecord record) {
    final review = AppDocumentExportManager.review(record);
    final manifest = review.manifest;
    if (manifest != null) return manifest;
    throw AppDocumentExportBlockedException(review.userMessage, review.issues);
  }

  static Future<AppDocumentExportPackagePlan> buildPackagePlan(
    AppDocumentRecord record, {
    AppFreeStorageReader? freeStorageReader,
  }) async {
    final manifest = requireManifest(record);
    final files = await _verifiedPackageFiles(record, manifest);
    final manifestJson = canonicalManifestJson(manifest);
    final totalBytes = files.fold<int>(
      utf8.encode(manifestJson).length,
      (total, file) => total + file.byteSize,
    );
    final storageWarningMessage = await _storageWarningForPackage(
      totalBytes,
      freeStorageReader: freeStorageReader,
    );
    return AppDocumentExportPackagePlan(
      manifest: manifest,
      manifestJson: manifestJson,
      manifestSha256: sha256.convert(utf8.encode(manifestJson)).toString(),
      files: files,
      totalBytes: totalBytes,
      storageWarningMessage: storageWarningMessage,
    );
  }

  static String canonicalManifestJson(AppDocumentExportManifest manifest) {
    return const JsonEncoder.withIndent('  ').convert(manifest.toMap());
  }

  static Future<String> _storageWarningForPackage(
    int totalBytes, {
    AppFreeStorageReader? freeStorageReader,
  }) async {
    final check = await AppStorageGuard.checkForBytes(
      operationBytes: totalBytes + packageScratchBytes,
      purpose: AppStoragePurpose.exportFile,
      freeStorageReader: freeStorageReader,
    );
    if (!check.hasEnoughSpace) {
      throw AppDocumentExportPackageException(check.blockingMessage());
    }
    if (!check.canVerify) return check.unknownMessage();
    if (check.shouldWarnLowStorage) return check.warningMessage();
    return '';
  }

  static Future<List<AppDocumentExportPackageFile>> _verifiedPackageFiles(
    AppDocumentRecord record,
    AppDocumentExportManifest manifest,
  ) async {
    final issues = <AppDocumentExportIntegrityIssue>[];
    final files = <AppDocumentExportPackageFile>[];
    final usedEntryNames = <String>{};
    for (var index = 0; index < record.attachments.length; index += 1) {
      final attachment = record.attachments[index];
      if (attachment.isImportedText) continue;
      final manifestAttachment = manifest.attachments[index];
      final label = manifestAttachment.displayName;
      final issue = await _verifyPackageFile(
        attachment,
        manifestAttachment,
        label,
      );
      if (issue.issue != null) {
        issues.add(issue.issue!);
      } else if (issue.file != null) {
        files.add(
          issue.file!.copyWith(
            packageEntryName: _uniquePackageEntryName(
              issue.file!.displayName,
              usedEntryNames,
            ),
          ),
        );
      }
    }
    if (issues.isEmpty) return List.unmodifiable(files);
    throw AppDocumentExportIntegrityException(
      _integrityMessage(issues),
      List.unmodifiable(issues),
    );
  }

  static Future<_PackageFileVerification> _verifyPackageFile(
    ReceiptAttachmentRecord attachment,
    AppDocumentExportAttachment manifestAttachment,
    String label,
  ) async {
    if (!attachment.isReadOnlyProof) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.mutableProof,
          attachmentLabel: label,
        ),
      );
    }
    if (!attachment.isPdf && !attachment.isPhoto) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.unsupportedAttachment,
          attachmentLabel: label,
        ),
      );
    }
    final sourcePath = attachment.path.trim();
    if (sourcePath.isEmpty || sourcePath.toLowerCase().endsWith('.partial')) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: sourcePath.isEmpty
              ? AppDocumentExportIntegrityIssue.missingFile
              : AppDocumentExportIntegrityIssue.partialFile,
          attachmentLabel: label,
        ),
      );
    }
    final file = File(sourcePath);
    FileStat stat;
    try {
      stat = await file.stat();
    } catch (_) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.missingFile,
          attachmentLabel: label,
        ),
      );
    }
    if (stat.type != FileSystemEntityType.file) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.missingFile,
          attachmentLabel: label,
        ),
      );
    }
    final expectedByteSize = attachment.byteSize;
    if (expectedByteSize != null && expectedByteSize != stat.size) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.byteSizeMismatch,
          attachmentLabel: label,
        ),
      );
    }
    final actualHash = await _safeFileHash(file);
    if (actualHash.isEmpty) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.unreadableFile,
          attachmentLabel: label,
        ),
      );
    }
    final expectedHash = attachment.fileHash.trim();
    if (expectedHash.isNotEmpty && expectedHash != actualHash) {
      return _PackageFileVerification.issue(
        AppDocumentExportIntegrityIssue(
          code: AppDocumentExportIntegrityIssue.hashMismatch,
          attachmentLabel: label,
        ),
      );
    }
    if (attachment.isPdf) {
      final pdfBytes = await _safeReadBytes(file);
      if (pdfBytes == null) {
        return _PackageFileVerification.issue(
          AppDocumentExportIntegrityIssue(
            code: AppDocumentExportIntegrityIssue.unreadableFile,
            attachmentLabel: label,
          ),
        );
      }
      final securityIssues =
          AppPdfSecurityPolicy.activeContentIssueCodesForBytes(pdfBytes);
      if (securityIssues.isNotEmpty) {
        return _PackageFileVerification.issue(
          AppDocumentExportIntegrityIssue(
            code: AppDocumentExportIntegrityIssue.unsafePdfContent,
            attachmentLabel: label,
          ),
        );
      }
      final privacyIssues = AppPdfPrivacyPolicy.issueCodesForExport(
        bytes: pdfBytes,
      );
      if (privacyIssues.isNotEmpty) {
        return _PackageFileVerification.issue(
          AppDocumentExportIntegrityIssue(
            code: AppDocumentExportIntegrityIssue.privatePdfContent,
            attachmentLabel: label,
          ),
        );
      }
    }
    return _PackageFileVerification.file(
      AppDocumentExportPackageFile(
        attachmentId: manifestAttachment.id,
        displayName: manifestAttachment.displayName,
        packageEntryName: '',
        path: file.path,
        kind: attachment.kind,
        byteSize: stat.size,
        sha256: actualHash,
        readOnlyProof: attachment.isReadOnlyProof,
      ),
    );
  }

  static Future<String> _safeFileHash(File file) async {
    try {
      return (await sha256.bind(file.openRead()).first).toString();
    } catch (_) {
      return '';
    }
  }

  static Future<List<int>?> _safeReadBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static String _integrityMessage(
    List<AppDocumentExportIntegrityIssue> issues,
  ) {
    if (issues.any(
      (issue) => issue.code == AppDocumentExportIntegrityIssue.hashMismatch,
    )) {
      return 'Maintainiac stopped this document export because a proof file changed after it was saved.';
    }
    if (issues.any(
      (issue) => issue.code == AppDocumentExportIntegrityIssue.byteSizeMismatch,
    )) {
      return 'Maintainiac stopped this document export because a proof file size did not match its saved record.';
    }
    if (issues.any(
      (issue) => issue.code == AppDocumentExportIntegrityIssue.partialFile,
    )) {
      return 'Maintainiac stopped this document export because a proof file is still being written.';
    }
    if (issues.any(
      (issue) => issue.code == AppDocumentExportIntegrityIssue.unsafePdfContent,
    )) {
      return 'Maintainiac stopped this document export because a PDF proof includes unsupported active content.';
    }
    if (issues.any(
      (issue) =>
          issue.code == AppDocumentExportIntegrityIssue.privatePdfContent,
    )) {
      return 'Maintainiac stopped this document export because a PDF proof includes private information.';
    }
    return 'Maintainiac stopped this document export because one or more proof files could not be verified.';
  }

  static String _uniquePackageEntryName(String displayName, Set<String> used) {
    final clean = _packageEntryBaseName(displayName);
    final extension = path.extension(clean);
    final baseName = path.basenameWithoutExtension(clean);
    var candidate = clean;
    var index = 2;
    while (used.contains(candidate.toLowerCase())) {
      candidate = '$baseName-copy-$index$extension';
      index += 1;
    }
    used.add(candidate.toLowerCase());
    return candidate;
  }

  static String _packageEntryBaseName(String displayName) {
    final raw = _basename(displayName)
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]+'), '-')
        .replaceAll(
          RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]+'),
          '-',
        )
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\.{2,}'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[.\s-]+|[.\s-]+$'), '');
    final normalized = raw.isEmpty ? 'document-proof' : raw;
    final extension = path.extension(normalized).trim();
    final baseName = path.basenameWithoutExtension(normalized).trim();
    final safeBase = baseName.isEmpty ? 'document-proof' : baseName;
    final safeExtension = extension.isEmpty ? '.bin' : extension.toLowerCase();
    final entry = '$safeBase$safeExtension';
    if (entry.length <= 120) return entry;
    final maxBaseLength = 120 - safeExtension.length;
    return '${safeBase.substring(0, maxBaseLength.clamp(1, safeBase.length))}$safeExtension';
  }

  static AppDocumentExportManifest _manifestFor(AppDocumentRecord record) {
    return AppDocumentExportManifest(
      documentId: _publicDocumentId(record),
      kind: record.kind,
      title: record.displayTitle,
      sourceLabel: _cleanDisplayText(record.sourceLabel),
      createdAtIso8601: record.createdAt.toUtc().toIso8601String(),
      updatedAtIso8601: record.updatedAt.toUtc().toIso8601String(),
      importedText: _cleanDisplayText(record.importedText),
      notes: _cleanDisplayText(record.notes),
      attachments: [
        for (final attachment in record.attachments)
          AppDocumentExportAttachment(
            id: _publicAttachmentId(attachment),
            kind: attachment.kind,
            displayName: _attachmentDisplayName(attachment),
            mimeType: _cleanDisplayText(attachment.mimeType),
            byteSize: attachment.byteSize,
            fileHash: attachment.fileHash.trim(),
            pageCount: attachment.pageCount,
            readState: attachment.readState,
            storageState: attachment.storageState,
            isReadOnlyProof: attachment.isReadOnlyProof,
            riskFlags: _cleanList(attachment.riskFlags),
            documentSignals: _cleanList(attachment.documentSignals),
          ),
      ],
    );
  }

  static List<String> _privacyIssues(AppDocumentRecord record) {
    final metadata = <String>[
      record.title,
      record.importedText,
      record.notes,
      record.sourceLabel,
      record.displayTitle,
      for (final attachment in record.attachments) ...[
        _attachmentDisplayName(attachment),
        attachment.mimeType,
        attachment.importedText,
        attachment.sourceLabel,
        ...attachment.riskFlags,
        ...attachment.documentSignals,
      ],
    ];
    return AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: metadata,
    );
  }

  static String _attachmentDisplayName(ReceiptAttachmentRecord attachment) {
    final displayName = _cleanDisplayText(attachment.displayName);
    if (displayName.isNotEmpty) return _basename(displayName);
    final originalName = _cleanDisplayText(attachment.originalFileName);
    if (originalName.isNotEmpty) return _basename(originalName);
    return attachment.label;
  }

  static String _basename(String value) {
    final normalized = value.replaceAll('\\', '/');
    return path.basename(normalized);
  }

  static String _publicDocumentId(AppDocumentRecord record) {
    final source = [
      record.kind.name,
      record.createdAt.toUtc().toIso8601String(),
      record.title,
      record.attachments.length.toString(),
    ].join('|');
    return 'document-${_stableDigest(source)}';
  }

  static String _publicAttachmentId(ReceiptAttachmentRecord attachment) {
    final hashInput = [
      attachment.kind.name,
      attachment.createdAt.toUtc().toIso8601String(),
      attachment.fileHash,
      attachment.byteSize?.toString() ?? '',
      attachment.displayName,
    ].join('|');
    return 'attachment-${_stableDigest(hashInput)}';
  }

  static String _stableDigest(String value) {
    return sha256.convert(utf8.encode(value)).toString().substring(0, 16);
  }

  static List<String> _cleanList(List<String> values) {
    return values
        .map(_cleanDisplayText)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static String _cleanDisplayText(String value) {
    return value
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class AppDocumentExportBlockedException implements Exception {
  const AppDocumentExportBlockedException(this.message, this.issues);

  final String message;
  final List<String> issues;

  @override
  String toString() => message;
}

class _PackageFileVerification {
  const _PackageFileVerification({this.file, this.issue});

  factory _PackageFileVerification.file(AppDocumentExportPackageFile file) {
    return _PackageFileVerification(file: file);
  }

  factory _PackageFileVerification.issue(
    AppDocumentExportIntegrityIssue issue,
  ) {
    return _PackageFileVerification(issue: issue);
  }

  final AppDocumentExportPackageFile? file;
  final AppDocumentExportIntegrityIssue? issue;
}

extension on AppDocumentExportPackageFile {
  AppDocumentExportPackageFile copyWith({String? packageEntryName}) {
    return AppDocumentExportPackageFile(
      attachmentId: attachmentId,
      displayName: displayName,
      packageEntryName: packageEntryName ?? this.packageEntryName,
      path: this.path,
      kind: kind,
      byteSize: byteSize,
      sha256: this.sha256,
      readOnlyProof: readOnlyProof,
    );
  }
}
