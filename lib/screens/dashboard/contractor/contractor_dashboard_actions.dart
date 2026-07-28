part of 'contractor_dashboard_screen.dart';

extension _ContractorDashboardActions on _ContractorDashboardScreenState {
  void _openMetric(ContractorMetricTarget target) {
    switch (target) {
      case ContractorMetricTarget.openJobs:
      case ContractorMetricTarget.jobsToday:
        _openJobs();
      case ContractorMetricTarget.receiptsToReview:
        _open(const ExpensesScreen());
      case ContractorMetricTarget.unpaidInvoices:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.invoices),
        );
      case ContractorMetricTarget.paymentsThisWeek:
        _open(ContractorWeeklyPaymentsScreen(anchorDate: _now));
      case ContractorMetricTarget.expensesThisWeek:
        _open(ContractorWeeklyExpensesScreen(anchorDate: _now));
    }
  }

  Future<void> _handleCommand(ContractorCommand command) async {
    switch (command.target) {
      case ContractorCommandTarget.createJob:
      case ContractorCommandTarget.jobs:
        _openJobs();
      case ContractorCommandTarget.addReceipt:
        await _openExpenseEntry(
          odometerTitle: 'Receipt Odometer',
          eventType: ActiveWorkdayEventType.expense,
        );
      case ContractorCommandTarget.addExpense:
        await _openExpenseEntry(
          odometerTitle: 'Expense Odometer',
          eventType: ActiveWorkdayEventType.expense,
        );
      case ContractorCommandTarget.fuel:
        await _openExpenseEntry(
          odometerTitle: 'Fuel Odometer',
          eventType: ActiveWorkdayEventType.fuel,
          initialCategory: 'Fuel',
        );
      case ContractorCommandTarget.materials:
        _open(const WorkSupplyScreen());
      case ContractorCommandTarget.helpers:
        _open(const EmployeePermissionsScreen());
      case ContractorCommandTarget.createInvoice:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.invoices),
        );
      case ContractorCommandTarget.estimate:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.estimates),
        );
      case ContractorCommandTarget.recordPayment:
        _open(const InvoicePaymentScreen());
      case ContractorCommandTarget.addStop:
      case ContractorCommandTarget.note:
        await _recordQuickActiveDayEvent(command);
    }
  }

  Future<void> _openExpenseEntry({
    required String odometerTitle,
    required ActiveWorkdayEventType eventType,
    String? initialCategory,
  }) async {
    final reading = await openOdometerEntryResult(
      context,
      title: odometerTitle,
      saveLabel: 'Continue',
    );
    if (reading == null || !mounted) return;
    final saved = await Navigator.of(context).push<ExpenseReceiptRecord>(
      appNativeRoute<ExpenseReceiptRecord>(
        context,
        ExpenseReceiptEntryScreen(
          initialCategory: initialCategory,
          initialOdometerReading: reading,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday?.activeSession != null) {
      final updated = await _recordContractorDayEvent(
        activeWorkday!,
        eventType,
        odometerReading: saved.odometerReading ?? reading,
      );
      if (!updated || !mounted) return;
    }
  }

  Future<void> _recordQuickActiveDayEvent(ContractorCommand command) async {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday?.activeSession == null) {
      _showActiveDayRequired(command.label);
      return;
    }
    String? note;
    final odometerReading = GlobalOdometerScope.of(context).confirmedReading;
    if (command.target == ContractorCommandTarget.addStop) {
      note = await openWorkdayNoteSheet(
        context,
        title: 'Add Stop Details',
        fieldLabel: 'What kind of stop is this?',
        hintText: 'Customer, store, pickup, delivery, or break',
        saveLabel: 'Continue',
      );
      if (note == null || !mounted) return;
    } else {
      note = await openWorkdayNoteSheet(context);
      if (note == null || !mounted) return;
    }
    final type = command.target == ContractorCommandTarget.addStop
        ? ActiveWorkdayEventType.stop
        : ActiveWorkdayEventType.note;
    final updated = await _recordContractorDayEvent(
      activeWorkday!,
      type,
      odometerReading: odometerReading,
      note: note,
    );
    if (!updated || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${command.label} saved to the active contractor day.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(appNativeRoute<void>(context, screen));
  }

  void _openJobs() {
    _open(const WorkSupplyJobsScreen());
  }

  void _showActiveDayRequired(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Start your contractor day before using $label.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
