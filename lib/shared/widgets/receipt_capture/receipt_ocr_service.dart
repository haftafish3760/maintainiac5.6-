import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';

import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';

class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.rawText,
    required this.parserText,
    required this.textByAttachmentId,
    this.warnings = const [],
  });

  final String rawText;
  final String parserText;
  final Map<String, String> textByAttachmentId;
  final List<String> warnings;

  bool get hasText => rawText.trim().isNotEmpty;
  String get appFillText => parserText.trim().isEmpty ? rawText : parserText;
}

class ReceiptOcrService {
  const ReceiptOcrService({
    this.maxPdfOcrPages = ReceiptPdfInspector.localAssistedReadPageLimit,
    this.pdfPageReadTimeout = const Duration(seconds: 12),
  });

  final int maxPdfOcrPages;
  final Duration pdfPageReadTimeout;

  Future<ReceiptOcrResult> recognizeTextFromAttachments(
    List<ReceiptAttachmentRecord> attachments,
  ) async {
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
    final pdfAttachments = attachments
        .where((attachment) => attachment.isPdf && attachment.path.isNotEmpty)
        .toList(growable: false);
    final pdfPreflight = await _pdfPreflight(pdfAttachments);

    final needsImageOcr =
        photoAttachments.isNotEmpty || pdfAttachments.isNotEmpty;
    if (!needsImageOcr) {
      final textByAttachment = {...importedTextByAttachment};
      final warnings = <String>[
        if (textByAttachment.isEmpty && pdfAttachments.isEmpty)
          'Attach at least one receipt photo, PDF, or pasted receipt text before scanning.',
        ...pdfPreflight.messages,
      ];
      final combined = _combinedReceiptText(textByAttachment.values);
      return ReceiptOcrResult(
        rawText: combined.rawText,
        parserText: combined.parserText,
        textByAttachmentId: Map.unmodifiable(textByAttachment),
        warnings: List.unmodifiable([...warnings, ...combined.warnings]),
      );
    }
    if (photoAttachments.isEmpty &&
        pdfAttachments.isNotEmpty &&
        pdfPreflight.blockedAttachmentIds.length == pdfAttachments.length) {
      final textByAttachment = {...importedTextByAttachment};
      final combined = _combinedReceiptText(textByAttachment.values);
      return ReceiptOcrResult(
        rawText: combined.rawText,
        parserText: combined.parserText,
        textByAttachmentId: Map.unmodifiable(textByAttachment),
        warnings: List.unmodifiable([
          ...pdfPreflight.messages,
          ...combined.warnings,
        ]),
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final textByAttachment = <String, String>{...importedTextByAttachment};
    final warnings = <String>[...pdfPreflight.messages];
    try {
      for (final attachment in photoAttachments) {
        try {
          final image = InputImage.fromFilePath(attachment.path);
          final recognized = await recognizer.processImage(image);
          final text = recognized.text.trim();
          if (text.isEmpty) {
            warnings.add('No text was found in one receipt photo.');
          } else {
            textByAttachment[attachment.id] = text;
          }
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
      for (final attachment in pdfAttachments) {
        if (pdfPreflight.blockedAttachmentIds.contains(attachment.id)) {
          continue;
        }
        String text;
        try {
          text = await _recognizeTextFromPdfPages(attachment, recognizer);
        } on MissingPluginException {
          warnings.add('PDF receipt reading is not available in this build.');
          continue;
        } on PlatformException catch (error) {
          final message = error.message?.trim();
          warnings.add(
            message == null || message.isEmpty
                ? 'PDF receipt reading could not read one PDF.'
                : message,
          );
          continue;
        } catch (_) {
          warnings.add('PDF receipt reading could not read one PDF.');
          continue;
        }
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
      warnings: List.unmodifiable([...warnings, ...combined.warnings]),
    );
  }

  _CombinedReceiptText _combinedReceiptText(Iterable<String> sections) {
    final seenLines = <String>{};
    final seenProbableLines = <String>{};
    final rawSections = <String>[];
    final parserSections = <String>[];
    var suppressedDuplicateLines = 0;
    var probableOverlapLines = 0;
    for (final section in sections) {
      final rawSectionLines = <String>[];
      final parserSectionLines = <String>[];
      for (final line in section.split(RegExp(r'\r?\n'))) {
        final clean = line.trim();
        if (clean.isEmpty) continue;
        rawSectionLines.add(clean);
        final key = _receiptLineDedupeKey(clean);
        if (!seenLines.add(key)) {
          suppressedDuplicateLines += 1;
          continue;
        }
        final probableKey = _receiptLineProbableOverlapKey(clean);
        if (probableKey.length >= 5 && !seenProbableLines.add(probableKey)) {
          probableOverlapLines += 1;
        }
        parserSectionLines.add(clean);
      }
      if (rawSectionLines.isNotEmpty) {
        rawSections.add(rawSectionLines.join('\n'));
      }
      if (parserSectionLines.isNotEmpty) {
        parserSections.add(parserSectionLines.join('\n'));
      }
    }
    return _CombinedReceiptText(
      rawText: rawSections.join('\n\n').trim(),
      parserText: parserSections.join('\n\n').trim(),
      suppressedDuplicateLines: suppressedDuplicateLines,
      probableOverlapLines: probableOverlapLines,
    );
  }

  String _receiptLineDedupeKey(String line) {
    return line
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[#\-\s]+'), '')
        .trim();
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
    for (final attachment in attachments) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.assistedReadBlocker;
      if (blocker != null) {
        _addUniqueMessage(messages, blocker);
        blockedIds.add(attachment.id);
        continue;
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
    );
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
}

class _CombinedReceiptText {
  const _CombinedReceiptText({
    required this.rawText,
    required this.parserText,
    required this.suppressedDuplicateLines,
    required this.probableOverlapLines,
  });

  final String rawText;
  final String parserText;
  final int suppressedDuplicateLines;
  final int probableOverlapLines;

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
    return warnings;
  }
}

class _ReceiptPdfReadPreflight {
  const _ReceiptPdfReadPreflight({
    required this.messages,
    required this.blockedAttachmentIds,
  });

  final List<String> messages;
  final Set<String> blockedAttachmentIds;
}
