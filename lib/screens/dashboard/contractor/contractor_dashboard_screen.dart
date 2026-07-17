import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../expenses/home/expenses_home_screen.dart';
import '../../invoices/home/invoice_workspace_screen.dart';
import '../../invoices/home/invoice_home_models.dart';
import '../../work_supplies/jobs/work_supply_jobs_screen.dart';
import '../../work_supplies/work_supply_screen.dart';
import '../../../shared/calendar/calendar.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_pulse.dart';
import 'contractor_dashboard_sections.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  var _dayStarted = false;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AppScreenHeader(title: 'Contractor Command Center'),
          ),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          const ContractorScaleStrip(),
          const SizedBox(height: 10),
          const ContractorOperationsPulse(),
          const SizedBox(height: 10),
          const ContractorAttentionPanel(),
          const SizedBox(height: 10),
          if (_dayStarted) ...[
            const ContractorActiveShiftPanel(),
            const SizedBox(height: 10),
            ContractorCommandGrid(
              commands: contractorActiveCommands,
              onCommand: _handleCommand,
            ),
            const SizedBox(height: 10),
            ContractorDayControlPanel(
              dayStarted: true,
              onStartDay: _startContractorDay,
            ),
          ] else ...[
            ContractorDayControlPanel(
              dayStarted: false,
              onStartDay: _startContractorDay,
            ),
            const SizedBox(height: 10),
            ContractorCommandGrid(
              commands: contractorPreDayCommands,
              onCommand: _handleCommand,
            ),
          ],
          const SizedBox(height: 10),
          const ContractorJobsPanel(),
          const SizedBox(height: 10),
          const ContractorMetricsStrip(),
          const SizedBox(height: 76),
          const ContractorCalendar(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  void _startContractorDay() {
    setState(() => _dayStarted = true);
  }

  void _handleCommand(ContractorCommand command) {
    switch (command.target) {
      case ContractorCommandTarget.createJob:
      case ContractorCommandTarget.jobs:
        _open(const WorkSupplyJobsScreen());
      case ContractorCommandTarget.addReceipt:
      case ContractorCommandTarget.addExpense:
        _open(const ExpensesScreen());
      case ContractorCommandTarget.materials:
        _open(const WorkSupplyScreen());
      case ContractorCommandTarget.createInvoice:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.invoices),
        );
      case ContractorCommandTarget.estimate:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.estimates),
        );
      case ContractorCommandTarget.recordPayment:
      case ContractorCommandTarget.note:
        _showPending(command.label);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(appNativeRoute<void>(context, screen));
  }

  void _showPending(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label flow will connect to the job record next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ContractorDashboardLauncher extends StatelessWidget {
  const ContractorDashboardLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: const Color(0xFF12324A),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            appNativeRoute<void>(context, const ContractorDashboardScreen()),
          ),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF7CC7FF),
                  size: 24,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contractor Dashboard',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jobs, materials, invoices, expenses, and calendar.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976B9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
