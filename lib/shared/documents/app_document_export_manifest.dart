import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../pdf/app_pdf_privacy_policy.dart';
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

class AppDocumentExportManager {
  const AppDocumentExportManager._();

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
