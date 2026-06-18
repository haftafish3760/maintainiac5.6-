import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture.dart';
import '../../../shared/widgets/receipt_capture/receipt_proof_storage.dart';
import '../../../shared/widgets/receipt_form_sections.dart';
import '../categories/expense_categories.dart';
import '../data/expense_draft_store.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_materials_receipt_bridge.dart';
import '../data/expense_receipt_category_rules.dart';
import '../data/expense_receipt_classifier.dart';
import '../data/expense_receipt_parser.dart';
import '../../../shared/odometer/odometer_correction_review.dart';
import '../../../shared/odometer/odometer_mileage_review.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/state/global_odometer.dart';

part 'expense_receipt_entry_state_actions.dart';
part 'expense_receipt_save_actions.dart';
part 'expense_receipt_duplicate_dialog.dart';
part 'expense_receipt_header.dart';
part 'expense_receipt_inventory_prompt.dart';
part 'expense_receipt_parse_review.dart';
part 'expense_receipt_line_actions.dart';
part 'expense_receipt_recap.dart';
part 'expense_receipt_totals.dart';
part 'expense_receipt_line_fields.dart';
part 'expense_receipt_category_picker.dart';
part 'expense_receipt_line_editor.dart';
part 'expense_receipt_line_editor_actions.dart';
part 'expense_receipt_line_models.dart';

enum ExpenseReceiptFlowMode { general, materials, maintenanceRepair }

Future<ExpenseReceiptLineRecord?> showExpenseReceiptLineEditor(
  BuildContext context, {
  required ExpenseReceiptLineRecord? line,
  required int lineNumber,
  ExpenseLineUse defaultUse = ExpenseLineUse.business,
  String defaultCategory = 'Uncategorized',
}) async {
  final initial = line == null
      ? _ExpenseReceiptLine.blank(
          use: switch (defaultUse) {
            ExpenseLineUse.business => _ExpenseLineUse.business,
            ExpenseLineUse.personal => _ExpenseLineUse.personal,
            ExpenseLineUse.split => _ExpenseLineUse.split,
          },
          category: defaultCategory,
        )
      : _ExpenseReceiptLine.fromLedgerLine(line);
  final edited = await showModalBottomSheet<_ExpenseReceiptLine>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1F2528),
    builder: (context) =>
        _ReceiptLineEditorSheet(initial: initial, lineNumber: lineNumber),
  );
  if (edited == null) return null;
  return edited.toLedgerLine(
    id: line?.id ?? 'EXPL-${DateTime.now().microsecondsSinceEpoch}',
  );
}

class ExpenseReceiptEntryScreen extends StatefulWidget {
  const ExpenseReceiptEntryScreen({
    super.key,
    this.mode = ExpenseReceiptFlowMode.general,
    this.initialCategory,
    this.initialDate,
    this.initialAttachments = const [],
    this.initialImportedText = '',
    this.draftId,
    this.receiptId,
  });

  final ExpenseReceiptFlowMode mode;
  final String? initialCategory;
  final DateTime? initialDate;
  final List<ReceiptAttachmentRecord> initialAttachments;
  final String initialImportedText;
  final String? draftId;
  final String? receiptId;

  @override
  State<ExpenseReceiptEntryScreen> createState() =>
      _ExpenseReceiptEntryScreenState();
}

class _ExpenseReceiptEntryScreenState extends State<ExpenseReceiptEntryScreen> {
  final _storeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _storeNotesController = TextEditingController();
  final _receiptSubtotalController = TextEditingController();
  final _salesTaxController = TextEditingController();
  final _receiptTotalController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  var _hasReceipt = false;
  final _receiptAttachments = <ReceiptAttachmentRecord>[];
  var _rawReceiptText = '';
  var _scanningReceiptPhotos = false;
  var _lastReceiptScanSignature = '';
  ExpenseReceiptClassification? _receiptClassification;
  ExpenseReceiptParseQuality? _lastParseQuality;
  final _maintenanceHints = <ExpenseReceiptMaintenanceHint>[];
  var _trackMaterialsInInventory = false;
  final _lines = <_ExpenseReceiptLine>[];
  late final String _draftId;
  Timer? _draftTimer;
  ExpenseDraftController? _drafts;
  var _draftLoaded = false;
  var _savedReceipt = false;
  ExpenseReceiptRecord? _editingReceipt;

  bool get _isEditingReceipt => widget.receiptId != null;

  bool get _isMaterialsFlow =>
      widget.mode == ExpenseReceiptFlowMode.materials ||
      _editingReceipt?.sourceScreen == 'materials_expense_receipt';

  bool get _isMaintenanceRepairFlow =>
      widget.mode == ExpenseReceiptFlowMode.maintenanceRepair ||
      _editingReceipt?.sourceScreen == 'maintenance_repair_expense_receipt';

