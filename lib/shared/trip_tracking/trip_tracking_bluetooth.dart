import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_odometer_truth_policy.dart';
import 'trip_tracking_settings_store.dart';

/// A user-approved Bluetooth identity. Device labels are display-only; the
/// opaque identifier and stable vehicle id are the only matching keys.
class TripTrackingBluetoothVehicleLink {
  const TripTrackingBluetoothVehicleLink({
    required this.deviceId,
    required this.vehicleId,
    required this.createdAt,
    this.displayName = '',
    this.schemaVersion = 1,
  });

  final String deviceId;
  final String vehicleId;
  final DateTime createdAt;
  final String displayName;
  final int schemaVersion;

  bool get isValid =>
      schemaVersion == 1 &&
      _safeId(deviceId).isNotEmpty &&
      _safeId(vehicleId).isNotEmpty;

  /// The device identifier is never displayed or sent off-device.  This key is
  /// deliberately normalized only for local de-duplication; platform adapters
  /// remain responsible for supplying a stable opaque identifier.
  String get normalizedDeviceId => _safeId(deviceId);

  Map<String, Object?> toMap() => {
    'schemaVersion': 1,
    'deviceId': normalizedDeviceId,
    'vehicleId': _safeId(vehicleId),
    'createdAt': createdAt.toIso8601String(),
    'displayName': _safeDisplayName(displayName),
  };

  Map<String, Object?> toSafeSummary() => {
    ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
    'hasDeviceLink': isValid,
    'vehicleId': _safeId(vehicleId),
    'hasDisplayName': _safeDisplayName(displayName).isNotEmpty,
    'bluetoothLinkCanSetGlobalTruth': false,
    'bluetoothLinkCanConfirmOfficialMileage': false,
    'bluetoothLinkCanChangeOfficialMileage': false,
    'deviceIdIncluded': false,
    'rawBluetoothPayloadIncluded': false,
  };

  factory TripTrackingBluetoothVehicleLink.fromMap(Map<dynamic, dynamic> map) {
    final rawSchemaVersion = map['schemaVersion'];
    final schemaVersion = rawSchemaVersion == null
        ? 1
        : rawSchemaVersion is int
        ? rawSchemaVersion
        : 0;
    return TripTrackingBluetoothVehicleLink(
      deviceId: _safeId(map['deviceId']),
      vehicleId: _safeId(map['vehicleId']),
      createdAt:
          DateTime.tryParse('${map['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      displayName: _safeDisplayName(map['displayName']),
      schemaVersion: schemaVersion,
    );
  }
}

/// Local-only, user-approved Bluetooth-to-vehicle associations.
///
/// A device can identify only one vehicle at a time. Relinking the same opaque
/// device id deliberately replaces its prior association, while a vehicle may
/// have several approved devices (for example, a head unit and an OBD adapter).
/// No discovery result is persisted until the user explicitly creates a link.
class TripTrackingBluetoothVehicleLinkStore {
  TripTrackingBluetoothVehicleLinkStore._(this._box);
  TripTrackingBluetoothVehicleLinkStore.memory() : _box = null;

  static const boxName = 'gps_trip_tracking_bluetooth_vehicle_links';

  final Box<dynamic>? _box;
  final Map<String, TripTrackingBluetoothVehicleLink> _memoryLinks = {};

  static Future<TripTrackingBluetoothVehicleLinkStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TripTrackingBluetoothVehicleLinkStore._(box);
  }

  TripTrackingBluetoothVehicleLink? linkForDevice(String deviceId) {
    final key = _safeId(deviceId);
    if (key.isEmpty) return null;
    final value = _box == null ? _memoryLinks[key] : _box.get(key);
    if (value is TripTrackingBluetoothVehicleLink) return value;
    if (value is Map) {
      final link = TripTrackingBluetoothVehicleLink.fromMap(value);
      return link.isValid ? link : null;
    }
    return null;
  }

  List<TripTrackingBluetoothVehicleLink> linksForVehicle(String vehicleId) {
    final id = _safeId(vehicleId);
    if (id.isEmpty) return const [];
    final links = _box == null
        ? _memoryLinks.values
        : _box.values.whereType<Map>().map(
            TripTrackingBluetoothVehicleLink.fromMap,
          );
    return links
        .where((link) => link.isValid && link.vehicleId == id)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> save(TripTrackingBluetoothVehicleLink link) async {
    if (!link.isValid) {
      throw ArgumentError.value(
        link,
        'link',
        'A Bluetooth vehicle link requires both a device and a vehicle id.',
      );
    }
    final normalized = TripTrackingBluetoothVehicleLink(
      deviceId: link.normalizedDeviceId,
      vehicleId: _safeId(link.vehicleId),
      createdAt: link.createdAt,
      displayName: _safeDisplayName(link.displayName),
    );
    if (_box == null) {
      _memoryLinks[normalized.normalizedDeviceId] = normalized;
    } else {
      await _box.put(normalized.normalizedDeviceId, normalized.toMap());
    }
  }

  Future<void> removeDevice(String deviceId) async {
    final key = _safeId(deviceId);
    if (key.isEmpty) return;
    _memoryLinks.remove(key);
    await _box?.delete(key);
  }
}

String _safeId(Object? value) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return '';
  return clean.length > 160 ? clean.substring(0, 160) : clean;
}

