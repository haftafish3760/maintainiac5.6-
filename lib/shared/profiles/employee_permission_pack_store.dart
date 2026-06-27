import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EmployeePermissionPack {
  const EmployeePermissionPack({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.allowedRoleNamesByPermission,
    required this.allowedEmployeeIdsByPermission,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final Set<String> permissions;
  final Map<String, Set<String>> allowedRoleNamesByPermission;
  final Map<String, Set<String>> allowedEmployeeIdsByPermission;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeePermissionPack copyWith({
    String? id,
    String? name,
    String? description,
    Set<String>? permissions,
    Map<String, Set<String>>? allowedRoleNamesByPermission,
    Map<String, Set<String>>? allowedEmployeeIdsByPermission,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeePermissionPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      allowedRoleNamesByPermission:
          allowedRoleNamesByPermission ?? this.allowedRoleNamesByPermission,
      allowedEmployeeIdsByPermission:
          allowedEmployeeIdsByPermission ?? this.allowedEmployeeIdsByPermission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'permissions': permissions.toList()..sort(),
    'allowedRoleNamesByPermission': _targetMapToMap(
      allowedRoleNamesByPermission,
    ),
    'allowedEmployeeIdsByPermission': _targetMapToMap(
      allowedEmployeeIdsByPermission,
    ),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory EmployeePermissionPack.fromMap(Map<dynamic, dynamic> map) {
    return EmployeePermissionPack(
      id: _string(map['id'], fallback: _newPackId()),
      name: _string(map['name'], fallback: 'Permission Pack'),
      description: _string(map['description']),
      permissions: _stringSet(map['permissions']),
      allowedRoleNamesByPermission: _targetMapFromMap(
        map['allowedRoleNamesByPermission'],
      ),
      allowedEmployeeIdsByPermission: _targetMapFromMap(
        map['allowedEmployeeIdsByPermission'],
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  factory EmployeePermissionPack.create({
    required String name,
    required String description,
    required Set<String> permissions,
    required Map<String, Set<String>> allowedRoleNamesByPermission,
    required Map<String, Set<String>> allowedEmployeeIdsByPermission,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return EmployeePermissionPack(
      id: _newPackId(timestamp),
      name: name.trim(),
      description: description.trim(),
      permissions: {...permissions},
      allowedRoleNamesByPermission: _copyTargetMap(
        allowedRoleNamesByPermission,
      ),
      allowedEmployeeIdsByPermission: _copyTargetMap(
        allowedEmployeeIdsByPermission,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

class EmployeePermissionPackController extends ChangeNotifier {
  EmployeePermissionPackController._({
    required Box<dynamic>? box,
    required List<EmployeePermissionPack> packs,
  }) : _box = box,
       _packs = packs;

  EmployeePermissionPackController.memory({List<EmployeePermissionPack>? packs})
    : _box = null,
      _packs = packs ?? const [];

  static const boxName = 'employee_permission_packs_v1';
  static const _packsKey = 'packs';

  final Box<dynamic>? _box;
  List<EmployeePermissionPack> _packs;

  List<EmployeePermissionPack> get packs => List.unmodifiable(_packs);

  static Future<EmployeePermissionPackController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return EmployeePermissionPackController._(
      box: box,
      packs: _packsFromBox(box.get(_packsKey)),
    );
  }

  static Future<EmployeePermissionPackController> createOrMemory() async {
    try {
      final homePath = (Hive as dynamic).homePath;
      if (homePath == null && !Hive.isBoxOpen(boxName)) {
        return EmployeePermissionPackController.memory();
      }
      return await create();
    } catch (_) {
      return EmployeePermissionPackController.memory();
    }
  }

  Future<void> savePack(EmployeePermissionPack pack) async {
    final normalized = pack.copyWith(updatedAt: DateTime.now());
    _packs = [
      normalized,
      for (final existing in _packs)
        if (existing.id != normalized.id) existing,
    ]..sort((a, b) => a.name.compareTo(b.name));
    await _persist();
  }

  Future<void> _persist() async {
    await _box?.put(_packsKey, [for (final pack in _packs) pack.toMap()]);
    notifyListeners();
  }
}

List<EmployeePermissionPack> _packsFromBox(Object? value) {
  if (value is! Iterable) return const [];
  final packs = value
      .whereType<Map>()
      .map(EmployeePermissionPack.fromMap)
      .toList();
  packs.sort((a, b) => a.name.compareTo(b.name));
  return packs;
}

Map<String, Set<String>> _copyTargetMap(Map<String, Set<String>> source) {
  return {
    for (final entry in source.entries) entry.key: {...entry.value},
  };
}

Map<String, List<String>> _targetMapToMap(Map<String, Set<String>> source) {
  return {
    for (final entry in source.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value.toList()..sort(),
  };
}

Map<String, Set<String>> _targetMapFromMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && _stringSet(entry.value).isNotEmpty)
        (entry.key as String): _stringSet(entry.value),
  };
}

Set<String> _stringSet(Object? value) {
  if (value is! Iterable) return {};
  return value.whereType<String>().map((item) => item.trim()).toSet()
    ..removeWhere((item) => item.isEmpty);
}

String _string(Object? value, {String fallback = ''}) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? fallback : text;
}

DateTime _date(Object? value) {
  return value is String
      ? DateTime.tryParse(value) ?? DateTime.now()
      : DateTime.now();
}

String _newPackId([DateTime? now]) {
  return 'permission-pack-${(now ?? DateTime.now()).microsecondsSinceEpoch}';
}
