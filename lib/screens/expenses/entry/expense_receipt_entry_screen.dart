import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/receipts/receipt_processing_contract.dart';
import '../../../shared/receipts/receipt_ocr_handoff.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture.dart';
import '../../../shared/widgets/receipt_capture/receipt_proof_storage.dart';
import '../../../shared/widgets/receipt_form_sections.dart';
import '../categories/expense_categories.dart';
import '../data/expense_draft_store.dart';
import '../data/expense_cloud_backup_service.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_work_profile_store.dart';
import '../data/expense_materials_receipt_bridge.dart';
import '../data/expense_ocr_failure_diagnostics.dart';
import '../data/expense_parser_failure_diagnostics.dart';
import '../data/expense_receipt_category_rules.dart';
import '../data/expense_receipt_classifier.dart';
import '../data/expense_receipt_item_memory_store.dart';
import '../data/expense_receipt_ocr_candidate_fallback.dart';
import '../data/expense_receipt_parser.dart';
import '../data/expense_receipt_privacy_event_store.dart';
import '../data/expense_receipt_user_review_merge.dart';
import '../data/expense_screen_telemetry.dart';
import '../data/expense_screen_telemetry_recorder.dart';
import '../../../shared/odometer/odometer_correction_review.dart';
import '../../../shared/odometer/open_odometer_entry.dart';
import '../../../shared/odometer/odometer_mileage_review.dart';
import '../../../shared/odometer/odometer_review_dialogs.dart';
import '../../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/state/global_odometer.dart';

part 'expense_receipt_entry_state_actions.dart';
part 'expense_receipt_entry_split_percent_actions.dart';
part 'expense_receipt_entry_draft_actions.dart';
part 'expense_receipt_entry_ocr_actions.dart';
part 'expense_receipt_entry_imported_text_parse_actions.dart';
part 'expense_receipt_entry_telemetry_actions.dart';
part 'expense_receipt_entry_parser_telemetry_metadata.dart';
part 'expense_receipt_entry_parse_apply_actions.dart';
part 'expense_receipt_entry_split_percent_button.dart';
part 'expense_receipt_save_actions.dart';
part 'expense_receipt_save_readiness_helpers.dart';
part 'expense_receipt_save_readiness_dialog.dart';
part 'expense_receipt_duplicate_dialog.dart';
part 'expense_receipt_header.dart';
part 'expense_receipt_inventory_prompt.dart';
part 'expense_receipt_parse_review.dart';
part 'expense_receipt_parse_review_metrics.dart';
part 'expense_receipt_parse_review_intro_panel.dart';
part 'expense_receipt_parse_review_bottom_section_alert.dart';
part 'expense_receipt_parse_review_guidance.dart';
part 'expense_receipt_parse_review_guidance_factory.dart';
part 'expense_receipt_parse_review_guidance_detail_text.dart';
part 'expense_receipt_parse_review_guidance_fields.dart';
part 'expense_receipt_parse_review_instruction_widgets.dart';
part 'expense_receipt_parse_review_handoff_panel.dart';
part 'expense_receipt_parse_review_photo_recovery.dart';
part 'expense_receipt_parse_review_details.dart';
part 'expense_receipt_parse_review_ocr_review_row.dart';
part 'expense_receipt_parse_review_ocr_photo_helpers.dart';
part 'expense_receipt_parse_review_ocr_action_helpers.dart';
part 'expense_receipt_parse_review_ocr_readiness_helpers.dart';
part 'expense_receipt_parse_review_ocr_review_helpers.dart';
part 'expense_receipt_parse_review_line_evidence_panel.dart';
part 'expense_receipt_parse_review_line_evidence_controls.dart';
part 'expense_receipt_parse_review_misc_widgets.dart';
part 'expense_receipt_parse_review_text_helpers.dart';
part 'expense_receipt_line_actions.dart';
part 'expense_receipt_recap.dart';
part 'expense_receipt_recap_classification.dart';
part 'expense_receipt_recap_classification_guidance.dart';
part 'expense_receipt_recap_whole_use_button.dart';
part 'expense_receipt_recap_paper.dart';
part 'expense_receipt_recap_allocation_controls.dart';
part 'expense_receipt_recap_line_controls.dart';
part 'expense_receipt_totals.dart';
part 'expense_receipt_line_fields.dart';
part 'expense_receipt_category_picker.dart';
part 'expense_receipt_category_picker_widgets.dart';
part 'expense_receipt_line_editor.dart';
part 'expense_receipt_line_editor_derived_fields.dart';
part 'expense_receipt_line_editor_actions.dart';
part 'expense_receipt_line_editor_odometer_dialogs.dart';
part 'expense_receipt_line_models.dart';
part 'expense_receipt_line_computed_fields.dart';
part 'expense_receipt_line_model_conversions.dart';
part 'expense_receipt_line_labels.dart';
part 'expense_receipt_line_review_actions.dart';
part 'expense_receipt_line_support.dart';
part 'expense_receipt_entry_line_editor_launcher.dart';
part 'expense_receipt_entry_core_helpers.dart';
part 'expense_receipt_entry_totals_helpers.dart';
part 'expense_receipt_entry_photo_preparation_telemetry.dart';
part 'expense_receipt_entry_photo_preparation_telemetry_metadata.dart';
part 'expense_receipt_entry_photo_preparation_telemetry_tail.dart';
part 'expense_receipt_entry_diagnostic_bucket_helpers.dart';
part 'expense_receipt_entry_read_handoff_helpers.dart';
part 'expense_receipt_entry_read_handoff_metadata.dart';
part 'expense_receipt_entry_read_handoff_no_line_labels.dart';
part 'expense_receipt_entry_capture_diagnostic_helpers.dart';
part 'expense_receipt_entry_line_mode_helpers.dart';
part 'expense_receipt_detail_level_panel.dart';
part 'expense_receipt_category_scope_panel.dart';
part 'expense_receipt_entry_lifecycle_helpers.dart';
part 'expense_receipt_entry_attachment_panel.dart';
part 'expense_receipt_entry_start_guide.dart';
part 'expense_receipt_entry_scaffold.dart';
part 'expense_receipt_entry_manual_flow.dart';
part 'expense_receipt_entry_manual_flow_editors.dart';
part 'expense_receipt_entry_manual_widgets.dart';
part 'expense_receipt_entry_manual_details_widgets.dart';
part 'expense_receipt_entry_manual_summary_widgets.dart';
part 'expense_receipt_entry_manual_date_time.dart';
part 'expense_receipt_entry_no_line_recovery_panel.dart';
part 'expense_receipt_entry_byte_bucket.dart';
part 'expense_receipt_entry_odometer_prompt.dart';
part 'expense_receipt_entry_odometer_panel.dart';
part 'expense_receipt_entry_odometer_lifecycle.dart';
part 'expense_receipt_entry_job_context_panel.dart';

