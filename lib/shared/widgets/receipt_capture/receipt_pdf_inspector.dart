import 'dart:io';

import 'receipt_capture_models.dart';
import 'receipt_pdf_limits.dart';

part 'receipt_pdf_inspection.dart';

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

  static Future<ReceiptPdfInspection> inspect(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return const ReceiptPdfInspection(
        path: '',
        exists: false,
        byteSize: 0,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.unknown,
        validationStatus: ReceiptPdfValidationStatus.missing,
        riskFlags: [],
        documentSignals: [],
      );
    }
    final file = File(trimmed);
    if (!await file.exists()) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: false,
        byteSize: 0,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.unknown,
        validationStatus: ReceiptPdfValidationStatus.missing,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    late final int byteSize;
    try {
      byteSize = await file.length();
    } catch (_) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: 0,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.failed,
        validationStatus: ReceiptPdfValidationStatus.failed,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    if (byteSize <= 0) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: byteSize,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.unknown,
        validationStatus: ReceiptPdfValidationStatus.empty,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    late final List<int> header;
    try {
      header = await _readHeader(file);
    } catch (_) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: byteSize,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.failed,
        validationStatus: ReceiptPdfValidationStatus.failed,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    final headerOffset = _pdfHeaderOffset(header);
    final hasPdfHeader = headerOffset != null;
    if (!hasPdfHeader) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: byteSize,
        pageCount: null,
        hasPdfHeader: false,
        pageCountStatus: ReceiptPdfPageCountStatus.failed,
        validationStatus: ReceiptPdfValidationStatus.invalidHeader,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    if (byteSize > ReceiptPdfLimits.maxPdfBytes) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: byteSize,
        pageCount: null,
        hasPdfHeader: true,
        pageCountStatus: ReceiptPdfPageCountStatus.unknown,
        validationStatus: ReceiptPdfValidationStatus.tooLarge,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    late final _ReceiptPdfInspectionBytes inspectionBytes;
    try {
      inspectionBytes = await _readInspectionBytes(file, byteSize);
    } catch (_) {
      return ReceiptPdfInspection(
        path: trimmed,
        exists: true,
        byteSize: byteSize,
        pageCount: null,
        hasPdfHeader: true,
        pageCountStatus: ReceiptPdfPageCountStatus.failed,
        validationStatus: ReceiptPdfValidationStatus.failed,
        riskFlags: const [],
        documentSignals: const [],
      );
    }
    final estimatedPages = estimatePageCount(inspectionBytes.bytes);
    final riskFlags = detectRiskFlags(
      inspectionBytes.bytes,
      headerOffset: headerOffset,
    );
    final documentSignals = detectDocumentSignals(inspectionBytes.bytes);
    final pageCountStatus = estimatedPages == null
        ? ReceiptPdfPageCountStatus.unknown
        : ReceiptPdfPageCountStatus.estimated;
    final validationStatus = estimatedPages == null
        ? ReceiptPdfValidationStatus.pageCountUnknown
        : ReceiptPdfValidationStatus.valid;
    return ReceiptPdfInspection(
      path: trimmed,
      exists: true,
      byteSize: byteSize,
      pageCount: estimatedPages,
      hasPdfHeader: true,
      pageCountStatus: pageCountStatus,
      validationStatus: validationStatus,
      riskFlags: riskFlags,
      documentSignals: documentSignals,
    );
  }

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

  static Future<List<int>> _readHeader(File file) async {
    final stream = file.openRead(0, 1024);
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
      if (chunks.length >= 1024) break;
    }
    return chunks;
  }

  static Future<_ReceiptPdfInspectionBytes> _readInspectionBytes(
    File file,
    int byteSize,
  ) async {
    if (byteSize <= ReceiptPdfLimits.localAssistedReadBytes) {
      return _ReceiptPdfInspectionBytes(await file.readAsBytes());
    }
    final header = await _readRange(file, 0, metadataSampleBytes);
    final tailStart = byteSize - metadataSampleBytes;
    final tail = await _readRange(
      file,
      tailStart < 0 ? 0 : tailStart,
      metadataSampleBytes,
    );
    if (tail.isEmpty) return _ReceiptPdfInspectionBytes(header);
    return _ReceiptPdfInspectionBytes([...header, ...tail]);
  }

  static Future<List<int>> _readRange(
    File file,
    int start,
    int maxBytes,
  ) async {
    final chunks = <int>[];
    final end = start + maxBytes;
    await for (final chunk in file.openRead(start, end)) {
      chunks.addAll(chunk);
      if (chunks.length >= maxBytes) break;
    }
    return chunks.length <= maxBytes ? chunks : chunks.sublist(0, maxBytes);
  }

  static int? _pdfHeaderOffset(List<int> bytes) {
    if (bytes.length < 5) return null;
    final maxStart = bytes.length < 1024 ? bytes.length - 5 : 1019;
    for (var index = 0; index <= maxStart; index++) {
      if (bytes[index] == 0x25 &&
          bytes[index + 1] == 0x50 &&
          bytes[index + 2] == 0x44 &&
          bytes[index + 3] == 0x46 &&
          bytes[index + 4] == 0x2D) {
        return index;
      }
    }
    return null;
  }
}

class _ReceiptPdfInspectionBytes {
  const _ReceiptPdfInspectionBytes(this.bytes);

  final List<int> bytes;
}
