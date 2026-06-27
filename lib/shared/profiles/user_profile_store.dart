import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'user_profile_models.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController._({
    required Box<dynamic>? box,
    required UserProfileRecord activeProfile,
  }) : _box = box,
       _activeProfile = activeProfile;

  UserProfileController.memory({UserProfileRecord? activeProfile})
    : _box = null,
      _activeProfile = activeProfile ?? UserProfileRecord.starterContractor();

  static const boxName = 'user_profile_settings_v1';
  static const _activeProfileKey = 'activeProfile';

  final Box<dynamic>? _box;
  UserProfileRecord _activeProfile;
  bool _recoveredFromStorageError = false;

  UserProfileRecord get activeProfile => _activeProfile;
  bool get recoveredFromStorageError => _recoveredFromStorageError;
  bool get isContractorMode =>
      _activeProfile.type == UserProfileType.contractor;
  bool get isDriverMode => _activeProfile.type == UserProfileType.driver;
  bool get isCustomerMode => _activeProfile.type == UserProfileType.customer;

  static Future<UserProfileController> create() async {
    try {
      final box = await Hive.openBox<dynamic>(boxName);
      final stored = box.get(_activeProfileKey);
      final profile = _profileFromStoredValue(stored);
      final controller = UserProfileController._(
        box: box,
        activeProfile: profile,
      );
      if (stored is! Map || profile.wasRepairedFrom(stored)) {
        controller._recoveredFromStorageError = true;
        await controller._repairStoredProfile();
      }
      return controller;
    } catch (_) {
      final controller = UserProfileController.memory();
      controller._recoveredFromStorageError = true;
      return controller;
    }
  }

  Future<void> saveActiveProfile(UserProfileRecord profile) async {
    final sanitized = profile.sanitized();
    await _box?.put(_activeProfileKey, sanitized.toMap());
    _activeProfile = sanitized;
    notifyListeners();
  }

  Future<void> setProfileType(UserProfileType type) async {
    if (type == _activeProfile.type) return;
    await saveActiveProfile(
      _activeProfile.copyWith(
        type: type,
        customerFacingEnabled: type == UserProfileType.contractor
            ? _activeProfile.customerFacingEnabled
            : false,
      ),
    );
  }

  Future<void> setPrimaryVehicleId(String vehicleId) async {
    final normalized = vehicleId.trim();
    if (normalized.isEmpty || normalized == _activeProfile.primaryVehicleId) {
      return;
    }
    await saveActiveProfile(
      _activeProfile.copyWith(
        activeVehicleIds: [
          normalized,
          for (final id in _activeProfile.activeVehicleIds)
            if (id != normalized) id,
        ],
      ),
    );
  }

  bool can(UserPermission permission) => _activeProfile.can(permission);

  static UserProfileRecord _profileFromStoredValue(Object? stored) {
    if (stored is Map) return UserProfileRecord.fromMap(stored).sanitized();
    return UserProfileRecord.starterContractor();
  }

  Future<void> _repairStoredProfile() async {
    try {
      await _box?.put(_activeProfileKey, _activeProfile.toMap());
    } catch (_) {
      _recoveredFromStorageError = true;
    }
  }
}

class UserProfileScope extends InheritedNotifier<UserProfileController> {
  const UserProfileScope({
    super.key,
    required UserProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static UserProfileController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<UserProfileScope>();
    assert(scope != null, 'UserProfileScope was not found.');
    return scope!.notifier!;
  }

  static UserProfileController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserProfileScope>()
        ?.notifier;
  }
}
