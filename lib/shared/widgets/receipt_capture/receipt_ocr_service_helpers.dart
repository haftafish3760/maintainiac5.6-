part of 'receipt_ocr_service.dart';

ReceiptProcessingSource _sourceFor(List<ReceiptAttachmentRecord> attachments) {
  final hasPhoto = attachments.any((attachment) => attachment.isPhoto);
  final hasPdf = attachments.any((attachment) => attachment.isPdf);
  final hasImportedText = attachments.any(
    (attachment) => attachment.isImportedText,
  );
  final sourceCount = [
    hasPhoto,
    hasPdf,
    hasImportedText,
  ].where((present) => present).length;
  if (sourceCount == 0) return ReceiptProcessingSource.none;
  if (sourceCount > 1) return ReceiptProcessingSource.mixed;
  if (hasPhoto) return ReceiptProcessingSource.photo;
  if (hasPdf) return ReceiptProcessingSource.pdf;
  return ReceiptProcessingSource.importedText;
}

void _addUniqueMessage(List<String> messages, String message) {
  final clean = message.trim();
  if (clean.isEmpty || messages.contains(clean)) return;
  messages.add(clean);
}

List<String> _photoQualityWarnings(List<ReceiptAttachmentRecord> photos) {
  final warnings = <String>[];
  for (var index = 0; index < photos.length; index++) {
    final attachment = photos[index];
    final section = index + 1;
    if (attachment.photoQualityNeedsReview) {
      final label = attachment.photoQualityLabel.trim().isEmpty
          ? 'Photo quality needs review'
          : attachment.photoQualityLabel;
      final issues = attachment.photoQualityWarnings.take(2).join(' ');
      warnings.add(
        'Receipt photo quality needs review for section $section: $label.${issues.isEmpty ? '' : ' $issues'}',
      );
    }
    if (attachment.riskFlags.contains(
      'ocr_source_small_proof_copy_review_required',
    )) {
      warnings.add(
        'Receipt proof copy is small for section $section. OCR used the prepared source first, but review the saved proof image before saving.',
      );
    }
    if (_hasScannerPreparationRisk(attachment.riskFlags)) {
      warnings.add(
        'Receipt image cleanup needs review for section $section. OCR used the safest available source, but check that the receipt text is clear before saving.',
      );
    }
  }
  return warnings;
}

bool _hasScannerPreparationRisk(List<String> riskFlags) {
  for (final risk in riskFlags) {
    if (_isScannerPreparationRiskToken(risk)) return true;
  }
  return false;
}

bool _isScannerPreparationRiskToken(String value) {
  final normalized = value.toLowerCase();
  if (!normalized.startsWith('ocr_source_')) return false;
  return normalized.contains('quality_guard') ||
      normalized.contains('decode_failed') ||
      normalized.contains('skipped');
}
