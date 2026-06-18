part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewBottomControls extends StatelessWidget {
  const _ReceiptReviewBottomControls({
    required this.photoPaths,
    required this.selectedIndex,
    required this.dataSaverLevel,
    required this.storagePreview,
    required this.selectedQualityCheck,
    required this.reviewMode,
    required this.bestShotCandidateMode,
    required this.canRemove,
    required this.openingCamera,
    required this.cropProcessing,
    required this.savingPhotos,
    required this.onPhotoSelected,
    required this.onDataSaverSelected,
    required this.onModeChanged,
    required this.onStraightenLeft,
    required this.onStraightenRight,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onRemove,
    required this.onContinue,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final _ReceiptReviewMode reviewMode;
  final bool bestShotCandidateMode;
  final bool canRemove;
  final bool openingCamera;
  final bool cropProcessing;
  final bool savingPhotos;
  final ValueChanged<int> onPhotoSelected;
  final ValueChanged<ReceiptDataSaverLevel> onDataSaverSelected;
  final ValueChanged<_ReceiptReviewMode> onModeChanged;
  final VoidCallback onStraightenLeft;
  final VoidCallback onStraightenRight;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback onRemove;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xDD050607),
        border: Border(top: BorderSide(color: Color(0xFF344047))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReceiptReviewStepStrip(
              selected: reviewMode,
              onSelected: onModeChanged,
            ),
            const SizedBox(height: 8),
            if (photoPaths.length > 1) ...[
              _ReceiptPhotoStrip(
                photoPaths: photoPaths,
                selectedIndex: selectedIndex,
                onSelected: onPhotoSelected,
              ),
              const SizedBox(height: 6),
            ],
            if (reviewMode == _ReceiptReviewMode.dataSaver)
              Column(
                children: [
                  _ReceiptDataSaverPreviewCard(preview: storagePreview),
                  const SizedBox(height: 8),
                  _ReceiptDataSaverStrip(
                    selected: dataSaverLevel,
                    onSelected: onDataSaverSelected,
                  ),
                ],
              )
            else if (reviewMode == _ReceiptReviewMode.crop)
              _ReceiptCropActions(
                cropProcessing: cropProcessing,
                onStraightenLeft: onStraightenLeft,
                onStraightenRight: onStraightenRight,
                onRotateLeft: onRotateLeft,
                onRotateRight: onRotateRight,
                onResetCrop: onResetCrop,
                onApplyCrop: onApplyCrop,
                onCancelCrop: onCancelCrop,
              )
            else
              Column(
                children: [
                  if (bestShotCandidateMode && selectedQualityCheck != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ReceiptBestShotQualityCard(
                        quality: selectedQualityCheck!,
                      ),
                    ),
                  if (photoPaths.length == 1)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _ReceiptLongReceiptReviewHint(),
                    ),
                  _ReceiptPreviewActions(
                    openingCamera: openingCamera || savingPhotos,
                    canRemove: canRemove,
                    onAddPhoto: onAddPhoto,
                    onRetake: onRetake,
                    onRemove: onRemove,
                  ),
                ],
              ),
            if (openingCamera || savingPhotos) ...[
              const SizedBox(height: 8),
              savingPhotos
                  ? const ReceiptPickerStatus(label: 'Saving receipt photos...')
                  : const ReceiptPickerStatus(),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: savingPhotos ? null : onContinue,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                bestShotCandidateMode
                    ? 'Use Selected Image'
                    : photoPaths.length == 1
                    ? 'Use This Image'
                    : 'Use These Photos',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptReviewStepStrip extends StatelessWidget {
  const _ReceiptReviewStepStrip({
    required this.selected,
    required this.onSelected,
  });

  final _ReceiptReviewMode selected;
  final ValueChanged<_ReceiptReviewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StepStripButton(
            label: 'Review',
            icon: Icons.visibility_rounded,
            selected: selected == _ReceiptReviewMode.preview,
            onTap: () => onSelected(_ReceiptReviewMode.preview),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StepStripButton(
            label: 'Crop',
            icon: Icons.crop_rounded,
            selected: selected == _ReceiptReviewMode.crop,
            onTap: () => onSelected(_ReceiptReviewMode.crop),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StepStripButton(
            label: 'Data Saver',
            icon: Icons.storage_rounded,
            selected: selected == _ReceiptReviewMode.dataSaver,
            onTap: () => onSelected(_ReceiptReviewMode.dataSaver),
          ),
        ),
      ],
    );
  }
}

class _StepStripButton extends StatelessWidget {
  const _StepStripButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFFFFD166)
            : const Color(0xFF172126),
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}

class _ReceiptPreviewActions extends StatelessWidget {
  const _ReceiptPreviewActions({
    required this.openingCamera,
    required this.canRemove,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onRemove,
  });

  final bool openingCamera;
  final bool canRemove;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: Icons.add_a_photo_rounded,
          label: 'Add Additional Photos',
          onPressed: openingCamera ? null : onAddPhoto,
        ),
        _ActionButton(
          icon: Icons.camera_alt_rounded,
          label: 'Retake',
          onPressed: openingCamera ? null : onRetake,
        ),
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Remove',
          onPressed: canRemove ? onRemove : null,
        ),
      ],
    );
  }
}

class _ReceiptCropActions extends StatelessWidget {
  const _ReceiptCropActions({
    required this.cropProcessing,
    required this.onStraightenLeft,
    required this.onStraightenRight,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
  });

  final bool cropProcessing;
  final VoidCallback onStraightenLeft;
  final VoidCallback onStraightenRight;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _ActionButton(
              icon: Icons.rotate_left_rounded,
              label: 'Straighten Left',
              onPressed: cropProcessing ? null : onStraightenLeft,
            ),
            _ActionButton(
              icon: Icons.rotate_right_rounded,
              label: 'Straighten Right',
              onPressed: cropProcessing ? null : onStraightenRight,
            ),
            _ActionButton(
              icon: Icons.undo_rounded,
              label: 'Rotate Left',
              onPressed: cropProcessing ? null : onRotateLeft,
            ),
            _ActionButton(
              icon: Icons.redo_rounded,
              label: 'Rotate Right',
              onPressed: cropProcessing ? null : onRotateRight,
            ),
            _ActionButton(
              icon: Icons.fit_screen_rounded,
              label: 'Reset Crop',
              onPressed: cropProcessing ? null : onResetCrop,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: cropProcessing ? null : onCancelCrop,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel Crop'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: cropProcessing ? null : onApplyCrop,
                icon: cropProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(cropProcessing ? 'Cropping' : 'Apply Crop'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptDataSaverStrip extends StatelessWidget {
  const _ReceiptDataSaverStrip({
    required this.selected,
    required this.onSelected,
  });

  final ReceiptDataSaverLevel selected;
  final ValueChanged<ReceiptDataSaverLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReceiptDataSaverLevel.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = ReceiptDataSaverLevel.values[index];
          final active = level == selected;
          return SizedBox(
            width: 150,
            child: InkWell(
              onTap: () => onSelected(level),
              borderRadius: BorderRadius.circular(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF172126),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFFFE2A1)
                        : const Color(0xFF526168),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${level.label}: ${level.shortLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF101416)
                              : const Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        level.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF263238)
                              : const Color(0xFFC7D0D4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1976B9),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
