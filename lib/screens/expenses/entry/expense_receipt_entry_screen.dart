import 'dart:async';
import 'dart:math' as math;

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
import '../data/expense_ocr_failure_diagnostics.dart';
import '../data/expense_parser_failure_diagnostics.dart';
import '../data/expense_receipt_category_rules.dart';
import '../data/expense_receipt_classifier.dart';
import '../data/expense_receipt_item_memory_store.dart';
import '../data/expense_receipt_parser.dart';
import '../data/expense_receipt_privacy_event_store.dart';
import '../data/expense_screen_telemetry.dart';
import '../data/expense_screen_telemetry_recorder.dart';
import '../../../shared/odometer/odometer_correction_review.dart';
import '../../../shared/odometer/odometer_mileage_review.dart';
import '../../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/state/global_odometer.dart';

part 'expense_receipt_entry_state_actions.dart';
part 'expense_receipt_save_actions.dart';
part 'expense_receipt_duplicate_dialog.dart';
part 'expense_receipt_header.dart';
part 'expense_receipt_inventory_prompt.dart';
part 'expense_receipt_detail_mode_panel.dart';
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

enum _ReceiptDetailEntryMode { quickClassify, detailedItems }

extension _ReceiptDetailEntryModeX on _ReceiptDetailEntryMode {
  ExpenseReceiptReviewStyle get settingsStyle {
    return switch (this) {
      _ReceiptDetailEntryMode.quickClassify =>
        ExpenseReceiptReviewStyle.simpleAmounts,
      _ReceiptDetailEntryMode.detailedItems =>
        ExpenseReceiptReviewStyle.fullItemDetails,
    };
  }

