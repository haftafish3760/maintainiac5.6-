part of 'receipt_image_processor.dart';

Future<ReceiptImagePreparationReport> _prepareReceiptSourceWithReport({
  required String path,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final bytes = await ReceiptImageProcessor._readFileBytes(path);
  if (bytes == null) {
    return ReceiptImageProcessor._unreadableReceiptSourceReport(
      path: path,
      action: 'source_file_unavailable_no_clear_ocr_source',
      code: 'source_file_unavailable',
    );
  }
  final decoded = ReceiptImageProcessor._decodeImage(bytes);
  if (decoded == null) {
    return ReceiptImageProcessor._unreadableReceiptSourceReport(
      path: path,
      action: 'decode_failed_no_clear_ocr_source',
      code: 'decode_failed',
    );
  }
  final originalQuality = _qualityCheck(decoded);
  final baseline = _resizeToMaxSide(decoded, 2600);
  final scannerDecisionCodes = <String>[];
  // Keep edge detection, rotation, and cleanup inside the same bounded image
  // budget as OCR. A camera original can be far larger without yielding more
  // usable receipt text, while multiplying memory and latency on older phones.
  var processed = baseline;
  var oriented = false;
  if (cleanupSettings.orientationCorrection) {
    final orientation = _autoOrientReceiptWithDecision(processed);
    processed = orientation.image;
    scannerDecisionCodes.add(orientation.code);
    oriented = orientation.code == 'orientation_applied_portrait_receipt';
  } else {
    scannerDecisionCodes.add('orientation_skipped_setting_off');
  }
  final beforeCropWidth = processed.width;
  final beforeCropHeight = processed.height;
  if (cleanupSettings.autoCrop) {
    final crop = _autoCropReceiptWithDecision(processed);
    processed = crop.image;
    scannerDecisionCodes.add(crop.code);
  } else {
    scannerDecisionCodes.add('crop_skipped_setting_off');
  }
  final cropped =
      processed.width != beforeCropWidth ||
      processed.height != beforeCropHeight;
  final beforeStraightenWidth = processed.width;
  final beforeStraightenHeight = processed.height;
  if (cleanupSettings.autoStraighten) {
    final straighten = _autoStraightenReceiptWithDecision(processed);
    processed = straighten.image;
    scannerDecisionCodes.add(straighten.code);
  } else {
    scannerDecisionCodes.add('straighten_skipped_setting_off');
  }
  final straightened =
      processed.width != beforeStraightenWidth ||
      processed.height != beforeStraightenHeight;
  if (cleanupSettings.autoStraighten) {
    scannerDecisionCodes.add(_perspectiveReadinessCode(processed));
  } else {
    scannerDecisionCodes.add('perspective_skipped_setting_off');
  }
  final cleanup = _enhanceReceiptForReadingWithDecision(
    processed,
    cleanupSettings: cleanupSettings,
  );
  processed = cleanup.image;
  scannerDecisionCodes.add(cleanup.code);
  final safe = _bestReceiptOcrSource([baseline, processed]);
  final usedEnhanced = !identical(safe, baseline);
  scannerDecisionCodes.add(
    usedEnhanced
        ? 'ocr_source_enhanced_selected'
        : 'ocr_source_full_quality_selected_quality_guard',
  );
  final ocrQuality = _qualityCheck(safe);
  final cleanupActions = <String>[
    if (baseline.width != decoded.width || baseline.height != decoded.height)
      'bounded_resolution',
    if (usedEnhanced && oriented) 'auto_orient',
    if (usedEnhanced && cropped) 'auto_crop',
    if (usedEnhanced && straightened) 'auto_straighten',
    if (usedEnhanced) 'scanner_cleanup',
    if (!usedEnhanced) 'temporary_full_quality_source_preserved',
    ...cleanupSettings.enabledDiagnosticLabels,
  ];
  if (identical(safe, baseline)) {
    final alreadyBounded =
        decoded.width == baseline.width && decoded.height == baseline.height;
    if (alreadyBounded) {
      final ocrPath = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: path,
        prefix: 'ocr_original',
      );
      return ReceiptImagePreparationReport(
        sourcePath: path,
        ocrSourcePath: ocrPath,
        originalQuality: originalQuality,
        ocrQuality: ocrQuality,
        cleanupActions: cleanupActions,
        usedEnhancedOcrSource: false,
        scannerDecisionCodes: scannerDecisionCodes,
      );
    }
  }
  final ocrPath = await _writeJpg(
    safe,
    prefix: usedEnhanced ? 'enhanced' : 'ocr_bounded',
    quality: 94,
  );
  return ReceiptImagePreparationReport(
    sourcePath: path,
    ocrSourcePath: ocrPath,
    originalQuality: originalQuality,
    ocrQuality: ocrQuality,
    cleanupActions: cleanupActions,
    usedEnhancedOcrSource: usedEnhanced,
    scannerDecisionCodes: scannerDecisionCodes,
  );
}
