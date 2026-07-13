part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.rawText,
    required this.parserText,
    required this.textByAttachmentId,
    required this.source,
    this.stats = const ReceiptOcrReadStats(),
    this.sourceHandoffSummary = const ReceiptOcrSourceHandoffSummary.empty(),
    this.layout = const ReceiptOcrDocument.empty(),
    this.warnings = const [],
    this.parserLineSourceLocations = const [],
  });

  final String rawText;
  final String parserText;
  final Map<String, String> textByAttachmentId;
  final ReceiptProcessingSource source;
  final ReceiptOcrReadStats stats;
  final ReceiptOcrSourceHandoffSummary sourceHandoffSummary;

  /// Provider-neutral layout preserved from OCR. Downstream receipt systems
  /// consume this instead of reaching into an ML Kit-specific result type.
  final ReceiptOcrDocument layout;
  final List<String> warnings;
  final List<ReceiptOcrParserLineLocation> parserLineSourceLocations;

  bool get hasText => rawText.trim().isNotEmpty;
  String get appFillText => parserText.trim().isEmpty ? rawText : parserText;
  List<String> get orderedRawLines => _receiptOcrLines(rawText);
  List<String> get orderedParserLines => _receiptOcrLines(appFillText);

  ReceiptOcrDiagnostics get diagnostics =>
      ReceiptOcrDiagnostics.fromResult(this);
  List<ReceiptOcrWarning> get structuredWarnings {
    return warnings.map(ReceiptOcrWarning.fromMessage).toList(growable: false);
  }

  List<ReceiptOcrWarning> get prioritizedWarnings {
    final structured = structuredWarnings.toList(growable: false);
    structured.sort(_compareWarningsForResult);
    return List.unmodifiable(structured);
  }

  int _compareWarningsForResult(
    ReceiptOcrWarning left,
    ReceiptOcrWarning right,
  ) {
    if (!hasText) {
      final leftIsNoReadable =
          left.kind == ReceiptOcrWarningKind.noReadableText;
      final rightIsNoReadable =
          right.kind == ReceiptOcrWarningKind.noReadableText;
      if (leftIsNoReadable != rightIsNoReadable) {
        final concrete = leftIsNoReadable ? right : left;
        if (concrete.isConcreteNoTextCause) {
          return leftIsNoReadable ? 1 : -1;
        }
      }
    }
    return ReceiptOcrWarning.compareByPriority(left, right);
  }

  ReceiptOcrWarning? get primaryWarning {
    final prioritized = prioritizedWarnings;
    if (prioritized.isEmpty) return null;
    return prioritized.first;
  }

  String get strongestActionMessage {
    final warning = primaryWarning;
    if (warning != null) return warning.reviewMessage;
    if (!hasText) {
      return 'No readable text. Retake the photo or enter it by hand.';
    }
    return 'Review the filled receipt before saving.';
  }

  String reviewMessage({required String successMessage}) {
    final read = stats.readSummaryLabel;
    final skipped = stats.skippedSummaryLabel;
    final warning = primaryWarning;
    final skippedSourceWarning = _firstWarningMessageForKind(
      ReceiptOcrWarningKind.sourceSkipped,
      except: warning,
    );
    if (!hasText) {
      final noText =
          warning?.reviewMessage ?? 'No readable receipt text was found.';
      return skippedSourceWarning.isEmpty
          ? noText
          : '$noText $skippedSourceWarning';
    }
    final parts = <String>[
      successMessage,
      if (read.isNotEmpty) 'Read $read.',
      if (skipped.isNotEmpty) '$skipped saved as proof only.',
      if (warning != null) warning.reviewMessage,
      if (skippedSourceWarning.isNotEmpty) skippedSourceWarning,
      if (warning != null && warning.reviewInstruction.isNotEmpty)
        warning.reviewInstruction,
    ];
    return parts.join(' ');
  }

  String _firstWarningMessageForKind(
    ReceiptOcrWarningKind kind, {
    ReceiptOcrWarning? except,
  }) {
    for (final warning in structuredWarnings) {
      if (warning.kind != kind) continue;
      if (except != null && warning.message == except.message) continue;
      return warning.message;
    }
    return '';
  }

  ReceiptProcessingSnapshot get processingSnapshot {
    return ReceiptProcessingSnapshot(
      source: source,
      stage: hasText
          ? ReceiptProcessingStage.textExtracted
          : ReceiptProcessingStage.noSource,
      destination: ReceiptSaveDestination.undecided,
      needsReview: true,
      warningCount: warnings.length,
    );
  }
}
