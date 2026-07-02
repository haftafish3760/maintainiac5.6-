part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrReadStats {
  const ReceiptOcrReadStats({
    this.importedTextRead = 0,
    this.photosRead = 0,
    this.photosSkipped = 0,
    this.pdfsRead = 0,
    this.pdfsSkipped = 0,
    this.pdfPagesRequested = 0,
  });

  final int importedTextRead;
  final int photosRead;
  final int photosSkipped;
  final int pdfsRead;
  final int pdfsSkipped;
  final int pdfPagesRequested;

  int get attachmentsRead => importedTextRead + photosRead + pdfsRead;
  int get attachmentsSkipped => photosSkipped + pdfsSkipped;
  bool get usedLocalOcr => photosRead > 0 || pdfsRead > 0;
  bool get hadSkippedWork => attachmentsSkipped > 0;

  String get readSummaryLabel {
    final parts = <String>[
      if (importedTextRead > 0)
        '$importedTextRead pasted/imported text ${importedTextRead == 1 ? 'source' : 'sources'}',
      if (photosRead > 0)
        '$photosRead receipt ${photosRead == 1 ? 'photo' : 'photos'}',
      if (pdfsRead > 0) '$pdfsRead receipt ${pdfsRead == 1 ? 'PDF' : 'PDFs'}',
    ];
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.single;
    return '${parts.take(parts.length - 1).join(', ')} and ${parts.last}';
  }

  String get skippedSummaryLabel {
    final parts = <String>[
      if (photosSkipped > 0)
        '$photosSkipped extra ${photosSkipped == 1 ? 'photo was' : 'photos were'}',
      if (pdfsSkipped > 0)
        '$pdfsSkipped extra ${pdfsSkipped == 1 ? 'PDF was' : 'PDFs were'}',
    ];
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.single;
    return '${parts.take(parts.length - 1).join(', ')} and ${parts.last}';
  }
}
