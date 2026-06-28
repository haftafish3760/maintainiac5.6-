import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../navigation/app_page_routes.dart';
import '../../state/expense_settings_store.dart';
import '../receipt_form/receipt_form_panel.dart';
import 'receipt_capture_models.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_camera_permission.dart';
import 'receipt_image_processor.dart';
import 'receipt_image_picker.dart';
import 'receipt_assistance_policy.dart';
import 'receipt_native_capture_staging.dart';
import 'receipt_native_camera_contract.dart';
import 'receipt_native_camera_service.dart';
import 'receipt_ocr_service.dart';
import 'receipt_photo_review_screen.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_pdf_viewer_screen.dart';
import 'receipt_picker_status.dart';
import 'receipt_proof_storage.dart';
import 'receipt_scanner_service.dart';
import 'receipt_storage_guard.dart';

part 'receipt_attachment_list.dart';
part 'receipt_imported_text_sheet.dart';
part 'receipt_attachment_button.dart';
part 'receipt_attachment_import_actions.dart';
part 'receipt_attachment_ocr_actions.dart';
part 'receipt_import_source_sheet.dart';
part 'receipt_import_source_tile.dart';
part 'receipt_pdf_import_actions.dart';
part 'receipt_pdf_import_sheets.dart';
part 'receipt_pdf_duplicate_helpers.dart';
part 'receipt_pdf_selection_tile.dart';
part 'receipt_capture_settings_sheet.dart';
part 'receipt_camera_help_sheet.dart';

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
    this.onReceiptReadFinished,
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
  final ValueChanged<bool>? onReceiptReadFinished;

  @override
  State<SharedReceiptAttachmentPanel> createState() =>
      _SharedReceiptAttachmentPanelState();
}

