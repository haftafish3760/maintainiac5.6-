import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class AppPdfTypography {
  const AppPdfTypography._();

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
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(_byteDataView(data));
  }

  static ByteData _byteDataView(ByteData data) {
    return ByteData.sublistView(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
