part of 'receipt_assistance_policy.dart';

class ReceiptAssistanceDecision {
  const ReceiptAssistanceDecision({
    required this.mode,
    required this.reason,
    this.warnings = const [],
  });

  final ReceiptAssistanceMode mode;
  final String reason;
  final List<String> warnings;

  bool get shouldReadLocally =>
      mode == ReceiptAssistanceMode.localRead ||
      mode == ReceiptAssistanceMode.localReadWithReview;

  bool get needsReview => mode != ReceiptAssistanceMode.localRead;
}

class ReceiptAssistancePolicy {
  const ReceiptAssistancePolicy({
    this.device = const ReceiptDeviceCapability.standard(),
    this.cloudAssistedAvailable = false,
  });

  final ReceiptDeviceCapability device;
  final bool cloudAssistedAvailable;

  ReceiptAssistanceDecision decideForAttachment(
    ReceiptAttachmentRecord attachment,
  ) {
    if (attachment.isImportedText) {
      final text = attachment.importedText.trim();
      if (text.isEmpty) {
        return const ReceiptAssistanceDecision(
          mode: ReceiptAssistanceMode.proofOnly,
          reason: 'No receipt text was available to read.',
        );
      }
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localRead,
        reason: 'Imported receipt text can be read directly on this device.',
      );
    }
    if (attachment.isPdf) return _decideForPdf(attachment);
    if (attachment.isPhoto) return _decideForPhoto(attachment);
    return const ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.proofOnly,
      reason: 'This attachment type can be saved as proof.',
    );
  }

  ReceiptAssistanceDecision decideForAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) {
    if (attachments.isEmpty) {
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason: 'No receipt proof was attached.',
      );
    }
    final decisions = attachments.map(decideForAttachment).toList();
    final photoCount = attachments
        .where((attachment) => attachment.isPhoto)
        .length;
    final countWarnings = <String>[
      if (photoCount > device.maxLocalPhotoCount)
        'This receipt has $photoCount photos. ${device.profileName} is tuned for ${device.maxLocalPhotoCount}; review the result before saving.',
    ];
    if (decisions.any((decision) => decision.shouldReadLocally)) {
      final warnings = [
        ...countWarnings,
        for (final decision in decisions) ...decision.warnings,
      ];
      return ReceiptAssistanceDecision(
        mode: warnings.isEmpty
            ? ReceiptAssistanceMode.localRead
            : ReceiptAssistanceMode.localReadWithReview,
        reason: 'At least one receipt attachment can be read on this device.',
        warnings: warnings,
      );
    }
    if (decisions.any(
      (decision) => decision.mode == ReceiptAssistanceMode.cloudCandidate,
    )) {
      return const ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.cloudCandidate,
        reason:
            'Receipt proof can be saved now and offered for cloud-assisted reading later.',
      );
    }
    return ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.proofOnly,
      reason: decisions.first.reason,
      warnings: [
        ...countWarnings,
        for (final decision in decisions) ...decision.warnings,
      ],
    );
  }

  ReceiptAssistanceDecision _decideForPdf(ReceiptAttachmentRecord attachment) {
    final validation = attachment.validationStatus;
    if (validation == ReceiptPdfValidationStatus.missing ||
        validation == ReceiptPdfValidationStatus.empty ||
        validation == ReceiptPdfValidationStatus.invalidHeader ||
        validation == ReceiptPdfValidationStatus.tooLarge ||
        validation == ReceiptPdfValidationStatus.failed) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason: 'This PDF cannot be read safely on this device.',
        warnings: [validation.label],
      );
    }
    if (attachment.riskFlags.contains(ReceiptPdfInspector.encryptionRiskFlag) ||
        attachment.riskFlags.any(
          ReceiptPdfInspector.activeContentRiskFlags.contains,
        )) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason:
            'This PDF can be saved as proof, but app-assisted reading will not open protected or active PDF content.',
        warnings: attachment.riskFlags,
      );
    }
    final byteSize = attachment.byteSize ?? 0;
    final pageCount = attachment.pageCount ?? 1;
    final tooLargeForDevice =
        byteSize > device.maxLocalPdfBytes ||
        pageCount > device.maxLocalPdfPages;
    if (tooLargeForDevice) {
      if (cloudAssistedAvailable &&
          byteSize <= ReceiptPdfLimits.cloudAssistedReadBytes &&
          pageCount <= ReceiptPdfLimits.cloudAssistedReadPageLimit) {
        return ReceiptAssistanceDecision(
          mode: ReceiptAssistanceMode.cloudCandidate,
          reason:
              'This PDF is too heavy for ${device.profileName}, but it fits the future cloud-assisted reading limits.',
          warnings: ['Save as proof first; cloud reading must be explicit.'],
        );
      }
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.proofOnly,
        reason:
            'This PDF is too heavy for ${device.profileName}. Save it as proof and enter the totals/allocation manually.',
      );
    }
    final warnings = <String>[];
    if (attachment.pageCountStatus == ReceiptPdfPageCountStatus.unknown) {
      warnings.add('PDF page count is unknown.');
    }
    if (pageCount > ReceiptPdfLimits.softPdfPageWarning) {
      warnings.add('Long receipt PDF; review parsed lines before saving.');
    }
    if (attachment.documentSignals.contains(
      ReceiptPdfInspector.imageContentSignal,
    )) {
      warnings.add('Image-based PDF; reading quality depends on page clarity.');
    }
    return ReceiptAssistanceDecision(
      mode: warnings.isEmpty
          ? ReceiptAssistanceMode.localRead
          : ReceiptAssistanceMode.localReadWithReview,
      reason:
          'This PDF fits ${device.profileName} local app-assisted reading limits.',
      warnings: warnings,
    );
  }

  ReceiptAssistanceDecision _decideForPhoto(
    ReceiptAttachmentRecord attachment,
  ) {
    final byteSize = attachment.byteSize ?? 0;
    final qualityWarnings = <String>[
      if (attachment.photoQualityNeedsReview)
        attachment.photoQualityLabel.trim().isEmpty
            ? 'Receipt photo quality needs review.'
            : attachment.photoQualityLabel,
      ...attachment.photoQualityWarnings,
    ];
    if (byteSize > device.maxLocalPhotoBytes) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localReadWithReview,
        reason:
            'This receipt photo is large for ${device.profileName}; read locally, then review carefully.',
        warnings: [
          'Large receipt photo may be slower on older phones.',
          ...qualityWarnings,
        ],
      );
    }
    if (qualityWarnings.isNotEmpty) {
      return ReceiptAssistanceDecision(
        mode: ReceiptAssistanceMode.localReadWithReview,
        reason:
            'This receipt photo can be read on ${device.profileName}, but the photo quality needs review.',
        warnings: qualityWarnings,
      );
    }
    return ReceiptAssistanceDecision(
      mode: ReceiptAssistanceMode.localRead,
      reason: 'Receipt photos can be read on ${device.profileName}.',
    );
  }
}
