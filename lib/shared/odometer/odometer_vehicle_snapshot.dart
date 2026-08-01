import 'odometer_validation.dart';
import 'odometer_distance_value.dart';

class OdometerVehicleSnapshot {
  const OdometerVehicleSnapshot({
    required this.vehicleId,
    required this.currentReading,
    this.currentReadingTenths,
    required this.updatedAt,
    required this.history,
    this.drivingPatternReviewEnabled = false,
  });

  final String vehicleId;
  final int currentReading;
  final int? currentReadingTenths;
  final DateTime updatedAt;
  final List<OdometerReadingEvent> history;
  final bool drivingPatternReviewEnabled;

  factory OdometerVehicleSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final rawHistory = map['history'];
    return OdometerVehicleSnapshot(
      vehicleId: safeOdometerVehicleId(map['vehicleId']),
      currentReading: _safeOdometerReading(map['currentReading']),
      currentReadingTenths: _optionalSafeOdometerTenths(
        map['currentReadingTenths'],
      ),
      updatedAt:
          DateTime.tryParse('${map['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      history: rawHistory is Iterable
          ? rawHistory
                .whereType<Map>()
                .map(OdometerReadingEvent.fromMap)
                .toList()
          : const [],
      drivingPatternReviewEnabled: map['drivingPatternReviewEnabled'] == true,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'vehicleId': vehicleId,
      'currentReading': _safeOdometerReading(currentReading),
      'currentReadingTenths': effectiveCurrentReadingTenths,
      'updatedAt': updatedAt.toIso8601String(),
      'history': history.map((event) => event.toMap()).toList(),
      'drivingPatternReviewEnabled': drivingPatternReviewEnabled,
    };
  }

  int get effectiveCurrentReadingTenths =>
      _optionalSafeOdometerTenths(currentReadingTenths) ?? currentReading * 10;
}

int _safeOdometerReading(Object? value) {
  final parsed = value is int ? value : int.tryParse('${value ?? ''}');
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

int? _optionalSafeOdometerTenths(Object? value) {
  if (value == null) return null;
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null ||
      parsed < 0 ||
      parsed > OdometerDistanceValue.maximumTenths) {
    return null;
  }
  return parsed;
}

const defaultVehicleId = 'active_vehicle';

String safeOdometerVehicleId(Object? value) {
  final normalized = '${value ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return defaultVehicleId;
  return normalized.length > 160 ? normalized.substring(0, 160) : normalized;
}

String odometerVehicleIdForLabel(String? label) {
  final trimmed = label?.trim();
  if (trimmed == null || trimmed.isEmpty) return defaultVehicleId;
  final normalized = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? defaultVehicleId : normalized;
}

/// Returns the permanent record key for a vehicle.  Older profiles that have
/// not yet been migrated still fall back to their normalized label so their
/// existing local odometer history remains reachable.
String odometerVehicleIdForVehicleId(
  String? vehicleId, {
  String? fallbackLabel,
}) {
  final stableId = safeOdometerVehicleId(vehicleId);
  if (stableId != defaultVehicleId) return stableId;
  return odometerVehicleIdForLabel(fallbackLabel);
}
