part of 'receipt_attachment_panel.dart';

String _receiptReadSourceSummary(List<ReceiptAttachmentRecord> attachments) {
  final photoCount = attachments
      .where((attachment) => attachment.isPhoto)
      .length;
  final pdfCount = attachments.where((attachment) => attachment.isPdf).length;
  final textCount = attachments
      .where((attachment) => attachment.isImportedText)
      .length;
  final parts = <String>[
    if (photoCount > 0)
      photoCount == 1
          ? '1 clear receipt photo'
          : '$photoCount clear receipt photos',
    if (pdfCount > 0)
      pdfCount == 1 ? '1 receipt PDF' : '$pdfCount receipt PDFs',
    if (textCount > 0)
      textCount == 1
          ? '1 saved receipt text'
          : '$textCount saved receipt texts',
  ];
  if (parts.isEmpty) return 'the receipt image';
  if (parts.length == 1) return parts.single;
  if (parts.length == 2) return '${parts.first} and ${parts.last}';
  return '${parts.take(parts.length - 1).join(', ')}, and ${parts.last}';
}

_ReceiptReadRecoveryAdvice _receiptReadRecoveryAdvice(
  List<ReceiptAttachmentRecord> attachments, {
  ReceiptOcrDiagnostics? diagnostics,
}) {
  final photoCount = attachments
      .where((attachment) => attachment.isPhoto)
      .length;
  final pdfCount = attachments.where((attachment) => attachment.isPdf).length;
  final textCount = attachments
      .where((attachment) => attachment.isImportedText)
      .length;
  final hasPhoto = photoCount > 0;
  final hasPdf = pdfCount > 0;
  final hasText = textCount > 0;
  final sourceQualityAction = diagnostics
      ?.ocrSourceHandoffContract['sourceQualityReviewAction']
      ?.toString()
      .trim();
  if (hasPhoto && !hasPdf && !hasText) {
    if (sourceQualityAction == 'add_bottom_section_with_ghost_slice') {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt bottom section still needs capture.',
        primaryAction:
            'Keep the image attached, add the bottom receipt section with the top reference strip, or continue by hand.',
        shortAction:
            'Add the bottom section with the reference strip, or continue by hand.',
      );
    }
    if (sourceQualityAction == 'check_bottom_or_add_photo') {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt bottom photo needs review.',
        primaryAction:
            'Keep the image attached, zoom into the total and final lines, add a clearer bottom photo, or continue by hand.',
        shortAction:
            'Check the bottom, add a clearer bottom photo, or continue by hand.',
      );
    }
    if (sourceQualityAction == 'retake_or_raise_brightness') {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt photo saved too dark for reliable reading.',
        primaryAction:
            'Keep the image attached, raise Brightness or add light, retake the receipt, or continue by hand.',
        shortAction:
            'Raise Brightness, retake with more light, or continue by hand.',
      );
    }
    if (sourceQualityAction == 'retake_hold_steady') {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt photo may be too soft for reliable reading.',
        primaryAction:
            'Keep the image attached, retake while holding steady, or continue by hand.',
        shortAction: 'Retake while holding steady, or continue by hand.',
      );
    }
    if (photoCount > 1) {
      return const _ReceiptReadRecoveryAdvice(
        failureLead: 'Receipt photo text was not readable enough.',
        primaryAction:
            'Keep the image attached, check the photo order, add a clearer missing section, or continue by hand.',
        shortAction:
            'Check photo order, add a clearer section, or continue by hand.',
      );
    }
    return const _ReceiptReadRecoveryAdvice(
      failureLead: 'Receipt photo text was not readable enough.',
      primaryAction:
          'Keep the image attached, retake with brighter light and the full receipt in frame, use Add Another Photo if it is long, or continue by hand.',
      shortAction:
          'Retake, use Add Another Photo if needed, or continue by hand.',
    );
  }
  if (hasPdf && !hasPhoto && !hasText) {
    return const _ReceiptReadRecoveryAdvice(
      failureLead: 'Receipt PDF text was not readable enough.',
      primaryAction:
          'Keep the PDF attached, add a clear receipt photo if you have one, or continue by hand.',
      shortAction:
          'Add a clear receipt photo if available, or continue by hand.',
    );
  }
  if (hasText && !hasPhoto && !hasPdf) {
    return const _ReceiptReadRecoveryAdvice(
      failureLead: 'Saved receipt text could not be used to fill the form.',
      primaryAction:
          'Keep the saved text, paste cleaner receipt text, attach a clear photo, or continue by hand.',
      shortAction:
          'Paste cleaner text, attach a clear photo, or continue by hand.',
    );
  }
  if (hasPhoto || hasPdf || hasText) {
    return const _ReceiptReadRecoveryAdvice(
      failureLead: 'Receipt sources were not readable enough.',
      primaryAction:
          'Keep the image attached, choose the clearest source, add a clearer receipt photo, or continue by hand.',
      shortAction:
          'Choose the clearest source, add a clearer photo, or continue by hand.',
    );
  }
  return const _ReceiptReadRecoveryAdvice(
    failureLead: 'Receipt image was not readable enough.',
    primaryAction:
        'Attach a clear receipt photo, import a readable PDF, paste receipt text, or continue by hand.',
    shortAction: 'Attach a clear image or continue by hand.',
  );
}

class _ReceiptReadRecoveryAdvice {
  const _ReceiptReadRecoveryAdvice({
    required this.failureLead,
    required this.primaryAction,
    required this.shortAction,
  });

  final String failureLead;
  final String primaryAction;
  final String shortAction;
}
