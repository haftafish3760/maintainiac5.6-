import 'package:flutter_test/flutter_test.dart';

import 'support/calendar_qa/calendar_projection_scenario_suite.dart';
import 'support/qa_harness/qa_harness.dart';

void main() {
  test('calendar scenario harness passes focused smoke volume', () async {
    final report =
        await QaHarness(
          domain: 'calendar',
          suites: const [CalendarProjectionScenarioSuite()],
        ).run(
          const QaContext(
            strict: true,
            redactor: QaRedactor(),
            profile: 'calendar_smoke',
            maxGeneratedCases: 500,
          ),
        );

    expect(report.checked, greaterThanOrEqualTo(2000));
    expect(report.hasBlockingFailures, isFalse);
    expect(report.actualFailureCount, 0);
  });
}
