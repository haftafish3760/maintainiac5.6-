part of 'work_supply_jobs_screen.dart';

extension _WorkSupplyJobsActions on _WorkSupplyJobsScreenState {
  void _beginCreateJob() {
    if (_openingCreateJob) return;
    unawaited(_createJob());
  }

  void _beginImportEstimate() {
    if (_openingCreateJob) return;
    unawaited(_importEstimate());
  }

  Future<void> _createJob({WorkSupplyJobDraft? initialDraft}) async {
    _openingCreateJob = true;
    final jobController = MaintainiacJobScope.of(context);
    final operational = OperationalContextScope.of(context).context;
    WorkSupplyJobDraft? draft;
    try {
      draft = await Navigator.of(context).push<WorkSupplyJobDraft>(
        appNativeRoute(
          context,
          WorkSupplyJobFormScreen(
            initialDay: _selectedDay,
            initialDraft: initialDraft,
          ),
        ),
      );
    } finally {
      _openingCreateJob = false;
    }
    if (draft == null || !mounted) return;
    final now = DateTime.now().toUtc();
    try {
      await jobController.save(
        maintainiacJobRecordFromDraft(
          draft: draft,
          now: now,
          workProfileId: operational.workProfileId,
          activeVehicleId: operational.activeVehicleId,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save job: $error')));
    }
  }

  Future<void> _importEstimate() async {
    _openingCreateJob = true;
    final estimates =
        InvoiceLedgerScope.maybeOf(context)?.records
            .where((record) => record.isEstimate)
            .where((record) => record.status.name != 'voided')
            .toList(growable: false) ??
        const <InvoiceRecord>[];
    InvoiceRecord? estimate;
    try {
      estimate = await Navigator.of(context).push<InvoiceRecord>(
        appNativeRoute(
          context,
          WorkSupplyEstimatePickerScreen(estimates: estimates),
        ),
      );
    } finally {
      _openingCreateJob = false;
    }
    if (estimate == null || !mounted) return;
    await _createJob(initialDraft: _jobDraftFromEstimate(estimate));
  }

  void _showPendingConnection(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is not connected yet. No job or financial record was changed.',
        ),
      ),
    );
  }
}

WorkSupplyJobDraft _jobDraftFromEstimate(InvoiceRecord estimate) {
  final client = estimate.client;
  return WorkSupplyJobDraft(
    name: estimate.displayTitle,
    clientName: client.bestName,
    clientPhone: client.phone,
    clientEmail: client.email,
    serviceAddress: [
      client.street,
      client.city,
      client.state,
      client.postalCode,
    ].where((value) => value.trim().isNotEmpty).join(', '),
    notes: '',
    repeatRule: JobRepeatRule.none,
    inAppReminder: false,
    pushReminder: false,
    soundReminder: false,
    reminderLeadMinutes: 60,
    estimateId: estimate.id,
  );
}

WorkSupplyJob _workSupplyJobFromRecord(MaintainiacJobRecord record) {
  return WorkSupplyJob(
    name: record.name,
    number: record.number,
    customerName: record.customerReference,
    address: record.address,
    assignedVehicles: record.vehicleIds,
    workProfiles: record.workProfileId.isEmpty
        ? const []
        : [record.workProfileId],
    scheduledDate: record.scheduledStart,
  );
}
