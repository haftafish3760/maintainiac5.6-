// Job draft mapping. The Jobs owner converts form input to its source record;
// Calendar never creates or persists an appointment record.

import '../../../shared/jobs/maintainiac_job_store.dart';
import 'work_supply_job_form_models.dart';

WorkSupplyJobDraft workSupplyJobDraftFromRecord(MaintainiacJobRecord record) {
  return WorkSupplyJobDraft(
    name: record.name,
    clientName: record.customerReference,
    clientPhone: record.customerPhone,
    clientEmail: record.customerEmail,
    serviceAddress: record.address,
    notes: record.notes,
    scheduledStart: record.scheduledStart,
    scheduledEnd: record.scheduledEnd,
    scheduleEnabled: record.scheduledStart != null,
    repeatRule: JobRepeatRule.values.firstWhere(
      (rule) => rule.name == record.repeatRule,
      orElse: () => JobRepeatRule.none,
    ),
    repeatWeekdays: record.repeatWeekdays,
    repeatUntil: record.repeatUntil,
    inAppReminder: record.inAppReminder,
    pushReminder: record.pushReminder,
    soundReminder: record.soundReminder,
    reminderLeadMinutes: record.reminderLeadMinutes,
    estimateId: record.estimateId,
  );
}

MaintainiacJobRecord maintainiacJobRecordFromDraft({
  required WorkSupplyJobDraft draft,
  required DateTime now,
  String workProfileId = '',
  String activeVehicleId = '',
  MaintainiacJobRecord? existing,
}) {
  final source = existing;
  return MaintainiacJobRecord(
    id: source?.id ?? '',
    number: source?.number ?? '',
    name: draft.name,
    customerId: source?.customerId ?? '',
    customerReference: draft.clientName,
    customerPhone: draft.clientPhone,
    customerEmail: draft.clientEmail,
    address: draft.serviceAddress,
    notes: draft.notes,
    workProfileId: source?.workProfileId.isNotEmpty == true
        ? source!.workProfileId
        : workProfileId,
    vehicleIds: source?.vehicleIds.isNotEmpty == true
        ? source!.vehicleIds
        : activeVehicleId.trim().isEmpty
        ? const <String>[]
        : [activeVehicleId],
    assignedMemberIds: source?.assignedMemberIds ?? const <String>[],
    estimateId: draft.estimateId,
    invoiceId: source?.invoiceId ?? '',
    scheduledStart: draft.scheduledStart,
    scheduledEnd: draft.scheduledEnd,
    repeatRule: draft.repeatRule.name,
    repeatWeekdays: draft.repeatWeekdays,
    repeatUntil: draft.repeatUntil,
    inAppReminder: draft.inAppReminder,
    pushReminder: draft.pushReminder,
    soundReminder: draft.soundReminder,
    reminderLeadMinutes: draft.reminderLeadMinutes,
    archived: source?.archived ?? false,
    createdAt: source?.createdAt ?? now,
    updatedAt: now,
  );
}
