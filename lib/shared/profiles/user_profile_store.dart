import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'user_profile_models.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController._({
    required Box<dynamic> box,
    required UserProfileRecord activeProfile,
  }) : _box = box,
       _activeProfile = activeProfile;

  static const boxName = 'user_profile_settings_v1';
  static const _activeProfileKey = 'activeProfile';

  final Box<dynamic> _box;
  UserProfileRecord _activeProfile;

  UserProfileRecord get activeProfile => _activeProfile;
  bool get isContractorMode =>
      _activeProfile.type == UserProfileType.contractor;
  bool get isDriverMode => _activeProfile.type == UserProfileType.driver;
  bool get isCustomerMode => _activeProfile.type == UserProfileType.customer;

  static Future<UserProfileController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    final stored = box.get(_activeProfileKey);
    final profile = stored is Map
        ? UserProfileRecord.fromMap(stored)
        : UserProfileRecord.starterContractor();
    return UserProfileController._(box: box, activeProfile: profile);
  }

  Future<void> saveActiveProfile(UserProfileRecord profile) async {
    _activeProfile = profile;
    await _box.put(_activeProfileKey, profile.toMap());
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
