class MaintainiacFirestoreScopePolicy {
  const MaintainiacFirestoreScopePolicy._();

  static void validateWrite({
    required String path,
    required Map<String, Object?> data,
    required String? authenticatedUid,
  }) {
    final segments = path.split('/');
    if (segments.isEmpty) return;
    final uid = authenticatedUid?.trim() ?? '';
    if (segments.first == 'users') {
      if (segments.length < 3 || segments[1].trim().isEmpty) {
        throw const MaintainiacFirestoreScopeMismatch(
          'Cloud user path is invalid.',
        );
      }
      if (uid.isEmpty || segments[1] != uid) {
        throw const MaintainiacFirestoreScopeMismatch(
          'Cloud user record does not belong to the authenticated account.',
        );
      }
      _validateOptionalOwner(data, 'createdByUid', uid);
      _validateOptionalOwner(data, 'updatedByUid', uid);
      return;
    }
    if (segments.first != 'orgs') return;
    if (segments.length < 4 || segments[1].trim().isEmpty) {
      throw const MaintainiacFirestoreScopeMismatch(
        'Cloud organization path is invalid.',
      );
    }
    if (uid.isEmpty) {
      throw const MaintainiacFirestoreScopeMismatch(
        'Cloud organization writes require an authenticated account.',
      );
    }
    if (data['orgId']?.toString().trim() != segments[1]) {
      throw const MaintainiacFirestoreScopeMismatch(
        'Cloud document organization does not match its path.',
      );
    }
    final updatedByUid = data['updatedByUid']?.toString().trim() ?? '';
    if (updatedByUid.isEmpty || updatedByUid != uid) {
      throw const MaintainiacFirestoreScopeMismatch(
        'Cloud document does not belong to the authenticated account.',
      );
    }
  }

  static void _validateOptionalOwner(
    Map<String, Object?> data,
    String field,
    String uid,
  ) {
    if (data.containsKey(field) && data[field]?.toString().trim() != uid) {
      throw MaintainiacFirestoreScopeMismatch(
        'Cloud document $field does not match the authenticated account.',
      );
    }
  }
}

class MaintainiacFirestoreScopeMismatch implements Exception {
  const MaintainiacFirestoreScopeMismatch(this.message);

  final String message;

  @override
  String toString() => message;
}
