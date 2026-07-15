import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A durable Expense-only work context.  It is deliberately separate from
/// accounting, payroll, and the downstream receipt parsers: it only answers
/// which user-created work profile owns an Expense record.
class ExpenseWorkProfile {
  const ExpenseWorkProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  factory ExpenseWorkProfile.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseWorkProfile(
      id: '${map['id'] ?? ''}'.trim(),
      name: '${map['name'] ?? ''}'.trim(),
      isDefault: map['isDefault'] == true,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ?? now,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? now,
    );
  }

  final String id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  ExpenseWorkProfile copyWith({String? name, DateTime? updatedAt}) {
    return ExpenseWorkProfile(
      id: id,
      name: name ?? this.name,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExpenseWorkProfileController extends ChangeNotifier {
  ExpenseWorkProfileController._(this._box);
  ExpenseWorkProfileController.memory() : _box = null {
    _ensureDefault();
  }

  static const boxName = 'expense_work_profiles_v1';
  static const _activeProfileKey = '_active_profile_id';
  static const defaultProfileId = 'expense_work_default';
  final Box<dynamic>? _box;
  final _memory = <String, ExpenseWorkProfile>{};
  String? _memoryActiveProfileId;

  static Future<ExpenseWorkProfileController> create() async {
    final controller = ExpenseWorkProfileController._(
      await Hive.openBox<dynamic>(boxName),
    );
    await controller._ensureDefault();
    return controller;
  }

  List<ExpenseWorkProfile> get profiles {
    final box = _box;
    final values = box == null ? _memory.values : box.values;
    final profiles = <ExpenseWorkProfile>[];
    for (final value in values) {
      final profile = switch (value) {
        ExpenseWorkProfile() => value,
        Map() => ExpenseWorkProfile.fromMap(value),
        _ => null,
      };
      if (profile != null && profile.id.isNotEmpty && profile.name.isNotEmpty) {
        profiles.add(profile);
      }
    }
    profiles.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List.unmodifiable(profiles);
  }

  ExpenseWorkProfile get activeWorkProfile {
    final activeId = _activeProfileId;
    return profiles.firstWhere(
      (profile) => profile.id == activeId,
      orElse: () => profiles.firstWhere(
        (profile) => profile.id == defaultProfileId,
        orElse: () => profiles.first,
      ),
    );
  }

  String get _activeProfileId =>
      _box?.get(_activeProfileKey) as String? ??
      _memoryActiveProfileId ??
      defaultProfileId;

  Future<ExpenseWorkProfile> save(ExpenseWorkProfile profile) async {
    final name = profile.name.trim();
    if (name.isEmpty) throw ArgumentError.value(name, 'name', 'Required');
    final now = DateTime.now();
    final id = profile.id.trim().isEmpty
        ? 'expense_work_${now.microsecondsSinceEpoch}'
        : profile.id.trim();
    final saved = ExpenseWorkProfile(
      id: id,
      name: name,
      isDefault: id == defaultProfileId,
      createdAt: profile.createdAt,
      updatedAt: now,
    );
    await _writeProfile(saved);
    notifyListeners();
    return saved;
  }

  Future<void> select(String profileId) async {
    if (!profiles.any((profile) => profile.id == profileId)) {
      throw ArgumentError.value(profileId, 'profileId', 'Unknown work profile');
    }
    if (_box == null) {
      _memoryActiveProfileId = profileId;
    } else {
      await _box.put(_activeProfileKey, profileId);
    }
    notifyListeners();
  }

  Future<void> delete(String profileId) async {
    if (profileId == defaultProfileId) {
      throw StateError('The default work profile cannot be deleted.');
    }
    if (_box == null) {
      _memory.remove(profileId);
    } else {
      await _box.delete(profileId);
    }
    if (_activeProfileId == profileId) await select(defaultProfileId);
    notifyListeners();
  }

  Future<void> _ensureDefault() async {
    if (profiles.any((profile) => profile.id == defaultProfileId)) return;
    final now = DateTime.now();
    await _writeProfile(
      ExpenseWorkProfile(
        id: defaultProfileId,
        name: 'Default work profile',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _writeProfile(ExpenseWorkProfile profile) async {
    if (_box == null) {
      _memory[profile.id] = profile;
    } else {
      await _box.put(profile.id, profile.toMap());
    }
  }
}

class ExpenseWorkProfileScope
    extends InheritedNotifier<ExpenseWorkProfileController> {
  const ExpenseWorkProfileScope({
    super.key,
    required ExpenseWorkProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseWorkProfileController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseWorkProfileScope>();
    assert(scope != null, 'ExpenseWorkProfileScope is missing above context.');
    return scope!.notifier!;
  }
}
