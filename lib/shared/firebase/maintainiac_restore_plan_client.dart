import 'maintainiac_callable_functions.dart';

class MaintainiacCloudRestorePlan {
  const MaintainiacCloudRestorePlan({
    required this.recordCount,
    required this.structuredBytes,
    required this.mediaBytes,
    required this.manifestRevision,
  });

  final int recordCount;
  final int structuredBytes;
  final int mediaBytes;
  final int manifestRevision;

  int get totalDownloadBytes => structuredBytes + mediaBytes;
}

class MaintainiacRestorePlanClient {
  const MaintainiacRestorePlanClient(this._functions);

  final MaintainiacCallableFunctionClient _functions;

  Future<MaintainiacCloudRestorePlan> fetch({
    required String organizationId,
    required String deviceId,
  }) async {
    _token(organizationId, 'organizationId');
    _token(deviceId, 'deviceId');
    final result = await _functions.call(
      name: 'getRestorePlan',
      data: {'organizationId': organizationId, 'deviceId': deviceId},
    );
    final recordCount = _nonNegativeInt(result, 'recordCount');
    final structuredBytes = _nonNegativeInt(result, 'structuredBytes');
    final mediaBytes = _nonNegativeInt(result, 'mediaBytes');
    final manifestRevision = _nonNegativeInt(result, 'manifestRevision');
    return MaintainiacCloudRestorePlan(
      recordCount: recordCount,
      structuredBytes: structuredBytes,
      mediaBytes: mediaBytes,
      manifestRevision: manifestRevision,
    );
  }

  void _token(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
      throw ArgumentError.value(value, name);
    }
  }

  int _nonNegativeInt(Map<String, Object?> result, String key) {
    final value = result[key];
    if (value is! int || value < 0) {
      throw const FormatException('Restore plan is malformed.');
    }
    return value;
  }
}
