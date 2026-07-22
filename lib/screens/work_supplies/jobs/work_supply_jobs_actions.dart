part of 'work_supply_jobs_screen.dart';

extension _WorkSupplyJobsActions on _WorkSupplyJobsScreenState {
  void _beginCreateJob() {
    unawaited(_createJob());
  }

  Future<void> _createJob() async {
    final nameController = TextEditingController();
    final customerController = TextEditingController();
    final addressController = TextEditingController();
    final details = await showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Job name'),
              ),
              TextField(
                controller: customerController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer or reference (optional)',
                ),
              ),
              TextField(
                controller: addressController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Job address (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop((
              nameController.text,
              customerController.text,
              addressController.text,
            )),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    customerController.dispose();
    addressController.dispose();
    if (details == null || details.$1.trim().isEmpty || !context.mounted) {
      return;
    }
    final currentContext = context;
    final operational = OperationalContextScope.of(currentContext).context;
    final now = DateTime.now().toUtc();
    try {
      await MaintainiacJobScope.of(currentContext).save(
        MaintainiacJobRecord(
          id: '',
          name: details.$1,
          customerReference: details.$2,
          address: details.$3,
          workProfileId: operational.workProfileId,
          vehicleIds: [operational.activeVehicleId],
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (error) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('Could not save job: $error')));
    }
  }
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
