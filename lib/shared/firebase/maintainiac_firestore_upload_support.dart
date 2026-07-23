part of 'maintainiac_firestore_upload_queue.dart';

bool _maintainiacRecordBelongsToAccount(
  MaintainiacFirestoreQueuedDocument record,
  String authenticatedUid,
) {
  try {
    MaintainiacFirestoreScopePolicy.validateWrite(
      path: record.path,
      data: record.data,
      authenticatedUid: authenticatedUid,
    );
    return true;
  } on MaintainiacFirestoreScopeMismatch {
    return false;
  }
}

String _maintainiacBatchSha256(List<MaintainiacFirestoreQueuedDocument> batch) {
  return sha256
      .convert(utf8.encode(_maintainiacCanonicalBatch(batch)))
      .toString();
}

int _maintainiacBatchBytes(List<MaintainiacFirestoreQueuedDocument> batch) {
  return utf8.encode(_maintainiacCanonicalBatch(batch)).length;
}

String _maintainiacCanonicalBatch(
  List<MaintainiacFirestoreQueuedDocument> batch,
) {
  return jsonEncode([
    for (final record in batch)
      {
        'path': record.path,
        'data': _maintainiacCanonicalSyncValue(record.data),
      },
  ]);
}

Object? _maintainiacCanonicalSyncValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is num && value.isFinite) return value;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is List) {
    return value.map(_maintainiacCanonicalSyncValue).toList(growable: false);
  }
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw const FormatException('Cloud sync batch has a non-text field.');
    }
    final keys = value.keys.cast<String>().toList()..sort();
    return {
      for (final key in keys) key: _maintainiacCanonicalSyncValue(value[key]),
    };
  }
  throw const FormatException('Cloud sync batch contains unsupported data.');
}
