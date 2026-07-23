import 'package:cloud_firestore/cloud_firestore.dart';

import '../records/maintainiac_restore_applier.dart';
import 'maintainiac_cloud_identity.dart';
import 'maintainiac_firestore_durable_record_codec.dart';

class MaintainiacDurableCloudDocument {
  const MaintainiacDurableCloudDocument({required this.id, required this.data});

  final String id;
  final Map<String, Object?> data;
}

abstract interface class MaintainiacDurableCloudRecordSource {
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  });
}

class FirebaseMaintainiacDurableCloudRecordSource
    implements MaintainiacDurableCloudRecordSource {
  FirebaseMaintainiacDurableCloudRecordSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('orgs/$organizationId/records')
        .where('createdByUid', isEqualTo: uid)
        .where('privateToOwner', isEqualTo: true)
        .orderBy('recordKey')
        .limit(limit);
    if (afterRecordKey != null) {
      query = query.startAfter([afterRecordKey]);
    }
    final snapshot = await query.get();
    return List.unmodifiable([
      for (final document in snapshot.docs)
        MaintainiacDurableCloudDocument(
          id: document.id,
          data: Map<String, Object?>.unmodifiable(document.data()),
        ),
    ]);
  }
}

class MaintainiacDurableCloudRestorePage {
  const MaintainiacDurableCloudRestorePage({
    required this.records,
    required this.hasMore,
    this.nextCursor,
  });

  final List<MaintainiacRestoreEnvelope> records;
  final bool hasMore;
  final String? nextCursor;
}

class MaintainiacDurableCloudRestoreGateway {
  MaintainiacDurableCloudRestoreGateway({
    required MaintainiacDurableCloudRecordSource source,
    required MaintainiacCloudIdentityProvider identityProvider,
  }) : _source = source,
       _identityProvider = identityProvider;

  static const int defaultPageSize = 50;
  static const int maximumPageSize = 100;

  final MaintainiacDurableCloudRecordSource _source;
  final MaintainiacCloudIdentityProvider _identityProvider;

  Future<MaintainiacDurableCloudRestorePage> fetchPage({
    required String organizationId,
    int pageSize = defaultPageSize,
    String? afterRecordKey,
  }) async {
    final uid = _authenticatedUid();
    _token(organizationId, 'organizationId');
    if (pageSize < 1 || pageSize > maximumPageSize) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    if (afterRecordKey != null &&
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(afterRecordKey)) {
      throw ArgumentError.value(afterRecordKey, 'afterRecordKey');
    }
    final documents = await _source.fetchPage(
      organizationId: organizationId,
      uid: uid,
      limit: pageSize + 1,
      afterRecordKey: afterRecordKey,
    );
    final sorted = [...documents]..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.map((document) => document.id).toSet().length != sorted.length ||
        sorted.any(
          (document) =>
              !RegExp(r'^[a-f0-9]{64}$').hasMatch(document.id) ||
              (afterRecordKey != null &&
                  document.id.compareTo(afterRecordKey) <= 0),
        )) {
      throw const FormatException('Cloud restore page identity is invalid.');
    }
    final hasMore = sorted.length > pageSize;
    final page = sorted.take(pageSize).toList(growable: false);
    final accountScopeId = '$organizationId.$uid';
    final records = [
      for (final document in page)
        MaintainiacFirestoreDurableRecordCodec.decode(
          expectedOrganizationId: organizationId,
          expectedUid: uid,
          expectedAccountScopeId: accountScopeId,
          documentId: document.id,
          data: document.data,
        ),
    ];
    return MaintainiacDurableCloudRestorePage(
      records: List.unmodifiable(records),
      hasMore: hasMore,
      nextCursor: hasMore && page.isNotEmpty ? page.last.id : null,
    );
  }

  String _authenticatedUid() {
    final uid = _identityProvider.currentUid?.trim() ?? '';
    _token(uid, 'uid');
    return uid;
  }

  void _token(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value)) {
      throw StateError('Cloud restore requires a valid $name.');
    }
  }
}
