import 'package:flutter/material.dart';

enum ContractorCommandTarget {
  createJob,
  jobs,
  addReceipt,
  addExpense,
  fuel,
  materials,
  helpers,
  createInvoice,
  recordPayment,
  estimate,
  addStop,
  note,
}

enum ContractorMetricTarget {
  openJobs,
  jobsToday,
  receiptsToReview,
  unpaidInvoices,
  paymentsThisWeek,
  expensesThisWeek,
}

class ContractorMetric {
  const ContractorMetric({
    required this.label,
    required this.value,
    required this.color,
    this.target,
  });

  final String label;
  final String value;
  final Color color;
  final ContractorMetricTarget? target;
}

class ContractorAttentionItem {
  const ContractorAttentionItem({
    required this.title,
    required this.detail,
    required this.color,
    required this.icon,
    required this.target,
  });

  final String title;
  final String detail;
  final Color color;
  final IconData icon;
  final ContractorMetricTarget target;
}

class ContractorJobPreview {
  const ContractorJobPreview({
    required this.id,
    required this.time,
    required this.title,
    required this.summary,
    required this.status,
  });

  final String id;
  final String time;
  final String title;
  final String summary;
  final String status;
}

class ContractorCommand {
  const ContractorCommand({
    required this.label,
    required this.icon,
    required this.color,
    required this.target,
  });

  final String label;
  final IconData icon;
  final Color color;
  final ContractorCommandTarget target;
}

const contractorPreDayCommands = [
  ContractorCommand(
    label: 'Jobs',
    icon: Icons.work_outline_rounded,
    color: Color(0xFF1976B9),
    target: ContractorCommandTarget.jobs,
  ),
  ContractorCommand(
    label: 'Create Job',
    icon: Icons.work_rounded,
    color: Color(0xFF2E6FA8),
    target: ContractorCommandTarget.createJob,
  ),
  ContractorCommand(
    label: 'Fuel',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFF087A70),
    target: ContractorCommandTarget.fuel,
  ),
  ContractorCommand(
    label: 'Expense',
    icon: Icons.payments_rounded,
    color: Color(0xFFFF8552),
    target: ContractorCommandTarget.addExpense,
  ),
  ContractorCommand(
    label: 'Materials',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF8F6CEB),
    target: ContractorCommandTarget.materials,
  ),
  ContractorCommand(
    label: 'Helpers',
    icon: Icons.groups_rounded,
    color: Color(0xFF455A64),
    target: ContractorCommandTarget.helpers,
  ),
  ContractorCommand(
    label: 'Create Estimate',
    icon: Icons.request_quote_rounded,
    color: Color(0xFF78909C),
    target: ContractorCommandTarget.estimate,
  ),
];

const contractorActiveCommands = [
  ContractorCommand(
    label: 'Jobs',
    icon: Icons.work_outline_rounded,
    color: Color(0xFF1976B9),
    target: ContractorCommandTarget.jobs,
  ),
  ContractorCommand(
    label: 'Add Stop',
    icon: Icons.place_rounded,
    color: Color(0xFF2E6FA8),
    target: ContractorCommandTarget.addStop,
  ),
  ContractorCommand(
    label: 'Fuel',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFF087A70),
    target: ContractorCommandTarget.fuel,
  ),
  ContractorCommand(
    label: 'Add Receipt',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFFFC44D),
    target: ContractorCommandTarget.addReceipt,
  ),
  ContractorCommand(
    label: 'Use Materials',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF8F6CEB),
    target: ContractorCommandTarget.materials,
  ),
  ContractorCommand(
    label: 'Add Expense',
    icon: Icons.payments_rounded,
    color: Color(0xFFFF8552),
    target: ContractorCommandTarget.addExpense,
  ),
  ContractorCommand(
    label: 'Create Invoice',
    icon: Icons.description_rounded,
    color: Color(0xFF607D8B),
    target: ContractorCommandTarget.createInvoice,
  ),
  ContractorCommand(
    label: 'Record Payment',
    icon: Icons.attach_money_rounded,
    color: Color(0xFF19C15F),
    target: ContractorCommandTarget.recordPayment,
  ),
  ContractorCommand(
    label: 'Job Note',
    icon: Icons.note_alt_rounded,
    color: Color(0xFF607D8B),
    target: ContractorCommandTarget.note,
  ),
  ContractorCommand(
    label: 'Helpers',
    icon: Icons.groups_rounded,
    color: Color(0xFF455A64),
    target: ContractorCommandTarget.helpers,
  ),
];
