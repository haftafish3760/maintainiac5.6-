import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_cloud_audit_root.dart';

void main() {
  List<String> events(int count) => List.generate(
    count,
    (index) => '2026-08-01T00:00:00.000Z saved ${index + 1}',
  );

  test(
    'keeps a bounded root tail while retaining complete audit integrity',
    () {
      final values = events(100);
      final root = MaintainiacCloudAuditRoot.fromEvents(values);

      expect(root.eventCount, 100);
      expect(root.recentEvents, values.sublist(76));
      expect(root.verifies(values), isTrue);
      expect(root.verifies(values.skip(1)), isFalse);
    },
  );

  test('rejects changed recent audit evidence even when the count matches', () {
    final values = events(25);
    final root = MaintainiacCloudAuditRoot.fromEvents(values);
    final changed = [...values]..[24] = '2026-08-01T00:00:00.000Z changed';

    expect(root.verifies(changed), isFalse);
  });

  test('round trips only bounded cloud-safe fields', () {
    final root = MaintainiacCloudAuditRoot.fromEvents(events(2));
    final restored = MaintainiacCloudAuditRoot.fromMap(root.toMap());

    expect(restored.toMap(), root.toMap());
  });
}
