import 'dart:convert';

class AppPdfTextDecoder {
  const AppPdfTextDecoder._();

  static String withDecodedHexStrings(String text) {
    final decoded = decodedHexStrings(text);
    if (decoded.isEmpty) return text;
    return '$text\n${decoded.join('\n')}';
  }

  static List<String> decodedHexStrings(String text) {
    final decoded = <String>[];
    for (final match in RegExp(
      r'<([0-9a-fA-F\s]{4,})>',
      multiLine: true,
    ).allMatches(text)) {
      final values = _hexValues(match.group(1)!);
      if (values == null || values.isEmpty) continue;
      final decodedValue = _decodePdfHexString(values);
      if (decodedValue == null) continue;
      decoded.add(decodedValue);
    }
    return List.unmodifiable(decoded);
  }

  static List<int>? _hexValues(String source) {
    final hex = source.replaceAll(RegExp(r'\s+'), '');
    if (hex.isEmpty || hex.length.isOdd) return null;
    final values = <int>[];
    for (var index = 0; index < hex.length; index += 2) {
      final value = int.tryParse(hex.substring(index, index + 2), radix: 16);
      if (value == null) return null;
      values.add(value);
    }
    return values;
  }

  static String? _decodePdfHexString(List<int> values) {
    if (values.length >= 2 && values[0] == 0xFE && values[1] == 0xFF) {
      return _decodeUtf16CodeUnits(
        values.skip(2).toList(),
        littleEndian: false,
      );
    }
    if (values.length >= 2 && values[0] == 0xFF && values[1] == 0xFE) {
      return _decodeUtf16CodeUnits(values.skip(2).toList(), littleEndian: true);
    }
    if (!values.every(_isPrintableCodeUnit)) return null;
    return latin1.decode(values, allowInvalid: true);
  }

  static String? _decodeUtf16CodeUnits(
    List<int> values, {
    required bool littleEndian,
  }) {
    if (values.isEmpty || values.length.isOdd) return null;
    final buffer = StringBuffer();
    for (var index = 0; index < values.length; index += 2) {
      final first = values[index];
      final second = values[index + 1];
      final codeUnit = littleEndian
          ? first | (second << 8)
          : (first << 8) | second;
      if (!_isPrintableCodeUnit(codeUnit)) return null;
      buffer.writeCharCode(codeUnit);
    }
    final decoded = buffer.toString();
    return decoded.trim().isEmpty ? null : decoded;
  }

  static bool _isPrintableCodeUnit(int value) =>
      value == 9 || value == 10 || value == 13 || value >= 32;
}
