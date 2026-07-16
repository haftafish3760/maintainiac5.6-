import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/maintaniac_localizations.dart';
import '../../backup/cloud_backup_status.dart';
import '../../storage/app_storage_guard.dart';
import 'receipt_capture_models.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_edge_cropper.dart';
import 'receipt_image_processor.dart';
import 'receipt_image_picker.dart';
import 'receipt_picker_status.dart';
import 'receipt_photo_review_retake_order.dart';
import 'receipt_photo_path_identity.dart';
import 'receipt_photo_review_ui_config.dart';
import 'receipt_storage_guard.dart';

part 'receipt_photo_review_controls.dart';
part 'receipt_photo_review_preview_action_tray.dart';
part 'receipt_photo_review_preview_action_status.dart';
part 'receipt_photo_review_top_bar.dart';
part 'receipt_photo_review_top_bar_buttons.dart';
part 'receipt_photo_review_image_edit_actions.dart';
part 'receipt_photo_review_alignment_guide.dart';
part 'receipt_photo_review_alignment_actions.dart';
part 'receipt_photo_review_capture_actions.dart';
part 'receipt_photo_review_capture_feedback.dart';
part 'receipt_photo_review_exit_actions.dart';
part 'receipt_photo_review_exit_stitch_actions.dart';
part 'receipt_photo_review_order_actions.dart';
part 'receipt_photo_review_save_actions.dart';
part 'receipt_photo_review_completion_actions.dart';
part 'receipt_photo_review_save_models.dart';
part 'receipt_photo_review_data_saver_panel.dart';
part 'receipt_photo_review_crop_and_proof_controls.dart';
part 'receipt_photo_review_crop_controls.dart';
part 'receipt_photo_review_stitch_controls.dart';
part 'receipt_photo_review_stitch_readiness.dart';
part 'receipt_photo_review_stitch_chips.dart';
part 'receipt_photo_review_order_controls.dart';
part 'receipt_photo_review_order_thumbnail.dart';
part 'receipt_photo_review_context_controls.dart';
part 'receipt_photo_review_preview_primary_row.dart';
part 'receipt_photo_review_mode_controls.dart';
part 'receipt_photo_review_common_controls.dart';
part 'receipt_photo_review_section_labels.dart';
part 'receipt_photo_review_build.dart';
part 'receipt_photo_review_surfaces.dart';
part 'receipt_photo_review_surface_controls.dart';
part 'receipt_photo_review_stitch_surface.dart';
part 'receipt_photo_review_photo_surface.dart';
part 'receipt_photo_review_async_work.dart';
part 'receipt_photo_review_stitch_preview_async.dart';
part 'receipt_photo_review_stitch_preview_widgets.dart';
part 'receipt_photo_review_stitch_pair_preview.dart';

enum _ReceiptReviewMode { preview, crop, order, stitch, dataSaver }

enum _ReceiptReviewMenuAction {
  addAdditionalPhotos,
  moveEarlier,
  moveLater,
  retake,
  remove,
}

enum _ReceiptReviewExitAction { keepReviewing, saveAndRead, leaveSafely }

enum _ReceiptContinueDecision { keepReviewing, addNextSection, continueAnyway }

class ReceiptPhotoReviewScreen extends StatefulWidget {
  const ReceiptPhotoReviewScreen({
    super.key,
    required this.initialPhotoPaths,
    required this.initialDataSaverLevel,
    this.bestShotCandidateMode = false,
    this.initialSelectedIndex = 0,
    this.initialQualityChecks = const [],
    this.initialQualityChecksByPath = const {},
    this.initialCaptureDiagnosticsByPath = const {},
    this.assistedReceiptFill = false,
    this.uiConfig = const ReceiptPhotoReviewUiConfig(),
  });

  final List<String> initialPhotoPaths;
  final ReceiptDataSaverLevel initialDataSaverLevel;
  final bool bestShotCandidateMode;
  final int initialSelectedIndex;
  final List<ReceiptPhotoQualityCheck> initialQualityChecks;
  final Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath;
  final Map<String, Map<String, Object?>> initialCaptureDiagnosticsByPath;
  final bool assistedReceiptFill;
  final ReceiptPhotoReviewUiConfig uiConfig;

  @override
  State<ReceiptPhotoReviewScreen> createState() =>
      _ReceiptPhotoReviewScreenState();
}

