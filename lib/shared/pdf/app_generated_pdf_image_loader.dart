import 'dart:typed_data';

import 'app_generated_pdf_export_estimator.dart';

typedef AppGeneratedPdfImageLoader =
    Future<Uint8List?> Function({
      required String attachmentId,
      required AppGeneratedPdfExportMode mode,
    });
