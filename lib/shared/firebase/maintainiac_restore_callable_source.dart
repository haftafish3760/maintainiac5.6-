import 'maintainiac_callable_functions.dart';
import 'maintainiac_durable_cloud_restore_gateway.dart';

class MaintainiacRestoreAuthorization {
  const MaintainiacRestoreAuthorization({
    required this.organizationId,
    required this.deviceId,
    required this.sessionId,
    required this.authorizationToken,
  });

  final String organizationId;
  final String deviceId;
  final String sessionId;
  final String authorizationToken;

  void validate() {
    if (!_token(organizationId) ||
        !_token(deviceId) ||
        !_token(sessionId) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(authorizationToken)) {
      throw const FormatException('Restore authorization is invalid.');
    }
  }
}

class CallableMaintainiacDurableCloudRecordSource
    implements MaintainiacDurableCloudRecordSource {
  CallableMaintainiacDurableCloudRecordSource({
    required MaintainiacCallableFunctionClient functions,
    required MaintainiacRestoreAuthorization authorization,
  }) : _functions = functions,
       _authorization = authorization {
    authorization.validate();
  }

  final MaintainiacCallableFunctionClient _functions;
  final MaintainiacRestoreAuthorization _authorization;

  @override
  Future<List<MaintainiacDurableCloudDocument>> fetchPage({
    required String organizationId,
    required String uid,
    required int limit,
    String? afterRecordKey,
  }) async {
    if (organizationId != _authorization.organizationId ||
        !_token(uid) ||
        limit < 1 ||
        limit > 10 ||
        (afterRecordKey != null &&
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(afterRecordKey))) {
      throw const FormatException('Restore page request is invalid.');
    }
    final response = await _functions.call(
      name: 'fetchRestoreRecordPage',
      data: {
        'organizationId': _authorization.organizationId,
        'deviceId': _authorization.deviceId,
        'sessionId': _authorization.sessionId,
        'authorizationToken': _authorization.authorizationToken,
        'limit': limit,
        'afterRecordKey': ?afterRecordKey,
      },
    );
    final rawDocuments = response['documents'];
    if (rawDocuments is! List || rawDocuments.length > limit) {
      throw const FormatException('Restore page response is malformed.');
    }
    final documents = <MaintainiacDurableCloudDocument>[];
    for (final raw in rawDocuments) {
      if (raw is! Map ||
          raw.keys.any((key) => key is! String) ||
          raw.keys.toSet().difference(const {'id', 'data'}).isNotEmpty ||
          raw.keys.length != 2 ||
          raw['id'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(raw['id'] as String) ||
          raw['data'] is! Map ||
          (raw['data'] as Map).keys.any((key) => key is! String)) {
        throw const FormatException('Restore document is malformed.');
      }
      documents.add(
        MaintainiacDurableCloudDocument(
          id: raw['id'] as String,
          data: Map<String, Object?>.unmodifiable(
            Map<String, Object?>.from(raw['data'] as Map),
          ),
        ),
      );
    }
    return List.unmodifiable(documents);
  }
}

bool _token(String value) => RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value);
