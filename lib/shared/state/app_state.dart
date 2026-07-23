import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../maintenance/maintenance_local_store.dart';
import '../storage/app_storage_guard.dart';

part 'app_state_maintenance_models.dart';
part 'app_state_maintenance_controller.dart';

enum VehicleUsage { businessOnly, personalOnly, businessPersonal }

extension VehicleUsageDetails on VehicleUsage {
  String get label {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Business only';
      case VehicleUsage.personalOnly:
        return 'Personal only';
      case VehicleUsage.businessPersonal:
        return 'Business + personal';
    }
  }

  String get shortLabel {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Business';
      case VehicleUsage.personalOnly:
        return 'Personal';
      case VehicleUsage.businessPersonal:
        return 'Mixed';
    }
  }

  String get setupDescription {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Tracked miles default to business unless you mark an exception.';
      case VehicleUsage.personalOnly:
        return 'Hidden from business mileage by default, but still available for maintenance and fuel.';
      case VehicleUsage.businessPersonal:
        return 'Every trip or day segment must be classified as business or personal.';
    }
  }

  String get odometerPrompt {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Was this missed business mileage, a correction, or a personal exception?';
      case VehicleUsage.personalOnly:
        return 'Was this personal mileage, a correction, or rare business use?';
      case VehicleUsage.businessPersonal:
        return 'Classify these miles as business, personal, or correction.';
    }
  }
}

class VehicleProfile {
  VehicleProfile({
    required this.nickname,
    this.id = '',
    this.year = '',
    this.make = '',
    this.model = '',
    this.usage = VehicleUsage.businessPersonal,
    this.tireSizeStatus = VehicleTireSizeStatus.unknown,
    this.speedometerCalibrationStatus =
        VehicleSpeedometerCalibrationStatus.unknown,
    this.tireConfigurationRevision = 0,
    this.tireConfigurationUpdatedAt,
    this.archivedAt,
  });

  final String nickname;

  /// A stable local identity for records. Unlike [nickname], this must not
  /// change when the user renames the vehicle.
  final String id;
  final String year;
  final String make;
  final String model;
  final VehicleUsage usage;
  final VehicleTireSizeStatus tireSizeStatus;
  final VehicleSpeedometerCalibrationStatus speedometerCalibrationStatus;

