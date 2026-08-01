// Exact tenth-unit odometer values and locale-aware display conversion.
//
// Owns parsing, formatting, serialization, and presentation-only conversion
// between miles and kilometers. It does not own vehicle settings, trip
// distance acceptance, odometer history, or user confirmation. Odometer,
// trip-review, and Dashboard projections consume this value. A unit change
// must never rewrite the stored physical odometer or confirmed history.

enum OdometerDistanceUnit { miles, kilometers }

enum OdometerNumberConvention { decimalPoint, decimalComma }

class OdometerExactEntryResult {
  const OdometerExactEntryResult(this.value);

  final OdometerDistanceValue value;

  int get wholeReading => value.tenths ~/ 10;
  int get readingTenths => value.tenths;
}

class OdometerDistanceValue {
  const OdometerDistanceValue._({required this.tenths, required this.unit});

  static const int maximumTenths = 99999999;
  static const String schema = 'odometer_distance_value_v1';

  final int tenths;
  final OdometerDistanceUnit unit;

  static OdometerDistanceValue? fromTenths({
    required int tenths,
    required OdometerDistanceUnit unit,
  }) {
    if (tenths < 0 || tenths > maximumTenths) return null;
    return OdometerDistanceValue._(tenths: tenths, unit: unit);
  }

  static OdometerDistanceValue? fromWholeUnits({
    required int wholeUnits,
    required OdometerDistanceUnit unit,
  }) {
    if (wholeUnits < 0 || wholeUnits > maximumTenths ~/ 10) return null;
    return OdometerDistanceValue._(tenths: wholeUnits * 10, unit: unit);
  }

  /// Accepts a whole number or exactly one optional decimal digit.
  ///
  /// Decimal-point input may use commas for grouping. Decimal-comma input may
  /// use periods for grouping. Hundredths are rejected rather than rounded.
  static OdometerDistanceValue? tryParse(
    String raw, {
    required OdometerDistanceUnit unit,
    OdometerNumberConvention convention = OdometerNumberConvention.decimalPoint,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('-')) return null;
    final decimal = convention == OdometerNumberConvention.decimalPoint
        ? '.'
        : ',';
    final grouping = convention == OdometerNumberConvention.decimalPoint
        ? ','
        : '.';
    final escapedDecimal = RegExp.escape(decimal);
    final escapedGrouping = RegExp.escape(grouping);
    final valid = RegExp(
      '^(?:\\d{1,3}(?:$escapedGrouping\\d{3})+|\\d+)(?:$escapedDecimal\\d)?\$',
    );
    if (!valid.hasMatch(trimmed)) return null;
    final normalized = trimmed.replaceAll(grouping, '');
    final parts = normalized.split(decimal);
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 2 ? int.parse(parts.last) : 0;
    final tenths = whole * 10 + fraction;
    return fromTenths(tenths: tenths, unit: unit);
  }

  int? differenceTenthsFrom(OdometerDistanceValue earlier) {
    if (earlier.unit != unit || tenths < earlier.tenths) return null;
    return tenths - earlier.tenths;
  }

  /// Converts only for display. The returned integer is rounded to one tenth.
  int displayTenthsIn(OdometerDistanceUnit targetUnit) {
    if (targetUnit == unit) return tenths;
    if (unit == OdometerDistanceUnit.miles) {
      return (tenths * 1.609344).round();
    }
    return (tenths / 1.609344).round();
  }

  String format({
    OdometerNumberConvention convention = OdometerNumberConvention.decimalPoint,
    bool includeTenths = true,
  }) {
    final whole = tenths ~/ 10;
    final fraction = tenths % 10;
    final grouping = convention == OdometerNumberConvention.decimalPoint
        ? ','
        : '.';
    final decimal = convention == OdometerNumberConvention.decimalPoint
        ? '.'
        : ',';
    final grouped = _groupThousands(whole, grouping);
    return includeTenths ? '$grouped$decimal$fraction' : grouped;
  }

  Map<String, Object?> toMap() => {
    'schema': schema,
    'tenths': tenths,
    'unit': unit.name,
  };

  static OdometerDistanceValue? fromMap(Map<dynamic, dynamic> map) {
    if (map['schema'] != schema) return null;
    final rawTenths = map['tenths'];
    final tenths = rawTenths is int ? rawTenths : int.tryParse('$rawTenths');
    final unit = OdometerDistanceUnit.values.where(
      (candidate) => candidate.name == map['unit'],
    );
    if (tenths == null || unit.length != 1) return null;
    return fromTenths(tenths: tenths, unit: unit.single);
  }
}

String _groupThousands(int value, String separator) {
  final raw = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    if (index > 0 && (raw.length - index) % 3 == 0) output.write(separator);
    output.write(raw[index]);
  }
  return output.toString();
}
