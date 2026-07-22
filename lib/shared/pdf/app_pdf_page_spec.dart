import 'package:pdf/pdf.dart';

enum AppPdfPageOrientation { portrait, landscape }

enum AppPdfPaperSize { letter, legal, a4 }

class AppPdfPageSpec {
  const AppPdfPageSpec({required this.paperSize, required this.orientation});

  static const letterPortrait = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.letter,
    orientation: AppPdfPageOrientation.portrait,
  );

  static const letterLandscape = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.letter,
    orientation: AppPdfPageOrientation.landscape,
  );

  static const legalPortrait = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.legal,
    orientation: AppPdfPageOrientation.portrait,
  );

  static const legalLandscape = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.legal,
    orientation: AppPdfPageOrientation.landscape,
  );

  static const a4Portrait = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.a4,
    orientation: AppPdfPageOrientation.portrait,
  );

  static const a4Landscape = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.a4,
    orientation: AppPdfPageOrientation.landscape,
  );

  static const all = <AppPdfPageSpec>[
    letterPortrait,
    letterLandscape,
    legalPortrait,
    legalLandscape,
    a4Portrait,
    a4Landscape,
  ];

  final AppPdfPaperSize paperSize;
  final AppPdfPageOrientation orientation;

  bool get isLandscape => orientation == AppPdfPageOrientation.landscape;

  bool get isPortrait => orientation == AppPdfPageOrientation.portrait;

  PdfPageFormat get format {
    final base = switch (paperSize) {
      AppPdfPaperSize.letter => PdfPageFormat.letter,
      AppPdfPaperSize.legal => PdfPageFormat.legal,
      AppPdfPaperSize.a4 => PdfPageFormat.a4,
    };
    return isLandscape ? base.landscape : base.portrait;
  }

  double get width => format.width;

  double get height => format.height;

  String get key => '${paperSize.name}_${orientation.name}';

  static AppPdfPageSpec fromKey(String key) {
    final normalized = key.trim().toLowerCase();
    for (final spec in all) {
      if (spec.key == normalized) return spec;
    }
    return letterPortrait;
  }

  AppPdfPageSpec rotated() {
    return AppPdfPageSpec(
      paperSize: paperSize,
      orientation: isLandscape
          ? AppPdfPageOrientation.portrait
          : AppPdfPageOrientation.landscape,
    );
  }
}
