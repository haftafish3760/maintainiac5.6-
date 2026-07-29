import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../profiles/user_profile_models.dart';
import '../state/app_state.dart';
import '../storage/app_storage_guard.dart';
import 'operational_context_models.dart';

typedef OperationalContextStorageCheck = Future<AppStorageCheck> Function();

class OperationalContextController extends ChangeNotifier {
  OperationalContextController._({
    required Box<dynamic>? box,
    required ActiveOperationalContext context,
    OperationalContextStorageCheck? storageCheck,
  }) : _box = box,
       _context = context,
       _storageCheck = storageCheck;

  static const boxName = 'operational_context_v1';
  static const _activeContextKey = 'activeContext';

  final Box<dynamic>? _box;
  final OperationalContextStorageCheck? _storageCheck;
  ActiveOperationalContext _context;
  Future<void> _writeTail = Future<void>.value();

  ActiveOperationalContext get context => _context;

  bool can(UserPermission permission) => _context.can(permission);

  bool get showsContractorDashboard => _context.isContractorDashboard;
  bool get showsMileage => _context.showsMileage;

  static Future<OperationalContextController> create({
    required UserProfileRecord profile,
    required String activeVehicleId,
    required String activeVehicleLabel,
    required VehicleUsage activeVehicleUsage,
    OperationalContextStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final stored = box.get(_activeContextKey);
    final fallback = ActiveOperationalContext.fromProfile(
      profile: profile,
      activeVehicleId: activeVehicleId,
      activeVehicleLabel: activeVehicleLabel,
      activeVehicleUsage: activeVehicleUsage,
    );
    final restored = stored is Map
        ? ActiveOperationalContext.fromMap(stored)
        : null;
    final context = restored != null && _hasSafeOperationalContextIds(restored)
        ? restored
        : fallback;
    return OperationalContextController._(
      box: box,
      context: context,
      storageCheck: storageCheck ?? _defaultStorageCheck,
    );
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
      storageCheck: null,
    );
  }

  Future<void> syncFromProfile({
    required UserProfileRecord profile,
    required String activeVehicleId,
    required String activeVehicleLabel,
    required VehicleUsage activeVehicleUsage,
  }) async {
    return _update((current) {
      return ActiveOperationalContext.fromProfile(
        profile: profile,
        activeVehicleId: activeVehicleId,
        activeVehicleLabel: activeVehicleLabel,
        activeVehicleUsage: activeVehicleUsage,
      ).copyWith(
        companyMode: current.companyMode,
        dashboardMode: current.dashboardMode,
        mileageMode: current.mileageMode,
        syncMode: current.syncMode,
        companyId: current.companyId,
        companyName: current.companyName.isEmpty
            ? profile.businessName
            : current.companyName,
      );
    });
  }

  Future<void> setActiveVehicle({
    required String vehicleId,
    required String vehicleLabel,
    required VehicleUsage usage,
  }) async {
    return _update(
      (current) => current.copyWith(
        activeVehicleId: vehicleId,
        activeVehicleLabel: vehicleLabel,
        activeVehicleUsage: usage,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setActiveWorkProfile({
    required String workProfileId,
    required String workProfileName,
  }) {
    return _update(
      (current) => current.copyWith(
        workProfileId: workProfileId,
        workProfileName: workProfileName,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setDashboardMode(OperationalDashboardMode mode) async {
    return _update(
      (current) => current.copyWith(
        dashboardMode: mode,
        mileageMode: _mileageModeForDashboard(mode),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setSyncMode(OperationalSyncMode mode) async {
    return _update(
      (current) => current.copyWith(syncMode: mode, updatedAt: DateTime.now()),
    );
  }

  Future<void> save(ActiveOperationalContext context) {
    return _update((_) => context);
  }

  Future<void> _update(
    ActiveOperationalContext Function(ActiveOperationalContext current) update,
  ) {
    return _enqueue(() async {
      final next = update(_context);
      _validateContext(next);
      final box = _box;
      if (box != null) {
        await _ensureStorageForWrite();
        await box.put(_activeContextKey, next.toMap());
      }
      _context = next;
      notifyListeners();
    });
  }

  Future<void> _ensureStorageForWrite() async {
    final storageCheck = _storageCheck;
    if (storageCheck == null) return;
    final result = await storageCheck();
    if (!result.hasEnoughSpace) {
      throw StateError(result.blockingMessage());
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (error, _) {});
    return result;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() {
    return AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
  }

  void _validateContext(ActiveOperationalContext context) {
    for (final entry in <String, String>{
      'userProfileId': context.userProfileId,
      'workProfileId': context.workProfileId,
      'activeVehicleId': context.activeVehicleId,
      if (context.companyId.trim().isNotEmpty) 'companyId': context.companyId,
    }.entries) {
      if (!_isSafeOperationalContextId(entry.value)) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Operational dashboard context ids must be safe reference tokens.',
        );
      }
    }
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

bool _isSafeOperationalContextId(String value) {
  final clean = value.trim();
  return clean == value &&
      clean.isNotEmpty &&
      clean.length <= 160 &&
      RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clean);
}

bool _hasSafeOperationalContextIds(ActiveOperationalContext context) {
  return _isSafeOperationalContextId(context.userProfileId) &&
      _isSafeOperationalContextId(context.workProfileId) &&
      _isSafeOperationalContextId(context.activeVehicleId) &&
      (context.companyId.trim().isEmpty ||
          _isSafeOperationalContextId(context.companyId));
}