class _SharedReceiptAttachmentPanelState
    extends State<SharedReceiptAttachmentPanel> {
  final List<String> _photoPaths = [];
  final Map<String, String> _photoIdByPath = {};
  final Map<String, ReceiptPhotoQualityCheck> _photoQualityByPath = {};
  final Map<String, ReceiptAttachmentReadState> _photoReadStateByPath = {};
  final List<ReceiptAttachmentRecord> _documentAttachments = [];
  var _openingPicker = false;
  var _readingForReview = false;
  var _receiptReadStatus = _ReceiptReadStatusKind.success;
  var _receiptReadStatusMessage = '';
  var _loadingRecoverableNativeCaptures = false;
  List<ReceiptNativeCaptureRecoveryRecord> _recoverableNativeCaptures =
      const [];
  ReceiptDataSaverLevel _dataSaverLevel = ReceiptDataSaverLevel.balanced;
  var _settingsApplied = false;
  var _panelDisposed = false;

  bool get _hasAttachment =>
      _photoPaths.isNotEmpty || _documentAttachments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _applyInitialAttachments(widget.initialAttachments);
    unawaited(_loadRecoverableNativeCaptures());
  }

  @override
  void dispose() {
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

  void _applyInitialAttachments(List<ReceiptAttachmentRecord> attachments) {
    _photoPaths
      ..clear()
      ..addAll(
        attachments
            .where((attachment) => attachment.isPhoto)
            .map((attachment) => attachment.path)
            .where((path) => path.trim().isNotEmpty),
      );
    _photoIdByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .where((attachment) => attachment.id.trim().isNotEmpty)
            .map((attachment) => MapEntry(attachment.path, attachment.id)),
      );
    _photoQualityByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .map((attachment) {
              final quality = _qualityCheckFromAttachment(attachment);
              return quality == null
                  ? null
                  : MapEntry(attachment.path, quality);
            })
            .whereType<MapEntry<String, ReceiptPhotoQualityCheck>>(),
      );
    _photoReadStateByPath
      ..clear()
      ..addEntries(
        attachments
            .where((attachment) => attachment.isPhoto)
            .where((attachment) => attachment.path.trim().isNotEmpty)
            .map(
              (attachment) => MapEntry(attachment.path, attachment.readState),
            ),
      );
    _documentAttachments
      ..clear()
      ..addAll(attachments.where((attachment) => !attachment.isPhoto));
    if (attachments.isNotEmpty) {
      _dataSaverLevel = attachments.last.dataSaverLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (!_settingsApplied && settings != null && !_hasAttachment) {
      _settingsApplied = true;
      _dataSaverLevel = settings.defaultDataSaverLevel;
    }
    return ReceiptFormPanel(
      title: 'Attach A Receipt',
      subtitle:
          'Add receipt proof from the camera, gallery, device files, or another app.',
      icon: Icons.receipt_long_rounded,
      trailing: IconButton(
        tooltip: 'Receipt photo settings',
        onPressed: _openReceiptCaptureSettings,
        icon: const Icon(Icons.settings_rounded),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF11181B),
          foregroundColor: const Color(0xFFFFD166),
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Color(0xFF56666E)),
          ),
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptButton(
                icon: Icons.add_rounded,
                label: 'Add Receipt',
                onTap: _openingPicker ? null : _openReceiptImportOptions,
              ),
            ),
          ],
        ),
        if (_openingPicker) ...[
          const SizedBox(height: 8),
          const ReceiptPickerStatus(),
        ],
        if (_recoverableNativeCaptures.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptInterruptedCaptureBanner(
            record: _recoverableNativeCaptures.first,
            total: _recoverableNativeCaptures.length,
            loading: _loadingRecoverableNativeCaptures,
            onResume: _openingPicker
                ? null
                : () => unawaited(
                    _resumeRecoverableNativeCapture(
                      _recoverableNativeCaptures.first,
                    ),
                  ),
            onDismiss: _openingPicker
                ? null
                : () => unawaited(
                    _dismissRecoverableNativeCapture(
                      _recoverableNativeCaptures.first,
                    ),
                  ),
          ),
        ],
        if (_readingForReview || _receiptReadStatusMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReceiptReadReviewStatus(
            reading: _readingForReview,
            status: _receiptReadStatus,
            message: _receiptReadStatusMessage,
          ),
        ],
        if (_hasAttachment) ...[
          const SizedBox(height: 10),
          _ReceiptAttachmentSummary(
            photoCount: _photoPaths.length,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            appAssistedEnabled:
                settings?.appAssistedEnabledFor(widget.area) != false,
            onReview: _reviewPhotos,
          ),
          const SizedBox(height: 8),
          _ReceiptAttachmentList(
            photoPaths: _photoPaths,
            photoQualityByPath: _photoQualityByPath,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            onReviewPhotos: _reviewPhotos,
            onRemovePhoto: (index) => unawaited(_removePhotoAt(index)),
            onRemoveDocument: _removeDocument,
            onEditDocument: _editDocument,
            onReadDocument: _readDocumentForReceipt,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openingPicker ? null : _openReceiptImportOptions,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add More Proof'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _requestClearAttachments,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _loadRecoverableNativeCaptures() async {
    if (_loadingRecoverableNativeCaptures) return;
    _updateAttachmentState(() => _loadingRecoverableNativeCaptures = true);
    try {
      final records = await const ReceiptNativeCaptureStaging()
          .recoverableNativeCaptures();
      _updateAttachmentState(() {
        _recoverableNativeCaptures = records;
        _loadingRecoverableNativeCaptures = false;
      });
    } catch (_) {
      _updateAttachmentState(() {
        _recoverableNativeCaptures = const [];
        _loadingRecoverableNativeCaptures = false;
      });
    }
  }

  Future<void> _resumeRecoverableNativeCapture(
    ReceiptNativeCaptureRecoveryRecord record,
  ) async {
    if (_openingPicker) return;
    if (!_updateAttachmentState(() => _openingPicker = true)) return;
    try {
      final photoPaths = record.recoverablePhotoPaths;
      final accepted = await _reviewPickedPhotoPaths(
        photoPaths,
        initialQualityChecksByPath: await _qualityChecksForPhotoPaths(
          photoPaths,
        ),
        initialCaptureDiagnosticsByPath: {
          for (final path in photoPaths) path: record.captureDiagnostics,
        },
      );
      if (accepted) {
        await const ReceiptNativeCaptureStaging().clearRecoveryRecord(record);
      }
    } finally {
      if (_updateAttachmentState(() => _openingPicker = false)) {
        unawaited(_loadRecoverableNativeCaptures());
      }
    }
  }

  Future<void> _dismissRecoverableNativeCapture(
    ReceiptNativeCaptureRecoveryRecord record,
  ) async {
    await const ReceiptNativeCaptureStaging().discardRecoveryRecord(record);
    if (!mounted) return;
    unawaited(_loadRecoverableNativeCaptures());
  }

  Future<void> _requestClearAttachments() async {
    final count = _photoPaths.length + _documentAttachments.length;
    final confirmed = await _confirmProofRemoval(
      title: 'Clear receipt proof?',
      message: count == 1
          ? 'This removes the attached proof from this receipt form. Saved read-only proof files are only deleted if they are still staged.'
          : 'This removes all $count attached proofs from this receipt form. Saved read-only proof files are only deleted if they are still staged.',
      confirmLabel: 'Clear Proof',
    );
    if (!mounted || !confirmed) return;
    _clearAttachments();
  }

  void _clearAttachments() {
    for (final attachment in _documentAttachments) {
      unawaited(
        ReceiptProofStorage.instance.deleteStagedAttachment(attachment),
      );
    }
    _updateAttachmentState(() {
      _photoPaths.clear();
      _photoIdByPath.clear();
      _photoQualityByPath.clear();
      _photoReadStateByPath.clear();
      _documentAttachments.clear();
      _readingForReview = false;
      _receiptReadStatus = _ReceiptReadStatusKind.success;
      _receiptReadStatusMessage = '';
    });
    _publishAttachmentChange();
  }

  Future<void> _removePhotoAt(int index) async {
    if (index < 0 || index >= _photoPaths.length) return;
    final photoNumber = index + 1;
    final confirmed = await _confirmProofRemoval(
      title: 'Remove receipt photo?',
      message:
          'This removes receipt photo $photoNumber from this receipt form. If this is part of a long receipt, make sure the remaining photos still cover the full receipt.',
      confirmLabel: 'Remove Photo',
    );
    if (!mounted || !confirmed) return;
    _updateAttachmentState(() {
      final removed = _photoPaths.removeAt(index);
      _photoIdByPath.remove(removed);
      _photoQualityByPath.remove(removed);
      _photoReadStateByPath.remove(removed);
    });
    _publishAttachmentChange();
  }

  Future<void> _removeDocument(ReceiptAttachmentRecord attachment) async {
    final confirmed = await _confirmProofRemoval(
      title: 'Remove receipt proof?',
      message:
          '${attachment.label} will be removed from this receipt form. Saved read-only proof files are only deleted if they are still staged.',
      confirmLabel: 'Remove Proof',
    );
    if (!mounted || !confirmed) return;
    unawaited(ReceiptProofStorage.instance.deleteStagedAttachment(attachment));
    _updateAttachmentState(() {
      _documentAttachments.removeWhere(
        (current) => current.id == attachment.id,
      );
    });
    _publishAttachmentChange();
  }

  Future<bool> _confirmProofRemoval({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => _ReceiptProofRemovalSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
    return result ?? false;
  }

  void _publishAttachmentChange() {
    final now = DateTime.now();
    final attachments = [
      for (var index = 0; index < _photoPaths.length; index++)
        ReceiptAttachmentRecord(
          id: _photoAttachmentIdForPath(_photoPaths[index], index, now),
          path: _photoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: _dataSaverLevel,
          createdAt: now,
          byteSize: _fileSize(_photoPaths[index]),
          readState:
              _photoReadStateByPath[_photoPaths[index]] ??
              ReceiptAttachmentReadState.notRead,
        ).withPhotoQuality(_photoQualityByPath[_photoPaths[index]]),
      ..._documentAttachments,
    ];
    widget.onChanged(attachments.isNotEmpty);
    widget.onAttachmentsChanged?.call(attachments);
  }

  String _photoAttachmentIdForPath(String path, int index, DateTime now) {
    final existing = _photoIdByPath[path];
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final generated = 'RCPH-${now.microsecondsSinceEpoch}-$index';
    _photoIdByPath[path] = generated;
    return generated;
  }

  bool _updateAttachmentState(VoidCallback update) {
    if (!mounted || _panelDisposed) return false;
    setState(update);
    return true;
  }

  Future<bool> _openReceiptCaptureSettings() async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings == null) {
      _showPickerError('Receipt settings are not available yet.');
      return false;
    }
    final result = await Navigator.of(context).push<bool>(
      appNativeRoute(
        context,
        _ReceiptCaptureSettingsScreen(settings: settings, area: widget.area),
      ),
    );
    if (!mounted) return false;
    _updateAttachmentState(
      () => _dataSaverLevel = settings.defaultDataSaverLevel,
    );
    return result ?? true;
  }

  int? _fileSize(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  void _showPickerError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showPickerMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  ReceiptPhotoQualityCheck? _qualityCheckFromAttachment(
    ReceiptAttachmentRecord attachment,
  ) {
    final score = attachment.photoQualityScore;
    if (!attachment.isPhoto || score == null) return null;
    return ReceiptPhotoQualityCheck(
      width: attachment.photoWidth ?? 1000,
      height: attachment.photoHeight ?? 1000,
      focusScore: attachment.photoFocusScore ?? 8,
      brightness: attachment.photoBrightness ?? 128,
      contrast: attachment.photoContrast ?? 28,
      cropScore: attachment.photoCropScore ?? .72,
      textBandScore: attachment.photoTextBandScore ?? 12,
      isLikelyReadable: !attachment.photoQualityNeedsReview,
    );
  }
}

