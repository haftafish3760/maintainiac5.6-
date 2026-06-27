import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

import '../../receipts/receipt_processing_contract.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';

class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.rawText,
    required this.parserText,
    required this.textByAttachmentId,
    required this.source,
    this.stats = const ReceiptOcrReadStats(),
    this.warnings = const [],
  });

  final String rawText;
  final String parserText;
  final Map<String, String> textByAttachmentId;
  final ReceiptProcessingSource source;
  final ReceiptOcrReadStats stats;
  final List<String> warnings;

  bool get hasText => rawText.trim().isNotEmpty;
  String get appFillText => parserText.trim().isEmpty ? rawText : parserText;
  ReceiptOcrDiagnostics get diagnostics =>
      ReceiptOcrDiagnostics.fromResult(this);
  List<ReceiptOcrWarning> get structuredWarnings {
    return warnings.map(ReceiptOcrWarning.fromMessage).toList(growable: false);
  }

  String reviewMessage({required String successMessage}) {
    final read = stats.readSummaryLabel;
    final skipped = stats.skippedSummaryLabel;
    if (!hasText) {
      return warnings.isEmpty
          ? 'No readable receipt text was found.'
          : warnings.first;
    }
    final parts = <String>[
      successMessage,
      if (read.isNotEmpty) 'Read $read.',
      if (skipped.isNotEmpty) '$skipped saved as proof only.',
      if (structuredWarnings.isNotEmpty)
        structuredWarnings.first.reviewMessage
      else if (warnings.isNotEmpty)
        warnings.first,
    ];
    return parts.join(' ');
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

enum ReceiptOcrReviewSeverity {
  good('Good'),
  review('Review'),
  partial('Partial'),
  blocked('Blocked');

  const ReceiptOcrReviewSeverity(this.label);

  final String label;
}

enum ReceiptOcrWarningKind {
  noSource,
  noReadableText,
  sourceSkipped,
  duplicateText,
  probableOverlap,
  sectionGap,
  pdfSafety,
  pdfTooLarge,
  pdfUnreadable,
  pluginUnavailable,
  photoQuality,
  photoReadFailure,
  pdfReadFailure,
  unknown,
}

class ReceiptOcrWarning {
  const ReceiptOcrWarning({
    required this.kind,
    required this.severity,
    required this.message,
  });

  factory ReceiptOcrWarning.fromMessage(String message) {
    final clean = message.trim();
    final lower = clean.toLowerCase();
    final kind = _kindFor(lower);
    return ReceiptOcrWarning(
      kind: kind,
      severity: _severityFor(kind, lower),
      message: clean,
    );
  }

  final ReceiptOcrWarningKind kind;
  final ReceiptOcrReviewSeverity severity;
  final String message;

  bool get isBlocking => severity == ReceiptOcrReviewSeverity.blocked;
  bool get isPartial => severity == ReceiptOcrReviewSeverity.partial;
  bool get needsReview => severity == ReceiptOcrReviewSeverity.review;

  String get label {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource => 'No receipt attached',
      ReceiptOcrWarningKind.noReadableText => 'No readable text',
      ReceiptOcrWarningKind.sourceSkipped =>
        isBlocking ? 'Receipt reading off' : 'Receipt source skipped',
      ReceiptOcrWarningKind.duplicateText => 'Duplicate lines ignored',
      ReceiptOcrWarningKind.probableOverlap => 'Possible receipt overlap',
      ReceiptOcrWarningKind.sectionGap => 'Possible missing receipt section',
      ReceiptOcrWarningKind.pdfSafety => 'PDF safety warning',
      ReceiptOcrWarningKind.pdfTooLarge => 'PDF too large',
      ReceiptOcrWarningKind.pdfUnreadable => 'PDF unreadable',
      ReceiptOcrWarningKind.pluginUnavailable => 'OCR unavailable',
      ReceiptOcrWarningKind.photoQuality => 'Photo quality warning',
      ReceiptOcrWarningKind.photoReadFailure => 'Photo read failed',
      ReceiptOcrWarningKind.pdfReadFailure => 'PDF read failed',
      ReceiptOcrWarningKind.unknown => 'OCR warning',
    };
  }

  String get actionLabel {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource =>
        'Attach a receipt photo, PDF, or pasted text.',
      ReceiptOcrWarningKind.noReadableText =>
        'Retake the photo, attach another page, or enter the receipt manually.',
      ReceiptOcrWarningKind.sourceSkipped =>
        isBlocking
            ? 'Turn on receipt reading or enter the receipt manually.'
            : 'Review the saved proof if any line is missing.',
      ReceiptOcrWarningKind.duplicateText =>
        'Check the removed overlap before saving.',
      ReceiptOcrWarningKind.probableOverlap =>
        'Review nearby line items for duplicate or missing charges.',
      ReceiptOcrWarningKind.sectionGap =>
        'Check the receipt photos for a skipped middle section.',
      ReceiptOcrWarningKind.pdfSafety =>
        'Use the PDF as proof only or attach a safe copy.',
      ReceiptOcrWarningKind.pdfTooLarge =>
        'Attach a smaller PDF or scan the receipt with photos.',
      ReceiptOcrWarningKind.pdfUnreadable =>
        'Attach a valid PDF, photo, or pasted receipt text.',
      ReceiptOcrWarningKind.pluginUnavailable =>
        'Enter the receipt manually in this build.',
      ReceiptOcrWarningKind.photoQuality =>
        'Review the receipt photo or retake it before trusting the parsed lines.',
      ReceiptOcrWarningKind.photoReadFailure =>
        'Retake the photo or enter the receipt manually.',
      ReceiptOcrWarningKind.pdfReadFailure =>
        'Attach a clearer PDF/photo or enter the receipt manually.',
      ReceiptOcrWarningKind.unknown => 'Review this receipt before saving.',
    };
  }

  String get reviewMessage => '$label. $actionLabel';

  static ReceiptOcrWarningKind _kindFor(String lower) {
    if (lower.contains('attach at least one receipt')) {
      return ReceiptOcrWarningKind.noSource;
    }
    if (lower.contains('no readable receipt text') ||
        lower.contains('no text was found') ||
        lower.contains('could not render readable pages')) {
      return ReceiptOcrWarningKind.noReadableText;
    }
    if (lower.contains('saved as proof only') ||
        lower.contains('reading is turned off') ||
        lower.contains('only the first')) {
      return ReceiptOcrWarningKind.sourceSkipped;
    }
    if (lower.contains('no repeated receipt text between sections') ||
        lower.contains('possible missing receipt section')) {
      return ReceiptOcrWarningKind.sectionGap;
    }
    if (lower.contains('repeated receipt')) {
      return ReceiptOcrWarningKind.duplicateText;
    }
    if (lower.contains('overlapping receipt')) {
      return ReceiptOcrWarningKind.probableOverlap;
    }
    if (lower.contains('encrypted') ||
        lower.contains('protected') ||
        lower.contains('active content') ||
        lower.contains('scripts') ||
        lower.contains('embedded javascript')) {
      return ReceiptOcrWarningKind.pdfSafety;
    }
    if (lower.contains('too large') || lower.contains('smaller file')) {
      return ReceiptOcrWarningKind.pdfTooLarge;
    }
    if (lower.contains('could not be found') ||
        lower.contains('valid pdf') ||
        lower.contains('empty pdf') ||
        lower.contains('cannot be read safely')) {
      return ReceiptOcrWarningKind.pdfUnreadable;
    }
    if (lower.contains('not available in this build') ||
        lower.contains('missingplugin')) {
      return ReceiptOcrWarningKind.pluginUnavailable;
    }
    if (lower.contains('receipt photo quality needs review')) {
      return ReceiptOcrWarningKind.photoQuality;
    }
    if (lower.contains('receipt photo reading could not read')) {
      return ReceiptOcrWarningKind.photoReadFailure;
    }
    if (lower.contains('pdf receipt reading could not read')) {
      return ReceiptOcrWarningKind.pdfReadFailure;
    }
    return ReceiptOcrWarningKind.unknown;
  }

  static ReceiptOcrReviewSeverity _severityFor(
    ReceiptOcrWarningKind kind,
    String lower,
  ) {
    return switch (kind) {
      ReceiptOcrWarningKind.noSource ||
      ReceiptOcrWarningKind.noReadableText ||
      ReceiptOcrWarningKind.pdfSafety ||
      ReceiptOcrWarningKind.pdfTooLarge ||
      ReceiptOcrWarningKind.pdfUnreadable ||
      ReceiptOcrWarningKind.pluginUnavailable ||
      ReceiptOcrWarningKind.photoReadFailure ||
      ReceiptOcrWarningKind.pdfReadFailure => ReceiptOcrReviewSeverity.blocked,
      ReceiptOcrWarningKind.photoQuality => ReceiptOcrReviewSeverity.review,
      ReceiptOcrWarningKind.sourceSkipped =>
        lower.contains('turned off')
            ? ReceiptOcrReviewSeverity.blocked
            : ReceiptOcrReviewSeverity.partial,
      ReceiptOcrWarningKind.duplicateText ||
      ReceiptOcrWarningKind.sectionGap ||
      ReceiptOcrWarningKind.probableOverlap ||
      ReceiptOcrWarningKind.unknown => ReceiptOcrReviewSeverity.review,
    };
  }
}

