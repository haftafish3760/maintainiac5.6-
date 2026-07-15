import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';

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
    'archivedAt': archivedAt?.toUtc().toIso8601String(),
  };

  VehicleProfile copyWith({
    String? nickname,
    String? id,
    String? year,
    String? make,
    String? model,
    VehicleUsage? usage,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => VehicleProfile(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    year: year ?? this.year,
    make: make ?? this.make,
    model: model ?? this.model,
    usage: usage ?? this.usage,
    archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
  );
}

class WorkProfile {
  WorkProfile({required this.name});

  final String name;
}

class MaintenanceRecord {
  MaintenanceRecord({
    required this.itemName,
    required this.vehicleName,
    required this.intervalMiles,
    required this.milesSinceService,
    required this.intervalMonths,
    required this.monthsSinceService,
    required this.importance,
    this.lastServiceDate,
    this.lastServiceOdometer = 0,
    this.detailA = '',
    this.detailB = '',
    this.setupComplete = false,
    this.lastServiceEstimated = true,
    this.lastOdometerEstimated = true,
    this.thresholdsEnabled = true,
    this.mileageYellowAt = 900,
    this.mileageOrangeAt = 600,
    this.mileageRedAt = 300,
    this.timeYellowDays = 60,
    this.timeOrangeDays = 30,
    this.timeRedDays = 14,
    this.inAppNotifications = false,
    this.pushNotifications = false,
    this.soundNotifications = false,
    this.pairOilFilter = true,
    this.timeOnly = false,
  });

  final String itemName;
  final String vehicleName;
  final int intervalMiles;
  final int milesSinceService;
  final int intervalMonths;
  final int monthsSinceService;
  final int importance;
  final DateTime? lastServiceDate;
  final int lastServiceOdometer;
  final String detailA;
  final String detailB;
  final bool setupComplete;
  final bool lastServiceEstimated;
  final bool lastOdometerEstimated;
  final bool thresholdsEnabled;
  final int mileageYellowAt;
  final int mileageOrangeAt;
  final int mileageRedAt;
  final int timeYellowDays;
  final int timeOrangeDays;
  final int timeRedDays;
  final bool inAppNotifications;
  final bool pushNotifications;
  final bool soundNotifications;
  final bool pairOilFilter;
  final bool timeOnly;

  int get milesRemaining => intervalMiles - milesSinceService;
  int get monthsRemaining => intervalMonths - monthsSinceService;

  MaintenanceRecord copyWith({
    String? itemName,
    String? vehicleName,
    int? intervalMiles,
    int? milesSinceService,
    int? intervalMonths,
    int? monthsSinceService,
    int? importance,
    DateTime? lastServiceDate,
    int? lastServiceOdometer,
    String? detailA,
    String? detailB,
    bool? setupComplete,
    bool? lastServiceEstimated,
    bool? lastOdometerEstimated,
    bool? thresholdsEnabled,
    int? mileageYellowAt,
    int? mileageOrangeAt,
    int? mileageRedAt,
    int? timeYellowDays,
    int? timeOrangeDays,
    int? timeRedDays,
    bool? inAppNotifications,
    bool? pushNotifications,
    bool? soundNotifications,
    bool? pairOilFilter,
    bool? timeOnly,
  }) {
    return MaintenanceRecord(
      itemName: itemName ?? this.itemName,
      vehicleName: vehicleName ?? this.vehicleName,
      intervalMiles: intervalMiles ?? this.intervalMiles,
      milesSinceService: milesSinceService ?? this.milesSinceService,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      monthsSinceService: monthsSinceService ?? this.monthsSinceService,
      importance: importance ?? this.importance,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      detailA: detailA ?? this.detailA,
      detailB: detailB ?? this.detailB,
      setupComplete: setupComplete ?? this.setupComplete,
      lastServiceEstimated: lastServiceEstimated ?? this.lastServiceEstimated,
      lastOdometerEstimated:
          lastOdometerEstimated ?? this.lastOdometerEstimated,
      thresholdsEnabled: thresholdsEnabled ?? this.thresholdsEnabled,
      mileageYellowAt: mileageYellowAt ?? this.mileageYellowAt,
      mileageOrangeAt: mileageOrangeAt ?? this.mileageOrangeAt,
      mileageRedAt: mileageRedAt ?? this.mileageRedAt,
      timeYellowDays: timeYellowDays ?? this.timeYellowDays,
      timeOrangeDays: timeOrangeDays ?? this.timeOrangeDays,
      timeRedDays: timeRedDays ?? this.timeRedDays,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      soundNotifications: soundNotifications ?? this.soundNotifications,
      pairOilFilter: pairOilFilter ?? this.pairOilFilter,
      timeOnly: timeOnly ?? this.timeOnly,
    );
  }
}

class MaintenanceServiceEvent {
  MaintenanceServiceEvent({
    required this.itemName,
    required this.vehicleName,
    required this.serviceDate,
    required this.odometer,
    this.provider = '',
    this.totalCost = 0,
    this.receiptProofCount = 0,
    this.notes = '',
  });

  final String itemName;
  final String vehicleName;
  final DateTime serviceDate;
  final int odometer;
  final String provider;
  final double totalCost;
  final int receiptProofCount;
  final String notes;
}

typedef VehicleProfileStorageCheck = Future<AppStorageCheck> Function();

class AppStateController extends ChangeNotifier {
  AppStateController() : _vehicleBox = null, _vehicleStorageCheck = null;
  AppStateController._(
    this._vehicleBox, {
    VehicleProfileStorageCheck? storageCheck,
  }) : _vehicleStorageCheck = storageCheck ?? _defaultVehicleStorageCheck;

  static const vehicleBoxName = 'maintainiac_vehicle_profiles';
  static const _vehicleSnapshotKey = 'snapshot';

  static Future<AppStateController> create({
    VehicleProfileStorageCheck? storageCheck,
  }) async {
    final controller = AppStateController._(
      await Hive.openBox<dynamic>(vehicleBoxName),
      storageCheck: storageCheck,
    );
    await controller._restoreVehicles();
    return controller;
  }

  final Box<dynamic>? _vehicleBox;
  final VehicleProfileStorageCheck? _vehicleStorageCheck;
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

  List<VehicleProfile> get allVehicles => List.unmodifiable(_vehicles);
  List<VehicleProfile> get vehicles =>
      List.unmodifiable(_vehicles.where((vehicle) => !vehicle.isArchived));
  VehicleProfile? vehicleById(String vehicleId) {
    for (final vehicle in _vehicles) {
      if (vehicle.id == vehicleId) return vehicle;
    }
    return null;
  }

  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);
  List<MaintenanceServiceEvent> get maintenanceEvents =>
      List.unmodifiable(_maintenanceEvents);
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

  void addMaintenanceRecords(List<MaintenanceRecord> records) {
    _maintenance.addAll(records);
    _sortMaintenanceRecords();
    notifyListeners();
  }

  void updateMaintenanceRecord(MaintenanceRecord record) {
    final index = _maintenance.indexWhere(
      (saved) =>
          saved.vehicleName == record.vehicleName &&
          saved.itemName == record.itemName,
    );
    if (index == -1) return;
    _maintenance[index] = record;
    _sortMaintenanceRecords();
    notifyListeners();
  }

  void _sortMaintenanceRecords() {
    _maintenance.sort((a, b) {
      final urgency = _maintenanceAttentionRank(
        b,
      ).compareTo(_maintenanceAttentionRank(a));
      if (urgency != 0) return urgency;
      return b.importance.compareTo(a.importance);
    });
  }

  int _maintenanceAttentionRank(MaintenanceRecord record) {
    if (record.timeOnly) {
      if (record.monthsRemaining <= 0) return 4000 + record.importance;
      if (record.monthsRemaining <= 3) return 3000 + record.importance;
      if (record.monthsRemaining <= 6) return 2000 + record.importance;
      return record.importance;
    }
    if (record.milesRemaining <= 300) return 4000 + record.importance;
    if (record.milesRemaining <= 600) return 3000 + record.importance;
    if (record.milesRemaining <= 900) return 2000 + record.importance;
    return record.importance;
  }

  void logMaintenanceService(MaintenanceServiceEvent event) {
    _maintenanceEvents.add(event);
    final index = _maintenance.indexWhere(
      (record) =>
          record.vehicleName == event.vehicleName &&
          record.itemName == event.itemName,
    );
    if (index != -1) {
      _maintenance[index] = _maintenance[index].copyWith(
        milesSinceService: 0,
        monthsSinceService: 0,
        lastServiceDate: event.serviceDate,
        lastServiceOdometer: event.odometer,
        setupComplete: true,
        lastServiceEstimated: false,
        lastOdometerEstimated: false,
      );
    }
    _sortMaintenanceRecords();
    notifyListeners();
  }

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