  ReceiptCaptureArea get _receiptCaptureArea {
    if (_isMaterialsFlow) return ReceiptCaptureArea.materialsInventory;
    if (_isMaintenanceRepairFlow) return ReceiptCaptureArea.maintenanceRepair;
    return ReceiptCaptureArea.expenses;
  }

  double get _businessTotal =>
      _lines
          .where((line) => line.use != _ExpenseLineUse.personal)
          .fold(0.0, (sum, line) => sum + line.businessAmount) +
      _allocatedReceiptAdjustment(_businessLineSubtotal);

  double get _personalTotal =>
      _lines
          .where((line) => line.use != _ExpenseLineUse.business)
          .fold(0.0, (sum, line) => sum + line.personalAmount) +
      _allocatedReceiptAdjustment(_personalLineSubtotal);

  double get _receiptTotal =>
      _enteredReceiptTotal ??
      _lineSubtotal + ((_enteredReceiptTax ?? 0) + _subtotalAdjustment);
  double get _lineSubtotal =>
      _lines.fold(0, (sum, line) => sum + line.subtotal);
  double get _businessLineSubtotal =>
      _lines.fold(0, (sum, line) => sum + line.businessAmount);
  double get _personalLineSubtotal =>
      _lines.fold(0, (sum, line) => sum + line.personalAmount);
  double? get _enteredReceiptSubtotal =>
      _parseMoneyInput(_receiptSubtotalController.text);
  double? get _enteredReceiptTax => _parseMoneyInput(_salesTaxController.text);
  double? get _enteredReceiptTotal =>
      _parseMoneyInput(_receiptTotalController.text);
  double get _subtotalAdjustment {
    final enteredSubtotal = _enteredReceiptSubtotal;
    if (enteredSubtotal == null) return 0;
    return enteredSubtotal - _lineSubtotal;
  }

  double get _receiptAdjustment => _receiptTotal - _lineSubtotal;

  double _allocatedReceiptAdjustment(double lineAmount) {
    if (_lineSubtotal <= 0 || _receiptAdjustment == 0) return 0;
    return _receiptAdjustment * (lineAmount / _lineSubtotal);
  }

