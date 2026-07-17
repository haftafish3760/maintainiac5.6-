import 'odometer_validation.dart';

class OdometerVehicleSnapshot {
  const OdometerVehicleSnapshot({
    required this.vehicleId,
    required this.currentReading,
    required this.updatedAt,
    required this.history,
    this.drivingPatternReviewEnabled = false,
  });

  final String vehicleId;
  final int currentReading;
  final DateTime updatedAt;
  final List<OdometerReadingEvent> history;
  final bool drivingPatternReviewEnabled;

  factory OdometerVehicleSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final rawHistory = map['history'];
    return OdometerVehicleSnapshot(
      vehicleId: '${map['vehicleId'] ?? defaultVehicleId}',
      currentReading: _safeOdometerReading(map['currentReading']),
      updatedAt:
          DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? DateTime.now(),
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
      'updatedAt': updatedAt.toIso8601String(),
      'history': history.map((event) => event.toMap()).toList(),
      'drivingPatternReviewEnabled': drivingPatternReviewEnabled,
    };
  }
}

int _safeOdometerReading(Object? value) {
  final parsed = value is int ? value : int.tryParse('${value ?? ''}');
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

const defaultVehicleId = 'active_vehicle';

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
  final stableId = vehicleId?.trim();
  if (stableId != null && stableId.isNotEmpty) return stableId;
  return odometerVehicleIdForLabel(fallbackLabel);
}
