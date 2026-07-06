import 'dart:convert';
import 'dart:typed_data';

import 'app_pdf_privacy_policy.dart';
import 'app_pdf_security_policy.dart';

const int appGeneratedPdfMaxBytes = 25 * 1024 * 1024;

enum AppGeneratedPdfKind {
  receipt,
  estimate,
  invoice,
  expenseExport,
  inventoryReport,
  maintenanceReport,
  customerStatement,
}

class AppGeneratedPdfDocument {
  const AppGeneratedPdfDocument({
    required this.kind,
    required this.title,
    required this.fileName,
    required this.bytes,
    required this.createdAt,
    this.sourceModule = '',
    this.sourceRecordId = '',
    this.shareSubject = '',
    this.shareText = '',
  });

  final AppGeneratedPdfKind kind;
  final String title;
  final String fileName;
  final Uint8List bytes;
  final DateTime createdAt;
  final String sourceModule;
  final String sourceRecordId;
  final String shareSubject;
  final String shareText;

  String get kindLabel {
    return switch (kind) {
      AppGeneratedPdfKind.receipt => 'Receipt',
      AppGeneratedPdfKind.estimate => 'Estimate',
      AppGeneratedPdfKind.invoice => 'Invoice',
      AppGeneratedPdfKind.expenseExport => 'Expense Export',
      AppGeneratedPdfKind.inventoryReport => 'Inventory Report',
      AppGeneratedPdfKind.maintenanceReport => 'Maintenance Report',
      AppGeneratedPdfKind.customerStatement => 'Customer Statement',
    };
  }

  String get safeFileName {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'maintainiac-document.pdf';
    final withExtension = trimmed.toLowerCase().endsWith('.pdf')
        ? trimmed
        : '$trimmed.pdf';
    return AppGeneratedPdfFileName.clean(withExtension);
  }

  int get byteSize => bytes.lengthInBytes;

  AppGeneratedPdfValidationReport get validation =>
      AppGeneratedPdfValidationReport.inspectDocument(this);

  bool get isSendablePdf => validation.isValid;
}

class AppGeneratedPdfFileName {
  const AppGeneratedPdfFileName._();

  static const Set<String> _windowsReservedNames = {
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };
  static const Set<String> _dangerousTrailingExtensions = {
    'apk',
    'bat',
    'cmd',
    'com',
    'dmg',
    'exe',
    'ipa',
    'jar',
    'js',
    'msi',
    'pkg',
    'ps1',
    'scr',
    'sh',
    'vbs',
  };

  static String clean(String fileName) {
    final cleaned = fileName
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
    final normalized = cleaned.isEmpty ? 'maintainiac-document.pdf' : cleaned;
    final withExtension = normalized.toLowerCase().endsWith('.pdf')
        ? '${_safeBase(normalized.substring(0, normalized.length - 4))}.pdf'
        : '${_safeBase(normalized)}.pdf';
    if (withExtension.length <= 120) return withExtension;
    final baseName = withExtension.substring(0, withExtension.length - 4);
    return '${_safeBase(baseName.substring(0, 116))}.pdf';
  }

  static String _safeBase(String rawBaseName) {
    var baseName = rawBaseName.trim().replaceAll(
      RegExp(r'^[.\s-]+|[.\s-]+$'),
      '',
    );
    baseName = _stripDangerousTrailingExtensions(baseName);
    if (baseName.toLowerCase().endsWith('.pdf')) {
      baseName = baseName.substring(0, baseName.length - 4).trim();
    }
    if (baseName.isEmpty) baseName = 'maintainiac-document';
    if (_windowsReservedNames.contains(baseName.toLowerCase())) {
      return 'maintainiac-$baseName';
    }
    return baseName;
  }

  static String _stripDangerousTrailingExtensions(String value) {
    var cleaned = value;
    while (true) {
      final dotIndex = cleaned.lastIndexOf('.');
      if (dotIndex <= 0 || dotIndex == cleaned.length - 1) return cleaned;
      final extension = cleaned.substring(dotIndex + 1).toLowerCase();
      if (!_dangerousTrailingExtensions.contains(extension)) return cleaned;
      cleaned = cleaned
          .substring(0, dotIndex)
          .trim()
          .replaceAll(RegExp(r'^[.\s-]+|[.\s-]+$'), '');
      if (cleaned.isEmpty) return cleaned;
    }
  }
}

class AppGeneratedPdfValidationReport {
  const AppGeneratedPdfValidationReport({
    required this.byteSize,
    required this.issues,
  });

  factory AppGeneratedPdfValidationReport.inspect(Uint8List bytes) {
    return AppGeneratedPdfValidationReport._inspect(bytes: bytes);
  }

