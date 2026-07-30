part of 'work_supply_jobs_screen.dart';

class _JobsHeader extends StatelessWidget {
  const _JobsHeader({required this.jobCount, required this.onCreateJob});

  final int jobCount;
  final VoidCallback onCreateJob;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF162229),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jobs',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jobCount active job records tied to schedule, mileage, expenses, inventory, receipts, and invoices.',
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'New Job',
              compact: true,
              tone: AppButtonTone.commit,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: onCreateJob,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsCommandSummary extends StatelessWidget {
  const _JobsCommandSummary({required this.jobs});

  final List<WorkSupplyJob> jobs;

  @override
  Widget build(BuildContext context) {
    final mileage = jobs.fold<double>(0, (sum, job) => sum + job.mileage);
    final expenses = jobs.fold<double>(0, (sum, job) => sum + job.expenses);
    final inventoryItems = jobs.fold<int>(
      0,
      (sum, job) => sum + job.inventoryItems,
    );
    final invoices = jobs.fold<double>(0, (sum, job) => sum + job.invoiceTotal);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16334A), Color(0xFF11251F)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF58A6D6), width: 1.15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _JobMetric(label: 'Active Jobs', value: jobs.length.toString()),
            _JobMetric(label: 'Mileage', value: mileage.toStringAsFixed(1)),
            _JobMetric(label: 'Expenses', value: _money(expenses)),
            _JobMetric(label: 'Inventory', value: inventoryItems.toString()),
            _JobMetric(label: 'Invoices', value: _money(invoices)),
          ],
        ),
      ),
    );
  }
}

class _JobMetric extends StatelessWidget {
  const _JobMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xDD0F181D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF405159)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobScheduleSection extends StatelessWidget {
  const _JobScheduleSection({
    required this.selectedDay,
    required this.selectedJobs,
    required this.markersForDay,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final List<WorkSupplyJob> selectedJobs;
  final List<WorkSupplyCalendarMarker> Function(DateTime day) markersForDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Job Schedule',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a date to see the jobs, mileage, inventory, receipts, and expenses tied to that day.',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            WorkSupplyCalendarPanel(
              markersByDay: const {},
              onDaySelected: onDaySelected,
              markersForDay: markersForDay,
              calendarSource: CalendarFlowSource.jobs,
              openCalendarDay: true,
            ),
            const SizedBox(height: 10),
            _JobsForDayPanel(day: selectedDay, jobs: selectedJobs),
          ],
        ),
      ),
    );
  }
}

class _JobQuickActions extends StatelessWidget {
  const _JobQuickActions({
    required this.onCreateJob,
    required this.onImportEstimate,
    required this.onAddExpense,
    required this.onUseInventory,
  });

  final VoidCallback onCreateJob;
  final VoidCallback onImportEstimate;
  final VoidCallback onAddExpense;
  final VoidCallback onUseInventory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                label: 'Create Job',
                icon: Icons.assignment_add,
                onTap: onCreateJob,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                label: 'Import Estimate',
                icon: Icons.request_quote_rounded,
                onTap: onImportEstimate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                label: 'Add Expense',
                icon: Icons.receipt_long_rounded,
                onTap: onAddExpense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                label: 'Use Inventory',
                icon: Icons.inventory_2_rounded,
                onTap: onUseInventory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF273943),
          foregroundColor: const Color(0xFFE8ECEE),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
