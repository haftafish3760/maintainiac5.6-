part of 'receipt_pdf_inspector.dart';

Future<ReceiptPdfInspection> _inspectReceiptPdf(String path) async {
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
  final entityType = await FileSystemEntity.type(trimmed, followLinks: false);
  if (entityType == FileSystemEntityType.notFound) {
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
  if (entityType != FileSystemEntityType.file) {
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
    final currentType = await FileSystemEntity.type(
      trimmed,
      followLinks: false,
    );
    if (currentType != FileSystemEntityType.file) {
      throw const FileSystemException('PDF path is not a regular file.');
    }
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
    final currentType = await FileSystemEntity.type(
      trimmed,
      followLinks: false,
    );
    if (currentType != FileSystemEntityType.file) {
      throw const FileSystemException('PDF path is not a regular file.');
    }
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
  final estimatedPages = ReceiptPdfInspector.estimatePageCount(
    inspectionBytes.bytes,
  );
  final riskFlags = ReceiptPdfInspector.detectRiskFlags(
    inspectionBytes.bytes,
    headerOffset: headerOffset,
  );
  final documentSignals = ReceiptPdfInspector.detectDocumentSignals(
    inspectionBytes.bytes,
  );
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
