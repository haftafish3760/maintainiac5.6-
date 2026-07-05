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

  static const a4Portrait = AppPdfPageSpec(
    paperSize: AppPdfPaperSize.a4,
    orientation: AppPdfPageOrientation.portrait,
  );

  final AppPdfPaperSize paperSize;
  final AppPdfPageOrientation orientation;

  bool get isLandscape => orientation == AppPdfPageOrientation.landscape;

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

  AppPdfPageSpec rotated() {
    return AppPdfPageSpec(
      paperSize: paperSize,
      orientation: isLandscape
          ? AppPdfPageOrientation.portrait
          : AppPdfPageOrientation.landscape,
    );
  }
}
