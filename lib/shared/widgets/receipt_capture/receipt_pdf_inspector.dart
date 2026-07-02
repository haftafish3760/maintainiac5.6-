import 'dart:io';

import 'receipt_capture_models.dart';
import 'receipt_pdf_limits.dart';

part 'receipt_pdf_inspection.dart';
part 'receipt_pdf_inspector_bytes.dart';
part 'receipt_pdf_inspector_inspect.dart';

class ReceiptPdfInspector {
  const ReceiptPdfInspector._();

  static const encryptionRiskFlag = 'encryption or password security';
  static const imageContentSignal = 'image content';
  static const headerOffsetRiskFlag = 'PDF header is not at the start';
  static const embeddedJavaScriptRiskFlag = 'embedded JavaScript';
  static const openActionRiskFlag = 'auto-open actions';
  static const launchActionRiskFlag = 'launch actions';
  static const automaticActionRiskFlag = 'automatic actions';
  static const embeddedFileRiskFlag = 'embedded files';
  static const embeddedMediaRiskFlag = 'embedded media';
  static const formSubmissionRiskFlag = 'form submission actions';
  static const activeContentRiskFlags = <String>{
    embeddedJavaScriptRiskFlag,
    openActionRiskFlag,
    launchActionRiskFlag,
    automaticActionRiskFlag,
    embeddedFileRiskFlag,
    embeddedMediaRiskFlag,
    formSubmissionRiskFlag,
  };
  static const receiptSignals = <String>{
    'receipt',
    'invoice',
    'subtotal',
    'tax',
    'total',
    'payment',
    'paid',
    'sale',
    'order',
    'cashier',
    'clerk',
    'customer copy',
    'store',
    'vendor',
    'balance due',
    'transaction',
    'authorization',
    'merchant',
    'qty',
    'quantity',
    'change due',
    'card',
    'visa',
    'mastercard',
    'amex',
    'discover',
  };
  static const nonReceiptSignals = <String>{
    'manual',
    'warranty',
    'policy',
    'statement',
    'terms',
    'certificate',
    'report',
  };

  static const localAssistedReadPageLimit =
      ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater;
  static const localAssistedReadBytes = ReceiptPdfLimits.localAssistedReadBytes;
  static const cloudAssistedReadPageLimit =
      ReceiptPdfLimits.cloudAssistedReadPageLimit;
  static const cloudAssistedReadBytes = ReceiptPdfLimits.cloudAssistedReadBytes;
  static const importBytesLimit = ReceiptPdfLimits.maxPdfBytes;
  static const metadataSampleBytes = 256 * 1024;

  static Future<ReceiptPdfInspection> inspect(String path) =>
      _inspectReceiptPdf(path);

  static int? estimatePageCount(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final text = String.fromCharCodes(bytes);
    final matches = RegExp(r'/Type\s*/Page\b').allMatches(text).length;
    if (matches > 0) return matches;
    final count = RegExp(
      r'/Type\s*/Pages\b[^>]*?/Count\s+(\d+)',
    ).firstMatch(text)?.group(1);
    if (count == null) return null;
    return int.tryParse(count);
  }

  static List<String> detectRiskFlags(List<int> bytes, {int? headerOffset}) {
    if (bytes.isEmpty) return const [];
    final text = String.fromCharCodes(bytes).toLowerCase();
    final flags = <String>[];
    if ((headerOffset ?? 0) > 0) flags.add(headerOffsetRiskFlag);
    if (_containsPdfName(text, 'encrypt')) flags.add(encryptionRiskFlag);
    if (_containsPdfName(text, 'javascript') || _containsPdfName(text, 'js')) {
      flags.add(embeddedJavaScriptRiskFlag);
    }
    if (_containsPdfName(text, 'openaction')) flags.add(openActionRiskFlag);
    if (_containsPdfName(text, 'launch')) flags.add(launchActionRiskFlag);
    if (_containsPdfName(text, 'aa')) flags.add(automaticActionRiskFlag);
    if (_containsPdfName(text, 'embeddedfile') ||
        _containsPdfName(text, 'filespec')) {
      flags.add(embeddedFileRiskFlag);
    }
    if (_containsPdfName(text, 'richmedia')) flags.add(embeddedMediaRiskFlag);
    if (_containsPdfName(text, 'submitform')) {
      flags.add(formSubmissionRiskFlag);
    }
    if (_containsPdfName(text, 'acroform') || _containsPdfName(text, 'xfa')) {
      flags.add('form fields');
    }
    if (_containsPdfName(text, 'annots')) flags.add('annotations');
    if (!text.contains('%%eof')) flags.add('missing EOF marker');
    if (!text.contains('startxref')) flags.add('missing startxref marker');
    if (!RegExp(r'(^|\s)xref(\s|$)').hasMatch(text)) {
      flags.add('missing xref table marker');
    }
    if (!_containsPdfName(text, 'trailer') && !text.contains('trailer')) {
      flags.add('missing trailer marker');
    }
    if (_containsPdfName(text, 'uri') ||
        text.contains('http://') ||
        text.contains('https://')) {
      flags.add('external links');
    }
    return List.unmodifiable(flags);
  }

  static List<String> detectDocumentSignals(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    final text = String.fromCharCodes(bytes).toLowerCase();
    final signals = <String>[];
    for (final signal in {...receiptSignals, ...nonReceiptSignals}) {
      if (_containsPhrase(text, signal)) signals.add(signal);
    }
    if (_containsPdfName(text, 'image') || _containsPdfName(text, 'xobject')) {
      signals.add(imageContentSignal);
    }
    return List.unmodifiable(signals);
  }

  static bool _containsPdfName(String text, String name) {
    final escaped = RegExp.escape(name.toLowerCase());
    return RegExp('/$escaped(?![a-z0-9])').hasMatch(text);
  }

  static bool _containsPhrase(String text, String phrase) {
    final escaped = RegExp.escape(phrase);
    return RegExp(r'(^|[^a-z0-9])' + escaped + r'([^a-z0-9]|$)').hasMatch(text);
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}
