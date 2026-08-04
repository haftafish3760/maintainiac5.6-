import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../navigation/app_page_routes.dart';
import '../receipt_form/receipt_form_panel.dart';
import 'receipt_capture_flow.dart';
import 'receipt_acquired_photo_staging.dart';
import 'receipt_capture_models.dart';
import 'receipt_capture_diagnostics_policy.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_capture_ui_config.dart';
import 'receipt_image_processor.dart';
import 'receipt_image_picker.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_native_capture_staging.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_ocr_service.dart';
import 'receipt_photo_path_identity.dart';
import 'receipt_photo_review_screen.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_pdf_viewer_screen.dart';
import 'receipt_picker_status.dart';
import 'receipt_pipeline_trace.dart';
import 'receipt_proof_storage.dart';
import 'receipt_scanner_service.dart';
import 'receipt_storage_guard.dart';
import 'receipt_temporary_artifact_cleanup.dart';

part 'receipt_attachment_list.dart';
part 'receipt_attachment_summary.dart';
part 'receipt_attachment_panel_build.dart';
part 'receipt_imported_text_sheet.dart';
part 'receipt_attachment_initial_state.dart';
part 'receipt_attachment_button.dart';
part 'receipt_attachment_camera_actions.dart';
part 'receipt_attachment_camera_fallback_actions.dart';
part 'receipt_attachment_import_actions.dart';
part 'receipt_attachment_native_signal_documents.dart';
part 'receipt_attachment_native_signal_helpers.dart';
part 'receipt_attachment_ocr_source_signals.dart';
part 'receipt_attachment_ocr_source_continuation_signals.dart';
part 'receipt_attachment_ocr_source_risk_flags.dart';
part 'receipt_attachment_ocr_actions.dart';
part 'receipt_attachment_ocr_recovery_advice.dart';
part 'receipt_attachment_publish_helpers.dart';
part 'receipt_attachment_publish_signals.dart';
part 'receipt_attachment_recovery_actions.dart';
part 'receipt_attachment_review_read_actions.dart';
part 'receipt_attachment_status_widgets.dart';
part 'receipt_interrupted_capture_banner.dart';
part 'receipt_attachment_text_document_actions.dart';
part 'receipt_import_source_sheet.dart';
part 'receipt_import_source_help.dart';
part 'receipt_import_source_tile.dart';
part 'receipt_pdf_import_actions.dart';
part 'receipt_pdf_import_sheets.dart';
part 'receipt_pdf_duplicate_helpers.dart';
part 'receipt_pdf_selection_tile.dart';
part 'receipt_capture_settings_sheet.dart';
part 'receipt_capture_runtime_settings.dart';
part 'receipt_capture_review_storage_settings.dart';
part 'receipt_camera_help_sheet.dart';
part 'receipt_camera_first_use_intro_sheet.dart';
part 'receipt_attachment_target_guidance.dart';
part 'receipt_attachment_panel_controller.dart';

class SharedReceiptAttachmentPanel extends StatefulWidget {
  const SharedReceiptAttachmentPanel({
    super.key,
    required this.hasReceipt,
    required this.onChanged,
    this.showCamera = true,
    this.area = ReceiptCaptureArea.expenses,
    this.initialAttachments = const [],
    this.onAttachmentsChanged,
    this.onImportedText,
    this.onReceiptPhotoReviewAccepted,
    this.onReceiptReadStarted,
    this.onReceiptOcrCompleted,
    this.onReceiptOcrResultForReview,
    this.onReceiptReadFinished,
    this.onReceiptCaptureDiagnostic,
    this.receiptContinuationReasonCode,
    this.receiptContinuationGuidance,
    this.showInterruptedCaptureRecovery = true,
    this.openImportOptionsOnFirstBuild = false,
    this.closeParentWhenImportCanceled = false,
    this.uiConfig = const ReceiptCaptureUiConfig(),
    this.controller,
  });

  final bool hasReceipt;
  final ValueChanged<bool> onChanged;
  final bool showCamera;
  final ReceiptCaptureArea area;
  final List<ReceiptAttachmentRecord> initialAttachments;
  final ValueChanged<List<ReceiptAttachmentRecord>>? onAttachmentsChanged;
  final FutureOr<void> Function(String text)? onImportedText;
  final ValueChanged<ReceiptPhotoReviewResult>? onReceiptPhotoReviewAccepted;
  final VoidCallback? onReceiptReadStarted;
  final ValueChanged<ReceiptOcrResult>? onReceiptOcrCompleted;

