enum JobRepeatRule {
  none('Does not repeat'),
  weekly('Every week'),
  everyTwoWeeks('Every 2 weeks'),
  monthly('Every month');

  const JobRepeatRule(this.label);

  final String label;
}

class WorkSupplyJobDraft {
  const WorkSupplyJobDraft({
    required this.name,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.serviceAddress,
    required this.notes,
    required this.repeatRule,
    required this.inAppReminder,
    required this.pushReminder,
    required this.soundReminder,
    required this.reminderLeadMinutes,
    this.estimateId = '',
    this.scheduledStart,
    this.scheduledEnd,
  });

  final String name;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String serviceAddress;
  final String notes;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final JobRepeatRule repeatRule;
  final bool inAppReminder;
  final bool pushReminder;
  final bool soundReminder;
  final int reminderLeadMinutes;
  final String estimateId;
}
