import 'package:flutter/widgets.dart';

class VehicleProfile {
  VehicleProfile({
    required this.nickname,
    this.year = '',
    this.make = '',
    this.model = '',
  });

  final String nickname;
  final String year;
  final String make;
  final String model;

  String get displayName {
    final details = [
      year,
      make,
      model,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return details.isEmpty ? nickname : '$nickname - $details';
  }
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
    this.timeOnly = false,
  });

  final String itemName;
  final String vehicleName;
  final int intervalMiles;
  final int milesSinceService;
  final int intervalMonths;
  final int monthsSinceService;
  final int importance;
  final bool timeOnly;

  int get milesRemaining => intervalMiles - milesSinceService;
  int get monthsRemaining => intervalMonths - monthsSinceService;
}

class AppStateController extends ChangeNotifier {
  int _odometer = 128415;
  final List<VehicleProfile> _vehicles = <VehicleProfile>[
    VehicleProfile(
      nickname: 'Work Truck 1',
      year: '2018',
      make: 'Ford',
      model: 'F-150',
    ),
    VehicleProfile(
      nickname: 'Work Truck 2',
      year: '2021',
      make: 'Ram',
      model: '2500',
    ),
    VehicleProfile(
      nickname: 'Backup Truck 1',
      year: '2019',
      make: 'Chevrolet',
      model: 'Silverado',
    ),
    VehicleProfile(
      nickname: 'Backup Truck 2',
      year: '2017',
      make: 'Toyota',
      model: 'Tacoma',
    ),
  ];
  final List<MaintenanceRecord> _maintenance = <MaintenanceRecord>[];
  late VehicleProfile? _activeVehicle = _vehicles.first;
  WorkProfile? _activeWorkProfile = WorkProfile(name: 'Main Work');

  int get odometer => _odometer;
  List<VehicleProfile> get vehicles => List.unmodifiable(_vehicles);
  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);
  VehicleProfile? get activeVehicle => _activeVehicle;
  WorkProfile? get activeWorkProfile => _activeWorkProfile;

  void updateOdometer(int value) {
    if (value < 0 || value == _odometer) return;
    _odometer = value;
    notifyListeners();
  }

  void addVehicle(VehicleProfile vehicle) {
    _vehicles.add(vehicle);
    _activeVehicle ??= vehicle;
    notifyListeners();
  }

  void selectVehicle(VehicleProfile vehicle) {
    _activeVehicle = vehicle;
    notifyListeners();
  }

  void setWorkProfile(String name) {
    _activeWorkProfile = WorkProfile(name: name);
    notifyListeners();
  }

  void addMaintenanceRecords(List<MaintenanceRecord> records) {
    _maintenance.addAll(records);
    _maintenance.sort((a, b) {
      final urgency = a.milesRemaining.compareTo(b.milesRemaining);
      return urgency == 0 ? b.importance.compareTo(a.importance) : urgency;
    });
    notifyListeners();
  }
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
