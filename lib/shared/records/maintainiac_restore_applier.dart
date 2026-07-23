import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'maintainiac_durable_record_store.dart';
import 'maintainiac_restore_contract.dart';
import 'maintainiac_restore_migration_registry.dart';
import 'maintainiac_restore_review_store.dart';

class MaintainiacRestoreEnvelope {
  MaintainiacRestoreEnvelope({
    required this.accountScopeId,
    required this.record,
    required this.schemaVersion,
    required this.contentSha256,
  });

  factory MaintainiacRestoreEnvelope.forRecord({
    required String accountScopeId,
    required MaintainiacDurableRecord record,
    required int schemaVersion,
  }) => MaintainiacRestoreEnvelope(
    accountScopeId: accountScopeId,
    record: record,
    schemaVersion: schemaVersion,
    contentSha256: MaintainiacRestoreApplier.contentSha256For(
      record,
      accountScopeId: accountScopeId,
    ),
  );

  final String accountScopeId;
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
  MaintainiacRestoreApplier({
    required MaintainiacDurableRecordStore store,
    required MaintainiacRestoreReviewStore reviewStore,
    required MaintainiacRestoreMigrationRegistry migrations,
    required String accountScopeId,
    required int maximumSupportedSchemaVersion,
  }) : _store = store,
       _reviewStore = reviewStore,
       _migrations = migrations,
       _accountScopeId = accountScopeId,
       _maximumSupportedSchemaVersion = maximumSupportedSchemaVersion;

  final MaintainiacDurableRecordStore _store;
  final MaintainiacRestoreReviewStore _reviewStore;
  final MaintainiacRestoreMigrationRegistry _migrations;
  final String _accountScopeId;
  final int _maximumSupportedSchemaVersion;

  Future<MaintainiacRestoreApplyResult> apply(
    MaintainiacRestoreEnvelope remote,
  ) async {
    if (!_verified(remote)) {
      if (_reviewable(remote)) {
        await _reviewStore.record(
          type: MaintainiacRestoreReviewType.corrupt,
          remote: _reviewRecord(remote),
        );
      }
      return const MaintainiacRestoreApplyResult(
        disposition: MaintainiacRestoreDisposition.rejectCorrupt,
      );
    }
    late final MaintainiacRestoreMigrationResult migration;
    try {
      migration = _migrations.migrate(
        record: remote.record,
        fromVersion: remote.schemaVersion,
        targetVersion: _maximumSupportedSchemaVersion,
      );
    } catch (_) {
      await _reviewStore.record(
        type: MaintainiacRestoreReviewType.migrationRequired,
        remote: _reviewRecord(remote),
      );
      return const MaintainiacRestoreApplyResult(
        disposition: MaintainiacRestoreDisposition.rejectCorrupt,
      );
    }
    if (migration.status == MaintainiacRestoreMigrationStatus.missing) {
      await _reviewStore.record(
        type: MaintainiacRestoreReviewType.migrationRequired,
        remote: _reviewRecord(remote),
      );
      return const MaintainiacRestoreApplyResult(
        disposition: MaintainiacRestoreDisposition.rejectCorrupt,
      );
    }
    final candidate = MaintainiacRestoreEnvelope.forRecord(
      accountScopeId: remote.accountScopeId,
      record: migration.record,
      schemaVersion: migration.schemaVersion,
    );
    final local = _store.recordFor(
      candidate.record.module,
      candidate.record.id,
    );
    final localVersion = local == null
        ? null
        : MaintainiacRestoreRecordVersion(
            revision: local.lifecycle.revision,
            schemaVersion: remote.schemaVersion,
            contentSha256: contentSha256For(
              local,
              accountScopeId: _accountScopeId,
            ),
            isDeleted: local.lifecycle.isDeleted,
          );
    final disposition = MaintainiacRestoreConflictPolicy.decide(
      remote: candidate.version,
      local: localVersion,
      maximumSupportedSchemaVersion: _maximumSupportedSchemaVersion,
    );
    if (disposition != MaintainiacRestoreDisposition.applyRemote) {
      if (disposition == MaintainiacRestoreDisposition.conflict) {
        await _reviewStore.record(
          type: MaintainiacRestoreReviewType.conflict,
          remote: _reviewRecord(candidate),
          local: _reviewRecord(
            MaintainiacRestoreEnvelope.forRecord(
              accountScopeId: _accountScopeId,
              record: local!,
              schemaVersion: candidate.schemaVersion,
            ),
          ),
        );
      }
      return MaintainiacRestoreApplyResult(
        disposition: disposition,
        record: local,
      );
    }
    try {
      final applied = await _store.applyRestoredRecord(
        candidate.record,
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

  bool _reviewable(MaintainiacRestoreEnvelope remote) {
    if (remote.accountScopeId != _accountScopeId ||
        !_validToken(remote.accountScopeId)) {
      return false;
    }
    try {
      MaintainiacDurableRecord.fromMap(remote.record.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  MaintainiacRestoreReviewRecord _reviewRecord(
    MaintainiacRestoreEnvelope envelope,
  ) => MaintainiacRestoreReviewRecord(
    accountScopeId: envelope.accountScopeId,
    record: envelope.record,
    schemaVersion: envelope.schemaVersion,
    contentSha256: envelope.contentSha256,
  );

  bool _verified(MaintainiacRestoreEnvelope remote) {
    if (remote.accountScopeId != _accountScopeId ||
        !_validToken(remote.accountScopeId) ||
        !remote.version.isValid ||
        remote.schemaVersion > _maximumSupportedSchemaVersion) {
      return false;
    }
    try {
      MaintainiacDurableRecord.fromMap(remote.record.toMap());
      return contentSha256For(
            remote.record,
            accountScopeId: remote.accountScopeId,
          ) ==
          remote.contentSha256;
    } catch (_) {
      return false;
    }
  }

  static String contentSha256For(
    MaintainiacDurableRecord record, {
    required String accountScopeId,
  }) {
    if (!_validToken(accountScopeId)) {
      throw const FormatException('Restore account scope is invalid.');
    }
    final canonical = jsonEncode(
      _canonicalValue({
        'accountScopeId': accountScopeId,
        'record': record.toMap(),
      }),
    );
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}

bool _validToken(String value) =>
    RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value);

Object? _canonicalValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is double && value.isFinite) {
    return value == value.truncateToDouble() ? value.toInt() : value;
  }
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
