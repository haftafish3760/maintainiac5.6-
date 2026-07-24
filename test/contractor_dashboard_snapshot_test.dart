import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_dashboard_models.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_dashboard_snapshot.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';

void main() {
  test(
    'contractor snapshot uses scheduled local jobs and honest zero states',
    () {
      final now = DateTime(2026, 7, 23, 10);
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          MaintainiacJobRecord(
            id: 'job_today',
            number: '1042',
            name: 'Service call',
            address: 'Main Street',
            scheduledStart: DateTime(2026, 7, 23, 13, 30),
            createdAt: now,
            updatedAt: now,
          ),
          MaintainiacJobRecord(
            id: 'job_tomorrow',
            number: '1043',
            name: 'Estimate',
            scheduledStart: DateTime(2026, 7, 24, 9),
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      addTearDown(jobs.dispose);

      final snapshot = ContractorDashboardSnapshot.fromControllers(
        now: now,
        vehicleCount: 2,
        milesToday: 14,
        dayStarted: true,
        jobs: jobs,
      );

      expect(_value(snapshot.scaleMetrics, 'Open jobs'), '2');
      expect(_value(snapshot.scaleMetrics, 'Vehicles'), '2');
      expect(_value(snapshot.operationsMetrics, 'Day status'), 'Active');
      expect(_value(snapshot.operationsMetrics, 'Jobs today'), '1');
      expect(_value(snapshot.businessMetrics, 'Payments this week'), r'$0.00');
      expect(_value(snapshot.businessMetrics, 'Expenses this week'), r'$0.00');
      expect(_value(snapshot.businessMetrics, 'Miles today'), '14');
      expect(snapshot.jobsToday, hasLength(1));
      expect(snapshot.jobsToday.single.title, 'Service call');
      expect(snapshot.jobsToday.single.time, '1:30 PM');
      expect(snapshot.jobsToday.single.summary, contains('Job 1042'));
      expect(snapshot.attentionItems, isEmpty);
    },
  );
}

String _value(List<ContractorMetric> metrics, String label) {
  return metrics.singleWhere((metric) => metric.label == label).value;
}
