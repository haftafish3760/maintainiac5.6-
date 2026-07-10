import 'dart:typed_data';

import 'app_generated_pdf_models.dart';

class AppGeneratedPdfExportVerification {
  const AppGeneratedPdfExportVerification({
    required this.pageCount,
    required this.issues,
  });

  factory AppGeneratedPdfExportVerification.inspect(
    Uint8List bytes, {
    int? expectedPageCount,
    int minimumPageCount = 1,
  }) {
    final issues = <String>[];
    final validation = AppGeneratedPdfValidationReport.inspect(bytes);
    issues.addAll(validation.issues);
    final pageCount = _pageCount(bytes);
    if (pageCount == null) {
      issues.add('page_count_unknown');
    } else {
      if (pageCount < minimumPageCount) {
        issues.add('page_count_below_minimum');
      }
      if (expectedPageCount != null && pageCount != expectedPageCount) {
        issues.add('page_count_mismatch');
      }
    }
    return AppGeneratedPdfExportVerification(
      pageCount: pageCount,
      issues: issues.toSet().toList(growable: false),
    );
  }

  final int? pageCount;
  final List<String> issues;

  bool get isValid => issues.isEmpty;

  void throwIfInvalid() {
    if (isValid) return;
    throw AppGeneratedPdfExportVerificationException(issues);
  }

  static int? _pageCount(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final text = String.fromCharCodes(bytes);
    final count = RegExp(r'/Type\s*/Page\b').allMatches(text).length;
    return count == 0 ? null : count;
  }
}

class AppGeneratedPdfExportVerificationException implements Exception {
  const AppGeneratedPdfExportVerificationException(this.issueCodes);

  final List<String> issueCodes;

  @override
  String toString() {
    return 'Generated PDF verification failed: ${issueCodes.join(', ')}';
  }
}