  static _ReceiptDetailEntryMode fromSettingsStyle(
    ExpenseReceiptReviewStyle style,
  ) {
    return switch (style) {
      ExpenseReceiptReviewStyle.simpleAmounts =>
        _ReceiptDetailEntryMode.quickClassify,
      ExpenseReceiptReviewStyle.fullItemDetails =>
        _ReceiptDetailEntryMode.detailedItems,
    };
  }
}

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
  final _receiptScrollController = ScrollController();
  final _receiptReviewKey = GlobalKey();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  var _hasReceipt = false;
  final _receiptAttachments = <ReceiptAttachmentRecord>[];
  var _rawReceiptText = '';
  var _scanningReceiptPhotos = false;
  var _lastReceiptScanSignature = '';
  ExpenseReceiptClassification? _receiptClassification;
  ExpenseReceiptParseQuality? _lastParseQuality;
  Map<String, ExpenseReceiptFieldConfidence> _lastFieldConfidences = const {};
  ReceiptOcrDiagnostics? _lastOcrDiagnostics;
  List<ReceiptOcrWarning> _lastOcrWarnings = const [];
  final _maintenanceHints = <ExpenseReceiptMaintenanceHint>[];
  var _trackMaterialsInInventory = false;
  var _detailEntryMode = _ReceiptDetailEntryMode.quickClassify;
  var _appliedReceiptReviewStyleDefault = false;
  final _lines = <_ExpenseReceiptLine>[];
  late final String _draftId;
  Timer? _draftTimer;
  ExpenseDraftController? _drafts;
  var _draftLoaded = false;
  var _savedReceipt = false;
  late final DateTime _screenOpenedAtUtc;
  var _telemetryAddFlowFinished = false;
  int _lastAttachmentCount = 0;
  ExpenseReceiptRecord? _editingReceipt;

  bool get _isEditingReceipt => widget.receiptId != null;

  int get _unreviewedParsedLineCount {
    return _lines.where((line) => line.parserNeedsReview).length;
  }

  ExpenseFailureDiagnostic get _abandonedReceiptEntryDiagnostic {
    if (_scanningReceiptPhotos) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptOcr,
        failedAt: 'receipt_ocr_in_progress',
        confirmedCause: 'user_left_during_receipt_ocr',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'ocr_scan_active_when_screen_closed',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (!_hasReceipt &&
        _receiptAttachments.isEmpty &&
        _rawReceiptText.isEmpty) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptAttachment,
        failedAt: 'before_receipt_attachment',
        confirmedCause: 'user_left_before_receipt_attachment',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'no_receipt_proof_or_imported_text',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (_lines.isEmpty) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.lineReview,
        failedAt: 'before_first_receipt_line',
        confirmedCause: 'user_left_before_first_receipt_line',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'receipt_line_count_zero',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    if (_unreviewedParsedLineCount > 0) {
      return const ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.lineReview,
        failedAt: 'unreviewed_parsed_lines',
        confirmedCause: 'user_left_with_unreviewed_parsed_lines',
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: 'unreviewed_line_count_positive',
        missingEvidence: 'none',
        abandoned: true,
      );
    }
    return const ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.saveExpense,
      failedAt: 'before_receipt_save',
      confirmedCause: 'user_left_before_receipt_save',
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence: 'receipt_lines_present_not_saved',
      missingEvidence: 'none',
      abandoned: true,
    );
  }

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
      _allocatedReceiptAdjustment(_businessAdjustmentBase);

  double get _personalTotal =>
      _lines
          .where((line) => line.use != _ExpenseLineUse.business)
          .fold(0.0, (sum, line) => sum + line.personalAmount) +
      _allocatedReceiptAdjustment(_personalAdjustmentBase);

  double get _receiptTotal =>
      _enteredReceiptTotal ??
      _lineSubtotal + ((_enteredReceiptTax ?? 0) + _subtotalAdjustment);
  double get _lineSubtotal =>
      _lines.fold(0, (sum, line) => sum + line.subtotal);
  double get _businessAdjustmentBase =>
      _lines.fold(0, (sum, line) => sum + math.max(0, line.businessAmount));
  double get _personalAdjustmentBase =>
      _lines.fold(0, (sum, line) => sum + math.max(0, line.personalAmount));
  double get _receiptAdjustmentBase =>
      _businessAdjustmentBase + _personalAdjustmentBase;
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

  String get _receiptDateLabel {
    final date =
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
    final time = _selectedTime;
    if (time == null) return date;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$date $hour:$minute $period';
  }

  String get _receiptStoreAddressLabel {
    return [
      _streetController.text.trim(),
      [
        _cityController.text.trim(),
        _stateController.text.trim(),
        _zipController.text.trim(),
      ].where((part) => part.isNotEmpty).join(' '),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  double _allocatedReceiptAdjustment(double lineAmount) {
    if (_receiptAdjustmentBase <= 0 || _receiptAdjustment == 0) return 0;
    return _receiptAdjustment * (lineAmount / _receiptAdjustmentBase);
  }

  void _updateReceiptState(VoidCallback update) {
    setState(update);
  }

  void _scrollToReceiptReview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reviewContext = _receiptReviewKey.currentContext;
      if (reviewContext == null) return;
      Scrollable.ensureVisible(
        reviewContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _markReceiptReadStarted() {
    if (!mounted || _scanningReceiptPhotos) return;
    _updateReceiptState(() => _scanningReceiptPhotos = true);
  }

  void _markReceiptReadFinished(bool didRead) {
    if (!mounted || didRead) return;
    _updateReceiptState(() => _scanningReceiptPhotos = false);
  }

  void _setReceiptReviewMode(_ReceiptDetailEntryMode value) {
    setState(() => _detailEntryMode = value);
    _scheduleDraftSave();
    unawaited(
      ExpenseSettingsScope.of(
        context,
      ).setReceiptReviewStyle(value.settingsStyle),
    );
  }

  Future<void> _addReceiptLineForMode({
    required _ExpenseLineUse use,
    required String category,
  }) async {
    if (_detailEntryMode == _ReceiptDetailEntryMode.detailedItems ||
        widget.initialCategory == 'Fuel' ||
        _isMaintenanceRepairFlow) {
      await _editLine(
        initial: _ExpenseReceiptLine.blank(use: use, category: category),
      );
      return;
    }
    final line = await _showQuickClassifyLineSheet(
      use: use,
      category: category,
      lineNumber: _lines.length + 1,
    );
    if (line == null || !mounted) return;
    setState(() => _lines.add(line));
    _scheduleDraftSave();
  }

  void _addReceiptTotalLine({
    required _ExpenseLineUse use,
    required String category,
  }) {
    final amount =
        _enteredReceiptTotal ?? _enteredReceiptSubtotal ?? _receiptTotal;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the receipt total first, or add the line manually.',
          ),
        ),
      );
      return;
    }
    final line = _ExpenseReceiptLine(
      description: switch (use) {
        _ExpenseLineUse.business => 'Business receipt total',
        _ExpenseLineUse.personal => 'Personal receipt total',
        _ExpenseLineUse.split => 'Split receipt total',
      },
      category: category,
      use: use,
      quantity: 1,
      unitsPerPackage: 1,
      stockUnit: 'receipt',
      subtotal: amount,
      businessPercent: use == _ExpenseLineUse.split ? .5 : null,
      rawReceiptText: _rawReceiptText,
      parserConfidence: _lastParseQuality?.confidence,
      parserReviewLabel: 'Review',
      parserReviewReason:
          'OCR read receipt text, but line items were not safe enough. User chose to save the receipt total.',
      parserNeedsReview: false,
    );
    setState(() => _lines.add(line));
    _scheduleDraftSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receipt total added. Review classification before saving.',
        ),
      ),
    );
  }

  Future<_ExpenseReceiptLine?> _showQuickClassifyLineSheet({
    required _ExpenseLineUse use,
    required String category,
    required int lineNumber,
  }) async {
    final amount = TextEditingController();
    final businessPercent = TextEditingController(text: '50');
    try {
      return await showModalBottomSheet<_ExpenseReceiptLine>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              10,
              10,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ReceiptFormPanel(
                  title: 'Receipt Line $lineNumber',
                  subtitle:
                      'Enter the amount from this receipt line and choose how it should count. The receipt photo stays attached as proof.',
                  icon: switch (use) {
                    _ExpenseLineUse.business => Icons.business_center_rounded,
                    _ExpenseLineUse.personal => Icons.person_rounded,
                    _ExpenseLineUse.split => Icons.call_split_rounded,
                  },
                  accentColor: switch (use) {
                    _ExpenseLineUse.business => const Color(0xFF34A9E8),
                    _ExpenseLineUse.personal => const Color(0xFF8F9BA1),
                    _ExpenseLineUse.split => const Color(0xFFFFD166),
                  },
                  children: [
                    _LineUseBanner(use: use),
                    if (use == _ExpenseLineUse.split) ...[
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Business %',
                        helperText:
                            'Enter the business portion. The rest is personal.',
                        controller: businessPercent,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Line Amount',
                      helperText:
                          'Use the amount from this receipt line. Description and item details can be left out.',
                      controller: amount,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final subtotal = _parseMoneyInput(amount.text) ?? 0;
                        if (subtotal <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter the line amount first.'),
                            ),
                          );
                          return;
                        }
                        final percent =
                            (double.tryParse(businessPercent.text.trim()) ??
                                50) /
                            100;
                        Navigator.of(context).pop(
                          _ExpenseReceiptLine(
                            description: switch (use) {
                              _ExpenseLineUse.business =>
                                'Business receipt items',
                              _ExpenseLineUse.personal =>
                                'Personal receipt items',
                              _ExpenseLineUse.split => 'Split receipt items',
                            },
                            category: category,
                            use: use,
                            quantity: 1,
                            unitsPerPackage: 1,
                            stockUnit: 'each',
                            subtotal: subtotal,
                            businessPercent: use == _ExpenseLineUse.split
                                ? percent.clamp(0, 1)
                                : null,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Line'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      amount.dispose();
      businessPercent.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _screenOpenedAtUtc = DateTime.now().toUtc();
    _draftId =
        widget.draftId ?? 'EXPD-${DateTime.now().microsecondsSinceEpoch}';
    final date = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(date.year, date.month, date.day);
    _receiptAttachments.addAll(widget.initialAttachments);
    _lastAttachmentCount = _receiptAttachments.length;
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
        if (mounted) unawaited(_parseImportedReceiptText(_rawReceiptText));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ExpenseScreenTelemetryRecorder.record(
        context,
        _isEditingReceipt
            ? ExpenseTelemetryEventType.editExpenseOpened
            : ExpenseTelemetryEventType.addExpenseStarted,
        metadata: {
          'entryMode': _isEditingReceipt ? 'edit' : 'receipt',
          'source': _receiptPrivacyFeatureArea,
        },
      );
      _scanReceiptAttachmentsIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drafts = ExpenseDraftScope.maybeOf(context);
    if (!_appliedReceiptReviewStyleDefault) {
      _appliedReceiptReviewStyleDefault = true;
      _detailEntryMode = _ReceiptDetailEntryModeX.fromSettingsStyle(
        ExpenseSettingsScope.of(context).receiptReviewStyle,
      );
    }
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
    final elapsedMs = DateTime.now()
        .toUtc()
        .difference(_screenOpenedAtUtc)
        .inMilliseconds
        .clamp(0, 86400000);
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.screenClosed,
      durationMs: elapsedMs,
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.timeSpentOnScreen,
      durationMs: elapsedMs,
      metadata: {'source': _receiptPrivacyFeatureArea},
    );
    if (!_isEditingReceipt && !_telemetryAddFlowFinished) {
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.addExpenseAbandoned,
        diagnostic: _abandonedReceiptEntryDiagnostic,
        metadata: {
          'entryMode': 'receipt',
          'source': _receiptPrivacyFeatureArea,
        },
      );
    }
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
    _receiptScrollController.dispose();
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
          controller: _receiptScrollController,
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
                final previousCount = _lastAttachmentCount;
                setState(() {
                  _receiptAttachments
                    ..clear()
                    ..addAll(attachments);
                  _hasReceipt = attachments.isNotEmpty;
                });
                _lastAttachmentCount = attachments.length;
                if (attachments.length > previousCount) {
                  final newest = attachments.last;
                  ExpenseScreenTelemetryRecorder.record(
                    context,
                    ExpenseTelemetryEventType.imageAttachSuccess,
                    metadata: {
                      'attachmentKind': newest.kind.name,
                      'bytesBucket': _byteBucket(newest.byteSize),
                    },
                  );
                  ExpenseScreenTelemetryRecorder.record(
                    context,
                    ExpenseTelemetryEventType.storageModeUsed,
                    metadata: {
                      'storageAction':
                          ExpenseScreenTelemetryRecorder.storageModeForAttachment(
                            newest,
                          ).name,
                    },
                  );
                } else if (attachments.length < previousCount) {
                  ExpenseScreenTelemetryRecorder.record(
                    context,
                    ExpenseTelemetryEventType.localImageRemoved,
                    metadata: {'storageAction': 'attachment_removed'},
                  );
                }
                _scheduleDraftSave();
              },
              onImportedText: _parseImportedReceiptText,
              onReceiptReadStarted: _markReceiptReadStarted,
              onReceiptReadFinished: _markReceiptReadFinished,
            ),
            const SizedBox(height: 8),
            if (_scanningReceiptPhotos) ...[
              const ReceiptPickerStatus(
                label:
                    'Reading the receipt and preparing the filled review section below...',
              ),
              const SizedBox(height: 8),
            ],
            if (_receiptClassification != null || _lines.isNotEmpty) ...[
              KeyedSubtree(
                key: _receiptReviewKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReceiptFormPanel(
                      title: 'App-Assisted Receipt Review',
                      subtitle:
                          'This is the filled receipt review from the photo. Check the store, date, totals, and lines, then choose Business, Personal, or Mixed before saving.',
                      icon: Icons.fact_check_rounded,
                      accentColor: const Color(0xFF8EF6A4),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ReceiptReviewStepMetric(
                                label: 'Lines',
                                value: '${_lines.length}',
                                color: const Color(0xFFFFD166),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ReceiptReviewStepMetric(
                                label: 'Needs Review',
                                value:
                                    '${_lines.where((line) => line.parserNeedsReview).length}',
                                color:
                                    _lines.any((line) => line.parserNeedsReview)
                                    ? const Color(0xFFFFD166)
                                    : const Color(0xFF8EF6A4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ReceiptReviewStepMetric(
                                label: 'Total',
                                value: _money(_receiptTotal),
                                color: const Color(0xFF34A9E8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_receiptClassification != null) ...[
                      _ReceiptClassificationReviewPanel(
                        classification: _receiptClassification!,
                        parseQuality: _lastParseQuality,
                        fieldConfidences: _lastFieldConfidences,
                        ocrDiagnostics: _lastOcrDiagnostics,
                        ocrWarnings: _lastOcrWarnings,
                        maintenanceHints: _maintenanceHints,
                        onApplyCategory: _applySuggestedReceiptCategory,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_lines.isEmpty) ...[
                      ReceiptFormPanel(
                        title: 'No Line Items Found',
                        subtitle:
                            'The receipt text was read, but the app could not safely build line items. Use the receipt total if that is enough, or add line items manually.',
                        icon: Icons.edit_note_rounded,
                        accentColor: const Color(0xFFFFD166),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ReceiptReviewStepMetric(
                                  label: 'Receipt Total',
                                  value: _money(_receiptTotal),
                                  color: const Color(0xFF34A9E8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ReceiptReviewStepMetric(
                                  label: 'OCR Lines',
                                  value: _lastOcrDiagnostics == null
                                      ? '0'
                                      : '${_lastOcrDiagnostics!.rawLineCount}',
                                  color: const Color(0xFFFFD166),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ReceiptNoLineRecoveryChip(
                                icon: Icons.business_center_rounded,
                                label: 'Use Total As Business',
                                color: const Color(0xFF34A9E8),
                                onPressed: () => _addReceiptTotalLine(
                                  use: _ExpenseLineUse.business,
                                  category:
                                      widget.initialCategory ?? 'Uncategorized',
                                ),
                              ),
                              _ReceiptNoLineRecoveryChip(
                                icon: Icons.person_rounded,
                                label: 'Use Total As Personal',
                                color: const Color(0xFF8F9BA1),
                                onPressed: () => _addReceiptTotalLine(
                                  use: _ExpenseLineUse.personal,
                                  category:
                                      widget.initialCategory ?? 'Uncategorized',
                                ),
                              ),
                              _ReceiptNoLineRecoveryChip(
                                icon: Icons.call_split_rounded,
                                label: 'Split Total 50/50',
                                color: const Color(0xFFFFD166),
                                onPressed: () => _addReceiptTotalLine(
                                  use: _ExpenseLineUse.split,
                                  category:
                                      widget.initialCategory ?? 'Uncategorized',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () => _addReceiptLineForMode(
                              use: _ExpenseLineUse.business,
                              category:
                                  widget.initialCategory ?? 'Uncategorized',
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Line Manually'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD166),
                              foregroundColor: const Color(0xFF101416),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_lines.isNotEmpty) ...[
                      _ReceiptWholeUseReviewPanel(
                        lines: _lines,
                        onMarkBusiness: () =>
                            _markAllReceiptLines(_ExpenseLineUse.business),
                        onMarkPersonal: () =>
                            _markAllReceiptLines(_ExpenseLineUse.personal),
                        onMarkMixed: () =>
                            _markAllReceiptLines(_ExpenseLineUse.split),
                      ),
                      const SizedBox(height: 8),
                      if (_lines.any((line) => line.hasParserReview)) ...[
                        _ReceiptLineEvidenceReviewPanel(
                          lines: _lines,
                          onConfirm: _confirmParsedLine,
                          onEdit: (index) =>
                              _editLine(index: index, initial: _lines[index]),
                          onMarkExpenseOnly: _markLineExpenseOnly,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReceiptRecapPanel(
                        lines: _lines,
                        storeName: _storeController.text.trim(),
                        storeAddress: _receiptStoreAddressLabel,
                        receiptDateLabel: _receiptDateLabel,
                        receiptSubtotal: _enteredReceiptSubtotal,
                        salesTax: _enteredReceiptTax,
                        receiptTotal: _receiptTotal,
                        businessTotal: _businessTotal,
                        personalTotal: _personalTotal,
                        onEdit: (index) =>
                            _editLine(index: index, initial: _lines[index]),
                        onSetUse: _setReceiptLineUse,
                        onDelete: (index) {
                          setState(() => _lines.removeAt(index));
                          _scheduleDraftSave();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
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
            _ReceiptDetailModePanel(
              value: _detailEntryMode,
              onChanged: _setReceiptReviewMode,
            ),
            const SizedBox(height: 8),
            _ReceiptLineActionsPanel(
              nextLineNumber: _lines.length + 1,
              materialMode: _isMaterialsFlow,
              maintenanceRepairMode: _isMaintenanceRepairFlow,
              fuelMode: widget.initialCategory == 'Fuel',
              detailedMode:
                  _detailEntryMode == _ReceiptDetailEntryMode.detailedItems,
              onAddBusiness: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.business,
                category: _isMaterialsFlow
                    ? 'Materials'
                    : widget.initialCategory ?? 'Uncategorized',
              ),
              onAddPersonal: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.personal,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
              onAddShared: () => _addReceiptLineForMode(
                use: _ExpenseLineUse.split,
                category: widget.initialCategory ?? 'Uncategorized',
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
            _ReceiptSavePanel(
              lineCount: _lines.length,
              reviewCount: _lines
                  .where((line) => line.parserNeedsReview)
                  .length,
              total: _receiptTotal,
              onSave: _saveReceipt,
            ),
          ],
        ),
      ),
    );
  }
}

String _byteBucket(int? bytes) {
  final value = bytes ?? 0;
  if (value <= 0) return 'unknown';
  if (value < 100 * 1024) return 'under_100kb';
  if (value < 500 * 1024) return 'under_500kb';
  if (value < 1024 * 1024) return 'under_1mb';
  if (value < 5 * 1024 * 1024) return 'under_5mb';
  return 'over_5mb';
}
