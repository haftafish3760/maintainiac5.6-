import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTestTypography {
  const PdfTestTypography._();

  static const regularFontAsset = 'assets/pdf_fonts/roboto_regular.ttf';
  static const boldFontAsset = 'assets/pdf_fonts/roboto_bold.ttf';

  static pw.ThemeData? _cachedTheme;

  static Future<pw.ThemeData> loadTheme() async {
    final cached = _cachedTheme;
    if (cached != null) return cached;
    final regular = await _loadFont(regularFontAsset);
    final bold = await _loadFont(boldFontAsset);
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    _cachedTheme = theme;
    return theme;
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(
        ByteData.sublistView(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
      );
    } catch (_) {
      final bytes = await File(assetPath).readAsBytes();
      return pw.Font.ttf(ByteData.sublistView(bytes));
    }
  }
}
