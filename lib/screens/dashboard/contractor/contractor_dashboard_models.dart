import 'package:flutter/material.dart';

enum ContractorCommandTarget {
  createJob,
  jobs,
  addReceipt,
  addExpense,
  materials,
  createInvoice,
  recordPayment,
  estimate,
  note,
  proofPhoto,
}

class ContractorMetric {
  const ContractorMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class ContractorAttentionItem {
  const ContractorAttentionItem({
    required this.title,
    required this.detail,
    required this.color,
    required this.icon,
  });

  final String title;
  final String detail;
  final Color color;
  final IconData icon;
}

class ContractorJobPreview {
  const ContractorJobPreview({
    required this.time,
    required this.customer,
    required this.summary,
    required this.status,
    required this.amount,
  });

  final String time;
  final String customer;
  final String summary;
  final String status;
  final String amount;
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

const contractorMetrics = [
  ContractorMetric(label: 'Open Jobs', value: '3', color: Color(0xFF4DA3FF)),
  ContractorMetric(label: 'Money In', value: r'$725', color: Color(0xFF55D68A)),
  ContractorMetric(
    label: 'Money Out',
    value: r'$312',
    color: Color(0xFFFF5C5C),
  ),
  ContractorMetric(
    label: 'Business Miles',
    value: '42.8',
    color: Color(0xFFFFD166),
  ),
];

const contractorOperationsPulse = [
  ContractorMetric(
    label: 'Vehicles Active',
    value: '2',
    color: Color(0xFF55D68A),
  ),
  ContractorMetric(
    label: 'Employees Active',
    value: '5',
    color: Color(0xFFFFD166),
  ),
  ContractorMetric(label: 'Jobs Today', value: '3', color: Color(0xFF7CC7FF)),
  ContractorMetric(label: 'Needs Review', value: '4', color: Color(0xFFB48CFF)),
];

const contractorAttentionItems = [
  ContractorAttentionItem(
    title: 'Receipt draft waiting',
    detail: 'Supplier receipt needs line review before it hits the job cost.',
    color: Color(0xFFFFC44D),
    icon: Icons.receipt_long_rounded,
  ),
  ContractorAttentionItem(
    title: 'Low truck stock',
    detail: 'Truck 1 is low on common plumbing fittings.',
    color: Color(0xFFFF8552),
    icon: Icons.inventory_2_rounded,
  ),
  ContractorAttentionItem(
    title: 'Estimate follow-up',
    detail: 'Kitchen repair estimate has not been accepted yet.',
    color: Color(0xFF4DA3FF),
    icon: Icons.assignment_turned_in_rounded,
  ),
];

const contractorJobsToday = [
  ContractorJobPreview(
    time: '8:30 AM',
    customer: 'Oak Street repair',
    summary: 'Leak repair, supply stop, invoice draft ready.',
    status: 'In progress',
    amount: r'$725',
  ),
  ContractorJobPreview(
    time: '11:45 AM',
    customer: 'Kitchen estimate',
    summary: 'Take photos, write estimate, schedule return.',
    status: 'Planned',
    amount: r'$0',
  ),
  ContractorJobPreview(
    time: '2:15 PM',
    customer: 'Shop drain call',
    summary: 'Check drain line, add receipt if parts are bought.',
    status: 'Needs parts',
    amount: r'$480',
  ),
];

const contractorPreDayCommands = [
  ContractorCommand(
    label: 'Create Job',
    icon: Icons.work_rounded,
    color: Color(0xFF2E6FA8),
    target: ContractorCommandTarget.createJob,
  ),
  ContractorCommand(
    label: 'Add Expense',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFFF8552),
    target: ContractorCommandTarget.addExpense,
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
    label: 'Add Stop',
    icon: Icons.place_rounded,
    color: Color(0xFF2E6FA8),
    target: ContractorCommandTarget.note,
  ),
  ContractorCommand(
    label: 'Job Note',
    icon: Icons.note_alt_rounded,
    color: Color(0xFF607D8B),
    target: ContractorCommandTarget.note,
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
    label: 'Proof Photo',
    icon: Icons.camera_alt_rounded,
    color: Color(0xFF4DA3FF),
    target: ContractorCommandTarget.proofPhoto,
  ),
];
