import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/state/app_state.dart';

class ExpenseVehicleProfileRecord {
  const ExpenseVehicleProfileRecord({
    required this.id,
    required this.nickname,
    required this.createdAt,
    required this.updatedAt,
    this.year = '',
    this.make = '',
    this.model = '',
    this.usage = VehicleUsage.businessPersonal,
    this.archived = false,
  });

  factory ExpenseVehicleProfileRecord.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseVehicleProfileRecord(
      id: map['id']?.toString().trim() ?? '',
      nickname: map['nickname']?.toString().trim() ?? '',
      year: map['year']?.toString().trim() ?? '',
      make: map['make']?.toString().trim() ?? '',
      model: map['model']?.toString().trim() ?? '',
      usage: VehicleUsage.values.firstWhere(
        (usage) => usage.name == map['usage']?.toString(),
        orElse: () => VehicleUsage.businessPersonal,
      ),
      archived: map['archived'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  final String id;
  final String nickname;
  final String year;
  final String make;
  final String model;
  final VehicleUsage usage;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final description = [
      year,
      make,
      model,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return description.isEmpty ? nickname : '$nickname — $description';
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'nickname': nickname,
    'year': year,
    'make': make,
    'model': model,
    'usage': usage.name,
    'archived': archived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ExpenseVehicleProfileController extends ChangeNotifier {
  ExpenseVehicleProfileController._(this._box);
  ExpenseVehicleProfileController.memory() : _box = null;

  static const boxName = 'expense_vehicle_profiles';
  final Box<dynamic>? _box;
  final Map<String, ExpenseVehicleProfileRecord> _memory = {};

  static Future<ExpenseVehicleProfileController> create() async =>
      ExpenseVehicleProfileController._(await Hive.openBox<dynamic>(boxName));

  List<ExpenseVehicleProfileRecord> get profiles {
    final values = _box == null
        ? _memory.values.toList(growable: false)
        : _box.values.toList(growable: false);
    return values
        .map(
          (value) => value is ExpenseVehicleProfileRecord
              ? value
              : value is Map
              ? ExpenseVehicleProfileRecord.fromMap(value)
              : null,
        )
        .whereType<ExpenseVehicleProfileRecord>()
        .where(
          (profile) => profile.id.isNotEmpty && profile.nickname.isNotEmpty,
        )
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<ExpenseVehicleProfileRecord> get activeProfiles =>
      profiles.where((profile) => !profile.archived).toList(growable: false);

  ExpenseVehicleProfileRecord? profileById(String id) {
    for (final profile in profiles) {
      if (profile.id == id.trim()) return profile;
    }
    return null;
  }

  Future<ExpenseVehicleProfileRecord> ensureProfile({
    required String id,
    required String nickname,
    String year = '',
    String make = '',
    String model = '',
    VehicleUsage usage = VehicleUsage.businessPersonal,
  }) async {
    final existing = profileById(id);
    if (existing != null) return existing;
    final now = DateTime.now();
    return save(
      ExpenseVehicleProfileRecord(
        id: id,
        nickname: nickname,
        year: year,
        make: make,
        model: model,
        usage: usage,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<ExpenseVehicleProfileRecord> save(
    ExpenseVehicleProfileRecord profile,
  ) async {
    final now = DateTime.now();
    final id = profile.id.trim().isEmpty
        ? 'VEH-${now.microsecondsSinceEpoch}'
        : profile.id.trim();
    final existing = profileById(id);
    final saved = ExpenseVehicleProfileRecord(
      id: id,
      nickname: profile.nickname.trim(),
      year: profile.year.trim(),
      make: profile.make.trim(),
      model: profile.model.trim(),
      usage: profile.usage,
      archived: profile.archived,
      createdAt: existing?.createdAt ?? profile.createdAt,
      updatedAt: now,
    );
    if (saved.nickname.isEmpty) {
      throw ArgumentError('A vehicle profile needs a visible name.');
    }
    if (_box == null) {
      _memory[id] = saved;
    } else {
      await _box.put(id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<ExpenseVehicleProfileRecord?> archive(String id) async {
    final profile = profileById(id);
    if (profile == null) return null;
    return save(
      ExpenseVehicleProfileRecord(
        id: profile.id,
        nickname: profile.nickname,
        year: profile.year,
        make: profile.make,
        model: profile.model,
        usage: profile.usage,
        archived: true,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      ),
    );
  }

  Map<String, Object?> toBackupMap({
    required String ownerUid,
    required DateTime exportedAtUtc,
  }) => {
    'schema': 'expense_vehicle_profiles_v1',
    'ownerUid': ownerUid.trim(),
    'exportedAtUtc': exportedAtUtc.toUtc().toIso8601String(),
    'profiles': [for (final profile in profiles) profile.toMap()],
  };
}

class ExpenseVehicleProfileScope
    extends InheritedNotifier<ExpenseVehicleProfileController> {
  const ExpenseVehicleProfileScope({
    super.key,
    required ExpenseVehicleProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseVehicleProfileController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseVehicleProfileScope>();
    assert(scope != null, 'ExpenseVehicleProfileScope was not found.');
    return scope!.notifier!;
  }
}