  factory AppGeneratedPdfValidationReport.inspectDocument(
    AppGeneratedPdfDocument document,
  ) {
    return AppGeneratedPdfValidationReport._inspect(
      bytes: document.bytes,
      metadata: [
        document.title,
        document.safeFileName,
        document.shareSubject,
        document.shareText,
        document.sourceModule,
        document.sourceRecordId,
      ],
    );
  }

  factory AppGeneratedPdfValidationReport._inspect({
    required Uint8List bytes,
    Iterable<String> metadata = const [],
  }) {
    final issues = <String>[];
    if (bytes.isEmpty) {
      issues.add('empty');
      return AppGeneratedPdfValidationReport(byteSize: 0, issues: issues);
    }
    if (bytes.lengthInBytes > appGeneratedPdfMaxBytes) {
      issues.add('too_large');
    }
    if (!_hasPdfHeader(bytes)) {
      issues.add('missing_pdf_header');
    }
    if (!_hasPdfEndMarker(bytes)) {
      issues.add('missing_pdf_end_marker');
    }
    if (_hasMultiplePdfEndMarkers(bytes)) {
      issues.add('multiple_pdf_end_markers');
    }
    if (AppPdfSecurityPolicy.containsPdfName(
      latin1.decode(bytes, allowInvalid: true),
      'encrypt',
    )) {
      issues.add('encrypted_pdf');
    }
    issues.addAll(AppPdfSecurityPolicy.activeContentIssueCodesForBytes(bytes));
    issues.addAll(
      AppPdfPrivacyPolicy.issueCodesForExport(bytes: bytes, metadata: metadata),
    );
    return AppGeneratedPdfValidationReport(
      byteSize: bytes.lengthInBytes,
      issues: issues.toSet().toList(growable: false),
    );
  }

  final int byteSize;
  final List<String> issues;

  bool get isValid => issues.isEmpty;

  bool hasIssue(String issue) => issues.contains(issue);

  String get userMessage {
    if (isValid) return 'PDF is ready.';
    if (hasIssue('empty')) {
      return 'Maintainiac could not create that PDF because the generated file was empty.';
    }
    if (hasIssue('too_large')) {
      return 'Maintainiac could not create that PDF because it is too large to safely send or save.';
    }
    if (hasIssue('missing_pdf_header') || hasIssue('missing_pdf_end_marker')) {
      return 'Maintainiac could not create that PDF because the generated file was incomplete.';
    }
    if (hasIssue('multiple_pdf_end_markers')) {
      return 'Maintainiac stopped this PDF because the generated file had unexpected appended PDF revisions.';
    }
    if (issues.any((issue) => issue.startsWith('private_')) ||
        hasIssue(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion) ||
        hasIssue(AppPdfPrivacyPolicy.internalId)) {
      return 'Maintainiac stopped this PDF because it may contain private information that should not be exported.';
    }
    return 'Maintainiac stopped this PDF because it contained unsupported active PDF features.';
  }

  static bool _hasPdfHeader(Uint8List bytes) {
    var index = 0;
    while (index < bytes.length && index < 32) {
      final value = bytes[index];
      if (value != 0x00 &&
          value != 0x09 &&
          value != 0x0A &&
          value != 0x0D &&
          value != 0x20) {
        break;
      }
      index += 1;
    }
    if (bytes.length - index < 5) return false;
    if (bytes[index] != 0x25 ||
        bytes[index + 1] != 0x50 ||
        bytes[index + 2] != 0x44 ||
        bytes[index + 3] != 0x46 ||
        bytes[index + 4] != 0x2D) {
      return false;
    }
    if (bytes.length - index < 8) return false;
    return _isAsciiDigit(bytes[index + 5]) &&
        bytes[index + 6] == 0x2E &&
        _isAsciiDigit(bytes[index + 7]);
  }

  static bool _hasPdfEndMarker(Uint8List bytes) {
    final start = bytes.length > 2048 ? bytes.length - 2048 : 0;
    final tail = latin1.decode(bytes.sublist(start));
    return RegExp(r'%%EOF[\s\x00]*$').hasMatch(tail);
  }

  static bool _hasMultiplePdfEndMarkers(Uint8List bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    return RegExp('%%EOF').allMatches(text).length > 1;
  }

  static bool _isAsciiDigit(int value) => value >= 0x30 && value <= 0x39;
}

class AppGeneratedPdfFile {
  const AppGeneratedPdfFile({
    required this.document,
    required this.path,
    required this.byteSize,
  });

  final AppGeneratedPdfDocument document;
  final String path;
  final int byteSize;
}
