import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../records/maintainiac_durable_record_store.dart';
import '../records/maintainiac_restore_applier.dart';
import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_upload_queue.dart';

/// Canonical Firestore envelope for module records whose complete payload is
/// approved for the generic cloud path. Sensitive modules keep their stricter
/// dedicated document builders while sharing the same local lifecycle.
class MaintainiacFirestoreDurableRecordCodec {
  const MaintainiacFirestoreDurableRecordCodec._();

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

  static MaintainiacRestoreEnvelope decode({
    required String expectedOrganizationId,
    required String expectedUid,
    required String expectedAccountScopeId,
    required String documentId,
    required Map<dynamic, dynamic> data,
  }) {
    if (data['schema'] != 'maintainiac_durable_record_v1' ||
        data['recordKey'] != documentId ||
        data['orgId'] != expectedOrganizationId ||
        data['createdByUid'] != expectedUid ||
        data['accountScopeId'] != expectedAccountScopeId ||
        data['module'] is! String ||
        data['localRecordId'] is! String ||
        data['recordSchemaVersion'] is! int ||
        data['recordPayload'] is! Map ||
        data['auditEvents'] is! List ||
        data['contentSha256'] is! String) {
      throw const FormatException('Cloud durable record is malformed.');
    }
    final module = data['module'] as String;
    final localRecordId = data['localRecordId'] as String;
    if (_recordKey(module, localRecordId) != documentId) {
      throw const FormatException('Cloud durable record identity is invalid.');
    }
    final record = MaintainiacDurableRecord.fromMap({
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
    return MaintainiacRestoreEnvelope(
      accountScopeId: expectedAccountScopeId,
      record: record,
      schemaVersion: data['recordSchemaVersion'] as int,
      contentSha256: data['contentSha256'] as String,
    );
  }

  static String _recordKey(String module, String id) =>
      sha256.convert(utf8.encode('$module\u0000$id')).toString();

  static void _token(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'Unsafe cloud identity.');
    }
  }
}
