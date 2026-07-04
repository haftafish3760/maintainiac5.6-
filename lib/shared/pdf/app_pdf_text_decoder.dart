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
    final decoded = <String>[
      ...decodedHexStrings(text),
      ...decodedCMapStrings(text),
    ];
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

  static List<String> decodedCMapStrings(String text) {
    final cmaps = _toUnicodeCMaps(text);
    if (cmaps.isEmpty) return const [];
    final decoded = <String>[];
    final seen = <String>{};
    for (final match in RegExp(
      r'<([0-9a-fA-F\s]{4,})>',
      multiLine: true,
    ).allMatches(text)) {
      final source = _compactHex(match.group(1)!);
      if (source == null || source.length < 4 || source.length.isOdd) {
        continue;
      }
      for (final cmap in cmaps) {
        final decodedValue = _decodeCMapHexString(source, cmap);
        if (decodedValue == null || decodedValue.trim().isEmpty) continue;
        if (seen.add(decodedValue)) decoded.add(decodedValue);
      }
    }
    return List.unmodifiable(decoded);
  }

  static List<int>? _hexValues(String source) {
    final hex = _compactHex(source);
    if (hex == null) return null;
    if (hex.isEmpty || hex.length.isOdd) return null;
    final values = <int>[];
    for (var index = 0; index < hex.length; index += 2) {
      final value = int.tryParse(hex.substring(index, index + 2), radix: 16);
      if (value == null) return null;
      values.add(value);
    }
    return values;
  }

  static String? _compactHex(String source) {
    final hex = source.replaceAll(RegExp(r'\s+'), '');
    if (hex.isEmpty || hex.length.isOdd) return null;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex) ? hex.toUpperCase() : null;
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

  static List<Map<String, String>> _toUnicodeCMaps(String text) {
    final maps = <Map<String, String>>[];
    for (final cmapSection in RegExp(
      r'begincmap(?<body>.*?)endcmap',
      dotAll: true,
      multiLine: true,
    ).allMatches(text)) {
      final map = _toUnicodeCMap(cmapSection.namedGroup('body')!);
      if (map.isNotEmpty) maps.add(map);
    }
    if (maps.isNotEmpty) return List.unmodifiable(maps);
    final fallback = _toUnicodeCMap(text);
    return fallback.isEmpty ? const [] : List.unmodifiable([fallback]);
  }

  static Map<String, String> _toUnicodeCMap(String text) {
    final map = <String, String>{};
    for (final section in RegExp(
      r'beginbfchar(?<body>.*?)endbfchar',
      dotAll: true,
      multiLine: true,
    ).allMatches(text)) {
      final body = section.namedGroup('body')!;
      for (final line in body.split(RegExp(r'\r?\n'))) {
        final match = RegExp(
          r'<([0-9a-fA-F\s]+)>\s+<([0-9a-fA-F\s]+)>',
        ).firstMatch(line);
        if (match == null) continue;
        _addCMapEntry(map, match.group(1)!, match.group(2)!);
      }
    }
    for (final section in RegExp(
      r'beginbfrange(?<body>.*?)endbfrange',
      dotAll: true,
      multiLine: true,
    ).allMatches(text)) {
      final body = section.namedGroup('body')!;
      for (final line in body.split(RegExp(r'\r?\n'))) {
        _addCMapRange(map, line);
      }
    }
    return Map.unmodifiable(map);
  }

  static void _addCMapEntry(
    Map<String, String> map,
    String sourceHex,
    String targetHex,
  ) {
    final source = _compactHex(sourceHex);
    final target = _compactHex(targetHex);
    if (source == null || target == null) return;
    final decoded = _decodeUnicodeHex(target);
    if (decoded == null || decoded.isEmpty) return;
    map[source] = decoded;
  }

  static void _addCMapRange(Map<String, String> map, String line) {
    final arrayMatch = RegExp(
      r'<([0-9a-fA-F\s]+)>\s+<([0-9a-fA-F\s]+)>\s+\[(.*?)\]',
      dotAll: true,
    ).firstMatch(line);
    if (arrayMatch != null) {
      final start = _hexNumber(arrayMatch.group(1)!);
      final end = _hexNumber(arrayMatch.group(2)!);
      if (start == null || end == null || end < start) return;
      final targets = RegExp(
        r'<([0-9a-fA-F\s]+)>',
      ).allMatches(arrayMatch.group(3)!).toList();
      for (
        var offset = 0;
        offset <= end - start && offset < targets.length;
        offset += 1
      ) {
        final source = _hexKey(start + offset, arrayMatch.group(1)!);
        final target = _compactHex(targets[offset].group(1)!);
        if (target == null) continue;
        final decoded = _decodeUnicodeHex(target);
        if (decoded == null || decoded.isEmpty) continue;
        map[source] = decoded;
      }
      return;
    }

    final scalarMatch = RegExp(
      r'<([0-9a-fA-F\s]+)>\s+<([0-9a-fA-F\s]+)>\s+<([0-9a-fA-F\s]+)>',
    ).firstMatch(line);
    if (scalarMatch == null) return;
    final start = _hexNumber(scalarMatch.group(1)!);
    final end = _hexNumber(scalarMatch.group(2)!);
    final targetStart = _hexNumber(scalarMatch.group(3)!);
    if (start == null || end == null || targetStart == null || end < start) {
      return;
    }
    for (var offset = 0; offset <= end - start; offset += 1) {
      final source = _hexKey(start + offset, scalarMatch.group(1)!);
      final target = _hexKey(targetStart + offset, scalarMatch.group(3)!);
      final decoded = _decodeUnicodeHex(target);
      if (decoded == null || decoded.isEmpty) continue;
      map[source] = decoded;
    }
  }

  static String? _decodeCMapHexString(String source, Map<String, String> cmap) {
    final codeUnitWidth = _cMapSourceWidth(cmap);
    if (codeUnitWidth == null ||
        codeUnitWidth == 0 ||
        source.length % codeUnitWidth != 0) {
      return null;
    }
    final buffer = StringBuffer();
    var mappedCount = 0;
    for (var index = 0; index < source.length; index += codeUnitWidth) {
      final glyph = source.substring(index, index + codeUnitWidth);
      final decoded = cmap[glyph];
      if (decoded == null) return null;
      mappedCount += 1;
      buffer.write(decoded);
    }
    final value = buffer.toString();
    if (mappedCount < 2 && value.trim().length < 2) return null;
    return value;
  }

  static int? _cMapSourceWidth(Map<String, String> cmap) {
    int? width;
    for (final key in cmap.keys) {
      if (width == null || key.length < width) width = key.length;
    }
    return width;
  }

  static String? _decodeUnicodeHex(String hex) {
    final values = _hexValues(hex);
    if (values == null || values.isEmpty) return null;
    if (values.length.isEven) {
      final utf16 = _decodeUtf16CodeUnits(values, littleEndian: false);
      if (utf16 != null) return utf16;
    }
    if (!values.every(_isPrintableCodeUnit)) return null;
    return latin1.decode(values, allowInvalid: true);
  }

  static int? _hexNumber(String source) {
    final hex = _compactHex(source);
    if (hex == null) return null;
    return int.tryParse(hex, radix: 16);
  }

  static String _hexKey(int value, String widthSource) {
    final width = _compactHex(widthSource)?.length ?? 4;
    return value.toRadixString(16).toUpperCase().padLeft(width, '0');
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