class ReceiptOcrDiagnostics {
  const ReceiptOcrDiagnostics({
    required this.severity,
    required this.source,
    required this.attachmentsRead,
    required this.attachmentsSkipped,
    required this.rawLineCount,
    required this.parserLineCount,
    required this.warningCount,
    required this.usedLocalOcr,
    required this.hasText,
    required this.hadDuplicateOrOverlapText,
    required this.pdfPagesRequested,
    required this.blockingWarningCount,
    required this.partialWarningCount,
    required this.reviewWarningCount,
    required this.warningKindCounts,
  });

  factory ReceiptOcrDiagnostics.fromResult(ReceiptOcrResult result) {
    final rawLineCount = _countReceiptTextLines(result.rawText);
    final parserLineCount = _countReceiptTextLines(result.parserText);
    final structuredWarnings = result.structuredWarnings;
    final duplicateOrOverlap = structuredWarnings.any(
      (warning) =>
          warning.kind == ReceiptOcrWarningKind.duplicateText ||
          warning.kind == ReceiptOcrWarningKind.probableOverlap ||
          warning.kind == ReceiptOcrWarningKind.sectionGap,
    );
    final severity = _severityFor(
      hasText: result.hasText,
      warnings: structuredWarnings,
      stats: result.stats,
      duplicateOrOverlap: duplicateOrOverlap,
    );
    return ReceiptOcrDiagnostics(
      severity: severity,
      source: result.source,
      attachmentsRead: result.stats.attachmentsRead,
      attachmentsSkipped: result.stats.attachmentsSkipped,
      rawLineCount: rawLineCount,
      parserLineCount: parserLineCount,
      warningCount: result.warnings.length,
      usedLocalOcr: result.stats.usedLocalOcr,
      hasText: result.hasText,
      hadDuplicateOrOverlapText: duplicateOrOverlap,
      pdfPagesRequested: result.stats.pdfPagesRequested,
      blockingWarningCount: structuredWarnings
          .where((warning) => warning.isBlocking)
          .length,
      partialWarningCount: structuredWarnings
          .where((warning) => warning.isPartial)
          .length,
      reviewWarningCount: structuredWarnings
          .where((warning) => warning.needsReview)
          .length,
      warningKindCounts: Map.unmodifiable(
        _warningKindCounts(structuredWarnings),
      ),
    );
  }

