part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryJobContext on _ExpenseReceiptEntryScreenState {
  Widget _buildJobContextPanel(BuildContext context) {
    final jobsController = ExpenseJobScope.of(context);
    final jobs = jobsController.activeJobs;
    final selected = jobs.where((job) => job.id == _expenseContext.jobId);
    final selectedJob = selected.isEmpty ? null : selected.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF293135),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3C494E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.work_outline, color: Color(0xFFB7C8CE)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job (optional)',
                    style: TextStyle(
                      color: Color(0xFFF2F7F8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedJob?.name ?? 'Not attached to a job',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB7C8CE)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _chooseExpenseJob(context, jobsController),
              child: Text(selectedJob == null ? 'Choose' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseExpenseJob(
    BuildContext context,
    ExpenseJobController jobsController,
  ) async {
    final jobs = jobsController.activeJobs;
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Attach to a job'),
              subtitle: Text('This receipt stays linked to the selected job.'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('No job'),
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create a job'),
              subtitle: const Text('Keep this expense with a new job.'),
              onTap: () => Navigator.of(sheetContext).pop('_create_job_'),
            ),
            for (final job in jobs)
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(job.name),
                subtitle: job.customerReference.isEmpty
                    ? null
                    : Text(job.customerReference),
                trailing: job.id == _expenseContext.jobId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(job.id),
              ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    final selected = selection == '_create_job_'
        ? await _createExpenseJob(context, jobsController)
        : _jobForId(jobs, selection);
    if (selection == '_create_job_' && selected == null) return;
    _setReceiptEntryState(() {
      _expenseContext = ExpenseReceiptContextSnapshot(
        workProfileId: _expenseContext.workProfileId,
        workProfileName: _expenseContext.workProfileName,
        vehicleId: _expenseContext.vehicleId,
        vehicleLabel: _expenseContext.vehicleLabel,
        jobId: selected?.id ?? '',
        jobLabel: selected?.name ?? '',
      );
    });
    _scheduleDraftSave();
  }

  ExpenseJobRecord? _jobForId(List<ExpenseJobRecord> jobs, String id) {
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  Future<ExpenseJobRecord?> _createExpenseJob(
    BuildContext context,
    ExpenseJobController jobs,
  ) async {
    final nameController = TextEditingController();
    final customerController = TextEditingController();
    final details = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create job'),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop((nameController.text, customerController.text)),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    customerController.dispose();
    if (details == null || details.$1.trim().isEmpty) return null;
    final now = DateTime.now();
    return jobs.save(
      ExpenseJobRecord(
        id: '',
        name: details.$1,
        customerReference: details.$2,
        workProfileId: _expenseContext.workProfileId,
        vehicleId: _expenseContext.vehicleId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
