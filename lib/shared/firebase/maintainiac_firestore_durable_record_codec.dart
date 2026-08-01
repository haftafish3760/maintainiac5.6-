import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../records/maintainiac_durable_record_store.dart';
import '../records/maintainiac_cloud_audit_root.dart';
import '../records/maintainiac_restore_applier.dart';
import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_upload_queue.dart';

/// Canonical Firestore envelope for module records whose complete payload is
/// approved for the generic cloud path. Sensitive modules keep their stricter
/// dedicated document builders while sharing the same local lifecycle.
class MaintainiacFirestoreDurableRecordCodec {
  const MaintainiacFirestoreDurableRecordCodec._();

  static const _keys = {
    'schema',
    'recordKey',
    'module',
    'localRecordId',
    'accountScopeId',
    'recordSchemaVersion',
    'contentSha256',
    'privateToOwner',
    'orgId',
    'createdByUid',
    'updatedByUid',
    'localRevision',
    'recordState',
    'createdAt',
    'updatedAt',
    'deletedAt',
    'auditEvents',
    'recordPayload',
  };

  static MaintainiacFirestoreDocumentDraft encode({
    required String organizationId,
    required String uid,
    required String accountScopeId,
    required int schemaVersion,
    required MaintainiacDurableRecord record,
  }) {
    _token(organizationId, 'organizationId');
    _token(uid, 'uid');
    _token(accountScopeId, 'accountScopeId');
    if (accountScopeId != '$organizationId.$uid') {
      throw ArgumentError.value(
        accountScopeId,
        'accountScopeId',
        'Cloud records must use the authenticated organization account scope.',
      );
    }
    if (schemaVersion < 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    final recordKey = _recordKey(record.module, record.id);
    final envelope = MaintainiacRestoreEnvelope.forRecord(
      accountScopeId: accountScopeId,
      record: record,
      schemaVersion: schemaVersion,
    );
    final lifecycle = record.lifecycle;
    final draft = MaintainiacFirestoreDocumentDraft(
      path: 'orgs/$organizationId/records/$recordKey',
      data: {
        'schema': 'maintainiac_durable_record_v1',
        'recordKey': recordKey,
        'module': record.module,
        'localRecordId': record.id,
        'accountScopeId': accountScopeId,
        'recordSchemaVersion': schemaVersion,
        'contentSha256': envelope.contentSha256,
        'privateToOwner': true,
        'orgId': organizationId,
        'createdByUid': uid,
        'updatedByUid': uid,
        'localRevision': lifecycle.revision,
        'recordState': lifecycle.state.name,
        'createdAt': lifecycle.createdAt.toUtc().toIso8601String(),
        'updatedAt': lifecycle.updatedAt.toUtc().toIso8601String(),
        'deletedAt': lifecycle.deletedAt?.toUtc().toIso8601String(),
        'auditEvents': lifecycle.auditEvents,
        'recordPayload': record.payload,
      },
    );
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    return draft;
  }

  /// Shared v2 migration input. The current v1 encoder remains readable while
  /// the server-side paged archive transition is rolled out.
  static MaintainiacCloudAuditRoot boundedAuditRootFor(
    MaintainiacDurableRecord record,
  ) => MaintainiacCloudAuditRoot.fromEvents(record.lifecycle.auditEvents);

  /// A v2 root keeps these three bounded fields; the archive supplies the
  /// complete event list before this record is restored locally.
  static Map<String, Object> boundedAuditRootFields(
    MaintainiacDurableRecord record,
  ) => boundedAuditRootFor(record).toMap();

  static MaintainiacRestoreEnvelope decode({
    required String expectedOrganizationId,
    required String expectedUid,
    required String expectedAccountScopeId,
    required String documentId,
    required Map<dynamic, dynamic> data,
  }) {
    if (expectedAccountScopeId != '$expectedOrganizationId.$expectedUid') {
      throw const FormatException('Cloud durable record scope is invalid.');
    }
    if (data.keys.any((key) => key is! String) ||
        data.keys.toSet().difference(_keys).isNotEmpty ||
        _keys.difference(data.keys.toSet()).isNotEmpty ||
        data['schema'] != 'maintainiac_durable_record_v1' ||
        data['recordKey'] != documentId ||
        data['orgId'] != expectedOrganizationId ||
        data['createdByUid'] != expectedUid ||
        data['updatedByUid'] != expectedUid ||
        data['accountScopeId'] != expectedAccountScopeId ||
        data['privateToOwner'] != true ||
        data['module'] is! String ||
        data['localRecordId'] is! String ||
        data['recordSchemaVersion'] is! int ||
        (data['recordSchemaVersion'] as int? ?? 0) < 1 ||
        data['recordPayload'] is! Map ||
        data['auditEvents'] is! List ||
        (data['auditEvents'] as List?)?.any((event) => event is! String) ==
            true ||
        data['contentSha256'] is! String ||
        !RegExp(
          r'^[a-f0-9]{64}$',
        ).hasMatch(data['contentSha256']?.toString() ?? '')) {
      throw const FormatException('Cloud durable record is malformed.');
    }
    final module = data['module'] as String;
    final localRecordId = data['localRecordId'] as String;
    if (_recordKey(module, localRecordId) != documentId) {
      throw const FormatException('Cloud durable record identity is invalid.');
    }
    late final MaintainiacDurableRecord record;
    try {
      record = MaintainiacDurableRecord.fromMap({
        'module': module,
        'id': localRecordId,
        'payload': data['recordPayload'],
        'lifecycle': {
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'revision': data['localRevision'],
          'state': data['recordState'],
          'deletedAt': data['deletedAt'],
          'auditEvents': data['auditEvents'],
        },
      });
    } catch (_) {
      throw const FormatException('Cloud durable record is malformed.');
    }
    final envelope = MaintainiacRestoreEnvelope(
      accountScopeId: expectedAccountScopeId,
      record: record,
      schemaVersion: data['recordSchemaVersion'] as int,
      contentSha256: data['contentSha256'] as String,
    );
    if (MaintainiacRestoreApplier.contentSha256For(
          record,
          accountScopeId: expectedAccountScopeId,
        ) !=
        envelope.contentSha256) {
      throw const FormatException('Cloud durable record hash is invalid.');
    }
    return envelope;
  }

  static String _recordKey(String module, String id) =>
      sha256.convert(utf8.encode('$module\u0000$id')).toString();

  static void _token(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'Unsafe cloud identity.');
    }
  }
}
