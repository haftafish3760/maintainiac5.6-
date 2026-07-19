import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'app_generated_pdf_export_estimator.dart';
import 'app_generated_pdf_image_loader.dart';

class AppGeneratedPdfReceiptImageReference {
  const AppGeneratedPdfReceiptImageReference({
    required this.attachmentId,
    required this.label,
  });

  final String attachmentId;
  final String label;
}

class AppGeneratedPdfReceiptSections {
  const AppGeneratedPdfReceiptSections._();

  static Future<List<pw.Widget>> build({
    required Iterable<AppGeneratedPdfReceiptImageReference> references,
    required AppGeneratedPdfExportMode mode,
    required AppGeneratedPdfImageResolver? imageResolver,
    required bool allowFullImageDownload,
  }) async {
    if (mode == AppGeneratedPdfExportMode.textOnly) return const [];
    final resolver = imageResolver;
    if (resolver == null) {
      throw const AppGeneratedPdfReceiptSectionException(
        'receipt_image_source_required',
      );
    }

    final sections = <pw.Widget>[];
    for (final reference in references) {
      try {
        final bytes = await resolver.resolve(
          attachmentId: reference.attachmentId,
          mode: mode,
          allowFullImageDownload: allowFullImageDownload,
        );
        sections.add(_image(reference.label, bytes, mode));
      } on AppGeneratedPdfImageResolutionException catch (error) {
        if (error.reasonCode ==
            'full_image_download_requires_explicit_selection') {
          rethrow;
        }
        sections.add(_unavailable(reference.label));
      } catch (_) {
        sections.add(_unavailable(reference.label));
      }
    }
    return sections;
  }

  static pw.Widget _image(
    String label,
    Uint8List bytes,
    AppGeneratedPdfExportMode mode,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label),
          pw.SizedBox(height: 4),
          pw.Image(
            pw.MemoryImage(bytes),
            height: mode == AppGeneratedPdfExportMode.thumbnails ? 120 : 420,
            fit: pw.BoxFit.contain,
          ),
        ],
      ),
    );
  }

  static pw.Widget _unavailable(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label),
            pw.SizedBox(height: 3),
            pw.Text(
              'Receipt image was unavailable. The receipt details remain in this export.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class AppGeneratedPdfReceiptSectionException implements Exception {
  const AppGeneratedPdfReceiptSectionException(this.reasonCode);

  final String reasonCode;
}
