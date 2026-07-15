import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ExpenseWorkProfileRecord {
  const ExpenseWorkProfileRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  factory ExpenseWorkProfileRecord.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ExpenseWorkProfileRecord(
      id: map['id']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      archived: map['archived'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  final String id;
  final String name;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'archived': archived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ExpenseWorkProfileController extends ChangeNotifier {
  ExpenseWorkProfileController._(this._box);
  ExpenseWorkProfileController.memory() : _box = null;

  static const boxName = 'expense_work_profiles';
  static const defaultProfileId = 'main-work';
  final Box<dynamic>? _box;
  final Map<String, ExpenseWorkProfileRecord> _memory = {};

  static Future<ExpenseWorkProfileController> create() async {
    final controller = ExpenseWorkProfileController._(
      await Hive.openBox<dynamic>(boxName),
    );
    await controller.ensureProfile(id: defaultProfileId, name: 'Main Work');
    return controller;
  }

  List<ExpenseWorkProfileRecord> get profiles {
    final values = _box == null
        ? _memory.values.toList(growable: false)
        : _box.values.toList(growable: false);
    return values
        .map(
          (value) => value is ExpenseWorkProfileRecord
              ? value
              : value is Map
              ? ExpenseWorkProfileRecord.fromMap(value)
              : null,
        )
        .whereType<ExpenseWorkProfileRecord>()
        .where((profile) => profile.id.isNotEmpty && profile.name.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<ExpenseWorkProfileRecord> get activeProfiles =>
      profiles.where((profile) => !profile.archived).toList(growable: false);

  ExpenseWorkProfileRecord? profileById(String id) {
    for (final profile in profiles) {
      if (profile.id == id.trim()) return profile;
    }
    return null;
  }

  Future<ExpenseWorkProfileRecord> ensureProfile({
    required String id,
    required String name,
  }) async {
    final existing = profileById(id);
    if (existing != null) return existing;
    final now = DateTime.now();
    return save(
      ExpenseWorkProfileRecord(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<ExpenseWorkProfileRecord> save(
    ExpenseWorkProfileRecord profile,
  ) async {
    final now = DateTime.now();
    final existing = profileById(profile.id);
    final id = profile.id.trim().isEmpty
        ? 'WORK-${now.microsecondsSinceEpoch}'
        : profile.id.trim();
    final saved = ExpenseWorkProfileRecord(
      id: id,
      name: profile.name.trim(),
      archived: profile.archived,
      createdAt: existing?.createdAt ?? profile.createdAt,
      updatedAt: now,
    );
    if (saved.name.isEmpty) throw ArgumentError('A work profile needs a name.');
    if (_box == null) {
      _memory[saved.id] = saved;
    } else {
      await _box.put(saved.id, saved.toMap());
    }
    notifyListeners();
    return saved;
  }

  Future<ExpenseWorkProfileRecord?> archive(String id) async {
    final profile = profileById(id);
    if (profile == null || profile.id == defaultProfileId) return null;
    return save(
      ExpenseWorkProfileRecord(
        id: profile.id,
        name: profile.name,
        archived: true,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      ),
    );
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
    assert(scope != null, 'ExpenseWorkProfileScope was not found.');
    return scope!.notifier!;
  }

  static ExpenseWorkProfileController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ExpenseWorkProfileScope>()
      ?.notifier;
}
