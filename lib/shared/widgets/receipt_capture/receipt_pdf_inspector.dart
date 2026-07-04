import 'dart:convert';
import 'dart:io';

import '../../pdf/app_pdf_security_policy.dart';
import 'receipt_capture_models.dart';
import 'receipt_pdf_limits.dart';

part 'receipt_pdf_inspection.dart';
part 'receipt_pdf_inspector_bytes.dart';
part 'receipt_pdf_inspector_inspect.dart';

class ReceiptPdfInspector {
  const ReceiptPdfInspector._();

  static const encryptionRiskFlag = 'encryption or password security';
  static const imageContentSignal = 'image content';
  static const textLayerSignal = 'text layer';
  static const rotatedPageSignal = 'rotated pages';
  static const croppedPageSignal = 'cropped pages';
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
    if (AppPdfSecurityPolicy.containsPdfName(text, 'encrypt')) {
      flags.add(encryptionRiskFlag);
    }
    final activeCodes = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      bytes,
    );
    if (activeCodes.contains(AppPdfSecurityPolicy.activeJavaScript)) {
      flags.add(embeddedJavaScriptRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.autoOpenAction)) {
      flags.add(openActionRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.activeLaunchAction)) {
      flags.add(launchActionRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.automaticAction)) {
      flags.add(automaticActionRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.embeddedFile)) {
      flags.add(embeddedFileRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.embeddedMedia)) {
      flags.add(embeddedMediaRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.formSubmissionAction)) {
      flags.add(formSubmissionRiskFlag);
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.dynamicFormContent)) {
      flags.add('form fields');
    }
    if (AppPdfSecurityPolicy.containsPdfName(text, 'annots')) {
      flags.add('annotations');
    }
    if (!text.contains('%%eof')) flags.add('missing EOF marker');
    if (!text.contains('startxref')) flags.add('missing startxref marker');
    if (!RegExp(r'(^|\s)xref(\s|$)').hasMatch(text)) {
      flags.add('missing xref table marker');
    }
    if (!AppPdfSecurityPolicy.containsPdfName(text, 'trailer') &&
        !text.contains('trailer')) {
      flags.add('missing trailer marker');
    }
    if (activeCodes.contains(AppPdfSecurityPolicy.externalLinks)) {
      flags.add('external links');
    }
    return List.unmodifiable(flags);
  }

  static List<String> detectDocumentSignals(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    final text = _pdfSignalText(bytes).toLowerCase();
    final signals = <String>[];
    for (final signal in {...receiptSignals, ...nonReceiptSignals}) {
      if (_containsPhrase(text, signal)) signals.add(signal);
    }
    if (AppPdfSecurityPolicy.containsPdfName(text, 'image') ||
        AppPdfSecurityPolicy.containsPdfName(text, 'xobject')) {
      signals.add(imageContentSignal);
    }
    if (_hasLikelyTextLayer(text)) signals.add(textLayerSignal);
    if (AppPdfSecurityPolicy.containsPdfName(text, 'rotate')) {
      signals.add(rotatedPageSignal);
    }
    if (AppPdfSecurityPolicy.containsPdfName(text, 'cropbox')) {
      signals.add(croppedPageSignal);
    }
    return List.unmodifiable(signals);
  }

  static bool _containsPhrase(String text, String phrase) {
    final escaped = RegExp.escape(phrase);
    return RegExp(r'(^|[^a-z0-9])' + escaped + r'([^a-z0-9]|$)').hasMatch(text);
  }

  static bool _hasLikelyTextLayer(String text) {
    return RegExp(r'(^|\s)bt(\s|$)').hasMatch(text) &&
        RegExp(r'(^|\s)et(\s|$)').hasMatch(text) &&
        (RegExp(r'\btj\b').hasMatch(text) ||
            text.contains("'") ||
            text.contains('"'));
  }

  static String _pdfSignalText(List<int> bytes) {
    final rawText = latin1.decode(bytes, allowInvalid: true);
    final decodedText = <String>[];
    for (final match in RegExp(
      r'<([0-9a-fA-F\s]{4,})>',
      multiLine: true,
    ).allMatches(rawText)) {
      final hex = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
      if (hex.length.isOdd) continue;
      final values = <int>[];
      for (var index = 0; index < hex.length; index += 2) {
        final value = int.tryParse(hex.substring(index, index + 2), radix: 16);
        if (value == null) {
          values.clear();
          break;
        }
        values.add(value);
      }
      if (values.isEmpty) continue;
      final decoded = _decodePdfHexString(values);
      if (decoded == null) continue;
      decodedText.add(decoded);
    }
    if (decodedText.isEmpty) return rawText;
    return '$rawText ${decodedText.join(' ')}';
  }

  static String? _decodePdfHexString(List<int> values) {
    if (values.length >= 2 && values[0] == 0xFE && values[1] == 0xFF) {
      return _decodeUtf16CodeUnits(
        values.skip(2).toList(),
        littleEndian: false,
      );
    }
    if (values.length >= 2 && values[0] == 0xFF && values[1] == 0xFE) {
      return _decodeUtf16CodeUnits(values.skip(2).toList(), littleEndian: true);
    }
    if (!_looksPrintable(values)) return null;
    return latin1.decode(values, allowInvalid: true);
  }

  static String? _decodeUtf16CodeUnits(
    List<int> values, {
    required bool littleEndian,
  }) {
    if (values.isEmpty || values.length.isOdd) return null;
    final buffer = StringBuffer();
    for (var index = 0; index < values.length; index += 2) {
      final first = values[index];
      final second = values[index + 1];
      final codeUnit = littleEndian
          ? first | (second << 8)
          : (first << 8) | second;
      if (!_isPrintableCodeUnit(codeUnit)) return null;
      buffer.writeCharCode(codeUnit);
    }
    final decoded = buffer.toString();
    return decoded.trim().isEmpty ? null : decoded;
  }

  static bool _looksPrintable(List<int> values) =>
      values.every(_isPrintableCodeUnit);

  static bool _isPrintableCodeUnit(int value) =>
      value == 9 || value == 10 || value == 13 || value >= 32;

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}
