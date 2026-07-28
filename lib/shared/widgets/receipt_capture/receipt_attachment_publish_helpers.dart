part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentPublishHelpers
    on _SharedReceiptAttachmentPanelState {
  Future<void> requestClearAttachments() async {
    final count = _photoPaths.length + _documentAttachments.length;
    final confirmed = await confirmProofRemoval(
      title: 'Clear receipt proof?',
      message: count == 1
          ? 'This removes the attached proof from this receipt form. Saved read-only proof files are only deleted if they are still staged.'
          : 'This removes all $count attached proofs from this receipt form. Saved read-only proof files are only deleted if they are still staged.',
      confirmLabel: 'Clear Proof',
    );
    if (!mounted || !confirmed) return;
    clearAttachments();
  }

  void clearAttachments() {
    for (final attachment in _documentAttachments) {
      unawaited(
        ReceiptProofStorage.instance.deleteStagedAttachment(attachment),
      );
    }
    updateAttachmentState(() {
      _photoPaths.clear();
      _photoIdByPath.clear();
      _photoQualityByPath.clear();
      _photoCaptureDiagnosticsByPath.clear();
      _photoReadStateByPath.clear();
      _documentAttachments.clear();
      _readingForReview = false;
      _needsBottomReceiptSection = false;
      _receiptReadStatus = _ReceiptReadStatusKind.success;
      _receiptReadStatusMessage = '';
      _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
    });
    publishAttachmentChange();
  }

  Future<void> removePhotoAt(int index) async {
    if (index < 0 || index >= _photoPaths.length) return;
    final photoNumber = index + 1;
    final confirmed = await confirmProofRemoval(
      title: 'Remove receipt photo?',
      message:
          'This removes receipt photo $photoNumber from this receipt form. If this is part of a long receipt, make sure the remaining photos still cover the full receipt.',
      confirmLabel: 'Remove Photo',
    );
    if (!mounted || !confirmed) return;
    updateAttachmentState(() {
      final removed = _photoPaths.removeAt(index);
      _photoIdByPath.remove(removed);
      _photoQualityByPath.remove(removed);
      _photoCaptureDiagnosticsByPath.remove(removed);
      _photoReadStateByPath.remove(removed);
      if (_photoPaths.isEmpty) _needsBottomReceiptSection = false;
    });
    publishAttachmentChange();
  }

  Future<void> removeDocument(ReceiptAttachmentRecord attachment) async {
    final confirmed = await confirmProofRemoval(
      title: 'Remove receipt proof?',
      message:
          '${attachment.label} will be removed from this receipt form. Saved read-only proof files are only deleted if they are still staged.',
      confirmLabel: 'Remove Proof',
    );
    if (!mounted || !confirmed) return;
    unawaited(ReceiptProofStorage.instance.deleteStagedAttachment(attachment));
    updateAttachmentState(() {
      _documentAttachments.removeWhere(
        (current) => current.id == attachment.id,
      );
    });
    publishAttachmentChange();
  }

  Future<bool> confirmProofRemoval({
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

  void publishAttachmentChange() {
    final now = DateTime.now();
    final attachments = [
      for (var index = 0; index < _photoPaths.length; index++)
        ReceiptAttachmentRecord(
          id: photoAttachmentIdForPath(_photoPaths[index], index, now),
          path: _photoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: _dataSaverLevel,
          createdAt: now,
          byteSize: receiptAttachmentFileSize(_photoPaths[index]),
          riskFlags: photoRiskFlagsFor(_photoPaths[index]),
          documentSignals: photoDocumentSignalsFor(_photoPaths[index]),
          sourceLabel: 'Maintainiac receipt camera review',
          linkedModule: _receiptAttachmentLinkedModule,
          readState:
              _photoReadStateByPath[_photoPaths[index]] ??
              ReceiptAttachmentReadState.notRead,
        ).withPhotoQuality(_photoQualityByPath[_photoPaths[index]]),
      ..._documentAttachments,
    ];
    widget.onChanged(attachments.isNotEmpty);
    widget.onAttachmentsChanged?.call(attachments);
  }

  Future<bool> openReceiptCaptureSettings({
    ReceiptSettingsScreenContext? screenContext,
  }) async {
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings == null) {
      showPickerError('Receipt settings are not available yet.');
      return false;
    }
    final result = await Navigator.of(context).push<bool>(
      appNativeRoute(
        context,
        _ReceiptCaptureSettingsScreen(
          settings: settings,
          area: widget.area,
          hasSavedReceiptProof:
              _photoPaths.isNotEmpty || _documentAttachments.isNotEmpty,
          uiConfig: widget.uiConfig,
          screenContext: screenContext,
        ),
      ),
    );
    if (!mounted) return false;
    updateAttachmentState(
      () => _dataSaverLevel = settings.defaultDataSaverLevel,
    );
    return result ?? true;
  }

  String get _receiptAttachmentLinkedModule {
    return switch (widget.area) {
      ReceiptCaptureArea.expenses => 'expenses',
      ReceiptCaptureArea.materialsInventory => 'materials_inventory',
      ReceiptCaptureArea.maintenanceRepair => 'maintenance_repair',
    };
  }

  String photoAttachmentIdForPath(String path, int index, DateTime now) {
    final existing = _photoIdByPath[path];
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final generated = 'RCPH-${now.microsecondsSinceEpoch}-$index';
    _photoIdByPath[path] = generated;
    return generated;
  }

  int? receiptAttachmentFileSize(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  void showPickerError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void showPickerMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  ReceiptPhotoQualityCheck? qualityCheckFromAttachment(
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