  final ReceiptOcrReviewSeverity severity;
  final ReceiptProcessingSource source;
  final int attachmentsRead;
  final int attachmentsSkipped;
  final int rawLineCount;
  final int parserLineCount;
  final int warningCount;
  final bool usedLocalOcr;
  final bool hasText;
  final bool hadDuplicateOrOverlapText;
  final int pdfPagesRequested;
  final int blockingWarningCount;
  final int partialWarningCount;
  final int reviewWarningCount;
  final Map<ReceiptOcrWarningKind, int> warningKindCounts;

  bool get hasBlockingWarnings => blockingWarningCount > 0;
  bool get hasPartialWarnings => partialWarningCount > 0;
  bool get hasReviewWarnings => reviewWarningCount > 0;

  int countForWarningKind(ReceiptOcrWarningKind kind) {
    return warningKindCounts[kind] ?? 0;
  }

  String get sourceLabel {
    return switch (source) {
      ReceiptProcessingSource.none => 'No receipt source',
      ReceiptProcessingSource.photo => 'Receipt photo',
      ReceiptProcessingSource.pdf => 'Receipt PDF',
      ReceiptProcessingSource.importedText => 'Imported text',
      ReceiptProcessingSource.mixed => 'Mixed receipt sources',
    };
  }

  String get readSummaryLabel {
    if (attachmentsRead == 0 && attachmentsSkipped == 0) {
      return 'Nothing read';
    }
    final read = attachmentsRead == 1
        ? '1 source read'
        : '$attachmentsRead sources read';
    if (attachmentsSkipped == 0) return read;
    final skipped = attachmentsSkipped == 1
        ? '1 saved as proof only'
        : '$attachmentsSkipped saved as proof only';
    return '$read, $skipped';
  }

