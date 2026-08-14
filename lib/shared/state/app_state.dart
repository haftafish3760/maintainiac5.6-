import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../maintenance/maintenance_local_store.dart';
import '../storage/app_storage_guard.dart';
import 'vehicle_profile_durable_record_bridge.dart';

part 'app_state_maintenance_models.dart';
part 'app_state_maintenance_controller.dart';
part 'app_state_vehicle_models.dart';

class AppStateController extends ChangeNotifier {
  AppStateController()
    : _vehicleBox = null,
      _vehicleStorageCheck = null,
      _durableVehicleBridge = null,
      _maintenanceStore = null;
  AppStateController._(
    this._vehicleBox, {
    VehicleProfileStorageCheck? storageCheck,
    VehicleProfileDurableRecordBridge? durableVehicleBridge,
    required MaintenanceLocalStore maintenanceStore,
  }) : _vehicleStorageCheck = storageCheck ?? _defaultVehicleStorageCheck,
       _durableVehicleBridge = durableVehicleBridge,
       _maintenanceStore = maintenanceStore;

  static const vehicleBoxName = 'maintainiac_vehicle_profiles';
  static const _vehicleSnapshotKey = 'snapshot';

  static Future<AppStateController> create({
    VehicleProfileStorageCheck? storageCheck,
    MaintenanceStorageCheck? maintenanceStorageCheck,
    VehicleProfileDurableRecordBridge? durableVehicleBridge,
  }) async {
    final controller = AppStateController._(
      await Hive.openBox<dynamic>(vehicleBoxName),
      storageCheck: storageCheck,
      durableVehicleBridge: durableVehicleBridge,
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
  final VehicleProfileDurableRecordBridge? _durableVehicleBridge;
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
    final restored = _restorePrimaryVehicleSnapshot(snapshot);
    if (restored == null) {
      final recovered = _durableVehicleBridge?.load();
      if (recovered == null) {
        await _persistVehicles();
        return;
      }
      _vehicles
        ..clear()
        ..addAll(recovered.vehicles.map(VehicleProfile.fromMap));
      _activeVehicle = _activeVehicleForId(recovered.activeVehicleId);
      await _writeVehicleSnapshot(_vehicles, _activeVehicle);
      notifyListeners();
      return;
    }
    _vehicles
      ..clear()
      ..addAll(restored);
    _activeVehicle = _activeVehicleForId(
      (snapshot as Map)['activeVehicleId']?.toString(),
    );
    final durableBridge = _durableVehicleBridge;
    if (durableBridge != null && durableBridge.load() == null) {
      await durableBridge.save(_durableSnapshot(_vehicles, _activeVehicle));
    }
    notifyListeners();
  }

  List<VehicleProfile>? _restorePrimaryVehicleSnapshot(Object? snapshot) {
    if (snapshot is! Map || snapshot['vehicles'] is! List) return null;
    final rawVehicles = snapshot['vehicles'] as List;
    if (rawVehicles.any((vehicle) => vehicle is! Map)) return null;
    final rawActiveVehicleId = snapshot['activeVehicleId'];
    final requestedActiveVehicleId = rawActiveVehicleId is String
        ? rawActiveVehicleId
        : null;
    final activeVehicleId =
        rawVehicles.any(
          (vehicle) =>
              vehicle['id'] == requestedActiveVehicleId &&
              vehicle['archivedAt'] == null,
        )
        ? requestedActiveVehicleId
        : null;
    final candidate = VehicleProfileDurableSnapshot(
      vehicles: rawVehicles
          .cast<Map>()
          .map((vehicle) => Map<String, dynamic>.from(vehicle))
          .toList(growable: false),
      activeVehicleId: activeVehicleId,
    );
    if (!candidate.isValid) return null;
    return candidate.vehicles
        .map(VehicleProfile.fromMap)
        .toList(growable: false);
  }

  VehicleProfile? _activeVehicleForId(String? activeVehicleId) {
    final activeVehicles = vehicles;
    if (activeVehicleId == null || activeVehicles.isEmpty) return null;
    return activeVehicles.firstWhere(
      (vehicle) => vehicle.id == activeVehicleId,
      orElse: () => activeVehicles.first,
    );
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
    await _durableVehicleBridge?.save(
      _durableSnapshot(vehicles, activeVehicle),
    );
  }

  VehicleProfileDurableSnapshot _durableSnapshot(
    List<VehicleProfile> vehicles,
    VehicleProfile? activeVehicle,
  ) => VehicleProfileDurableSnapshot(
    vehicles: [
      for (final vehicle in vehicles)
        Map<String, dynamic>.from(vehicle.toMap()),
    ],
    activeVehicleId: activeVehicle?.id,
  );

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