enum ExpenseReceiptFlowMode { general, materials, maintenanceRepair }

enum _ReceiptDetailEntryMode { basicReceipt, quickClassify, detailedItems }

enum _ManualReceiptStep { details, items, review }

extension _ReceiptDetailEntryModeX on _ReceiptDetailEntryMode {
  static _ReceiptDetailEntryMode fromSettingsStyle(
    ExpenseReceiptReviewStyle style,
  ) {
    return switch (style) {
      ExpenseReceiptReviewStyle.basicReceipt =>
        _ReceiptDetailEntryMode.basicReceipt,
      ExpenseReceiptReviewStyle.simpleAmounts =>
        _ReceiptDetailEntryMode.quickClassify,
      ExpenseReceiptReviewStyle.fullItemDetails =>
        _ReceiptDetailEntryMode.detailedItems,
      ExpenseReceiptReviewStyle.askEachTime =>
        _ReceiptDetailEntryMode.quickClassify,
    };
  }

  ExpenseReceiptReviewStyle get settingsStyle => switch (this) {
    _ReceiptDetailEntryMode.basicReceipt =>
      ExpenseReceiptReviewStyle.basicReceipt,
    _ReceiptDetailEntryMode.quickClassify =>
      ExpenseReceiptReviewStyle.simpleAmounts,
    _ReceiptDetailEntryMode.detailedItems =>
      ExpenseReceiptReviewStyle.fullItemDetails,
  };
}

class ExpenseReceiptEntryScreen extends StatefulWidget {
  const ExpenseReceiptEntryScreen({
    super.key,
    this.mode = ExpenseReceiptFlowMode.general,
    this.initialCategory,
    this.initialDate,
    this.initialOdometerReading,
    this.initialAttachments = const [],
    this.initialImportedText = '',
    this.draftId,
    this.receiptId,
    this.showInterruptedCaptureRecovery = false,
    this.fuelOcrHandoff,
    this.inventoryOcrHandoff,
  });

  final ExpenseReceiptFlowMode mode;
  final String? initialCategory;
  final DateTime? initialDate;
  final int? initialOdometerReading;
  final List<ReceiptAttachmentRecord> initialAttachments;
  final String initialImportedText;
  final String? draftId;
  final String? receiptId;
  final bool showInterruptedCaptureRecovery;
  final ReceiptOcrHandoffHandler<ExpenseReceiptParseResult>? fuelOcrHandoff;
  final ReceiptOcrHandoffHandler<ExpenseReceiptParseResult>?
  inventoryOcrHandoff;

  @override
  State<ExpenseReceiptEntryScreen> createState() =>
      _ExpenseReceiptEntryScreenState();
}

