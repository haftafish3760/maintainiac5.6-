import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'maintainiac_durable_record_store.dart';
import 'maintainiac_restore_contract.dart';

class MaintainiacRestoreEnvelope {
  MaintainiacRestoreEnvelope({
    required this.record,
    required this.schemaVersion,
    required this.contentSha256,
  });

  factory MaintainiacRestoreEnvelope.forRecord({
    required MaintainiacDurableRecord record,
    required int schemaVersion,
  }) => MaintainiacRestoreEnvelope(
    record: record,
    schemaVersion: schemaVersion,
    contentSha256: MaintainiacRestoreApplier.contentSha256For(record),
  );

  final MaintainiacDurableRecord record;
  final int schemaVersion;
  final String contentSha256;

  MaintainiacRestoreRecordVersion get version =>
      MaintainiacRestoreRecordVersion(
        revision: record.lifecycle.revision,
        schemaVersion: schemaVersion,
        contentSha256: contentSha256,
        isDeleted: record.lifecycle.isDeleted,
      );
}

class MaintainiacRestoreApplyResult {
  const MaintainiacRestoreApplyResult({required this.disposition, this.record});

  final MaintainiacRestoreDisposition disposition;
  final MaintainiacDurableRecord? record;
}

class MaintainiacRestoreApplier {
  const MaintainiacRestoreApplier({
    required MaintainiacDurableRecordStore store,
    required int maximumSupportedSchemaVersion,
  }) : _store = store,
       _maximumSupportedSchemaVersion = maximumSupportedSchemaVersion;

  final MaintainiacDurableRecordStore _store;
  final int _maximumSupportedSchemaVersion;

  Future<MaintainiacRestoreApplyResult> apply(
    MaintainiacRestoreEnvelope remote,
  ) async {
    if (!_verified(remote)) {
      return const MaintainiacRestoreApplyResult(
        disposition: MaintainiacRestoreDisposition.rejectCorrupt,
      );
    }
    final local = _store.recordFor(remote.record.module, remote.record.id);
    final localVersion = local == null
        ? null
        : MaintainiacRestoreRecordVersion(
            revision: local.lifecycle.revision,
            schemaVersion: remote.schemaVersion,
            contentSha256: contentSha256For(local),
            isDeleted: local.lifecycle.isDeleted,
          );
    final disposition = MaintainiacRestoreConflictPolicy.decide(
      remote: remote.version,
      local: localVersion,
      maximumSupportedSchemaVersion: _maximumSupportedSchemaVersion,
    );
    if (disposition != MaintainiacRestoreDisposition.applyRemote) {
      return MaintainiacRestoreApplyResult(
        disposition: disposition,
        record: local,
      );
    }
    try {
      final applied = await _store.applyRestoredRecord(
        remote.record,
        expectedLocalRevision: local?.lifecycle.revision,
      );
      return MaintainiacRestoreApplyResult(
        disposition: disposition,
        record: applied,
      );
    } on StateError {
      return MaintainiacRestoreApplyResult(
        disposition: MaintainiacRestoreDisposition.conflict,
        record: _store.recordFor(remote.record.module, remote.record.id),
      );
    }
  }

  bool _verified(MaintainiacRestoreEnvelope remote) {
    if (!remote.version.isValid ||
        remote.schemaVersion > _maximumSupportedSchemaVersion) {
      return false;
    }
    try {
      MaintainiacDurableRecord.fromMap(remote.record.toMap());
      return contentSha256For(remote.record) == remote.contentSha256;
    } catch (_) {
      return false;
    }
  }

  static String contentSha256For(MaintainiacDurableRecord record) {
    final canonical = jsonEncode(_canonicalValue(record.toMap()));
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}

Object? _canonicalValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is double && value.isFinite) return value;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is List) return value.map(_canonicalValue).toList(growable: false);
  if (value is Map) {
    final keys = value.keys.toList();
    if (keys.any((key) => key is! String)) {
      throw const FormatException('Restore record has a non-text field name.');
    }
    final sorted = keys.cast<String>()..sort();
    return {for (final key in sorted) key: _canonicalValue(value[key])};
  }
  throw const FormatException('Restore record contains unsupported data.');
}
