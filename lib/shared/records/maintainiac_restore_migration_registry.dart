import 'dart:convert';

import 'maintainiac_durable_record_store.dart';

typedef MaintainiacRestoreMigration =
    MaintainiacDurableRecord Function(MaintainiacDurableRecord record);

enum MaintainiacRestoreMigrationStatus { current, migrated, missing }

class MaintainiacRestoreMigrationStep {
  const MaintainiacRestoreMigrationStep({
    required this.module,
    required this.fromVersion,
    required this.migrate,
  });

  final String module;
  final int fromVersion;
  final MaintainiacRestoreMigration migrate;
}

class MaintainiacRestoreMigrationResult {
  const MaintainiacRestoreMigrationResult({
    required this.status,
    required this.record,
    required this.schemaVersion,
  });

  final MaintainiacRestoreMigrationStatus status;
  final MaintainiacDurableRecord record;
  final int schemaVersion;
}

class MaintainiacRestoreMigrationRegistry {
  MaintainiacRestoreMigrationRegistry(
    Iterable<MaintainiacRestoreMigrationStep> steps,
  ) : _steps = _build(steps);

  final Map<String, MaintainiacRestoreMigrationStep> _steps;

  MaintainiacRestoreMigrationResult migrate({
    required MaintainiacDurableRecord record,
    required int fromVersion,
    required int targetVersion,
  }) {
    if (fromVersion < 1 || targetVersion < 1 || fromVersion > targetVersion) {
      return MaintainiacRestoreMigrationResult(
        status: MaintainiacRestoreMigrationStatus.missing,
        record: record,
        schemaVersion: fromVersion,
      );
    }
    if (fromVersion == targetVersion) {
      return MaintainiacRestoreMigrationResult(
        status: MaintainiacRestoreMigrationStatus.current,
        record: record,
        schemaVersion: fromVersion,
      );
    }
    var current = record;
    var version = fromVersion;
    while (version < targetVersion) {
      final step = _steps[_key(current.module, version)];
      if (step == null) {
        return MaintainiacRestoreMigrationResult(
          status: MaintainiacRestoreMigrationStatus.missing,
          record: record,
          schemaVersion: fromVersion,
        );
      }
      final migrated = step.migrate(current);
      final verified = MaintainiacDurableRecord.fromMap(migrated.toMap());
      if (verified.module != current.module ||
          verified.id != current.id ||
          jsonEncode(verified.lifecycle.toMap()) !=
              jsonEncode(current.lifecycle.toMap())) {
        throw StateError(
          'Restore migrations must preserve record identity and lifecycle.',
        );
      }
      current = verified;
      version += 1;
    }
    return MaintainiacRestoreMigrationResult(
      status: MaintainiacRestoreMigrationStatus.migrated,
      record: current,
      schemaVersion: version,
    );
  }

  static Map<String, MaintainiacRestoreMigrationStep> _build(
    Iterable<MaintainiacRestoreMigrationStep> steps,
  ) {
    final result = <String, MaintainiacRestoreMigrationStep>{};
    for (final step in steps) {
      if (!_token(step.module) ||
          step.fromVersion < 1 ||
          result.containsKey(_key(step.module, step.fromVersion))) {
        throw ArgumentError('Restore migration steps must be unique and safe.');
      }
      result[_key(step.module, step.fromVersion)] = step;
    }
    return Map.unmodifiable(result);
  }

  static String _key(String module, int version) => '$module:$version';
}

bool _token(String value) =>
    value.isNotEmpty && value == value.trim() && !value.contains(':');
