part of 'maintenance_receipt_parser.dart';

class _SourceRow {
  const _SourceRow(this.lineNumber, this.text);

  final int lineNumber;
  final String text;

  String get comparisonText => _comparisonText(text);
}

List<_SourceRow> _sourceRows(String source) {
  final boundedSource = source.length <= _maxSourceCharacters
      ? source
      : source.substring(0, _maxSourceCharacters);
  final lines = boundedSource
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final rows = <_SourceRow>[];
  for (var index = 0; index < lines.length; index++) {
    if (rows.length >= _maxSourceRows) break;
    final normalized = lines[index].replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) continue;
    rows.add(
      _SourceRow(
        index + 1,
        normalized.length <= _maxSourceRowCharacters
            ? normalized
            : normalized.substring(0, _maxSourceRowCharacters),
      ),
    );
  }
  return rows;
}

const _maxSourceCharacters = 2 * 1024 * 1024;
const _maxSourceRows = 5000;
const _maxSourceRowCharacters = 500;

String _sourceFingerprint(String source) {
  final normalized = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map(
        (line) => _comparisonText(line.replaceAll(RegExp(r'\s+'), ' ').trim()),
      )
      .where((line) => line.isNotEmpty)
      .join('\n');
  return sha256.convert(utf8.encode(normalized)).toString();
}

String _comparisonText(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[‐‑‒–—―−]'), '-')
      .replaceAll(RegExp(r'[’‘`]'), "'")
      .replaceAll(
        RegExp(r"\b0\s*'?\s*reilly\b", caseSensitive: false),
        "o'reilly",
      )
      .replaceAll(RegExp(r'\b0il\b', caseSensitive: false), 'oil')
      .replaceAll(RegExp(r'\baut0zone\b', caseSensitive: false), 'autozone')
      .replaceAll(RegExp(r'\baut0z0ne\b', caseSensitive: false), 'autozone')
      .replaceAll(RegExp(r'\b0dometer\b', caseSensitive: false), 'odometer')
      .replaceAll(RegExp(r'\b0d0meter\b', caseSensitive: false), 'odometer')
      .replaceAll(RegExp(r'\bm1leage\b', caseSensitive: false), 'mileage')
      .replaceAll(RegExp(r'\bfi1ter\b', caseSensitive: false), 'filter')
      .replaceAll(RegExp(r'\bsynthetlc\b', caseSensitive: false), 'synthetic')
      .toLowerCase();
  return normalized.replaceAllMapped(
    RegExp(r'\b((?:0|5|10|15|20)w[- ]?(?:1|2|3|4|5|6))o\b'),
    (match) => '${match.group(1)}0',
  );
}

String _merchantName(List<_SourceRow> rows) {
  if (rows.isEmpty) return '';
  final joined = rows.take(5).map((row) => row.comparisonText).join(' ');
  final known = <(RegExp, String)>[
    (
      RegExp(r'\b(?:advance\s*auto\s*parts|advanceautoparts)\b'),
      'Advance Auto Parts',
    ),
    (RegExp(r'\bauto\s*zone\b'), 'AutoZone'),
    (RegExp(r"\bo\s*[’'`]?\s*reilly\s*auto\s*parts\b"), "O'Reilly Auto Parts"),
    (RegExp(r'\bnapa auto parts\b|\bnapa\b'), 'NAPA Auto Parts'),
    (RegExp(r'\bcarquest\b'), 'Carquest Auto Parts'),
    (RegExp(r'\bpep boys\b'), 'Pep Boys'),
    (RegExp(r'\bwal\s*-?\s*mart\b'), 'Walmart'),
    (RegExp(r'\bcostco(?:\s*wholesale)?\b'), 'Costco'),
    (RegExp(r"\bsam[’'`]?\s*s\s*club\b"), "Sam's Club"),
    (RegExp(r'\btractor\s*supply(?:\s*co)?\b'), 'Tractor Supply'),
    (RegExp(r'\brural\s*king\b'), 'Rural King'),
    (RegExp(r'\btake 5 oil change\b'), 'Take 5 Oil Change'),
    (RegExp(r'\bjiffy lube\b'), 'Jiffy Lube'),
    (RegExp(r'\bvalvoline instant oil change\b'), 'Valvoline'),
  ];
  for (final entry in known) {
    if (entry.$1.hasMatch(joined)) return entry.$2;
  }
  for (final row in rows.take(5)) {
    if (_metadataLine.hasMatch(row.comparisonText) ||
        _pricedLine.hasMatch(row.comparisonText) ||
        row.text.length > 80) {
      continue;
    }
    return _titleCase(row.text);
  }
  return '';
}

class _ReceiptDateRead {
  const _ReceiptDateRead(
    this.date, {
    this.ambiguousNumeric = false,
    this.unsupportedLocale = false,
    this.futureDateRejected = false,
  });

  final DateTime? date;
  final bool ambiguousNumeric;
  final bool unsupportedLocale;
  final bool futureDateRejected;
}

