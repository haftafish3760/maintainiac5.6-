part of 'receipt_pdf_inspector.dart';

Future<List<int>> _readHeader(File file) async {
  final stream = file.openRead(0, 1024);
  final chunks = <int>[];
  await for (final chunk in stream) {
    chunks.addAll(chunk);
    if (chunks.length >= 1024) break;
  }
  return chunks;
}

Future<_ReceiptPdfInspectionBytes> _readInspectionBytes(
  File file,
  int byteSize,
) async {
  if (byteSize <= ReceiptPdfLimits.localAssistedReadBytes) {
    return _ReceiptPdfInspectionBytes(await file.readAsBytes());
  }
  final header = await _readRange(
    file,
    0,
    ReceiptPdfInspector.metadataSampleBytes,
  );
  final tailStart = byteSize - ReceiptPdfInspector.metadataSampleBytes;
  final tail = await _readRange(
    file,
    tailStart < 0 ? 0 : tailStart,
    ReceiptPdfInspector.metadataSampleBytes,
  );
  if (tail.isEmpty) return _ReceiptPdfInspectionBytes(header);
  return _ReceiptPdfInspectionBytes([...header, ...tail]);
}

Future<List<int>> _readRange(File file, int start, int maxBytes) async {
  final chunks = <int>[];
  final end = start + maxBytes;
  await for (final chunk in file.openRead(start, end)) {
    chunks.addAll(chunk);
    if (chunks.length >= maxBytes) break;
  }
  return chunks.length <= maxBytes ? chunks : chunks.sublist(0, maxBytes);
}

int? _pdfHeaderOffset(List<int> bytes) {
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

class _ReceiptPdfInspectionBytes {
  const _ReceiptPdfInspectionBytes(this.bytes);

  final List<int> bytes;
}
