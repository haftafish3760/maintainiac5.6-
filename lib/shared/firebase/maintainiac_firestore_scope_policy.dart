class MaintainiacFirestoreScopePolicy {
  const MaintainiacFirestoreScopePolicy._();

  static void validateWrite({
    required String path,
    required Map<String, Object?> data,
    required String? authenticatedUid,
  }) {
    final segments = path.split('/');
    if (segments.isEmpty || segments.first != 'orgs') return;
    if (segments.length < 4 || segments[1].trim().isEmpty) {
      throw const MaintainiacFirestoreScopeMismatch(
        'Cloud organization path is invalid.',
      );
    }
    final uid = authenticatedUid?.trim() ?? '';
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
}

class MaintainiacFirestoreScopeMismatch implements Exception {
  const MaintainiacFirestoreScopeMismatch(this.message);

  final String message;

  @override
  String toString() => message;
}