String _safeDisplayName(Object? value) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return '';
  return clean.length > 80 ? clean.substring(0, 80) : clean;
}

enum BluetoothVehicleMatchDisposition {
  noMatch,
  recognitionDisabled,
  requiresUserConfirmation,
  automaticSwitchAllowed,
  alreadyActiveVehicle,
  blockedByActiveTrip,
  blockedByUnfinishedSession,
}

class BluetoothVehicleMatchDecision {
  const BluetoothVehicleMatchDecision({
    required this.disposition,
    required this.vehicleId,
    required this.safeReason,
  });

  final BluetoothVehicleMatchDisposition disposition;
  final String? vehicleId;
  final String safeReason;

  bool get canSwitchVehicle =>
      disposition == BluetoothVehicleMatchDisposition.automaticSwitchAllowed;
  bool get requiresUserConfirmation =>
      disposition == BluetoothVehicleMatchDisposition.requiresUserConfirmation;

  Map<String, Object?> toSafeSummary() => {
    ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
    'disposition': disposition.name,
    'vehicleId': vehicleId,
    'safeReason': safeReason,
    'canSwitchVehicle': canSwitchVehicle,
    'requiresUserConfirmation': requiresUserConfirmation,
    'bluetoothDecisionCanSetGlobalTruth': false,
    'bluetoothDecisionCanConfirmOfficialMileage': false,
    'bluetoothDecisionCanChangeOfficialMileage': false,
    'deviceIdIncluded': false,
    'rawBluetoothPayloadIncluded': false,
  };
}

BluetoothVehicleMatchDecision resolveBluetoothVehicleMatchDecision({
  required TripTrackingSettings settings,
  required TripTrackingBluetoothVehicleLink? link,
  required bool hasActiveGpsTrip,
  bool hasUnfinishedStoredSession = false,
  String? activeVehicleId,
}) {
  final disposition = resolveBluetoothVehicleMatch(
    settings: settings,
    link: link,
    hasActiveGpsTrip: hasActiveGpsTrip,
    hasUnfinishedStoredSession: hasUnfinishedStoredSession,
    activeVehicleId: activeVehicleId,
  );
  return BluetoothVehicleMatchDecision(
    disposition: disposition,
    vehicleId:
        disposition == BluetoothVehicleMatchDisposition.recognitionDisabled ||
            disposition == BluetoothVehicleMatchDisposition.noMatch
        ? null
        : _safeId(link?.vehicleId),
    safeReason: _safeMatchReason(disposition),
  );
}

BluetoothVehicleMatchDisposition resolveBluetoothVehicleMatch({
  required TripTrackingSettings settings,
  required TripTrackingBluetoothVehicleLink? link,
  required bool hasActiveGpsTrip,
  bool hasUnfinishedStoredSession = false,
  String? activeVehicleId,
}) {
  if (!settings.bluetoothVehicleRecognitionEnabled ||
      link == null ||
      !link.isValid) {
    return settings.bluetoothVehicleRecognitionEnabled
        ? BluetoothVehicleMatchDisposition.noMatch
        : BluetoothVehicleMatchDisposition.recognitionDisabled;
  }
  if (_safeId(activeVehicleId).isNotEmpty &&
      _safeId(activeVehicleId) == _safeId(link.vehicleId)) {
    return BluetoothVehicleMatchDisposition.alreadyActiveVehicle;
  }
  if (hasActiveGpsTrip) {
    return BluetoothVehicleMatchDisposition.blockedByActiveTrip;
  }
  if (hasUnfinishedStoredSession) {
    return BluetoothVehicleMatchDisposition.blockedByUnfinishedSession;
  }
  // A historical opt-in value may still be present in local settings, but a
  // Bluetooth connection is evidence, not authorization to mutate the active
  // vehicle. Keep the legacy value readable for migration compatibility while
  // requiring an explicit decision for every different-vehicle match.
  return BluetoothVehicleMatchDisposition.requiresUserConfirmation;
}

String _safeMatchReason(BluetoothVehicleMatchDisposition disposition) {
  return switch (disposition) {
    BluetoothVehicleMatchDisposition.noMatch => 'bluetooth_no_vehicle_match',
    BluetoothVehicleMatchDisposition.recognitionDisabled =>
      'bluetooth_recognition_disabled',
    BluetoothVehicleMatchDisposition.requiresUserConfirmation =>
      'bluetooth_vehicle_requires_confirmation',
    BluetoothVehicleMatchDisposition.automaticSwitchAllowed =>
      'bluetooth_vehicle_requires_confirmation',
    BluetoothVehicleMatchDisposition.alreadyActiveVehicle =>
      'bluetooth_vehicle_already_active',
    BluetoothVehicleMatchDisposition.blockedByActiveTrip =>
      'bluetooth_switch_blocked_by_active_gps_trip',
    BluetoothVehicleMatchDisposition.blockedByUnfinishedSession =>
      'bluetooth_switch_blocked_by_unfinished_session',
  };
}
