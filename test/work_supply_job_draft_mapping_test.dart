import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/jobs/work_supply_job_draft_mapping.dart';
import 'package:maintaniac/screens/work_supplies/jobs/work_supply_job_form_models.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';

void main() {
  test('source draft edit preserves linked records and job assignments', () {
    final original = _record();
    final draft = workSupplyJobDraftFromRecord(original);
    final saved = maintainiacJobRecordFromDraft(
      draft: WorkSupplyJobDraft(
        name: 'Jones plumbing follow-up',
        clientName: draft.clientName,
        clientPhone: draft.clientPhone,
        clientEmail: draft.clientEmail,
        serviceAddress: draft.serviceAddress,
        notes: draft.notes,
        scheduledStart: DateTime(2026, 8, 3, 9),
        scheduledEnd: DateTime(2026, 8, 3, 11),
        scheduleEnabled: true,
        repeatRule: JobRepeatRule.selectedWeekdays,
        repeatWeekdays: const [DateTime.monday, DateTime.wednesday],
        repeatUntil: DateTime(2026, 8, 31),
        inAppReminder: true,
        pushReminder: true,
        soundReminder: true,
        reminderLeadMinutes: 30,
        estimateId: draft.estimateId,
      ),
      existing: original,
      now: DateTime.utc(2026, 7, 29),
    );

    expect(saved.id, original.id);
    expect(saved.customerId, original.customerId);
    expect(saved.assignedMemberIds, original.assignedMemberIds);
    expect(saved.vehicleIds, original.vehicleIds);
    expect(saved.invoiceId, original.invoiceId);
    expect(saved.repeatWeekdays, [DateTime.monday, DateTime.wednesday]);
    expect(saved.repeatUntil, DateTime(2026, 8, 31));
  });

  test('new source record uses the active operational context once', () {
    final record = maintainiacJobRecordFromDraft(
      draft: _draft(),
      now: DateTime.utc(2026, 7, 29),
      workProfileId: 'profile-a',
      activeVehicleId: 'truck-1',
    );

    expect(record.workProfileId, 'profile-a');
    expect(record.vehicleIds, ['truck-1']);
    expect(record.id, isEmpty);
  });
}

MaintainiacJobRecord _record() => MaintainiacJobRecord(
  id: 'JOB-1',
  number: 'JOB-1',
  name: 'Jones plumbing',
  customerId: 'customer-1',
  customerReference: 'Jones',
  customerPhone: '555-0100',
  customerEmail: 'jones@example.com',
  address: '1 Main Street',
  notes: 'Gate code 1234',
  workProfileId: 'profile-a',
  vehicleIds: const ['truck-1'],
  assignedMemberIds: const ['employee-1'],
  estimateId: 'EST-1',
  invoiceId: 'INV-1',
  scheduledStart: DateTime(2026, 7, 27, 8),
  scheduledEnd: DateTime(2026, 7, 27, 10),
  repeatRule: 'weekly',
  inAppReminder: true,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
);

WorkSupplyJobDraft _draft() => WorkSupplyJobDraft(
  name: 'Jones plumbing',
  clientName: 'Jones',
  clientPhone: '',
  clientEmail: '',
  serviceAddress: '',
  notes: '',
  repeatRule: JobRepeatRule.none,
  inAppReminder: false,
  pushReminder: false,
  soundReminder: false,
  reminderLeadMinutes: 60,
);
