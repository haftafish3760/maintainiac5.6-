import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test(
    'restore plan returns record and download estimates without records',
    () async {
      final functions = _Functions(const {
        'recordCount': 12,
        'structuredBytes': 4096,
        'mediaBytes': 0,
        'manifestRevision': 4,
      });
      final plan = await MaintainiacRestorePlanClient(
        functions,
      ).fetch(organizationId: 'org-a', deviceId: 'device-a');

      expect(plan.recordCount, 12);
      expect(plan.totalDownloadBytes, 4096);
      expect(functions.name, 'getRestorePlan');
      expect(functions.data, {
        'organizationId': 'org-a',
        'deviceId': 'device-a',
      });
    },
  );

  test('restore plan fails closed on negative or malformed totals', () async {
    final client = MaintainiacRestorePlanClient(
      _Functions(const {
        'recordCount': -1,
        'structuredBytes': 0,
        'mediaBytes': 0,
        'manifestRevision': 1,
      }),
    );

    await expectLater(
      client.fetch(organizationId: 'org-a', deviceId: 'device-a'),
      throwsFormatException,
    );
  });

  test('restore plan rejects integers unsafe for cloud transport', () async {
    final client = MaintainiacRestorePlanClient(
      _Functions(const {
        'recordCount': 1,
        'structuredBytes': MaintainiacRestorePlanClient.maxSafeInteger + 1,
        'mediaBytes': 0,
        'manifestRevision': 1,
      }),
    );

    await expectLater(
      client.fetch(organizationId: 'org-a', deviceId: 'device-a'),
      throwsFormatException,
    );
  });

  test('restore plan rejects an unsafe combined download total', () async {
    final plan = await MaintainiacRestorePlanClient(
      _Functions(const {
        'recordCount': 1,
        'structuredBytes': MaintainiacRestorePlanClient.maxSafeInteger,
        'mediaBytes': 1,
        'manifestRevision': 1,
      }),
    ).fetch(organizationId: 'org-a', deviceId: 'device-a');

    expect(() => plan.totalDownloadBytes, throwsFormatException);
  });
}

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions(this.response);

  final Map<String, Object?> response;
  String? name;
  Map<String, Object?>? data;

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    this.name = name;
    this.data = data;
    return response;
  }
}