_ReceiptDateRead _receiptDate(
  List<_SourceRow> rows,
  String locale,
  DateTime? referenceDate, {
  bool skipNextDueRows = true,
}) {
  var futureDateRejected = false;
  bool isFuture(DateTime date) {
    if (referenceDate == null) return false;
    final referenceDay = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return date.isAfter(referenceDay);
  }

  for (final row in rows.take(16)) {
    if (skipNextDueRows && _nextDueDateSignal.hasMatch(row.comparisonText)) {
      continue;
    }
    final namedMonth = RegExp(
      r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?[,]?\s+(20\d{2})\b',
    ).firstMatch(row.comparisonText);
    if (namedMonth != null) {
      final date = _safeDate(
        namedMonth.group(3),
        '${_monthNumber(namedMonth.group(1)!)}',
        namedMonth.group(2),
      );
      if (date != null) {
        if (isFuture(date)) {
          futureDateRejected = true;
        } else {
          return _ReceiptDateRead(date, futureDateRejected: futureDateRejected);
        }
      }
    }
    final dayFirstNamed = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(20\d{2})\b',
    ).firstMatch(row.comparisonText);
    if (dayFirstNamed != null) {
      final date = _safeDate(
        dayFirstNamed.group(3),
        '${_monthNumber(dayFirstNamed.group(2)!)}',
        dayFirstNamed.group(1),
      );
      if (date != null) {
        if (isFuture(date)) {
          futureDateRejected = true;
        } else {
          return _ReceiptDateRead(date, futureDateRejected: futureDateRejected);
        }
      }
    }
    final iso = RegExp(
      r'\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b',
    ).firstMatch(row.comparisonText);
    if (iso != null) {
      final date = _safeDate(iso.group(1), iso.group(2), iso.group(3));
      if (date != null) {
        if (isFuture(date)) {
          futureDateRejected = true;
        } else {
          return _ReceiptDateRead(date, futureDateRejected: futureDateRejected);
        }
      }
    }
    final numeric = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
    ).firstMatch(row.comparisonText);
    if (numeric != null) {
      final first = int.tryParse(numeric.group(1)!);
      final second = int.tryParse(numeric.group(2)!);
      final rawYear = int.tryParse(numeric.group(3)!);
      final year = rawYear == null
          ? null
          : rawYear < 100
          ? 2000 + rawYear
          : rawYear;
      if (first == null || second == null || year == null) continue;
      final ambiguous = first <= 12 && second <= 12;
      final normalizedLocale = locale.trim().toLowerCase();
      final monthFirst =
          normalizedLocale == 'en-us' || normalizedLocale.startsWith('en-us-');
      final dayFirst = const {'en-gb', 'en-au', 'en-nz', 'en-ie'}.any(
        (value) =>
            normalizedLocale == value || normalizedLocale.startsWith('$value-'),
      );
      if (ambiguous && !monthFirst && !dayFirst) {
        return const _ReceiptDateRead(null, unsupportedLocale: true);
      }
      final useDayFirst = first > 12 || (ambiguous && dayFirst);
      final date = _safeDate(
        '$year',
        '${useDayFirst ? second : first}',
        '${useDayFirst ? first : second}',
      );
      if (date != null) {
        if (isFuture(date)) {
          futureDateRejected = true;
        } else {
          return _ReceiptDateRead(
            date,
            ambiguousNumeric: ambiguous,
            futureDateRejected: futureDateRejected,
          );
        }
      }
    }
  }
  return _ReceiptDateRead(null, futureDateRejected: futureDateRejected);
}

int? _monthNumber(String value) {
  const months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
  final index = months.indexOf(value.substring(0, 3));
  return index < 0 ? null : index + 1;
}

DateTime? _safeDate(String? year, String? month, String? day) {
  final y = int.tryParse(year ?? '');
  final m = int.tryParse(month ?? '');
  final d = int.tryParse(day ?? '');
  if (y == null || m == null || d == null) return null;
  final date = DateTime(y, m, d);
  return date.year == y && date.month == m && date.day == d ? date : null;
}

int? _readingFor(String text, RegExp pattern) {
  final match = pattern.firstMatch(text.replaceAll(',', ''));
  if (match == null) return null;
  final value = int.tryParse(match.group(1)!);
  return value == null || value < 0 || value > 99999999 ? null : value;
}

int? _serviceOdometerFor(String text) {
  return _readingFor(text, _serviceOdometerOutPattern) ??
      _readingFor(text, _serviceOdometerPattern);
}

String _safeSnippet(String source) {
  var value = source
      .replaceAll(
        RegExp(r'\b(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}\b'),
        '[PHONE REDACTED]',
      )
      .replaceAll(
        RegExp(r'\b(?:\d[ -]?){13,19}\b'),
        '[PAYMENT NUMBER REDACTED]',
      )
      .replaceAll(
        RegExp(
          r"\b\d{1,6}\s+[A-Za-z0-9.' -]{2,40}\s(?:st(?:reet)?|rd|road|ave(?:nue)?|blvd|boulevard|dr(?:ive)?|ln|lane|ct|court)\b",
          caseSensitive: false,
        ),
        '[ADDRESS REDACTED]',
      )
      .replaceAll(
        RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b', caseSensitive: false),
        '[VIN REDACTED]',
      )
      .replaceAll(RegExp(r'\b\d{7,}\b'), '[NUMBER REDACTED]')
      .replaceAll(
        RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b'),
        '[EMAIL REDACTED]',
      );
  if (value.length > 120) value = '${value.substring(0, 117)}...';
  return value;
}

