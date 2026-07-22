import '../../../shared/firebase/maintainiac_callable_functions.dart';

class ExpenseCloudProofUploadGrant {
  const ExpenseCloudProofUploadGrant({
    required this.id,
    required this.maximumBytes,
    required this.expiresAt,
  });

  final String id;
  final int maximumBytes;
  final DateTime expiresAt;

  bool get isUsable => DateTime.now().toUtc().isBefore(expiresAt);
}

/// Client boundary for the server-issued, short-lived upload grant. The app
/// never writes its own Firestore grant document.
abstract interface class ExpenseCloudProofUploadGrantIssuer {
  Future<ExpenseCloudProofUploadGrant> issue({
    required String organizationId,
    required String proofId,
    required int requestedBytes,
  });
}

class FirebaseExpenseCloudProofUploadGrantIssuer
    implements ExpenseCloudProofUploadGrantIssuer {
  FirebaseExpenseCloudProofUploadGrantIssuer({
    MaintainiacCallableFunctionClient? client,
  }) : _client = client ?? FirebaseMaintainiacCallableFunctionClient();

  final MaintainiacCallableFunctionClient _client;

  @override
  Future<ExpenseCloudProofUploadGrant> issue({
    required String organizationId,
    required String proofId,
    required int requestedBytes,
  }) async {
    final data = await _client.call(
      name: 'issueExpenseProofUploadGrant',
      data: {
        'organizationId': organizationId,
        'proofId': proofId,
        'requestedBytes': requestedBytes,
      },
    );
    final id = '${data['grantId'] ?? ''}'.trim();
    final maximumBytes = data['maxBytes'] is int ? data['maxBytes'] as int : 0;
    final expiresAt = DateTime.tryParse('${data['expiresAt'] ?? ''}')?.toUtc();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(id) ||
        maximumBytes <= 0 ||
        expiresAt == null ||
        !DateTime.now().toUtc().isBefore(expiresAt)) {
      throw StateError('The proof upload grant is invalid or expired.');
    }
    return ExpenseCloudProofUploadGrant(
      id: id,
      maximumBytes: maximumBytes,
      expiresAt: expiresAt,
    );
  }
}
