import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../navigation/app_page_routes.dart';
import '../receipt_form/receipt_form_panel.dart';
import 'receipt_capture_models.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_camera_screen.dart';
import 'receipt_image_picker.dart';
import 'receipt_ocr_service.dart';
import 'receipt_photo_review_screen.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_pdf_viewer_screen.dart';
import 'receipt_picker_status.dart';
import 'receipt_proof_storage.dart';
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
  });

  final bool hasReceipt;
  final ValueChanged<bool> onChanged;
  final bool showCamera;
  final ReceiptCaptureArea area;
  final List<ReceiptAttachmentRecord> initialAttachments;
  final ValueChanged<List<ReceiptAttachmentRecord>>? onAttachmentsChanged;
  final ValueChanged<String>? onImportedText;

  @override
  State<SharedReceiptAttachmentPanel> createState() =>
      _SharedReceiptAttachmentPanelState();
}

class _SharedReceiptAttachmentPanelState
    extends State<SharedReceiptAttachmentPanel> {
  final List<String> _photoPaths = [];
  final List<ReceiptAttachmentRecord> _documentAttachments = [];
  var _openingPicker = false;
  ReceiptDataSaverLevel _dataSaverLevel = ReceiptDataSaverLevel.balanced;
  var _settingsApplied = false;

  bool get _hasAttachment =>
      _photoPaths.isNotEmpty || _documentAttachments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _applyInitialAttachments(widget.initialAttachments);
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
        if (_hasAttachment) ...[
          const SizedBox(height: 10),
          _ReceiptAttachmentSummary(
            photoCount: _photoPaths.length,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            onReview: _reviewPhotos,
          ),
          const SizedBox(height: 8),
          _ReceiptAttachmentList(
            photoPaths: _photoPaths,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            onReviewPhotos: _reviewPhotos,
            onRemovePhoto: _removePhotoAt,
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
                  label: const Text('Add Receipt'),
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
    setState(() {
      _photoPaths.clear();
      _documentAttachments.clear();
    });
    _publishAttachmentChange();
  }

  void _removePhotoAt(int index) {
    if (index < 0 || index >= _photoPaths.length) return;
    setState(() => _photoPaths.removeAt(index));
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
    setState(() {
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
          id: 'RCPH-${now.microsecondsSinceEpoch}-$index',
          path: _photoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: _dataSaverLevel,
          createdAt: now,
          byteSize: _fileSize(_photoPaths[index]),
        ),
      ..._documentAttachments,
    ];
    widget.onChanged(attachments.isNotEmpty);
    widget.onAttachmentsChanged?.call(attachments);
  }

  void _updateAttachmentState(VoidCallback update) {
    setState(update);
  }

  Future<bool> _openReceiptCaptureSettings({bool setupMode = false}) async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings == null) {
      _showPickerError('Receipt settings are not available yet.');
      return false;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) => _ReceiptCaptureSettingsSheet(
        settings: settings,
        setupMode: setupMode,
      ),
    );
    if (!mounted) return false;
    setState(() => _dataSaverLevel = settings.defaultDataSaverLevel);
    return result ?? !setupMode;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showPickerMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
