part of 'receipt_ocr_service.dart';

class _CombinedReceiptText {
  const _CombinedReceiptText({
    required this.rawText,
    required this.parserText,
    required this.parserLineSourceLocations,
    required this.suppressedDuplicateLines,
    required this.probableOverlapLines,
    required this.possibleSectionGaps,
  });

  final String rawText;
  final String parserText;
  final List<ReceiptOcrParserLineLocation> parserLineSourceLocations;
  final int suppressedDuplicateLines;
  final int probableOverlapLines;
  final int possibleSectionGaps;

  List<String> get warnings {
    final warnings = <String>[];
    if (suppressedDuplicateLines > 0) {
      final label = suppressedDuplicateLines == 1 ? 'line' : 'lines';
      warnings.add(
        'Ignored $suppressedDuplicateLines repeated receipt $label for app-assisted fill. Original receipt text was kept; review line items before saving.',
      );
    }
    if (probableOverlapLines > 0) {
      final label = probableOverlapLines == 1 ? 'line' : 'lines';
      warnings.add(
        'Found $probableOverlapLines possible overlapping receipt $label. Nothing was changed automatically; review line items before saving.',
      );
    }
    if (possibleSectionGaps > 0) {
      final label = possibleSectionGaps == 1
          ? 'section break'
          : 'section breaks';
      warnings.add(
        'Found $possibleSectionGaps receipt $label with no repeated receipt text between sections. Possible missing receipt section; check photo order and line items before saving.',
      );
    }
    return warnings;
  }
}

class _ReceiptPdfReadPreflight {
  const _ReceiptPdfReadPreflight({
    required this.messages,
    required this.blockedAttachmentIds,
    required this.pagesPlannedForRead,
  });

  final List<String> messages;
  final Set<String> blockedAttachmentIds;
  final int pagesPlannedForRead;
}