  String get textSummaryLabel {
    if (!hasText) return 'No readable text';
    final readyLineCount = parserLineCount > 0 ? parserLineCount : rawLineCount;
    if (readyLineCount <= 0) return 'No readable text';
    final lineLabel = readyLineCount == 1 ? 'line' : 'lines';
    if (rawLineCount == parserLineCount || rawLineCount <= readyLineCount) {
      return '$readyLineCount receipt $lineLabel ready for review';
    }
    return '$readyLineCount receipt $lineLabel ready for review; repeated text was ignored';
  }

  String get warningSummaryLabel {
    if (warningCount == 0) return 'No OCR warnings';
    final parts = <String>[
      if (blockingWarningCount > 0) '$blockingWarningCount blocked',
      if (partialWarningCount > 0) '$partialWarningCount partial',
      if (reviewWarningCount > 0) '$reviewWarningCount review',
    ];
    if (parts.isEmpty) {
      return '$warningCount OCR ${warningCount == 1 ? 'warning' : 'warnings'}';
    }
    return '${parts.join(', ')} OCR ${warningCount == 1 ? 'warning' : 'warnings'}';
  }

  String get pdfWorkLabel {
    if (pdfPagesRequested <= 0) return 'No PDF pages requested';
    return '$pdfPagesRequested PDF ${pdfPagesRequested == 1 ? 'page' : 'pages'} requested';
  }

  String get reviewSummaryLabel {
    return '${severity.label}: $readSummaryLabel. $textSummaryLabel. $warningSummaryLabel.';
  }