enum _ReceiptReadStatusKind { reading, success, warning, failed }

class _ReceiptInterruptedCaptureBanner extends StatelessWidget {
  const _ReceiptInterruptedCaptureBanner({
    required this.record,
    required this.total,
    required this.loading,
    required this.onResume,
    required this.onDismiss,
  });

  final ReceiptNativeCaptureRecoveryRecord record;
  final int total;
  final bool loading;
  final VoidCallback? onResume;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final countLabel = record.recoveredCountLabel;
    final engineLabel = record.engine.label;
    final extraLabel = total > 1 ? ' $total interrupted captures found.' : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF12191C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          loading
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD166),
                  ),
                )
              : const Icon(
                  Icons.restore_rounded,
                  color: Color(0xFFFFD166),
                  size: 20,
                ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume Interrupted Receipt Photos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$countLabel from $engineLabel were saved locally before the receipt review finished. ${record.recoveryResumeDetail} Resume them or discard the staged receipt copies.$extraLabel',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onResume,
                        icon: const Icon(Icons.play_arrow_rounded, size: 17),
                        label: const Text('Resume'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Discard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE8ECEE),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFF56666E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReadReviewStatus extends StatelessWidget {
  const _ReceiptReadReviewStatus({
    required this.reading,
    required this.status,
    required this.message,
  });

  final bool reading;
  final _ReceiptReadStatusKind status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = message.trim().isEmpty
        ? 'Preparing receipt for app-assisted review...'
        : message;
    final effectiveStatus = reading ? _ReceiptReadStatusKind.reading : status;
    final title = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => 'Preparing Receipt',
      _ReceiptReadStatusKind.success => 'Receipt Ready For Review',
      _ReceiptReadStatusKind.warning => 'Receipt Needs Review',
      _ReceiptReadStatusKind.failed => 'Receipt Could Not Be Read',
    };
    final recoveryHint = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading =>
        'Keep this screen open. Maintainiac will show the receipt details as soon as the text is ready.',
      _ReceiptReadStatusKind.success =>
        'Check the store, date, totals, Business/Personal choice, and receipt lines.',
      _ReceiptReadStatusKind.warning =>
        'Check the highlighted fields and line items before saving.',
      _ReceiptReadStatusKind.failed =>
        'Use a clearer photo, add another photo for a long receipt, or keep the proof and fill the receipt by hand.',
    };
    final accent = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => const Color(0xFFFFD166),
      _ReceiptReadStatusKind.success => const Color(0xFF8EF6A4),
      _ReceiptReadStatusKind.warning => const Color(0xFFFFD166),
      _ReceiptReadStatusKind.failed => const Color(0xFFFF8A80),
    };
    final icon = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => null,
      _ReceiptReadStatusKind.success => Icons.fact_check_rounded,
      _ReceiptReadStatusKind.warning => Icons.warning_amber_rounded,
      _ReceiptReadStatusKind.failed => Icons.error_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF10171A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD166),
                  ),
                )
              : Icon(icon, color: accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveStatus == _ReceiptReadStatusKind.reading
                        ? accent
                        : const Color(0xFFE8ECEE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recoveryHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptProofRemovalSheet extends StatelessWidget {
  const _ReceiptProofRemovalSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
