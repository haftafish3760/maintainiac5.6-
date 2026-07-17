import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_settings_store.dart';

/// A user-approved Bluetooth identity. Device labels are display-only; the
/// opaque identifier and stable vehicle id are the only matching keys.
class TripTrackingBluetoothVehicleLink {
  const TripTrackingBluetoothVehicleLink({
    required this.deviceId,
    required this.vehicleId,
    required this.createdAt,
    this.displayName = '',
  });

  final String deviceId;
  final String vehicleId;
  final DateTime createdAt;
  final String displayName;

  bool get isValid =>
      _safeId(deviceId).isNotEmpty && _safeId(vehicleId).isNotEmpty;

  /// The device identifier is never displayed or sent off-device.  This key is
  /// deliberately normalized only for local de-duplication; platform adapters
  /// remain responsible for supplying a stable opaque identifier.
  String get normalizedDeviceId => _safeId(deviceId);

  Map<String, Object?> toMap() => {
    'deviceId': normalizedDeviceId,
    'vehicleId': _safeId(vehicleId),
    'createdAt': createdAt.toIso8601String(),
    'displayName': _safeDisplayName(displayName),
  };

  Map<String, Object?> toSafeSummary() => {
    'hasDeviceLink': isValid,
    'vehicleId': _safeId(vehicleId),
    'hasDisplayName': _safeDisplayName(displayName).isNotEmpty,
    'deviceIdIncluded': false,
    'rawBluetoothPayloadIncluded': false,
  };

  factory TripTrackingBluetoothVehicleLink.fromMap(Map<dynamic, dynamic> map) =>
      TripTrackingBluetoothVehicleLink(
        deviceId: _safeId(map['deviceId']),
        vehicleId: _safeId(map['vehicleId']),
        createdAt:
            DateTime.tryParse('${map['createdAt'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        displayName: _safeDisplayName(map['displayName']),
      );
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
  blockedByActiveTrip,
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
    'disposition': disposition.name,
    'vehicleId': vehicleId,
    'safeReason': safeReason,
    'canSwitchVehicle': canSwitchVehicle,
    'requiresUserConfirmation': requiresUserConfirmation,
    'deviceIdIncluded': false,
    'rawBluetoothPayloadIncluded': false,
  };
}

BluetoothVehicleMatchDecision resolveBluetoothVehicleMatchDecision({
  required TripTrackingSettings settings,
  required TripTrackingBluetoothVehicleLink? link,
  required bool hasActiveGpsTrip,
}) {
  final disposition = resolveBluetoothVehicleMatch(
    settings: settings,
    link: link,
    hasActiveGpsTrip: hasActiveGpsTrip,
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
}) {
  if (!settings.bluetoothVehicleRecognitionEnabled ||
      link == null ||
      !link.isValid) {
    return settings.bluetoothVehicleRecognitionEnabled
        ? BluetoothVehicleMatchDisposition.noMatch
        : BluetoothVehicleMatchDisposition.recognitionDisabled;
  }
  if (hasActiveGpsTrip) {
    return BluetoothVehicleMatchDisposition.blockedByActiveTrip;
  }
  return settings.automaticVehicleSwitchEnabled
      ? BluetoothVehicleMatchDisposition.automaticSwitchAllowed
      : BluetoothVehicleMatchDisposition.requiresUserConfirmation;
}

String _safeMatchReason(BluetoothVehicleMatchDisposition disposition) {
  return switch (disposition) {
    BluetoothVehicleMatchDisposition.noMatch => 'bluetooth_no_vehicle_match',
    BluetoothVehicleMatchDisposition.recognitionDisabled =>
      'bluetooth_recognition_disabled',
    BluetoothVehicleMatchDisposition.requiresUserConfirmation =>
      'bluetooth_vehicle_requires_confirmation',
    BluetoothVehicleMatchDisposition.automaticSwitchAllowed =>
      'bluetooth_vehicle_auto_switch_allowed',
    BluetoothVehicleMatchDisposition.blockedByActiveTrip =>
      'bluetooth_switch_blocked_by_active_gps_trip',
  };
}