class _ExpenseReceiptEntryScreenState extends State<ExpenseReceiptEntryScreen>
    with WidgetsBindingObserver {
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
  final _receiptReadHandoffKey = GlobalKey();
  final _receiptPhotoRecoveryKey = GlobalKey();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  var _hasReceipt = false;
  final _receiptAttachments = <ReceiptAttachmentRecord>[];
  final _manualReceiptAttachmentController = ReceiptAttachmentPanelController();
  final _manualReceiptStoreController = SharedReceiptStorePanelController();
  var _rawReceiptText = '';
  var _scanningReceiptPhotos = false;
  var _receiptReviewFlowStarted = false;
  var _receiptReadAttemptedWithoutText = false;
  var _lastReceiptScanSignature = '';
  var _pendingReceiptScanSignature = '';
  ExpenseReceiptClassification? _receiptClassification;
  ExpenseReceiptParseQuality? _lastParseQuality;
  ExpenseReceiptParseDiagnostics? _lastParseDiagnostics;
  Map<String, ExpenseReceiptFieldConfidence> _lastFieldConfidences = const {};
  var _lastReceiptParseCompleted = false;
  var _lastReceiptParseHadUsableData = false;
  var _lastReceiptParseHadSafeLines = false;
  ReceiptOcrDiagnostics? _lastOcrDiagnostics;
  List<ReceiptOcrWarning> _lastOcrWarnings = const [];
  final _maintenanceHints = <ExpenseReceiptMaintenanceHint>[];
  var _receiptReadHandoffProofCount = 0;
  var _receiptReadHandoffOcrSourceCount = 0;
  var _receiptReadHandoffDecision = '';
  var _receiptReadHandoffAction = '';
  var _receiptReadHandoffStage = 'Waiting for receipt details';
  var _receiptReadHandoffRouteResult = '';
  var _receiptReadHandoffCoverageWarning = '';
  Map<String, int> _receiptBrainLowStorageDownloadRiskCounts = const {};
  Map<String, int> _receiptBrainFullOfflineMustStayOptionalCounts = const {};
  Map<String, int> _receiptBrainFullOfflineExceedsBaseGuardrailCounts =
      const {};
  Map<String, int> _receiptInstallRequiredSegmentCounts = const {};
  Map<String, int> _receiptInstallFullOfflineSegmentCounts = const {};
  Map<String, int> _receiptInstallLowStorageImpactCounts = const {};
  Map<String, int> _receiptInstallRecommendedDistributionCounts = const {};
  Map<String, int> _receiptInstallCameraShellParserFreeCounts = const {};
  Map<String, int> _receiptInstallBaseUsefulOnTinyPhonesCounts = const {};
  Map<String, int> _receiptInstallOptionalPacksRequireConsentCounts = const {};
  var _trackMaterialsInInventory = false;
  int? _expenseOdometerReading;
  var _detailEntryMode = _ReceiptDetailEntryMode.quickClassify;
  var _manualReceiptStep = _ManualReceiptStep.details;
  var _receiptCategory = 'Uncategorized';
  var _receiptCategoryAppliesToAll = false;
  var _receiptReviewModeChangedByUser = false;
  var _appliedReceiptReviewStyleDefault = false;
  var _receiptEntryGuideInitialized = false;
  var _showReceiptEntryGuide = false;
  var _applyingParsedFieldValues = false;
  var _merchantValueLockedByUser = false;
  var _receiptDateLockedByUser = false;
  var _receiptTimeLockedByUser = false;
  var _receiptSubtotalLockedByUser = false;
  var _receiptTaxLockedByUser = false;
  var _receiptTotalLockedByUser = false;
  String? _lastParsedMerchantValue;
  String? _lastParsedSubtotalValue;
  String? _lastParsedTaxValue;
  String? _lastParsedTotalValue;
  final _lines = <_ExpenseReceiptLine>[];
  late final String _draftId;
  Timer? _draftTimer;
  ExpenseDraftController? _drafts;
  var _draftLoaded = false;
  var _savedReceipt = false;
  var _draftSaveFailureShown = false;
  late final DateTime _screenOpenedAtUtc;
  ExpenseScreenTelemetrySnapshot? _telemetrySnapshot;
  var _telemetryAddFlowFinished = false;
  int _lastAttachmentCount = 0;
  ExpenseReceiptRecord? _editingReceipt;
  ExpenseReceiptContextSnapshot _expenseContext =
      const ExpenseReceiptContextSnapshot();

  void _setReceiptEntryState(VoidCallback update) {
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initReceiptEntryState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleReceiptEntryDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeReceiptEntryState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    _draftTimer?.cancel();
    unawaited(_saveDraftNow());
  }

  @override
  Widget build(BuildContext context) => _buildReceiptEntryScaffold(context);
}
