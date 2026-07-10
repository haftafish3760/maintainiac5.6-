part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentPanelBuild on _SharedReceiptAttachmentPanelState {
  Widget _buildReceiptAttachmentPanel(BuildContext context) {
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
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptButton(
                icon: _readingForReview
                    ? Icons.manage_search_rounded
                    : Icons.add_rounded,
                label: _readingForReview ? 'Reading Receipt' : 'Add Receipt',
                onTap: _openingPicker || _readingForReview
                    ? null
                    : openReceiptImportOptions,
              ),
            ),
          ],
        ),
        if (_openingPicker) ...[
          const SizedBox(height: 8),
          const ReceiptPickerStatus(),
        ],
        if (_hasAttachment && settings?.cameraLongReceiptTips != false) ...[
          const SizedBox(height: 8),
          _ReceiptCaptureTargetGuidance(hasAttachment: _hasAttachment),
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
            progressPhase: _receiptReadProgressPhase,
            uiConfig: widget.uiConfig,
            onRetry: _hasAttachment && !_readingForReview
                ? () => unawaited(reviewReceiptPhotos())
                : null,
          ),
        ],
        if (_hasAttachment) ...[
          const SizedBox(height: 10),
          _ReceiptAttachmentSummary(
            photoCount: _photoPaths.length,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            appAssistedEnabled: _appAssistedReceiptFillEnabled,
            onReview: reviewReceiptPhotos,
          ),
          const SizedBox(height: 8),
          _ReceiptAttachmentList(
            photoPaths: _photoPaths,
            photoQualityByPath: _photoQualityByPath,
            documents: _documentAttachments,
            dataSaverLevel: _dataSaverLevel,
            onReviewPhotos: reviewReceiptPhotos,
            onRemovePhoto: (index) => unawaited(removePhotoAt(index)),
            onRemoveDocument: removeDocument,
            onEditDocument: editReceiptDocument,
            onReadDocument: readDocumentForReceipt,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openingPicker || _readingForReview
                      ? null
                      : _needsBottomReceiptSection
                      ? () => unawaited(takeReceiptPhoto())
                      : openReceiptImportOptions,
                  icon: Icon(
                    _needsBottomReceiptSection
                        ? Icons.vertical_align_bottom_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(
                    _readingForReview
                        ? 'Reading Receipt'
                        : _needsBottomReceiptSection
                        ? 'Add Bottom Section'
                        : 'Add Receipt Photo',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: requestClearAttachments,
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
}