  /// Changes only when the driver updates tire/calibration context. This lets
  /// advisory GPS comparison code avoid blending evidence across configurations.
  final int tireConfigurationRevision;
  final DateTime? tireConfigurationUpdatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  String get displayName {
    final details = [
      year,
      make,
      model,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return details.isEmpty ? nickname : '$nickname - $details';
  }

  factory VehicleProfile.fromMap(Map<dynamic, dynamic> map) {
    return VehicleProfile(
      id: map['id']?.toString() ?? '',
      nickname: map['nickname']?.toString() ?? 'Vehicle',
      year: map['year']?.toString() ?? '',
      make: map['make']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      usage: VehicleUsage.values.firstWhere(
        (usage) => usage.name == map['usage']?.toString(),
        orElse: () => VehicleUsage.businessPersonal,
      ),
      tireSizeStatus: VehicleTireSizeStatus.values.firstWhere(
        (status) => status.name == map['tireSizeStatus']?.toString(),
        orElse: () => VehicleTireSizeStatus.unknown,
      ),
      speedometerCalibrationStatus: VehicleSpeedometerCalibrationStatus.values
          .firstWhere(
            (status) =>
                status.name == map['speedometerCalibrationStatus']?.toString(),
            orElse: () => VehicleSpeedometerCalibrationStatus.unknown,
          ),
      tireConfigurationRevision: _nonNegativeInt(
        map['tireConfigurationRevision'],
      ),
      tireConfigurationUpdatedAt: DateTime.tryParse(
        '${map['tireConfigurationUpdatedAt'] ?? ''}',
      ),
      archivedAt: DateTime.tryParse('${map['archivedAt'] ?? ''}'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'nickname': nickname,
    'year': year,
    'make': make,
    'model': model,
    'usage': usage.name,
    'tireSizeStatus': tireSizeStatus.name,
    'speedometerCalibrationStatus': speedometerCalibrationStatus.name,
    'tireConfigurationRevision': tireConfigurationRevision,
    'tireConfigurationUpdatedAt': tireConfigurationUpdatedAt
        ?.toUtc()
        .toIso8601String(),
    'archivedAt': archivedAt?.toUtc().toIso8601String(),
  };

  VehicleProfile copyWith({
    String? nickname,
    String? id,
    String? year,
    String? make,
    String? model,
    VehicleUsage? usage,
    VehicleTireSizeStatus? tireSizeStatus,
    VehicleSpeedometerCalibrationStatus? speedometerCalibrationStatus,
    int? tireConfigurationRevision,
    DateTime? tireConfigurationUpdatedAt,
    bool clearTireConfigurationUpdatedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => VehicleProfile(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    year: year ?? this.year,
    make: make ?? this.make,
    model: model ?? this.model,
    usage: usage ?? this.usage,
    tireSizeStatus: tireSizeStatus ?? this.tireSizeStatus,
    speedometerCalibrationStatus:
        speedometerCalibrationStatus ?? this.speedometerCalibrationStatus,
    tireConfigurationRevision:
        tireConfigurationRevision ?? this.tireConfigurationRevision,
    tireConfigurationUpdatedAt: clearTireConfigurationUpdatedAt
        ? null
        : tireConfigurationUpdatedAt ?? this.tireConfigurationUpdatedAt,
    archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
  );
}

enum VehicleTireSizeStatus {
  factoryEquivalent,
  largerThanRecommended,
  smallerThanRecommended,
  unknown,
}

enum VehicleSpeedometerCalibrationStatus {
  calibratedForCurrentTires,
  notCalibratedForCurrentTires,
  unknown,
}

int _nonNegativeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed == null || parsed < 0 ? 0 : parsed;
}

class WorkProfile {
  WorkProfile({required this.name});

  final String name;
}

typedef VehicleProfileStorageCheck = Future<AppStorageCheck> Function();

class AppStateController extends ChangeNotifier {
  AppStateController()
    : _vehicleBox = null,
      _vehicleStorageCheck = null,
      _maintenanceStore = null;
  AppStateController._(
    this._vehicleBox, {
    VehicleProfileStorageCheck? storageCheck,
    required MaintenanceLocalStore maintenanceStore,
  }) : _vehicleStorageCheck = storageCheck ?? _defaultVehicleStorageCheck,
       _maintenanceStore = maintenanceStore;

  static const vehicleBoxName = 'maintainiac_vehicle_profiles';
  static const _vehicleSnapshotKey = 'snapshot';

  static Future<AppStateController> create({
    VehicleProfileStorageCheck? storageCheck,
    MaintenanceStorageCheck? maintenanceStorageCheck,
  }) async {
    final controller = AppStateController._(
      await Hive.openBox<dynamic>(vehicleBoxName),
      storageCheck: storageCheck,
      maintenanceStore: await MaintenanceLocalStore.create(
        storageCheck: maintenanceStorageCheck,
      ),
    );
    await controller._restoreVehicles();
    await controller._restoreMaintenance();
    return controller;
  }

  final Box<dynamic>? _vehicleBox;
  final VehicleProfileStorageCheck? _vehicleStorageCheck;
  final MaintenanceLocalStore? _maintenanceStore;
  final List<VehicleProfile> _vehicles = <VehicleProfile>[
    VehicleProfile(
      nickname: 'Work Truck 1',
      id: 'vehicle_work_truck_1',
      year: '2018',
      make: 'Ford',
      model: 'F-150',
      usage: VehicleUsage.businessPersonal,
    ),
    VehicleProfile(
      nickname: 'Work Truck 2',
      id: 'vehicle_work_truck_2',
      year: '2021',
      make: 'Ram',
      model: '2500',
      usage: VehicleUsage.businessOnly,
    ),
    VehicleProfile(
      nickname: 'Backup Truck 1',
      id: 'vehicle_backup_truck_1',
      year: '2019',
      make: 'Chevrolet',
      model: 'Silverado',
      usage: VehicleUsage.businessOnly,
    ),
    VehicleProfile(
      nickname: 'Backup Truck 2',
      id: 'vehicle_backup_truck_2',
      year: '2017',
      make: 'Toyota',
      model: 'Tacoma',
      usage: VehicleUsage.businessPersonal,
    ),
  ];
  final List<MaintenanceRecord> _maintenance = <MaintenanceRecord>[];
  final List<MaintenanceServiceEvent> _maintenanceEvents =
      <MaintenanceServiceEvent>[];
  late VehicleProfile? _activeVehicle = _vehicles.first;
  WorkProfile? _activeWorkProfile = WorkProfile(name: 'Main Work');
  Future<void> _vehicleWriteTail = Future<void>.value();
  bool _maintenanceRecoveredFromBackup = false;
  bool _maintenancePrimaryWasInvalid = false;

  List<VehicleProfile> get allVehicles => List.unmodifiable(_vehicles);
  List<VehicleProfile> get vehicles =>
      List.unmodifiable(_vehicles.where((vehicle) => !vehicle.isArchived));
  VehicleProfile? vehicleById(String vehicleId) {
    for (final vehicle in _vehicles) {
      if (vehicle.id == vehicleId) return vehicle;
    }
    return null;
  }

  VehicleProfile? get activeVehicle => _activeVehicle;
  WorkProfile? get activeWorkProfile => _activeWorkProfile;

  Future<void> addVehicle(VehicleProfile vehicle) =>
      _enqueueVehicleWrite(() async {
        final storedVehicle = vehicle.id.trim().isEmpty
            ? VehicleProfile(
                id: 'vehicle_${DateTime.now().microsecondsSinceEpoch}',
                nickname: vehicle.nickname,
                year: vehicle.year,
                make: vehicle.make,
                model: vehicle.model,
                usage: vehicle.usage,
              )
            : vehicle;
        if (_vehicles.any((item) => item.id == storedVehicle.id)) {
          throw ArgumentError.value(
            storedVehicle.id,
            'vehicle.id',
            'Vehicle IDs must be unique.',
          );
        }
        final nextVehicles = [..._vehicles, storedVehicle];
        final nextActiveVehicle = _activeVehicle ?? storedVehicle;
        await _writeVehicleSnapshot(nextVehicles, nextActiveVehicle);
        _vehicles
          ..clear()
          ..addAll(nextVehicles);
        _activeVehicle = nextActiveVehicle;
        notifyListeners();
      });

  Future<void> selectVehicle(VehicleProfile vehicle) =>
      _enqueueVehicleWrite(() async {
        final matches = vehicles
            .where((candidate) => candidate.id == vehicle.id)
            .toList(growable: false);
        if (matches.isEmpty) return;
        final nextActiveVehicle = matches.single;
        await _writeVehicleSnapshot(_vehicles, nextActiveVehicle);
        _activeVehicle = nextActiveVehicle;
        notifyListeners();
      });

  Future<void> updateVehicle(VehicleProfile vehicle) =>
      _enqueueVehicleWrite(() async {
        final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
        if (index < 0) return;
        final nextVehicles = [..._vehicles]..[index] = vehicle;
        final nextActiveVehicle = _activeVehicle?.id == vehicle.id
            ? vehicle
            : _activeVehicle;
        await _writeVehicleSnapshot(nextVehicles, nextActiveVehicle);
        _vehicles
          ..clear()
          ..addAll(nextVehicles);
        _activeVehicle = nextActiveVehicle;
        notifyListeners();
      });

  Future<void> deleteVehicle(String vehicleId) => _enqueueVehicleWrite(
    () async {
      if (vehicles.length <= 1) return;
      final index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
      if (index < 0) return;
      if (_vehicles[index].isArchived) return;
      final nextVehicles = [..._vehicles]
        ..[index] = _vehicles[index].copyWith(archivedAt: DateTime.now());
      final nextActiveVehicle = _activeVehicle?.id == vehicleId
          ? nextVehicles.firstWhere((vehicle) => !vehicle.isArchived)
          : _activeVehicle;
      await _writeVehicleSnapshot(nextVehicles, nextActiveVehicle);
      _vehicles
        ..clear()
        ..addAll(nextVehicles);
      _activeVehicle = nextActiveVehicle;
      notifyListeners();
    },
  );

  Future<void> restoreVehicle(String vehicleId) => _enqueueVehicleWrite(
    () async {
      final index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
      if (index < 0 || !_vehicles[index].isArchived) return;
      final nextVehicles = [..._vehicles]
        ..[index] = _vehicles[index].copyWith(clearArchivedAt: true);
      await _writeVehicleSnapshot(nextVehicles, _activeVehicle);
      _vehicles
        ..clear()
        ..addAll(nextVehicles);
      notifyListeners();
    },
  );

  Future<void> selectCompanyScope() => _enqueueVehicleWrite(() async {
    await _writeVehicleSnapshot(_vehicles, null);
    _activeVehicle = null;
    notifyListeners();
  });

  void setWorkProfile(String name) {
    _activeWorkProfile = WorkProfile(name: name);
    notifyListeners();
  }

  void _notifyStateListeners() => notifyListeners();

  Future<void> _restoreVehicles() async {
    final box = _vehicleBox;
    if (box == null) return;
    final snapshot = box.get(_vehicleSnapshotKey);
    if (snapshot is! Map) {
      await _persistVehicles();
      return;
    }
    final restored = (snapshot['vehicles'] as List? ?? const [])
        .whereType<Map>()
        .map(VehicleProfile.fromMap)
        .where((vehicle) => vehicle.id.trim().isNotEmpty)
        .toList(growable: false);
    if (restored.isEmpty) {
      await _persistVehicles();
      return;
    }
    _vehicles
      ..clear()
      ..addAll(restored);
    final activeId = snapshot['activeVehicleId']?.toString();
    final activeVehicles = vehicles;
    _activeVehicle = activeId == null || activeVehicles.isEmpty
        ? null
        : activeVehicles.firstWhere(
            (vehicle) => vehicle.id == activeId,
            orElse: () => activeVehicles.first,
          );
    notifyListeners();
  }

  Future<void> _persistVehicles() async {
    await _writeVehicleSnapshot(_vehicles, _activeVehicle);
  }

  Future<void> _writeVehicleSnapshot(
    List<VehicleProfile> vehicles,
    VehicleProfile? activeVehicle,
  ) async {
    final box = _vehicleBox;
    if (box == null) return;
    final storageCheck = _vehicleStorageCheck;
    if (storageCheck != null) {
      final storage = await storageCheck();
      if (!storage.hasEnoughSpace) {
        throw StateError(storage.blockingMessage());
      }
    }
    await box.put(_vehicleSnapshotKey, {
      'vehicles': [for (final vehicle in vehicles) vehicle.toMap()],
      'activeVehicleId': activeVehicle?.id,
    });
  }

  Future<T> _enqueueVehicleWrite<T>(Future<T> Function() operation) {
    final next = _vehicleWriteTail.then((_) => operation());
    _vehicleWriteTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultVehicleStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

class AppStateScope extends InheritedNotifier<AppStateController> {
  const AppStateScope({
    required AppStateController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppStateController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