  static int _countReceiptTextLines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .length;
  }

  static Map<ReceiptOcrWarningKind, int> _warningKindCounts(
    List<ReceiptOcrWarning> warnings,
  ) {
    final counts = <ReceiptOcrWarningKind, int>{};
    for (final warning in warnings) {
      counts.update(warning.kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static ReceiptOcrReviewSeverity _severityFor({
    required bool hasText,
    required List<ReceiptOcrWarning> warnings,
    required ReceiptOcrReadStats stats,
    required bool duplicateOrOverlap,
  }) {
    if (!hasText) return ReceiptOcrReviewSeverity.blocked;
    if (warnings.any((warning) => warning.isBlocking)) {
      return ReceiptOcrReviewSeverity.review;
    }
    if (stats.hadSkippedWork) return ReceiptOcrReviewSeverity.partial;
    if (duplicateOrOverlap || warnings.isNotEmpty) {
      return ReceiptOcrReviewSeverity.review;
    }
    return ReceiptOcrReviewSeverity.good;
  }
}

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

class ReceiptOcrService {
  const ReceiptOcrService({
    this.maxPdfOcrPages = ReceiptPdfInspector.localAssistedReadPageLimit,
    this.pdfPageReadTimeout = const Duration(seconds: 12),
    this.maxPhotoOcrAttachments = 8,
    this.maxPdfOcrAttachments = 2,
  }) : assert(maxPdfOcrPages >= 0),
       assert(maxPhotoOcrAttachments >= 0),
       assert(maxPdfOcrAttachments >= 0);

  factory ReceiptOcrService.forDevice(ReceiptDeviceCapability capability) {
    final pdfAttachmentLimit = switch (capability.tier) {
      ReceiptCapabilityTier.light => 1,
      ReceiptCapabilityTier.medium => 2,
      ReceiptCapabilityTier.heavyweight => 3,
    };
    final timeout = switch (capability.tier) {
      ReceiptCapabilityTier.light => const Duration(seconds: 8),
      ReceiptCapabilityTier.medium => const Duration(seconds: 12),
      ReceiptCapabilityTier.heavyweight => const Duration(seconds: 16),
    };
    return ReceiptOcrService(
      maxPdfOcrPages: capability.maxLocalPdfPages,
      pdfPageReadTimeout: timeout,
      maxPhotoOcrAttachments: capability.maxLocalPhotoCount,
      maxPdfOcrAttachments: pdfAttachmentLimit,
    );
  }

  final int maxPdfOcrPages;
  final Duration pdfPageReadTimeout;
  final int maxPhotoOcrAttachments;
  final int maxPdfOcrAttachments;

  Future<ReceiptOcrResult> recognizeTextFromAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) async {
    final source = _sourceFor(attachments);
    final importedTextByAttachment = <String, String>{
      for (final attachment in attachments)
        if (attachment.isImportedText &&
            attachment.importedText.trim().isNotEmpty)
          attachment.id: attachment.importedText.trim(),
    };
    final photoAttachments = attachments
        .where(
          (attachment) =>
              attachment.isPhoto && attachment.path.trim().isNotEmpty,
        )
        .toList(growable: false);
    final readablePhotoAttachments = photoAttachments
        .take(maxPhotoOcrAttachments)
        .toList(growable: false);
    final skippedPhotoCount =
        photoAttachments.length - readablePhotoAttachments.length;
    final photoReadWarnings = <String>[
      ..._photoQualityWarnings(photoAttachments),
      if (skippedPhotoCount > 0)
        maxPhotoOcrAttachments == 0
            ? 'Receipt photo reading is turned off for this device profile.'
            : 'Only the first $maxPhotoOcrAttachments receipt photos were read on this device. $skippedPhotoCount extra ${skippedPhotoCount == 1 ? 'photo was' : 'photos were'} saved as proof only.',
    ];
    final pdfAttachments = attachments
        .where((attachment) => attachment.isPdf && attachment.path.isNotEmpty)
        .toList(growable: false);
    final readablePdfAttachments = pdfAttachments
        .take(maxPdfOcrAttachments)
        .toList(growable: false);
    final skippedPdfCount =
        pdfAttachments.length - readablePdfAttachments.length;
    final pdfReadWarnings = <String>[
      if (skippedPdfCount > 0)
        maxPdfOcrAttachments == 0
            ? 'PDF receipt reading is turned off for this device profile.'
            : 'Only the first $maxPdfOcrAttachments receipt PDFs were read on this device. $skippedPdfCount extra ${skippedPdfCount == 1 ? 'PDF was' : 'PDFs were'} saved as proof only.',
    ];
    final pdfPreflight = await _pdfPreflight(readablePdfAttachments);

    final needsImageOcr =
        readablePhotoAttachments.isNotEmpty ||
        readablePdfAttachments.isNotEmpty;
    if (!needsImageOcr) {
      final textByAttachment = {...importedTextByAttachment};
      final warnings = <String>[
        if (textByAttachment.isEmpty &&
            pdfAttachments.isEmpty &&
            photoAttachments.isEmpty)
          'Attach at least one receipt photo, PDF, or pasted receipt text before scanning.',
        ...photoReadWarnings,
        ...pdfReadWarnings,
        ...pdfPreflight.messages,
      ];
      final combined = _combinedReceiptText(textByAttachment.values);
      return ReceiptOcrResult(
        rawText: combined.rawText,
        parserText: combined.parserText,
        textByAttachmentId: Map.unmodifiable(textByAttachment),
        source: source,
        stats: ReceiptOcrReadStats(
          importedTextRead: importedTextByAttachment.length,
          photosSkipped: skippedPhotoCount,
          pdfsSkipped: skippedPdfCount,
          pdfPagesRequested: pdfPreflight.pagesPlannedForRead,
        ),
        warnings: List.unmodifiable([...warnings, ...combined.warnings]),
      );
    }
    if (photoAttachments.isEmpty &&
        readablePdfAttachments.isNotEmpty &&
        pdfPreflight.blockedAttachmentIds.length ==
            readablePdfAttachments.length) {
      final textByAttachment = {...importedTextByAttachment};
      final combined = _combinedReceiptText(textByAttachment.values);
      return ReceiptOcrResult(
        rawText: combined.rawText,
        parserText: combined.parserText,
        textByAttachmentId: Map.unmodifiable(textByAttachment),
        source: source,
        stats: ReceiptOcrReadStats(
          importedTextRead: importedTextByAttachment.length,
          photosSkipped: skippedPhotoCount,
          pdfsSkipped:
              skippedPdfCount + pdfPreflight.blockedAttachmentIds.length,
          pdfPagesRequested: pdfPreflight.pagesPlannedForRead,
        ),
        warnings: List.unmodifiable([
          ...pdfReadWarnings,
          ...pdfPreflight.messages,
          ...combined.warnings,
        ]),
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final textByAttachment = <String, String>{...importedTextByAttachment};
    final warnings = <String>[
      ...photoReadWarnings,
      ...pdfReadWarnings,
      ...pdfPreflight.messages,
    ];
    var photosRead = 0;
    var pdfsRead = 0;
    var pdfsSkipped =
        skippedPdfCount + pdfPreflight.blockedAttachmentIds.length;
    try {
      for (final attachment in readablePhotoAttachments) {
        try {
          final image = InputImage.fromFilePath(attachment.path);
          final recognized = await recognizer.processImage(image);
          final text = recognized.text.trim();
          if (text.isEmpty) {
            warnings.add('No text was found in one receipt photo.');
          } else {
            textByAttachment[attachment.id] = text;
          }
          photosRead += 1;
        } on MissingPluginException {
          warnings.add('Receipt photo reading is not available in this build.');
          break;
        } on PlatformException catch (error) {
          final message = error.message?.trim();
          warnings.add(
            message == null || message.isEmpty
                ? 'Receipt photo reading could not read one photo.'
                : message,
          );
        } catch (_) {
          warnings.add('Receipt photo reading could not read one photo.');
        }
      }
      for (final attachment in readablePdfAttachments) {
        if (pdfPreflight.blockedAttachmentIds.contains(attachment.id)) {
          continue;
        }
        String text;
        try {
          text = await _recognizeTextFromPdfPages(attachment, recognizer);
        } on MissingPluginException {
          warnings.add('PDF receipt reading is not available in this build.');
          pdfsSkipped += 1;
          continue;
        } on PlatformException catch (error) {
          final message = error.message?.trim();
          warnings.add(
            message == null || message.isEmpty
                ? 'PDF receipt reading could not read one PDF.'
                : message,
          );
          pdfsSkipped += 1;
          continue;
        } catch (_) {
          warnings.add('PDF receipt reading could not read one PDF.');
          pdfsSkipped += 1;
          continue;
        }
        pdfsRead += 1;
        if (text.trim().isNotEmpty) {
          textByAttachment[attachment.id] = text.trim();
        } else {
          warnings.add(
            'PDF receipt reading could not render readable pages from this PDF.',
          );
        }
      }
    } finally {
      try {
        await recognizer.close();
      } catch (_) {}
    }

    final combined = _combinedReceiptText(textByAttachment.values);
    return ReceiptOcrResult(
      rawText: combined.rawText,
      parserText: combined.parserText,
      textByAttachmentId: Map.unmodifiable(textByAttachment),
      source: source,
      stats: ReceiptOcrReadStats(
        importedTextRead: importedTextByAttachment.length,
        photosRead: photosRead,
        photosSkipped: skippedPhotoCount,
        pdfsRead: pdfsRead,
        pdfsSkipped: pdfsSkipped,
        pdfPagesRequested: pdfPreflight.pagesPlannedForRead,
      ),
      warnings: List.unmodifiable([...warnings, ...combined.warnings]),
    );
  }

  ReceiptProcessingSource _sourceFor(
    List<ReceiptAttachmentRecord> attachments,
  ) {
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

  _CombinedReceiptText _combinedReceiptText(Iterable<String> sections) {
    final rawSections = <String>[];
    final parserSections = <String>[];
    var previousExactTail = const <String>[];
    var previousProbableTail = const <String>[];
    var suppressedDuplicateLines = 0;
    var probableOverlapLines = 0;
    var possibleSectionGaps = 0;
    var sectionIndex = 0;
    for (final section in sections) {
      final rawSectionLines = section
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      if (rawSectionLines.isEmpty) continue;
      final parserSectionLines = <String>[];
      var stillInOverlapHeader = true;
      var foundBoundarySignal = sectionIndex == 0;
      final previousExactTailSet = previousExactTail.toSet();
      final previousProbableTailSet = previousProbableTail.toSet();
      for (final clean in rawSectionLines) {
        final key = _receiptLineDedupeKey(clean);
        final probableKey = _receiptLineProbableOverlapKey(clean);
        if (stillInOverlapHeader &&
            key.isNotEmpty &&
            previousExactTailSet.contains(key)) {
          suppressedDuplicateLines += 1;
          foundBoundarySignal = true;
          continue;
        }
        if (stillInOverlapHeader &&
            probableKey.length >= 5 &&
            previousProbableTailSet.contains(probableKey)) {
          probableOverlapLines += 1;
          foundBoundarySignal = true;
        }
        stillInOverlapHeader = false;
        parserSectionLines.add(clean);
      }
      if (!foundBoundarySignal && previousExactTail.isNotEmpty) {
        possibleSectionGaps += 1;
      }
      rawSections.add(rawSectionLines.join('\n'));
      if (parserSectionLines.isNotEmpty) {
        parserSections.add(parserSectionLines.join('\n'));
      }
      previousExactTail = rawSectionLines
          .map(_receiptLineDedupeKey)
          .where((key) => key.isNotEmpty)
          .toList(growable: false)
          .reversed
          .take(8)
          .toList(growable: false);
      previousProbableTail = rawSectionLines
          .map(_receiptLineProbableOverlapKey)
          .where((key) => key.length >= 5)
          .toList(growable: false)
          .reversed
          .take(8)
          .toList(growable: false);
      sectionIndex += 1;
    }
    return _CombinedReceiptText(
      rawText: rawSections.join('\n\n').trim(),
      parserText: parserSections.join('\n\n').trim(),
      suppressedDuplicateLines: suppressedDuplicateLines,
      probableOverlapLines: probableOverlapLines,
      possibleSectionGaps: possibleSectionGaps,
    );
  }

  String _receiptLineDedupeKey(String line) {
    var key = line
        .toUpperCase()
        .replaceAll(RegExp(r'(?<=\d)O(?=\d)'), '0')
        .replaceAll(RegExp(r'\bO(?=\d)'), '0')
        .replaceAll(RegExp(r'(?<=\d)O\b'), '0')
        .replaceAll(RegExp(r'^[#\-\s]+'), '')
        .replaceAll(RegExp(r'\$'), '')
        .replaceAll(RegExp(r'(?<=\d)[.,](?=\d{2}\b)'), '')
        .replaceAll(RegExp(r'(?<=\d)\s+(?=\d{2}(?:[A-Z])?$)'), '')
        .replaceAll(RegExp(r'(?<=\d)[A-Z]$'), '')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (key.startsWith('LINE ')) {
      key = key.replaceFirst(RegExp(r'^LINE \d+ '), '');
    }
    return key;
  }

  String _receiptLineProbableOverlapKey(String line) {
    return _receiptLineDedupeKey(
      line,
    ).replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceAll(RegExp(r'\d+$'), '');
  }

  Future<_ReceiptPdfReadPreflight> _pdfPreflight(
    List<ReceiptAttachmentRecord> attachments,
  ) async {
    final messages = <String>[];
    final blockedIds = <String>{};
    var pagesPlannedForRead = 0;
    for (final attachment in attachments) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.assistedReadBlocker;
      if (blocker != null) {
        _addUniqueMessage(messages, blocker);
        blockedIds.add(attachment.id);
        continue;
      }
      pagesPlannedForRead += _plannedPdfPagesForRead(inspection);
      final deviceLimitWarning = _devicePdfReadLimitWarning(inspection);
      if (deviceLimitWarning != null) {
        _addUniqueMessage(messages, deviceLimitWarning);
      }
      final warning =
          inspection.userWarning ??
          inspection.documentFitWarning ??
          inspection.longReceiptWarning;
      if (warning != null) {
        _addUniqueMessage(messages, warning);
      }
    }
    return _ReceiptPdfReadPreflight(
      messages: List.unmodifiable(messages),
      blockedAttachmentIds: Set.unmodifiable(blockedIds),
      pagesPlannedForRead: pagesPlannedForRead,
    );
  }

  int _plannedPdfPagesForRead(ReceiptPdfInspection inspection) {
    if (maxPdfOcrPages <= 0) return 0;
    final pages = inspection.pageCount;
    if (pages == null || pages <= 0) return maxPdfOcrPages;
    return pages.clamp(0, maxPdfOcrPages);
  }

  String? _devicePdfReadLimitWarning(ReceiptPdfInspection inspection) {
    if (maxPdfOcrPages <= 0) return null;
    final pages = inspection.pageCount;
    if (pages == null || pages <= maxPdfOcrPages) return null;
    return 'Only the first $maxPdfOcrPages pages of this PDF will be read on this device. The full PDF stays saved as read-only proof.';
  }

  Future<String> _recognizeTextFromPdfPages(
    ReceiptAttachmentRecord attachment,
    TextRecognizer recognizer,
  ) async {
    if (maxPdfOcrPages <= 0) return '';
    final bytes = await File(attachment.path).readAsBytes();
    final tempDir = await Directory.systemTemp.createTemp(
      'maintaniac_pdf_read_',
    );
    final pageTexts = <String>[];
    var pageIndex = 0;
    try {
      await for (final page in Printing.raster(
        bytes,
        dpi: 160,
      ).timeout(pdfPageReadTimeout)) {
        if (pageIndex >= maxPdfOcrPages) break;
        final png = await page.toPng();
        final imageFile = File('${tempDir.path}/page_$pageIndex.png');
        await imageFile.writeAsBytes(png, flush: true);
        final image = InputImage.fromFilePath(imageFile.path);
        final recognized = await recognizer.processImage(image);
        final text = recognized.text.trim();
        if (text.isNotEmpty) pageTexts.add(text);
        pageIndex += 1;
      }
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    } catch (error) {
      if (error.toString().contains('MissingPluginException')) rethrow;
      return '';
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
    return pageTexts.join('\n\n').trim();
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
      if (!attachment.photoQualityNeedsReview) continue;
      final label = attachment.photoQualityLabel.trim().isEmpty
          ? 'Photo quality needs review'
          : attachment.photoQualityLabel;
      final issues = attachment.photoQualityWarnings.take(2).join(' ');
      warnings.add(
        'Receipt photo quality needs review for section ${index + 1}: $label.${issues.isEmpty ? '' : ' $issues'}',
      );
    }
    return warnings;
  }
}

class _CombinedReceiptText {
  const _CombinedReceiptText({
    required this.rawText,
    required this.parserText,
    required this.suppressedDuplicateLines,
    required this.probableOverlapLines,
    required this.possibleSectionGaps,
  });

  final String rawText;
  final String parserText;
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
