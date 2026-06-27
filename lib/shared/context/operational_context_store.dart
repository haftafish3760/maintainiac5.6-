import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../profiles/user_profile_models.dart';
import '../state/app_state.dart';
import 'operational_context_models.dart';

class OperationalContextController extends ChangeNotifier {
  OperationalContextController._({
    required Box<dynamic>? box,
    required ActiveOperationalContext context,
  }) : _box = box,
       _context = context;

  static const boxName = 'operational_context_v1';
  static const _activeContextKey = 'activeContext';

  final Box<dynamic>? _box;
  ActiveOperationalContext _context;

  ActiveOperationalContext get context => _context;

  bool can(UserPermission permission) => _context.can(permission);

  bool get showsContractorDashboard => _context.isContractorDashboard;
  bool get showsMileage => _context.showsMileage;

  static Future<OperationalContextController> create({
    required UserProfileRecord profile,
    required String activeVehicleId,
    required String activeVehicleLabel,
    required VehicleUsage activeVehicleUsage,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final stored = box.get(_activeContextKey);
    final context = stored is Map
        ? ActiveOperationalContext.fromMap(stored)
        : ActiveOperationalContext.fromProfile(
            profile: profile,
            activeVehicleId: activeVehicleId,
            activeVehicleLabel: activeVehicleLabel,
            activeVehicleUsage: activeVehicleUsage,
          );
    return OperationalContextController._(box: box, context: context);
  }

  factory OperationalContextController.memory({
    required UserProfileRecord profile,
    String activeVehicleId = 'work_truck_1',
    String activeVehicleLabel = 'Work Truck 1',
    VehicleUsage activeVehicleUsage = VehicleUsage.businessPersonal,
  }) {
    return OperationalContextController._(
      box: null,
      context: ActiveOperationalContext.fromProfile(
        profile: profile,
        activeVehicleId: activeVehicleId,
        activeVehicleLabel: activeVehicleLabel,
        activeVehicleUsage: activeVehicleUsage,
      ),
    );
  }

  Future<void> syncFromProfile({
    required UserProfileRecord profile,
    required String activeVehicleId,
    required String activeVehicleLabel,
    required VehicleUsage activeVehicleUsage,
  }) async {
    final next =
        ActiveOperationalContext.fromProfile(
          profile: profile,
          activeVehicleId: activeVehicleId,
          activeVehicleLabel: activeVehicleLabel,
          activeVehicleUsage: activeVehicleUsage,
        ).copyWith(
          companyMode: _context.companyMode,
          dashboardMode: _context.dashboardMode,
          mileageMode: _context.mileageMode,
          syncMode: _context.syncMode,
          companyId: _context.companyId,
          companyName: _context.companyName.isEmpty
              ? profile.businessName
              : _context.companyName,
        );
    await save(next);
  }

  Future<void> setActiveVehicle({
    required String vehicleId,
    required String vehicleLabel,
    required VehicleUsage usage,
  }) async {
    await save(
      _context.copyWith(
        activeVehicleId: vehicleId,
        activeVehicleLabel: vehicleLabel,
        activeVehicleUsage: usage,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setDashboardMode(OperationalDashboardMode mode) async {
    await save(
      _context.copyWith(
        dashboardMode: mode,
        mileageMode: _mileageModeForDashboard(mode),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setSyncMode(OperationalSyncMode mode) async {
    await save(_context.copyWith(syncMode: mode, updatedAt: DateTime.now()));
  }

  Future<void> save(ActiveOperationalContext context) async {
    _context = context;
    await _box?.put(_activeContextKey, context.toMap());
    notifyListeners();
  }
}

class OperationalContextScope
    extends InheritedNotifier<OperationalContextController> {
  const OperationalContextScope({
    super.key,
    required OperationalContextController controller,
    required super.child,
  }) : super(notifier: controller);

  static OperationalContextController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OperationalContextScope>();
    assert(scope != null, 'OperationalContextScope was not found.');
    return scope!.notifier!;
  }

  static OperationalContextController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OperationalContextScope>()
        ?.notifier;
  }
}

OperationalMileageMode _mileageModeForDashboard(OperationalDashboardMode mode) {
  return switch (mode) {
    OperationalDashboardMode.gigDriver ||
    OperationalDashboardMode.soloContractor => OperationalMileageMode.workday,
    OperationalDashboardMode.fleetOwner => OperationalMileageMode.fleetReview,
    OperationalDashboardMode.employee => OperationalMileageMode.employeeShift,
    OperationalDashboardMode.customer => OperationalMileageMode.customerHidden,
  };
}