  /// Receives the complete OCR evidence for an editable receipt handoff.
  ///
  /// Prefer this over [onImportedText] when the consumer can preserve OCR
  /// layout, coordinates, confidence, and source-image provenance.
  final FutureOr<void> Function(ReceiptOcrResult result, String traceId)?
  onReceiptOcrResultForReview;
  final ValueChanged<bool>? onReceiptReadFinished;
  final ValueChanged<Map<String, Object?>>? onReceiptCaptureDiagnostic;
  final String? receiptContinuationReasonCode;
  final String? receiptContinuationGuidance;
  final bool showInterruptedCaptureRecovery;
  final bool openImportOptionsOnFirstBuild;
  final bool closeParentWhenImportCanceled;
  final ReceiptCaptureUiConfig uiConfig;
  final ReceiptAttachmentPanelController? controller;

  @override
  State<SharedReceiptAttachmentPanel> createState() =>
      _SharedReceiptAttachmentPanelState();
}

class _SharedReceiptAttachmentPanelState
    extends State<SharedReceiptAttachmentPanel> {
  final List<String> _photoPaths = [];
  final Map<String, String> _photoIdByPath = {};
  final Map<String, ReceiptPhotoQualityCheck> _photoQualityByPath = {};
  final Map<String, Map<String, Object?>> _photoCaptureDiagnosticsByPath = {};
  final Map<String, ReceiptAttachmentReadState> _photoReadStateByPath = {};
  final List<ReceiptAttachmentRecord> _documentAttachments = [];
  var _openingPicker = false;
  var _readingForReview = false;
  var _reviewedPhotoReadInFlight = false;
  var _needsBottomReceiptSection = false;
  var _receiptReadStatus = _ReceiptReadStatusKind.success;
  var _receiptReadStatusMessage = '';
  var _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
  var _loadingRecoverableNativeCaptures = false;
  List<ReceiptNativeCaptureRecoveryRecord> _recoverableNativeCaptures =
      const [];
  ReceiptDataSaverLevel _dataSaverLevel = ReceiptDataSaverLevel.balanced;
  var _settingsApplied = false;
  var _panelDisposed = false;

  bool get _hasAttachment =>
      _photoPaths.isNotEmpty || _documentAttachments.isNotEmpty;

  bool get _receiptCaptureDiagnosticsImprovementEnabled {
    return ReceiptCaptureSettingsScope.maybeOf(
          context,
        )?.cameraDiagnosticsImprovementOptIn ??
        false;
  }

  bool get _appAssistedReceiptFillEnabled {
    return ReceiptCaptureSettingsScope.maybeOf(
          context,
        )?.appAssistedEnabledFor(widget.area) ==
        true;
  }

  void _publishReceiptCaptureDiagnostic(Map<String, Object?> diagnostic) {
    final envelope = const ReceiptCaptureDiagnosticPublishPolicy().envelope(
      improvementOptIn: _receiptCaptureDiagnosticsImprovementEnabled,
      diagnostic: diagnostic,
    );
    if (envelope.isEmpty) return;
    widget.onReceiptCaptureDiagnostic?.call(envelope);
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(
      openImportOptions: openReceiptImportOptions,
      openSettings: (screenContext) async {
        await openReceiptCaptureSettings(screenContext: screenContext);
      },
    );
    _applyInitialAttachments(widget.initialAttachments);
    if (widget.showInterruptedCaptureRecovery) {
      unawaited(_loadRecoverableNativeCaptures());
    }
    if (widget.openImportOptionsOnFirstBuild && !_hasAttachment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAttachment && !_openingPicker) {
          unawaited(openReceiptImportOptions());
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _panelDisposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SharedReceiptAttachmentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAttachments != widget.initialAttachments &&
        !_hasAttachment) {
      _applyInitialAttachments(widget.initialAttachments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildReceiptAttachmentPanel(context);
  }

  bool updateAttachmentState(VoidCallback update) {
    if (!mounted || _panelDisposed) return false;
    setState(update);
    return true;
  }
}
