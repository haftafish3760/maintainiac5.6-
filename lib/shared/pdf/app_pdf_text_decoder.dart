import 'dart:convert';
import 'dart:io';

class AppPdfTextDecoder {
  const AppPdfTextDecoder._();

  static const int _maxDecodedStreamBytes = 512 * 1024;
  static const int _maxDecodedStreams = 16;

  static String textWithDecodedPdfStreams(List<int> bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    final streams = decodedFlateStreams(bytes);
    final combined = streams.isEmpty ? raw : '$raw\n${streams.join('\n')}';
    return withDecodedHexStrings(combined);
  }

  static String withDecodedHexStrings(String text) {
    final decoded = decodedHexStrings(text);
    if (decoded.isEmpty) return text;
    return '$text\n${decoded.join('\n')}';
  }

  static List<String> decodedFlateStreams(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    final decoded = <String>[];
    var searchStart = 0;
    while (decoded.length < _maxDecodedStreams) {
      final streamStart = _indexOfAscii(bytes, 'stream', searchStart);
      if (streamStart < 0) break;
      final streamDataStart = _skipStreamLineEnding(bytes, streamStart + 6);
      final streamEnd = _indexOfAscii(bytes, 'endstream', streamDataStart);
      if (streamEnd < 0) break;
      if (_streamUsesFlateDecode(bytes, streamStart)) {
        final streamBytes = _trimTrailingLineEnding(
          bytes.sublist(streamDataStart, streamEnd),
        );
        final inflated = _tryInflate(streamBytes);
        if (inflated != null) decoded.add(inflated);
      }
      searchStart = streamEnd + 9;
    }
    return List.unmodifiable(decoded);
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

  static int _indexOfAscii(List<int> bytes, String needle, int start) {
    if (needle.isEmpty || start >= bytes.length) return -1;
    final codes = latin1.encode(needle);
    for (var index = start; index <= bytes.length - codes.length; index += 1) {
      var matched = true;
      for (var offset = 0; offset < codes.length; offset += 1) {
        if (bytes[index + offset] != codes[offset]) {
          matched = false;
          break;
        }
      }
      if (matched) return index;
    }
    return -1;
  }

  static int _skipStreamLineEnding(List<int> bytes, int index) {
    if (index < bytes.length && bytes[index] == 0x0D) index += 1;
    if (index < bytes.length && bytes[index] == 0x0A) index += 1;
    return index;
  }

  static bool _streamUsesFlateDecode(List<int> bytes, int streamStart) {
    final dictionaryStart = streamStart > 512 ? streamStart - 512 : 0;
    final dictionary = latin1
        .decode(bytes.sublist(dictionaryStart, streamStart), allowInvalid: true)
        .toLowerCase();
    return dictionary.contains('/flatedecode') || dictionary.contains('/fl');
  }

  static List<int> _trimTrailingLineEnding(List<int> bytes) {
    var end = bytes.length;
    while (end > 0 && (bytes[end - 1] == 0x0A || bytes[end - 1] == 0x0D)) {
      end -= 1;
    }
    return bytes.sublist(0, end);
  }

  static String? _tryInflate(List<int> streamBytes) {
    try {
      final inflated = zlib.decode(streamBytes);
      if (inflated.isEmpty || inflated.length > _maxDecodedStreamBytes) {
        return null;
      }
      return latin1.decode(inflated, allowInvalid: true);
    } catch (_) {
      return null;
    }
  }
}
