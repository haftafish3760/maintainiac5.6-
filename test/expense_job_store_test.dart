import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_job_store.dart';

void main() {
  test('job records are durable, contextual, and archivable', () async {
    final jobs = ExpenseJobController.memory();
    final saved = await jobs.save(
      ExpenseJobRecord(
        id: '',
        name: 'Kitchen repair',
        workProfileId: 'contractor',
        vehicleId: 'truck-1',
        customerReference: 'estimate-42',
        createdAt: DateTime(2026, 7, 15),
        updatedAt: DateTime(2026, 7, 15),
      ),
    );

    expect(saved.id, startsWith('JOB-'));
    expect(jobs.activeJobs.single.workProfileId, 'contractor');
    expect(jobs.activeJobs.single.vehicleId, 'truck-1');

    final archived = await jobs.archive(saved.id);
    expect(archived?.archived, isTrue);
    expect(jobs.activeJobs, isEmpty);
    expect(jobs.jobs.single.customerReference, 'estimate-42');
  });
}
