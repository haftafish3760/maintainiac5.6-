import 'dart:typed_data';

import '../../../shared/document_engine/document_engine_core.dart';
import 'invoice_pdf_privacy_guard.dart';
import 'invoice_record.dart';
import 'invoice_template_catalog.dart';

class InvoicePdfExportVerificationException implements Exception {
  const InvoicePdfExportVerificationException(this.issues);

  final List<String> issues;

  @override
  String toString() {
    return 'Invoice PDF export verification failed: ${issues.join(', ')}';
  }
}

class InvoicePdfExportVerifier {
  const InvoicePdfExportVerifier._();

  static const missingInvoiceNumber = 'missing_invoice_number';
  static const missingDocumentLabel = 'missing_document_label';
  static const missingBalanceDue = 'missing_balance_due';
  static const missingPdfTextLayer = 'missing_pdf_text_layer';
  static const wrongDocumentLabel = 'wrong_document_label';
  static const internalRecordIdExported = 'internal_record_id_exported';
  static const unsafeGeneratedPdf = 'unsafe_generated_pdf';

  static void ensureSafeExport({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    required List<int> bytes,
  }) {
    final issues = blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: bytes,
    );
    if (issues.isEmpty) return;
    throw InvoicePdfExportVerificationException(issues);
  }

  static List<String> blockingIssueCodesForExport({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    required List<int> bytes,
  }) {
    final issues = <String>[];
    final validation = AppGeneratedPdfValidationReport.inspect(
      Uint8List.fromList(bytes),
    );
    if (!validation.isValid) {
      issues.addAll(validation.issues);
      issues.add(unsafeGeneratedPdf);
    }
    issues.addAll(
      AppPdfPrivacyPolicy.issueCodesForExport(
        bytes: bytes,
        metadata: InvoicePdfPrivacyGuard.recordExportMetadata(record),
      ),
    );
    final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(bytes);
    if (_containsInternalExportId(record, decoded)) {
      issues.add(internalRecordIdExported);
    }
    return issues.toSet().toList(growable: false);
  }

  static List<String> issueCodesForExport({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    required List<int> bytes,
  }) {
    final issues = <String>[];
    final validation = AppGeneratedPdfValidationReport.inspect(
      Uint8List.fromList(bytes),
    );
    if (!validation.isValid) {
      issues.addAll(validation.issues);
      issues.add(unsafeGeneratedPdf);
    }
    issues.addAll(
      AppPdfPrivacyPolicy.issueCodesForExport(
        bytes: bytes,
        metadata: InvoicePdfPrivacyGuard.recordExportMetadata(record),
      ),
    );
    issues.addAll(
      _textLayerIssueCodes(record: record, template: template, bytes: bytes),
    );
    return issues.toSet().toList(growable: false);
  }

  static List<String> _textLayerIssueCodes({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    required List<int> bytes,
  }) {
    final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(bytes);
    final normalized = _normalize(decoded);
    final issues = <String>[];
    if (!_hasAnyBusinessText(normalized)) {
      issues.add(missingPdfTextLayer);
      return issues;
    }
    final documentLabel = record.isEstimate ? 'estimate' : 'invoice';
    final forbiddenLabel = record.isEstimate ? 'invoice' : 'estimate';
    if (!_containsNormalized(normalized, documentLabel)) {
      issues.add(missingDocumentLabel);
    }
    if (_containsNormalized(normalized, forbiddenLabel) &&
        !_containsNormalized(normalized, documentLabel)) {
      issues.add(wrongDocumentLabel);
    }
    if (record.invoiceNumber.trim().isNotEmpty &&
        !_containsNormalized(normalized, record.invoiceNumber)) {
      issues.add(missingInvoiceNumber);
    }
    final balance = AppPdfFormatters.money(record.balanceDue);
    final total = AppPdfFormatters.money(record.total);
    if (!_containsNormalized(normalized, balance) &&
        !_containsNormalized(normalized, total)) {
      issues.add(missingBalanceDue);
    }
    if (_containsInternalExportId(record, decoded)) {
      issues.add(internalRecordIdExported);
    }
    return issues;
  }

  static bool _hasAnyBusinessText(String normalized) {
    return normalized.contains('invoice') ||
        normalized.contains('estimate') ||
        normalized.contains('subtotal') ||
        normalized.contains('total') ||
        normalized.contains('balance');
  }

  static bool _containsNormalized(String haystack, String needle) {
    final normalizedNeedle = _normalize(needle);
    if (normalizedNeedle.isEmpty) return true;
    return haystack.contains(normalizedNeedle);
  }

  static bool _containsInternalExportId(InvoiceRecord record, String decoded) {
    final normalized = _normalize(decoded);
    for (final id in _internalExportIds(record)) {
      if (_containsNormalized(normalized, id)) return true;
    }
    return false;
  }

  static Iterable<String> _internalExportIds(InvoiceRecord record) sync* {
    final recordId = record.id.trim();
    if (_looksInternalExportId(recordId)) yield recordId;
    for (final line in record.lines) {
      final lineId = line.id.trim();
      if (_looksInternalExportId(lineId)) yield lineId;
    }
    for (final payment in record.payments) {
      final paymentId = payment.id.trim();
      if (_looksInternalExportId(paymentId)) yield paymentId;
    }
  }

  static bool _looksInternalExportId(String value) {
    final normalized = _normalize(value);
    if (normalized.length < 12) return false;
    if (RegExp(
      r'\b(?:internal|firebase|firestore|hive|record|uuid)\b',
    ).hasMatch(normalized)) {
      return true;
    }
    if (RegExp(
      r'\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b',
    ).hasMatch(normalized)) {
      return true;
    }
    return RegExp(r'\b[a-f0-9]{24,}\b').hasMatch(normalized);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\u0000]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9$.\- ]+'), '')
        .trim();
  }
}
