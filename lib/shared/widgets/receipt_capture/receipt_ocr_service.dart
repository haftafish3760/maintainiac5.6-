import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

import '../../receipts/receipt_processing_contract.dart';
import '../../receipts/receipt_ocr_contract.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';

export '../../receipts/receipt_ocr_contract.dart';

part 'receipt_ocr_service_models.dart';
part 'receipt_ocr_service_helpers.dart';
part 'receipt_ocr_service_text_combiner.dart';
part 'receipt_ocr_service_pdf_read.dart';

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
    final sourceHandoffSummary = ReceiptOcrSourceHandoffSummary.fromAttachments(
      attachments,
    );
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
            ? 'Receipt photo assistance is turned off for this device profile.'
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
            ? 'PDF receipt assistance is turned off for this device profile.'
            : 'Only the first $maxPdfOcrAttachments receipt PDFs opened receipt details on this device. $skippedPdfCount extra ${skippedPdfCount == 1 ? 'PDF was' : 'PDFs were'} saved as proof only.',
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
        sourceHandoffSummary: sourceHandoffSummary,
        parserLineSourceLocations: combined.parserLineSourceLocations,
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
        sourceHandoffSummary: sourceHandoffSummary,
        parserLineSourceLocations: combined.parserLineSourceLocations,
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
          warnings.add(
            'Receipt photo assistance is not available in this build.',
          );
          break;
        } on PlatformException catch (error) {
          final message = error.message?.trim();
          warnings.add(
            message == null || message.isEmpty
                ? 'Receipt photo assistance could not find text in one photo.'
                : message,
          );
        } catch (_) {
          warnings.add(
            'Receipt photo assistance could not find text in one photo.',
          );
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
          warnings.add(
            'PDF receipt assistance is not available in this build.',
          );
          pdfsSkipped += 1;
          continue;
        } on PlatformException catch (error) {
          final message = error.message?.trim();
          warnings.add(
            message == null || message.isEmpty
                ? 'PDF receipt assistance could not find text in one PDF.'
                : message,
          );
          pdfsSkipped += 1;
          continue;
        } catch (_) {
          warnings.add(
            'PDF receipt assistance could not find text in one PDF.',
          );
          pdfsSkipped += 1;
          continue;
        }
        pdfsRead += 1;
        if (text.trim().isNotEmpty) {
          textByAttachment[attachment.id] = text.trim();
        } else {
          warnings.add(
            'PDF receipt assistance could not render readable pages from this PDF.',
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
      sourceHandoffSummary: sourceHandoffSummary,
      parserLineSourceLocations: combined.parserLineSourceLocations,
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
}