  void _updateReceiptState(VoidCallback update) {
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _draftId =
        widget.draftId ?? 'EXPD-${DateTime.now().microsecondsSinceEpoch}';
    final date = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(date.year, date.month, date.day);
    _receiptAttachments.addAll(widget.initialAttachments);
    _hasReceipt = _receiptAttachments.isNotEmpty;
    _rawReceiptText = widget.initialImportedText.trim();
    for (final controller in [
      _storeController,
      _phoneController,
      _streetController,
      _cityController,
      _stateController,
      _zipController,
      _emailController,
      _websiteController,
      _storeNotesController,
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.addListener(_scheduleDraftSave);
    }
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.addListener(_refreshReceiptTotals);
    }
    if (_rawReceiptText.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _parseImportedReceiptText(_rawReceiptText);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanReceiptAttachmentsIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drafts = ExpenseDraftScope.maybeOf(context);
    if (_draftLoaded) return;
    _draftLoaded = true;
    final receiptId = widget.receiptId;
    if (receiptId != null) {
      final receipt = ExpenseLedgerScope.of(context).receiptById(receiptId);
      if (receipt == null) return;
      _applyReceipt(receipt);
      return;
    }
    final draftId = widget.draftId;
    if (draftId == null) {
      if (_receiptAttachments.isNotEmpty || _rawReceiptText.isNotEmpty) {
        unawaited(_saveDraftNow());
      }
      return;
    }
    final draft = _drafts?.draftById(draftId);
    if (draft == null) return;
    _applyDraft(draft);
    final missingProof =
        _drafts?.missingAttachmentsForDraft(draftId) ?? const [];
    if (missingProof.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${missingProof.length} receipt proof file${missingProof.length == 1 ? '' : 's'} could not be found. The draft fields were restored, but that proof may need to be reattached.',
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_savedReceipt && !_isEditingReceipt) {
      unawaited(_saveDraftNow());
    }
    if (!_savedReceipt && _isEditingReceipt) {
      unawaited(_discardUncommittedEditProofs());
    }
    for (final controller in [
      _storeController,
      _phoneController,
      _streetController,
      _cityController,
      _stateController,
      _zipController,
      _emailController,
      _websiteController,
      _storeNotesController,
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.removeListener(_scheduleDraftSave);
    }
    for (final controller in [
      _receiptSubtotalController,
      _salesTaxController,
      _receiptTotalController,
    ]) {
      controller.removeListener(_refreshReceiptTotals);
    }
    _storeController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _storeNotesController.dispose();
    _receiptSubtotalController.dispose();
    _salesTaxController.dispose();
    _receiptTotalController.dispose();
    super.dispose();
  }

  Future<void> _discardUncommittedEditProofs() {
    final originalIds = widget.initialAttachments
        .map((attachment) => attachment.id)
        .toSet();
    final uncommitted = _receiptAttachments.where(
      (attachment) =>
          attachment.storageState == ReceiptAttachmentStorageState.staged &&
          !originalIds.contains(attachment.id),
    );
    return ReceiptProofStorage.instance.deleteStagedAttachments(uncommitted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          children: [
            _ReceiptHeader(
              title: _isEditingReceipt
                  ? _isMaterialsFlow
                        ? 'Edit Materials Receipt'
                        : _isMaintenanceRepairFlow
                        ? 'Edit Maintenance Receipt'
                        : 'Edit Expense Receipt'
                  : _isMaterialsFlow
                  ? 'Materials Receipt'
                  : _isMaintenanceRepairFlow
                  ? 'Maintenance / Repair Receipt'
                  : 'Expense Receipt',
              subtitle: _isMaterialsFlow
                  ? 'Log material purchases as expenses. Inventory tracking is optional.'
                  : _isMaintenanceRepairFlow
                  ? 'Log the expense now. Maintenance event linking is next so the same receipt can update maintenance records.'
                  : _isEditingReceipt
                  ? 'Review and update the original saved receipt fields.'
                  : 'Record what was spent. Add each receipt line as business or personal.',
            ),
            const SizedBox(height: 8),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            if (_isMaterialsFlow) ...[
              _InventoryTrackingPrompt(
                value: _trackMaterialsInInventory,
                onChanged: (value) {
                  setState(() => _trackMaterialsInInventory = value);
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 8),
            ],
            SharedReceiptDateTimePanel(
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              onSelectDate: _selectDate,
              onSelectTime: _selectTime,
              onClearTime: () {
                setState(() => _selectedTime = null);
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            SharedReceiptAttachmentPanel(
              hasReceipt: _hasReceipt,
              area: _receiptCaptureArea,
              initialAttachments: _receiptAttachments,
              onChanged: (value) {
                setState(() => _hasReceipt = value);
                _scheduleDraftSave();
              },
              onAttachmentsChanged: (attachments) {
                setState(() {
                  _receiptAttachments
                    ..clear()
                    ..addAll(attachments);
                  _hasReceipt = attachments.isNotEmpty;
                });
                _scheduleDraftSave();
                _scanReceiptAttachmentsIfNeeded();
              },
              onImportedText: _parseImportedReceiptText,
            ),
            const SizedBox(height: 8),
            SharedReceiptStorePanel(
              store: _storeController,
              phone: _phoneController,
              street: _streetController,
              city: _cityController,
              state: _stateController,
              zip: _zipController,
              email: _emailController,
              website: _websiteController,
              notes: _storeNotesController,
              onChanged: () {
                setState(() {});
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            _ReceiptLineActionsPanel(
              nextLineNumber: _lines.length + 1,
              materialMode: _isMaterialsFlow,
              maintenanceRepairMode: _isMaintenanceRepairFlow,
              fuelMode: widget.initialCategory == 'Fuel',
              onAddBusiness: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  use: _ExpenseLineUse.business,
                  category: _isMaterialsFlow
                      ? 'Materials'
                      : widget.initialCategory ?? 'Uncategorized',
                ),
              ),
              onAddPersonal: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  use: _ExpenseLineUse.personal,
                  category: widget.initialCategory ?? 'Uncategorized',
                ),
              ),
              onAddShared: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  use: _ExpenseLineUse.split,
                  category: widget.initialCategory ?? 'Uncategorized',
                ),
              ),
              onAddMaterial: () => _editLine(
                initial: _ExpenseReceiptLine.blank(category: 'Materials'),
              ),
              onAddMaintenanceRepair: () => _editLine(
                initial: _ExpenseReceiptLine.blank(
                  category: widget.initialCategory == 'Maintenance'
                      ? 'Maintenance'
                      : 'Repair',
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ReceiptTotalsPanel(
              lineSubtotal: _lineSubtotal,
              receiptSubtotalController: _receiptSubtotalController,
              salesTaxController: _salesTaxController,
              receiptTotalController: _receiptTotalController,
            ),
            const SizedBox(height: 8),
            if (_receiptClassification != null) ...[
              _ReceiptClassificationReviewPanel(
                classification: _receiptClassification!,
                parseQuality: _lastParseQuality,
                maintenanceHints: _maintenanceHints,
                onApplyCategory: _applySuggestedReceiptCategory,
              ),
              const SizedBox(height: 8),
            ],
            _ReceiptRecapPanel(
              lines: _lines,
              receiptTotal: _receiptTotal,
              businessTotal: _businessTotal,
              personalTotal: _personalTotal,
              onEdit: (index) =>
                  _editLine(index: index, initial: _lines[index]),
              onDelete: (index) {
                setState(() => _lines.removeAt(index));
                _scheduleDraftSave();
              },
            ),
            const SizedBox(height: 8),
            _ReceiptSavePanel(
              lineCount: _lines.length,
              total: _receiptTotal,
              onSave: _saveReceipt,
            ),
          ],
        ),
      ),
    );
  }
}
