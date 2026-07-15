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
    this.archivedAt,
  });

  factory ExpenseWorkProfile.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseWorkProfile(
      id: '${map['id'] ?? ''}'.trim(),
      name: '${map['name'] ?? ''}'.trim(),
      isDefault: map['isDefault'] == true,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ?? now,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? now,
      archivedAt: DateTime.tryParse('${map['archivedAt'] ?? ''}'),
    );
  }

  final String id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'archivedAt': archivedAt?.toUtc().toIso8601String(),
  };

  ExpenseWorkProfile copyWith({
    String? name,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return ExpenseWorkProfile(
      id: id,
      name: name ?? this.name,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
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
  Future<void> _writeTail = Future<void>.value();

  static Future<ExpenseWorkProfileController> create() async {
    final controller = ExpenseWorkProfileController._(
      await Hive.openBox<dynamic>(boxName),
    );
    await controller._ensureDefault();
    return controller;
  }

  List<ExpenseWorkProfile> get allProfiles {
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

  List<ExpenseWorkProfile> get profiles =>
      List.unmodifiable(allProfiles.where((profile) => !profile.isArchived));

  ExpenseWorkProfile? profileById(String profileId) {
    for (final profile in allProfiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
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

  Future<ExpenseWorkProfile> save(ExpenseWorkProfile profile) =>
      _enqueue(() => _save(profile));

  Future<ExpenseWorkProfile> _save(ExpenseWorkProfile profile) async {
    final name = profile.name.trim();
    if (name.isEmpty) throw ArgumentError.value(name, 'name', 'Required');
    final now = DateTime.now();
    final id = profile.id.trim().isEmpty
        ? 'expense_work_${now.microsecondsSinceEpoch}'
        : profile.id.trim();
    final existing = profileById(id);
    if (existing != null && profile.updatedAt.isBefore(existing.updatedAt)) {
      throw StateError('Reload the newer work profile before saving changes.');
    }
    final saved = ExpenseWorkProfile(
      id: id,
      name: name,
      isDefault: id == defaultProfileId,
      createdAt: existing?.createdAt ?? profile.createdAt,
      updatedAt: now,
      archivedAt: id == defaultProfileId ? null : profile.archivedAt,
    );
    await _writeProfile(saved);
    notifyListeners();
    return saved;
  }

  Future<void> select(String profileId) => _enqueue(() => _select(profileId));

  Future<void> _select(String profileId) async {
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

  Future<void> delete(String profileId) => _enqueue(() => _delete(profileId));

  Future<void> _delete(String profileId) async {
    if (profileId == defaultProfileId) {
      throw StateError('The default work profile cannot be deleted.');
    }
    final profile = profileById(profileId);
    if (profile == null || profile.isArchived) return;
    final now = DateTime.now();
    await _writeProfile(profile.copyWith(updatedAt: now, archivedAt: now));
    if (_activeProfileId == profileId) await _select(defaultProfileId);
    notifyListeners();
  }

  Future<void> restore(String profileId) => _enqueue(() => _restore(profileId));

  Future<void> _restore(String profileId) async {
    final profile = profileById(profileId);
    if (profile == null || !profile.isArchived) return;
    await _writeProfile(
      profile.copyWith(updatedAt: DateTime.now(), clearArchivedAt: true),
    );
    notifyListeners();
  }

  Future<void> _ensureDefault() async {
    final defaultProfile = profileById(defaultProfileId);
    if (defaultProfile != null) {
      if (defaultProfile.isArchived) {
        await _writeProfile(
          defaultProfile.copyWith(
            updatedAt: DateTime.now(),
            clearArchivedAt: true,
          ),
        );
      }
      return;
    }
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

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
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