class _ReceiptPhotoReviewScreenState extends State<ReceiptPhotoReviewScreen> {
  late final List<String> _initialPhotoPaths = List<String>.of(
    uniqueNormalizedReceiptPhotoPaths(widget.initialPhotoPaths),
  );
  late final List<String> _photoPaths = [..._initialPhotoPaths];
  late ReceiptDataSaverLevel _dataSaverLevel =
      widget.initialDataSaverLevel == ReceiptDataSaverLevel.original
      ? ReceiptDataSaverLevel.balanced
      : widget.initialDataSaverLevel;
  late var _selectedIndex = _initialSelectedIndex();
  var _openingCamera = false;
  var _controlsVisible = true;
  late var _reviewMode = _initialReviewMode();
  var _cropProcessing = false;
  var _savingPhotos = false;
  var _selectedStitchPairIndex = 0;
  final _storagePreviews = <String, ReceiptImageStoragePreview>{};
  final _previewKeysInFlight = <String>{};
  final _qualityCheckKeysInFlight = <String>{};
  final _postFrameReviewWorkKeys = <String>{};
  final _completionDecisionsByPath = <String, Map<String, Object?>>{};
  final _dataSaverPreviewPaths = <String, String>{};
  final _dataSaverPreviewKeysInFlight = <String>{};
  final _generatedEditPaths = <String>{};
  late final _captureDiagnosticsByPath = _initialCaptureDiagnosticsByPath();
  final _manualOverlapFractions = <double?>[];
  var _closingReview = false;
  var _confirmingReviewExit = false;
  late final _qualityChecksByPath = _initialQualityChecksByPath();
  ReceiptStitchResult? _stitchPreviewResult;
  String? _stitchPreviewKey;
  bool _stitchPreviewInFlight = false;
  Timer? _stitchPreviewDebounce;
  var _reviewDisposed = false;
  var _reviewWorkGeneration = 0;
  Uint8List? _cropImageBytes;
  Size? _cropImageSize;
  Rect? _cropRect;
  Rect? _cropDisplayRect;
  String? _cropSourcePath;
  final _toolControlsScrollController = ScrollController();
  final _photoPreviewTransformController = TransformationController();
  TapDownDetails? _lastPhotoPreviewDoubleTap;

  ReceiptDeviceCapability get _deviceCapability {
    return ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
  }

  ReceiptStitchDeviceLimits get _stitchDeviceLimits {
    return _deviceCapability.stitchLimits;
  }

  bool _setPhotoReviewState(VoidCallback update) {
    if (!mounted) return false;
    setState(update);
    return true;
  }

  int _initialSelectedIndex() {
    if (_photoPaths.isEmpty) return 0;
    return widget.initialSelectedIndex.clamp(0, _photoPaths.length - 1);
  }

  _ReceiptReviewMode _initialReviewMode() {
    // Even for long receipts, start on the actual captured photo preview so
    // the user can immediately review, retake, add another section, or use it.
    return _ReceiptReviewMode.preview;
  }

  Map<String, Map<String, Object?>> _initialCaptureDiagnosticsByPath() {
    final diagnostics = <String, Map<String, Object?>>{};
    for (final entry in widget.initialCaptureDiagnosticsByPath.entries) {
      final normalizedPath = normalizedReceiptPhotoPath(entry.key);
      if (normalizedPath == null ||
          !receiptPhotoPathSetContains(_initialPhotoPaths, normalizedPath) ||
          diagnostics.containsKey(normalizedPath)) {
        continue;
      }
      diagnostics[normalizedPath] = Map<String, Object?>.unmodifiable(
        entry.value,
      );
    }
    return diagnostics;
  }

  @override
  void dispose() {
    _reviewDisposed = true;
    _invalidateReviewAsyncWork();
    _stitchPreviewDebounce?.cancel();
    _postFrameReviewWorkKeys.clear();
    _previewKeysInFlight.clear();
    _qualityCheckKeysInFlight.clear();
    _dataSaverPreviewKeysInFlight.clear();
    _toolControlsScrollController.dispose();
    _photoPreviewTransformController.dispose();
    unawaited(_deleteGeneratedStitchPreview());
    unawaited(_deleteGeneratedDataSaverPreviews());
    unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photoPaths.isEmpty) return _buildEmptyReviewRecovery();
    final selectedPhotoIndex = _selectedIndex.clamp(0, _photoPaths.length - 1);
    final photoPath = _photoPaths[selectedPhotoIndex];
    _syncManualOverlapSlots();
    _schedulePostFrameReviewWork(photoPath);
    if (_reviewMode == _ReceiptReviewMode.dataSaver) {
      _scheduleDataSaverPreviewWork(photoPath);
    }
    if (_reviewMode == _ReceiptReviewMode.stitch && _photoPaths.length > 1) {
      _ensureStitchPreview();
    }
    return _buildPhotoReviewScaffold(context, photoPath);
  }
}
