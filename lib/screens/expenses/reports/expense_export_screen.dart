import 'package:flutter/material.dart';

import '../../../shared/pdf/app_generated_pdf_export_estimator.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/expense_export_file_writer.dart';
import '../data/expense_export_handoff.dart';
import '../data/expense_export_models.dart';
import '../data/expense_export_store.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_screen_telemetry.dart';
import '../data/expense_screen_telemetry_recorder.dart';

part 'expense_export_header_range.dart';
part 'expense_export_panels.dart';
part 'expense_export_widgets.dart';

class ExpenseExportScreen extends StatefulWidget {
  const ExpenseExportScreen({super.key});

  @override
  State<ExpenseExportScreen> createState() => _ExpenseExportScreenState();
}

class _ExpenseExportScreenState extends State<ExpenseExportScreen> {
  var _preset = ExpenseExportRangePreset.month;
  var _categoryFilter = ExpenseExportCategoryFilter.all;
  var _destination = ExpenseExportDestination.share;
  late DateTime _from = _monthStart(DateTime.now());
  late DateTime _to = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final exportStore = ExpenseExportScope.of(context);
    final lastExport = exportStore.lastExport;
    final range = ExpenseDateRange(start: _from, end: _to);
    final snapshot = buildExpenseExportSnapshot(
      receipts: ledger.storedReceipts,
      range: range,
      categoryFilter: _categoryFilter,
      destination: _destination,
    );
    final canExport = exportStore.canRunExport(snapshot, DateTime.now());

    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        children: [
          const _ExportHeader(),
          const SizedBox(height: 8),
          _LastExportPanel(lastExport: lastExport),
          const SizedBox(height: 8),
          _ExportRangePanel(
            preset: _preset,
            from: _from,
            to: _to,
            lastExport: lastExport,
            onPresetChanged: (preset) {
              setState(() {
                _preset = preset;
                final dates = _rangeForPreset(preset, lastExport);
                _from = dates.start;
                _to = dates.end;
              });
            },
            onPickFrom: () => _pickDate(isStart: true),
            onPickTo: () => _pickDate(isStart: false),
          ),
          const SizedBox(height: 8),
          _ExportCategoryPanel(
            value: _categoryFilter,
            onChanged: (value) => setState(() => _categoryFilter = value),
          ),
          const SizedBox(height: 8),
          _ExportDestinationPanel(
            value: _destination,
            onChanged: (value) => setState(() => _destination = value),
          ),
          const SizedBox(height: 8),
          _ExportPreviewPanel(
            snapshot: snapshot,
            pdfEstimate: estimateExpenseExportPdf(
              snapshot: snapshot,
              mode: AppGeneratedPdfExportMode.textOnly,
            ),
            canExport: canExport,
            cloudUsedThisMonth: exportStore.cloudExportsUsedInMonth(
              DateTime.now(),
            ),
            onExport: snapshot.lineCount == 0 || !canExport
                ? null
                : () => _runExport(snapshot, exportStore),
          ),
        ],
      ),
    );
  }

  ExpenseDateRange _rangeForPreset(
    ExpenseExportRangePreset preset,
    ExpenseExportRecord? lastExport,
  ) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    return switch (preset) {
      ExpenseExportRangePreset.week => ExpenseDateRange(
        start: today.subtract(Duration(days: today.weekday - DateTime.monday)),
        end: today,
      ),
      ExpenseExportRangePreset.month => ExpenseDateRange(
        start: _monthStart(today),
        end: today,
      ),
      ExpenseExportRangePreset.sinceLast => rangeSinceLastExport(
        lastExport: lastExport,
        fallbackStart: _monthStart(today),
        end: today,
      ),
      ExpenseExportRangePreset.custom => ExpenseDateRange(
        start: _from,
        end: _to,
      ),
    };
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _from : _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            surface: Color(0xFF101719),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _preset = ExpenseExportRangePreset.custom;
      final date = _dateOnly(picked);
      if (isStart) {
        _from = date.isAfter(_to) ? _to : date;
      } else {
        _to = date.isBefore(_from) ? _from : date;
      }
    });
  }

  Future<void> _runExport(
    ExpenseExportSnapshot snapshot,
    ExpenseExportController exportStore,
  ) async {
    if (!exportStore.canRunExport(snapshot, DateTime.now())) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.exportBlocked,
        failureKind: 'monthly_export_limit_used',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.export,
          failedAt: 'before_export_file_write',
          confirmedCause: 'monthly_export_limit_used',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'export_store_can_run_export_false',
          missingEvidence: 'none',
        ),
        metadata: {
          'exportDestination': snapshot.destination.name,
          'lineCount': snapshot.lineCount,
          'receiptCount': snapshot.receiptCount,
        },
      );
      await _showExportBlockedDialog();
      return;
    }
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.exportStarted,
      metadata: {
        'exportDestination': snapshot.destination.name,
        'lineCount': snapshot.lineCount,
        'receiptCount': snapshot.receiptCount,
      },
    );
    final ExpenseExportFileSet files;
    final ExpenseExportHandoffResult handoffResult;
    try {
      files = await const ExpenseExportFileWriter().writeExpenseExport(
        snapshot,
      );
      handoffResult = await const ExpenseExportHandoff().send(
        snapshot: snapshot,
        files: files,
      );
    } catch (_) {
      if (mounted) {
        ExpenseScreenTelemetryRecorder.record(
          context,
          ExpenseTelemetryEventType.exportFailed,
          failureKind: 'export_write_or_handoff_failed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.export,
            failedAt: 'export_file_write_or_handoff',
            confirmedCause:
                'cause_not_confirmed_export_write_or_handoff_failed',
            causeStatus: ExpenseFailureCauseStatus.notConfirmed,
            evidence: 'export_write_or_handoff_threw_exception',
            missingEvidence: 'exception_type_and_export_stage',
          ),
          metadata: {
            'exportDestination': snapshot.destination.name,
            'lineCount': snapshot.lineCount,
            'receiptCount': snapshot.receiptCount,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That export could not be prepared. Try again.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    ExpenseExportRecord? saved;
    if (handoffResult.completed) {
      saved = await exportStore.markExported(
        snapshot,
        outputDirectory: handoffResult.savedPath ?? files.directoryPath,
        fileNames: files.files,
      );
    } else {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.exportFailed,
        failureKind: 'export_handoff_not_completed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.export,
          failedAt: 'export_handoff',
          confirmedCause: 'export_handoff_not_completed',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'handoff_result_completed_false',
          missingEvidence: 'none',
          abandoned: true,
        ),
        metadata: {
          'exportDestination': snapshot.destination.name,
          'lineCount': snapshot.lineCount,
          'receiptCount': snapshot.receiptCount,
        },
      );
    }
    if (!mounted) return;
    if (handoffResult.completed) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.exportCompleted,
        metadata: {
          'exportDestination': snapshot.destination.name,
          'lineCount': snapshot.lineCount,
          'receiptCount': snapshot.receiptCount,
        },
      );
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Expense Export Ready',
          style: TextStyle(color: Color(0xFFF0F4F2)),
        ),
        content: Text(
          !handoffResult.completed
              ? handoffResult.message
              : '${handoffResult.message}\n\nPrepared ${saved!.lineCount} line items from ${saved.receiptCount} receipts.\n\nFolder:\n${files.directoryPath}\n\nFiles:\n${saved.fileNames.join('\n')}',
          style: const TextStyle(color: Color(0xFFC8D0D3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    setState(() {});
  }

  Future<void> _showExportBlockedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Monthly Export Used',
          style: TextStyle(color: Color(0xFFF0F4F2)),
        ),
        content: const Text(
          'This account has already used the free cloud backup export for this month. Local device exports are still unlimited.',
          style: TextStyle(color: Color(0xFFC8D0D3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
