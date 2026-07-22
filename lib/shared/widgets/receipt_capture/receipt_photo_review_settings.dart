part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSettings on _ReceiptPhotoReviewScreenState {
  Future<void> openReceiptReviewSettings() async {
    if (_savingPhotos || _openingCamera) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101719),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Receipt Review Settings',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showThumbnailStrip,
                  onChanged: (value) {
                    _updateReviewState(() => _showThumbnailStrip = value);
                    setSheetState(() {});
                  },
                  title: const Text('Show photo strip'),
                  subtitle: const Text(
                    'Keep the captured receipt photos visible.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.crop_rounded),
                  title: const Text('Crop current photo'),
                  subtitle: const Text('Adjust the edges before saving.'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _setReviewMode(_ReceiptReviewMode.crop);
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Saved photo size',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                RadioGroup<ReceiptDataSaverLevel>(
                  groupValue: _dataSaverLevel,
                  onChanged: (value) {
                    if (value == null) return;
                    _updateReviewState(() => _dataSaverLevel = value);
                    setSheetState(() {});
                  },
                  child: Column(
                    children: [
                      for (final level in ReceiptDataSaverLevel.values)
                        RadioListTile<ReceiptDataSaverLevel>(
                          contentPadding: EdgeInsets.zero,
                          value: level,
                          title: Text(level.label),
                          subtitle: Text(level.description),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
