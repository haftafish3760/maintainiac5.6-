// Calendar high-volume deterministic projection regression. Reuses the shared
// QA harness without changing its behavior for inventory or other domains.

import 'package:flutter_test/flutter_test.dart';

import 'support/calendar_qa/calendar_projection_scenario_suite.dart';
import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'calendar projection harness passes bounded high-volume replay',
    () async {
      final report =
          await QaHarness(
            domain: 'calendar',
            suites: const [CalendarProjectionScenarioSuite()],
          ).run(
            const QaContext(
              strict: true,
              redactor: QaRedactor(),
              profile: 'calendar_projection_stress',
              maxGeneratedCases: 5000,
            ),
          );

      expect(report.checked, greaterThanOrEqualTo(20000));
      expect(report.hasBlockingFailures, isFalse);
      expect(report.actualFailureCount, 0);
    },
  );
}
