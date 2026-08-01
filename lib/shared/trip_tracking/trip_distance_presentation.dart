// Unit-aware, one-decimal presentation of accepted trip distance evidence.
//
// Owns conversion from canonical meters into miles or kilometers for display.
// It does not accept GPS samples, determine route truth, mutate odometer
// history, or store a global unit preference. Dashboard and review UI consume
// this projection after the future System Settings owner supplies a unit.

import '../odometer/odometer_distance_value.dart';

class TripDistancePresentation {
  const TripDistancePresentation._({
    required this.acceptedMeters,
    required this.displayValue,
  });

  final double acceptedMeters;
  final OdometerDistanceValue displayValue;

  static TripDistancePresentation? fromAcceptedMeters({
    required double acceptedMeters,
    required OdometerDistanceUnit displayUnit,
  }) {
    if (!acceptedMeters.isFinite || acceptedMeters < 0) return null;
    final units = displayUnit == OdometerDistanceUnit.miles
        ? acceptedMeters / 1609.344
        : acceptedMeters / 1000;
    final value = OdometerDistanceValue.fromTenths(
      tenths: (units * 10).round(),
      unit: displayUnit,
    );
    if (value == null) return null;
    return TripDistancePresentation._(
      acceptedMeters: acceptedMeters,
      displayValue: value,
    );
  }

  String format({
    OdometerNumberConvention convention = OdometerNumberConvention.decimalPoint,
  }) => displayValue.format(convention: convention);

  String get unitSymbol =>
      displayValue.unit == OdometerDistanceUnit.miles ? 'mi' : 'km';

  Map<String, Object?> toSafeMap() => {
    'schemaVersion': 1,
    'displayTenths': displayValue.tenths,
    'displayUnit': displayValue.unit.name,
    'unitSymbol': unitSymbol,
    'acceptedMetersChanged': false,
    'odometerChanged': false,
    'gpsTruthClaimed': false,
  };
}
