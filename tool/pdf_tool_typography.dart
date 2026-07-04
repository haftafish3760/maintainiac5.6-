import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

class PdfToolTypography {
  const PdfToolTypography._();

  static const regularFontPath = 'assets/pdf_fonts/roboto_regular.ttf';
  static const boldFontPath = 'assets/pdf_fonts/roboto_bold.ttf';

  static Future<pw.ThemeData> loadTheme() async {
    final regular = await _loadFont(regularFontPath);
    final bold = await _loadFont(boldFontPath);
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static Future<pw.Font> _loadFont(String path) async {
    final bytes = await File(path).readAsBytes();
    return pw.Font.ttf(ByteData.sublistView(bytes));
  }
}
