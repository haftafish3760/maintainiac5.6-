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

  bool get isValid => deviceId.trim().isNotEmpty && vehicleId.trim().isNotEmpty;

  /// The device identifier is never displayed or sent off-device.  This key is
  /// deliberately normalized only for local de-duplication; platform adapters
  /// remain responsible for supplying a stable opaque identifier.
  String get normalizedDeviceId => deviceId.trim();

  Map<String, Object?> toMap() => {
    'deviceId': deviceId,
    'vehicleId': vehicleId,
    'createdAt': createdAt.toIso8601String(),
    'displayName': displayName,
  };

  factory TripTrackingBluetoothVehicleLink.fromMap(Map<dynamic, dynamic> map) =>
      TripTrackingBluetoothVehicleLink(
        deviceId: '${map['deviceId'] ?? ''}',
        vehicleId: '${map['vehicleId'] ?? ''}',
        createdAt:
            DateTime.tryParse('${map['createdAt'] ?? ''}') ?? DateTime.now(),
        displayName: '${map['displayName'] ?? ''}',
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
    final key = deviceId.trim();
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
    final id = vehicleId.trim();
    if (id.isEmpty) return const [];
    final links = _box == null
        ? _memoryLinks.values
        : _box.values.whereType<Map>().map(
            TripTrackingBluetoothVehicleLink.fromMap,
          );
    return links
        .where((link) => link.isValid && link.vehicleId.trim() == id)
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
      vehicleId: link.vehicleId.trim(),
      createdAt: link.createdAt,
      displayName: link.displayName.trim(),
    );
    if (_box == null) {
      _memoryLinks[normalized.normalizedDeviceId] = normalized;
    } else {
      await _box.put(normalized.normalizedDeviceId, normalized.toMap());
    }
  }

  Future<void> removeDevice(String deviceId) async {
    final key = deviceId.trim();
    if (key.isEmpty) return;
    _memoryLinks.remove(key);
    await _box?.delete(key);
  }
}

enum BluetoothVehicleMatchDisposition {
  noMatch,
  recognitionDisabled,
  requiresUserConfirmation,
  automaticSwitchAllowed,
  blockedByActiveTrip,
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
