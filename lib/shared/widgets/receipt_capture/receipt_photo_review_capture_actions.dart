part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewCaptureActions on _ReceiptPhotoReviewScreenState {
  void handleReviewMenuAction(_ReceiptReviewMenuAction action) {
    switch (action) {
      case _ReceiptReviewMenuAction.addAdditionalPhotos:
        addAnotherReceiptPhoto();
      case _ReceiptReviewMenuAction.moveEarlier:
        moveCurrentReceiptPhoto(-1);
      case _ReceiptReviewMenuAction.moveLater:
        moveCurrentReceiptPhoto(1);
      case _ReceiptReviewMenuAction.retake:
        retakeCurrentReceiptPhoto();
      case _ReceiptReviewMenuAction.remove:
        unawaited(removeCurrentReceiptPhoto());
    }
  }

  Future<void> addAnotherReceiptPhoto() async {
    final selectedPhotoIndex = _photoPaths.isEmpty
        ? -1
        : _selectedIndex.clamp(0, _photoPaths.length - 1);
    final guideIndex = _photoPaths.isEmpty ? -1 : selectedPhotoIndex;
    final guidePhotoPath = _photoPaths.isEmpty
        ? null
        : _photoPaths[selectedPhotoIndex];
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: guidePhotoPath,
      showAlignmentGuide: false,
    );
    if (picked.paths.isEmpty || !_reviewWorkActive) return;
    final insertPlan = guidePhotoPath == null
        ? null
        : ReceiptPhotoInsertAfterOrderPlan.build(
            currentPhotoPaths: _photoPaths,
            anchorIndex: guideIndex,
            anchorPhotoPath: guidePhotoPath,
            insertedPhotoPaths: picked.paths,
          );
    if (guidePhotoPath != null && insertPlan == null) return;
    final insertDiagnostics =
        insertPlan?.captureDiagnosticsForInsertedPhotoPaths(picked.paths) ??
        const <String, Map<String, Object?>>{};
    _updateReviewState(() {
      final insertIndex = insertPlan?.selectedIndex ?? _photoPaths.length;
      if (insertPlan == null) {
        _photoPaths.addAll(picked.paths);
      } else {
        _photoPaths
          ..clear()
          ..addAll(insertPlan.photoPaths);
      }
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _captureDiagnosticsByPath.addAll(
        _mergeOrderCaptureDiagnostics(
          picked.captureDiagnosticsByPath,
          insertDiagnostics,
        ),
      );
      _selectedIndex = insertIndex;
    });
    _recoverReviewAfterPhotoSetChanged();
  }

  Future<void> retakeCurrentReceiptPhoto() async {
    if (_photoPaths.isEmpty) return;
    final selectedPhotoIndex = _selectedIndex.clamp(0, _photoPaths.length - 1);
    final targetPhotoPath = _photoPaths[selectedPhotoIndex];
    final retakeContext = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: _photoPaths,
      targetPhotoPath: targetPhotoPath,
    );
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: retakeContext?.previousSectionGuidePhotoPath,
      nextSectionGuidePhotoPath: retakeContext?.nextSectionGuidePhotoPath,
      alignmentReasonCode: retakeContext?.guidanceCode,
      alignmentGuidance: retakeContext?.guidanceText,
    );
    if (picked.paths.isEmpty || !_reviewWorkActive) return;
    final retakePlan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: _photoPaths,
      targetPhotoPath: targetPhotoPath,
      replacementPhotoPaths: picked.paths,
    );
    if (retakePlan == null) return;
    String? replacedGeneratedPath;
    final retakeDiagnostics = retakePlan.captureDiagnosticsForReplacementPaths(
      picked.paths,
    );
    _updateReviewState(() {
      _selectedIndex = retakePlan.selectedIndex;
      final replacedPath = retakePlan.replacedPhotoPath;
      if (_generatedEditPaths.contains(replacedPath)) {
        replacedGeneratedPath = replacedPath;
      }
      final firstPath = picked.paths.first;
      _replaceCurrentPhotoPath(
        firstPath,
        picked.qualityChecksByPath[firstPath],
      );
      _photoPaths
        ..clear()
        ..addAll(retakePlan.photoPaths);
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _captureDiagnosticsByPath.addAll(
        _mergeRetakeCaptureDiagnostics(
          picked.captureDiagnosticsByPath,
          retakeDiagnostics,
        ),
      );
    });
    _recoverReviewAfterPhotoSetChanged();
    if (replacedGeneratedPath != null) {
      await _deleteGeneratedEditPhotos(_photoPaths.toSet());
    }
  }

  Future<_PickedReceiptPhotos> _pickReceiptPhotos({
    String? alignmentGuidePhotoPath,
    String? nextSectionGuidePhotoPath,
    String? alignmentReasonCode,
    String? alignmentGuidance,
    bool showAlignmentGuide = true,
  }) async {
    if (_openingCamera) return const _PickedReceiptPhotos.empty();
    _updateReviewState(() => _openingCamera = true);
    ReceiptPhotoCoverageDecision? coverageDecision;
    try {
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
      if ((alignmentGuidePhotoPath != null ||
              nextSectionGuidePhotoPath != null) &&
          showAlignmentGuide) {
        final coverageGuidePath =
            alignmentGuidePhotoPath ?? nextSectionGuidePhotoPath!;
        coverageDecision = _coverageDecisionForPhoto(coverageGuidePath);
        final shouldContinue = await _showLongReceiptAlignmentGuide(
          alignmentGuidePhotoPath,
          nextSectionGuidePhotoPath: nextSectionGuidePhotoPath,
          coverageDecision: coverageDecision,
          alignmentReasonCode: alignmentReasonCode,
          alignmentGuidance: alignmentGuidance,
        );
        if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
        if (!shouldContinue) return const _PickedReceiptPhotos.empty();
      }
      final nativePicked = await _pickWithMaintainiacNativeCamera(
        settings,
        previousSectionGuidePhotoPath: alignmentGuidePhotoPath,
        nextSectionGuidePhotoPath: nextSectionGuidePhotoPath,
        previousSectionReasonCode: alignmentReasonCode,
        previousSectionGuidance: alignmentGuidance,
        previousSectionCoverageDecision: coverageDecision,
      );
      if (nativePicked.wasCanceled) return nativePicked;
      if (nativePicked.paths.isNotEmpty) return nativePicked;
      if (NativeReceiptScannerService.documentScannerAllowedOnThisPlatform) {
        final scanResult = await const NativeReceiptScannerService()
            .scanReceipt(
              pageLimit:
                  settings?.deviceCapability.maxLocalPhotoCount ??
                  const ReceiptDeviceCapability.standard().maxLocalPhotoCount,
              allowGalleryImport: false,
            );
        if (scanResult.hasScannedPages) {
          final cameraResult = scanResult.cameraResult!;
          return _stageDocumentScannerBackupPhotos(cameraResult);
        }
        if (scanResult.status == ReceiptNativeScanStatus.canceled) {
          return const _PickedReceiptPhotos.empty();
        }
        _showScannerFallbackNotice(scanResult);
      }
      _showCameraError(
        'Maintainiac receipt camera is not available. Opening the phone camera as backup capture; the next section still returns to Maintainiac receipt review.',
      );
      final picked = await ReceiptImagePicker.takeBackupReceiptPhotoSet();
      if (picked.isEmpty) return const _PickedReceiptPhotos.empty();
      return _stagePhoneCameraBackupPhotos(
        picked,
        hadPreviousSectionGuide:
            alignmentGuidePhotoPath != null ||
            nextSectionGuidePhotoPath != null,
        previousSectionReasonCode: alignmentReasonCode,
        previousSectionGuidance: alignmentGuidance,
        previousSectionCoverageDecision: coverageDecision,
      );
    } on MissingPluginException {
      if (_reviewWorkActive) {
        _showScannerFallbackNotice(
          const ReceiptNativeScanResult.unavailable(
            'Document scanning is not available in this build.',
          ),
        );
      }
      if (_reviewWorkActive) {
        _showCameraError(
          'Maintainiac receipt camera is not installed in this build. Opening the phone camera as backup capture; the next section still returns to Maintainiac receipt review.',
        );
      }
      try {
        final picked = await ReceiptImagePicker.takeBackupReceiptPhotoSet();
        if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
        if (picked.isEmpty) return const _PickedReceiptPhotos.empty();
        return _stagePhoneCameraBackupPhotos(
          picked,
          hadPreviousSectionGuide:
              alignmentGuidePhotoPath != null ||
              nextSectionGuidePhotoPath != null,
          previousSectionReasonCode: alignmentReasonCode,
          previousSectionGuidance: alignmentGuidance,
          previousSectionCoverageDecision: coverageDecision,
        );
      } on MissingPluginException {
        if (_reviewWorkActive) {
          _showCameraError(
            'The phone camera fallback is not available in this build. Use Add Existing Photo from the receipt form, or reinstall the app and try again.',
          );
        }
        return const _PickedReceiptPhotos.empty();
      }
    } on PlatformException catch (error) {
      if (_reviewWorkActive) {
        _showCameraError(_nativeCameraOpenErrorMessage(error));
      }
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (_reviewWorkActive) {
        _showCameraError(
          'The camera did not open. Try Add Another Photo again, or choose an existing receipt image.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    } finally {
      if (_reviewWorkActive) _updateReviewState(() => _openingCamera = false);
    }
  }

  ReceiptPhotoCoverageDecision _coverageDecisionForPhoto(String photoPath) {
    return ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityChecksByPath[photoPath],
      diagnostics: _captureDiagnosticsByPath[photoPath],
    );
  }

  Map<String, Object?> _coverageDiagnosticsForPhoto(
    String photoPath, {
    required ReceiptPhotoQualityCheck fallbackQuality,
  }) {
    final cameraDiagnostics = _captureDiagnosticsByPath[photoPath];
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityChecksByPath[photoPath] ?? fallbackQuality,
      diagnostics: cameraDiagnostics,
    );
    return {
      ..._defaultReceiptBrainDiagnosticsForReviewPhoto(
        captureRoute: cameraDiagnostics?['captureFlow']?.toString(),
      ),
      if (cameraDiagnostics != null) ...cameraDiagnostics,
      ReceiptCaptureDiagnosticKeys.photoCoverageStatus: decision.status.name,
      ReceiptCaptureDiagnosticKeys.photoCoverageReason: decision.reasonCode,
      ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos:
          decision.shouldPromptForMorePhotos,
      if (_completionDecisionsByPath.containsKey(photoPath))
        ..._completionDecisionsByPath[photoPath]!,
    };
  }

  Future<_PickedReceiptPhotos> _pickWithMaintainiacNativeCamera(
    ReceiptCaptureSettingsController? settings, {
    String? previousSectionGuidePhotoPath,
    String? nextSectionGuidePhotoPath,
    String? previousSectionReasonCode,
    String? previousSectionGuidance,
    ReceiptPhotoCoverageDecision? previousSectionCoverageDecision,
  }) async {
    final permission = await const ReceiptCameraPermission().ensureReady();
    if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
    if (!permission.canUseCamera) {
      _showCameraError(permission.userMessage);
      return const _PickedReceiptPhotos.empty();
    }
    final service = const ReceiptNativeCameraService();
    final nativeCapabilities = await service.readCapabilities();
    if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
    if (!nativeCapabilities.canOpenReceiptCamera) {
      _showCameraError(
        'Receipt camera is unavailable right now. Check permission, then try again or add a photo from your device.',
      );
      return const _PickedReceiptPhotos.empty();
    }
    final deviceCapability =
        settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
    final cameraSettings = receiptNativeCameraSettingsForCapture(
      settings: settings,
      assistedReceiptFill: widget.assistedReceiptFill,
      longReceiptMode: true,
      autoCaptureEnabled: settings?.cameraAutoCapture ?? false,
      reviewDepth: ReceiptNativeReviewDepth.detailedLines,
      dataSaverLevel: _dataSaverLevel,
    );
    try {
      final result = await service.captureReceipt(
        cameraSettings.sessionFor(
          deviceCapability: deviceCapability,
          nativeCapabilities: nativeCapabilities,
          previousSectionGuidePhotoPath: previousSectionGuidePhotoPath,
          nextSectionGuidePhotoPath: nextSectionGuidePhotoPath,
          previousSectionReasonCode:
              previousSectionReasonCode ??
              previousSectionCoverageDecision?.reasonCode,
          previousSectionGuidance:
              previousSectionGuidance ??
              previousSectionCoverageDecision?.guidance,
        ),
      );
      if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
      if (!result.hasPhotos) return const _PickedReceiptPhotos.empty();
      final staged = await const ReceiptNativeCaptureStaging().stage(
        result,
        dataSaverLevel: _dataSaverLevel,
      );
      if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
      if (!staged.hasPhotos) {
        throw const ReceiptProofStorageException(
          'That receipt photo was no longer available. Retake it before continuing.',
        );
      }
      final capturedPhotoCount = result.originalPhotoPaths
          .where((path) => path.trim().isNotEmpty)
          .length;
      if (staged.photoPaths.length < capturedPhotoCount) {
        _showCameraError(
          'One or more receipt photos could not be kept. Review the photos shown, then retake or add another photo if needed.',
        );
      }
      return _PickedReceiptPhotos.fromNativePhotoPaths(
        staged.photoPaths,
        captureDiagnosticsByPath: staged.captureDiagnosticsByPhotoPath,
      );
    } on ReceiptNativeCameraCanceledException {
      return const _PickedReceiptPhotos.canceled();
    } on ReceiptNativeCameraUnavailableException catch (error) {
      if (_reviewWorkActive && nativeCapabilities.available) {
        _showCameraError(
          '${error.message} Opening the phone camera as backup capture; the next section still returns to Maintainiac receipt review.',
        );
      }
      final picked = await ReceiptImagePicker.takeBackupReceiptPhotoSet();
      if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
      if (picked.isEmpty) return const _PickedReceiptPhotos.empty();
      return _stagePhoneCameraBackupPhotos(
        picked,
        hadPreviousSectionGuide: previousSectionGuidePhotoPath != null,
        previousSectionReasonCode: previousSectionReasonCode,
        previousSectionGuidance: previousSectionGuidance,
        previousSectionCoverageDecision: previousSectionCoverageDecision,
      );
    } on ReceiptProofStorageException catch (error) {
      if (_reviewWorkActive) _showCameraError(error.message);
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (_reviewWorkActive) {
        _showCameraError(
          'That backup receipt photo could not be kept safely. Retake it before continuing.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    }
  }

  Future<_PickedReceiptPhotos> _stagePhoneCameraBackupPhotos(
    ReceiptPickedPhotoSet picked, {
    required bool hadPreviousSectionGuide,
    String? previousSectionReasonCode,
    String? previousSectionGuidance,
    ReceiptPhotoCoverageDecision? previousSectionCoverageDecision,
  }) async {
    try {
      final staged = await const ReceiptAcquiredPhotoStaging().stage(
        sourcePaths: picked.paths,
        dataSaverLevel: _dataSaverLevel,
        captureFlow: 'phone_camera_backup_receipt_photo',
        temporaryIdPrefix: 'phone-camera-backup',
        diagnostics: const {
          'phoneCameraBackupRole': 'fallback_only',
          'phoneCameraBackupUsed': true,
        },
      );
      return _PickedReceiptPhotos.fromPhoneCameraBackupPaths(
        staged.photoPaths,
        hadPreviousSectionGuide: hadPreviousSectionGuide,
        previousSectionReasonCode: previousSectionReasonCode,
        previousSectionGuidance: previousSectionGuidance,
        previousSectionCoverageDecision: previousSectionCoverageDecision,
        stagingDiagnosticsByPath: staged.captureDiagnosticsByPhotoPath,
      );
    } on ReceiptProofStorageException catch (error) {
      if (_reviewWorkActive) _showCameraError(error.message);
      return const _PickedReceiptPhotos.empty();
    }
  }

  Future<_PickedReceiptPhotos> _stageDocumentScannerBackupPhotos(
    ReceiptCameraResult cameraResult,
  ) async {
    try {
      final staged = await const ReceiptAcquiredPhotoStaging().stage(
        sourcePaths: cameraResult.photoPaths,
        dataSaverLevel: _dataSaverLevel,
        captureFlow: 'document_scanner_backup_receipt_photo',
        temporaryIdPrefix: 'document-scanner-backup',
        diagnostics: const {
          'documentScannerBackupRole': 'fallback_only',
          'documentScannerBackupUsed': true,
        },
      );
      return _PickedReceiptPhotos.fromNativePhotoPaths(
        staged.photoPaths,
        captureDiagnosticsByPath: staged.captureDiagnosticsByPhotoPath,
      );
    } on ReceiptProofStorageException catch (error) {
      if (_reviewWorkActive) _showCameraError(error.message);
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (_reviewWorkActive) {
        _showCameraError(
          'That scanned receipt photo could not be kept safely. Scan it again before continuing.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    }
  }

  Map<String, Map<String, Object?>> _mergeRetakeCaptureDiagnostics(
    Map<String, Map<String, Object?>> pickedDiagnostics,
    Map<String, Map<String, Object?>> retakeDiagnostics,
  ) {
    return _mergeOrderCaptureDiagnostics(pickedDiagnostics, retakeDiagnostics);
  }

  Map<String, Map<String, Object?>> _mergeOrderCaptureDiagnostics(
    Map<String, Map<String, Object?>> pickedDiagnostics,
    Map<String, Map<String, Object?>> orderDiagnostics,
  ) {
    return Map<String, Map<String, Object?>>.unmodifiable({
      for (final entry in pickedDiagnostics.entries)
        entry.key: Map<String, Object?>.unmodifiable(entry.value),
      for (final entry in orderDiagnostics.entries)
        entry.key: Map<String, Object?>.unmodifiable({
          ...?pickedDiagnostics[entry.key],
          ...entry.value,
        }),
    });
  }
}
