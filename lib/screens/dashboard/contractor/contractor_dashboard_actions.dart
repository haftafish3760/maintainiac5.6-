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
