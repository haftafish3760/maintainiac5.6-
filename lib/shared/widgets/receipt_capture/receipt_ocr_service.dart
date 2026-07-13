import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

import '../../receipts/receipt_processing_contract.dart';
import '../../receipts/receipt_ocr_contract.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_attachment_duplicate_detector.dart';
import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';

export '../../receipts/receipt_ocr_contract.dart';

part 'receipt_ocr_service_models.dart';
part 'receipt_ocr_service_helpers.dart';
part 'receipt_ocr_service_text_combiner.dart';
part 'receipt_ocr_service_layout.dart';
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
    final importedTextByAttachment = <String, String>{};
    final repeatedAttachmentIds = <String>{};
    for (final attachment in attachments) {
      if (!attachment.isImportedText ||
          attachment.importedText.trim().isEmpty) {
        continue;
      }
      _appendAttachmentText(
        importedTextByAttachment,
        attachment.id,
        attachment.importedText.trim(),
        repeatedAttachmentIds,
      );
    }
    final photoAttachments = attachments
        .where(
          (attachment) =>
              attachment.isPhoto && attachment.path.trim().isNotEmpty,
        )
        .toList(growable: false);
    final duplicatePhotos = await detectDuplicateReceiptPhotos(
      photoAttachments,
    );
    final uniquePhotoAttachments = <ReceiptAttachmentRecord>[
      for (var index = 0; index < photoAttachments.length; index++)
        if (!duplicatePhotos.duplicateAttachmentIndexes.contains(index))
          photoAttachments[index],
    ];
    final readablePhotoAttachments = uniquePhotoAttachments
        .take(maxPhotoOcrAttachments)
        .toList(growable: false);
    final skippedPhotoCount =
        uniquePhotoAttachments.length - readablePhotoAttachments.length;
    final photoReadWarnings = <String>[
      ..._photoQualityWarnings(photoAttachments),
      if (duplicatePhotos.hasDuplicates)
        '${duplicatePhotos.duplicateCount} selected ${duplicatePhotos.duplicateCount == 1 ? 'photo appears' : 'photos appear'} identical to an earlier receipt photo. The first copy was read; keep or replace the duplicate before saving.',
      if (repeatedAttachmentIds.isNotEmpty) _repeatedAttachmentIdWarning,
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
          photosSkipped: skippedPhotoCount + duplicatePhotos.duplicateCount,
          duplicatePhotosSkipped: duplicatePhotos.duplicateCount,
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
          photosSkipped: skippedPhotoCount + duplicatePhotos.duplicateCount,
          duplicatePhotosSkipped: duplicatePhotos.duplicateCount,
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
    final layoutPages = <ReceiptOcrPage>[];
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
          layoutPages.add(
            _receiptOcrLayoutPageFromRecognizedText(attachment.id, recognized),
          );
          if (text.isEmpty) {
            warnings.add('No text was found in one receipt photo.');
          } else {
            _appendAttachmentText(
              textByAttachment,
              attachment.id,
              text,
              repeatedAttachmentIds,
            );
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
          _appendAttachmentText(
            textByAttachment,
            attachment.id,
            text.trim(),
            repeatedAttachmentIds,
          );
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

    if (repeatedAttachmentIds.isNotEmpty &&
        !warnings.contains(_repeatedAttachmentIdWarning)) {
      warnings.add(_repeatedAttachmentIdWarning);
    }

    final combined = _combinedReceiptText(textByAttachment.values);
    return ReceiptOcrResult(
      rawText: combined.rawText,
      parserText: combined.parserText,
      textByAttachmentId: Map.unmodifiable(textByAttachment),
      source: source,
      sourceHandoffSummary: sourceHandoffSummary,
      layout: ReceiptOcrDocument(pages: layoutPages),
      parserLineSourceLocations: combined.parserLineSourceLocations,
      stats: ReceiptOcrReadStats(
        importedTextRead: importedTextByAttachment.length,
        photosRead: photosRead,
        photosSkipped: skippedPhotoCount + duplicatePhotos.duplicateCount,
        duplicatePhotosSkipped: duplicatePhotos.duplicateCount,
        pdfsRead: pdfsRead,
        pdfsSkipped: pdfsSkipped,
        pdfPagesRequested: pdfPreflight.pagesPlannedForRead,
      ),
      warnings: List.unmodifiable([...warnings, ...combined.warnings]),
    );
  }
}

const _repeatedAttachmentIdWarning =
    'Some receipt attachments used the same identifier. Their text was kept together; review the saved proof before saving.';

void _appendAttachmentText(
  Map<String, String> textByAttachment,
  String attachmentId,
  String text,
  Set<String> repeatedAttachmentIds,
) {
  final existing = textByAttachment[attachmentId];
  if (existing == null || existing.isEmpty) {
    textByAttachment[attachmentId] = text;
    return;
  }
  repeatedAttachmentIds.add(attachmentId);
  textByAttachment[attachmentId] = '$existing\n$text';
}
