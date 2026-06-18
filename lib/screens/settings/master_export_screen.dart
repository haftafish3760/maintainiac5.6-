import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../expenses/data/expense_export_file_writer.dart';
import '../expenses/data/expense_export_handoff.dart';
import '../expenses/data/expense_export_models.dart';
import '../expenses/data/expense_export_store.dart';
import '../expenses/data/expense_ledger_models.dart';
import '../expenses/data/expense_ledger_store.dart';

part 'master_export_header_range.dart';
part 'master_export_module_selection.dart';
part 'master_export_source_destination.dart';
part 'master_export_preview.dart';
part 'master_export_widgets.dart';

class MasterExportScreen extends StatefulWidget {
  const MasterExportScreen({super.key});

  @override
  State<MasterExportScreen> createState() => _MasterExportScreenState();
}

class _MasterExportScreenState extends State<MasterExportScreen> {
  var _preset = ExpenseExportRangePreset.month;
  var _from = _monthStart(DateTime.now());
  var _to = _dateOnly(DateTime.now());
  var _includeExpenses = true;
  var _expenseCategoryFilter = ExpenseExportCategoryFilter.all;
  var _source = ExpenseExportSource.localDevice;
  var _destination = ExpenseExportDestination.share;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final exportStore = ExpenseExportScope.of(context);
    final lastExport = exportStore.lastExport;
    final range = ExpenseDateRange(start: _from, end: _to);
    final expenseSnapshot = buildExpenseExportSnapshot(
      receipts: ledger.storedReceipts,
      range: range,
      categoryFilter: _expenseCategoryFilter,
      source: _source,
      destination: _destination,
    );
    final canExport = exportStore.canRunExport(expenseSnapshot, DateTime.now());
    final totalFiles = _includeExpenses && expenseSnapshot.lineCount > 0
        ? expenseSnapshot.fileNames.length
        : 0;

    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        children: [
          const _MasterExportHeader(),
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
          _ModuleSelectionPanel(
            includeExpenses: _includeExpenses,
            expenseSnapshot: expenseSnapshot,
            expenseFilter: _expenseCategoryFilter,
            onIncludeExpenses: (value) =>
                setState(() => _includeExpenses = value),
            onExpenseFilter: (value) =>
                setState(() => _expenseCategoryFilter = value),
          ),
          const SizedBox(height: 8),
          _ExportSourcePanel(
            value: _source,
            onChanged: (value) => setState(() => _source = value),
          ),
          const SizedBox(height: 8),
          _ExportDestinationPanel(
            value: _destination,
            onChanged: (value) => setState(() => _destination = value),
          ),
          const SizedBox(height: 8),
          _MasterExportPreviewPanel(
            expenseSnapshot: expenseSnapshot,
            includeExpenses: _includeExpenses,
            fileCount: totalFiles,
            canExport: canExport,
            cloudUsedThisMonth: exportStore.cloudExportsUsedInMonth(
              DateTime.now(),
            ),
            onExport: totalFiles == 0 || !canExport
                ? null
                : () => _runExport(expenseSnapshot, exportStore),
          ),
        ],
      ),
    );
  }

  ExpenseDateRange _rangeForPreset(
    ExpenseExportRangePreset preset,
    ExpenseExportRecord? lastExport,
  ) {
    final today = _dateOnly(DateTime.now());
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
    ExpenseExportSnapshot expenseSnapshot,
    ExpenseExportController exportStore,
  ) async {
    if (!exportStore.canRunExport(expenseSnapshot, DateTime.now())) {
      await _showExportBlockedDialog();
      return;
    }
    ExpenseExportRecord? savedExpenseExport;
    ExpenseExportFileSet? files;
    ExpenseExportHandoffResult? handoffResult;
    if (_includeExpenses && expenseSnapshot.lineCount > 0) {
      files = await const ExpenseExportFileWriter().writeExpenseExport(
        expenseSnapshot,
      );
      handoffResult = await const ExpenseExportHandoff().send(
        snapshot: expenseSnapshot,
        files: files,
      );
      if (handoffResult.completed) {
        savedExpenseExport = await exportStore.markExported(
          expenseSnapshot,
          outputDirectory: handoffResult.savedPath ?? files.directoryPath,
          fileNames: files.files,
        );
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Export Complete',
          style: TextStyle(color: Color(0xFFF0F4F2)),
        ),
        content: Text(
          handoffResult != null && !handoffResult.completed
              ? handoffResult.message
              : savedExpenseExport == null
              ? 'No selected records were available for this export.'
              : '${handoffResult?.message ?? _destinationReadyMessage(savedExpenseExport.destination)}\n\nReceipts: ${savedExpenseExport.receiptCount}\nLines: ${savedExpenseExport.lineCount}\nFolder:\n${files?.directoryPath ?? savedExpenseExport.outputDirectory ?? 'Not available'}\n\nFiles:\n${savedExpenseExport.fileNames.join('\n')}',
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
