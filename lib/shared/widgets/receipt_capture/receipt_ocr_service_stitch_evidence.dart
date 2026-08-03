part of 'receipt_ocr_service.dart';

extension ReceiptOcrServiceStitchEvidence on ReceiptOcrService {
  Future<List<ReceiptStitchTextEvidence>> recognizeStitchTextEvidence(
    List<String> paths,
  ) async {
    final normalizedPaths = [
      for (final path in paths)
        if (path.trim().isNotEmpty) path.trim(),
    ];
    if (normalizedPaths.isEmpty) return const [];
    final createdAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final attachments = <ReceiptAttachmentRecord>[
      for (var index = 0; index < normalizedPaths.length; index++)
        ReceiptAttachmentRecord(
          id: 'long_receipt_section_$index',
          path: normalizedPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: createdAt,
          displayName: 'Receipt section ${index + 1}',
          sourceLabel: 'long_receipt_stitch_order',
        ),
    ];
    final result = await recognizeTextFromAttachments(attachments);
    final linesByAttachment = <String, List<String>>{};
    for (final page in result.layout.pages) {
      final orderedLines = [...page.lines]
        ..sort((left, right) {
          final leftTop = left.bounds?.top;
          final rightTop = right.bounds?.top;
          if (leftTop == null || rightTop == null) return 0;
          return leftTop.compareTo(rightTop);
        });
      linesByAttachment[page.attachmentId] = [
        for (final line in orderedLines)
          if (line.text.trim().isNotEmpty) line.text.trim(),
      ];
    }
    return [
      for (var index = 0; index < normalizedPaths.length; index++)
        ReceiptStitchTextEvidence(
          path: normalizedPaths[index],
          lines:
              linesByAttachment['long_receipt_section_$index'] ??
              _stitchEvidenceFallbackLines(
                result.textByAttachmentId['long_receipt_section_$index'],
              ),
        ),
    ];
  }
}

List<String> _stitchEvidenceFallbackLines(String? text) {
  if (text == null || text.trim().isEmpty) return const [];
  return [
    for (final line in text.split(RegExp(r'[\r\n]+')))
      if (line.trim().isNotEmpty) line.trim(),
  ];
}