String _titleCase(String value) => value
    .toLowerCase()
    .split(' ')
    .map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    })
    .join(' ');

typedef _DetailReader = String? Function(String text);

class _ItemDefinition {
  const _ItemDefinition({
    required this.itemName,
    required this.pattern,
    required this.servicePattern,
    this.detailA = _noDetail,
    this.detailB = _noDetail,
  });

  final String itemName;
  final RegExp pattern;
  final RegExp servicePattern;
  final _DetailReader detailA;
  final _DetailReader detailB;
}

String? _noDetail(String _) => null;

String? _oilType(String text) {
  if (RegExp(r'\bfull synthetic\b').hasMatch(text)) return 'Full Synthetic';
  if (RegExp(r'\bsynthetic blend\b|\bsyn blend\b').hasMatch(text)) {
    return 'Synthetic Blend';
  }
  if (RegExp(r'\bhigh mileage\b').hasMatch(text)) return 'High Mileage';
  if (RegExp(r'\bconventional\b').hasMatch(text)) return 'Conventional';
  return null;
}

String? _oilWeight(String text) {
  final match = RegExp(
    r'\b(0w|5w|10w|15w|20w)\s*-?\s*(16|20|30|40|50|60)\b',
  ).firstMatch(text);
  return match == null
      ? null
      : '${match.group(1)!.toUpperCase()}-${match.group(2)}';
}

String? _brakeAxle(String text) {
  if (RegExp(r'\bfront (?:disc )?(?:brake|pad|rotor)').hasMatch(text)) {
    return 'Front';
  }
  if (RegExp(r'\brear (?:disc )?(?:brake|pad|rotor)').hasMatch(text)) {
    return 'Rear';
  }
  return null;
}

String? _batteryGroup(String text) {
  final match = RegExp(
    r'\b(?:group|grp)\s*(\d{2,3}[a-z]?)\b|\b(\d{2,3}[a-z])\s+battery\b',
  ).firstMatch(text);
  return (match?.group(1) ?? match?.group(2))?.toUpperCase();
}

String? _oilFilterPart(String text) =>
    _partNumberAfter(text, r'(?:oil filter|filter oil)');

String? _engineAirFilterPart(String text) =>
    _partNumberAfter(text, r'(?:engine air filter|air filter element)');

String? _cabinAirFilterPart(String text) =>
    _partNumberAfter(text, r'(?:cabin air filter|cabin filter)');

String? _fuelFilterPart(String text) =>
    _partNumberAfter(text, r'(?:fuel filter|gas filter)');

String? _partNumberAfter(String text, String itemPattern) {
  final match = RegExp(
    '\\b$itemPattern\\s+(?:part(?:\\s*(?:no|number|#))?\\s*)?'
    r'([a-z]{1,6}[-]?\d{1,10}[a-z0-9-]*)\b',
  ).firstMatch(text);
  return match?.group(1)?.toUpperCase();
}

String? _wiperSize(String text) {
  final match = RegExp(
    r'\b(?:wiper blades?|windshield wipers?)\D{0,20}(\d{1,2})\s*(?:"|in\b|inch(?:es)?\b)',
  ).firstMatch(text);
  return match == null ? null : '${match.group(1)} in';
}

String? _tireSize(String text) {
  final match = RegExp(
    r'\b(\d{3})\s*\/\s*(\d{2})\s*r\s*(\d{2})\b',
  ).firstMatch(text);
  return match == null
      ? null
      : '${match.group(1)}/${match.group(2)}R${match.group(3)}';
}

String? _tireBrandAndType(String text) {
  const brands = [
    'Michelin',
    'Goodyear',
    'Bridgestone',
    'Continental',
    'Cooper',
    'BFGoodrich',
    'Firestone',
    'Pirelli',
    'Hankook',
    'Yokohama',
    'Toyo',
    'Kumho',
    'Falken',
    'General',
  ];
  final brand = brands
      .where((value) => text.contains(value.toLowerCase()))
      .firstOrNull;
  final type = RegExp(r'\ball[- ]season\b').hasMatch(text)
      ? 'All-Season'
      : RegExp(r'\bwinter\b|\bsnow tire').hasMatch(text)
      ? 'Winter'
      : RegExp(r'\bsummer tire').hasMatch(text)
      ? 'Summer'
      : null;
  return [brand, type].whereType<String>().join(' / ').nullIfEmpty;
}

String? _fluidSpec(String text) {
  const values = [
    'ATF+4',
    'DEXRON VI',
    'MERCON LV',
    'CVT',
    'DOT 3',
    'DOT 4',
    'DOT 5.1',
    'DEX-COOL',
  ];
  for (final value in values) {
    if (text.contains(value.toLowerCase())) return value;
  }
  return null;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
