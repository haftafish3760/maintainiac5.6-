import UIKit

extension ReceiptCameraViewController {
  func readSessionArguments() {
    assistedReceiptFill = arguments["assistedReceiptFill"] as? Bool ?? true
    longReceiptMode = arguments["longReceiptMode"] as? Bool ?? true
    autoCaptureEnabled = arguments["autoCaptureEnabled"] as? Bool ?? false
    autoCaptureAllowed = arguments["autoCaptureAllowed"] as? Bool ?? autoCaptureEnabled
    if !autoCaptureAllowed {
      autoCaptureEnabled = false
    }
    deviceTier = arguments["deviceTier"] as? String ?? "medium"
    settingsContractVersion = arguments["settingsContractVersion"] as? String ?? "receipt_native_camera_settings_v1"
    devicePolicyLabel = arguments["devicePolicyLabel"] as? String ?? "balanced_receipt_camera"
    reviewDepth = arguments["reviewDepth"] as? String ?? "pricesOnly"
    focusMode = arguments["focusMode"] as? String ?? "continuous"
    exposureMode = arguments["exposureMode"] as? String ?? "auto"
    whiteBalanceMode = arguments["whiteBalanceMode"] as? String ?? "auto"
    whiteBalanceLockEnabled = arguments["whiteBalanceLockEnabled"] as? Bool ?? (whiteBalanceMode == "locked")
    dataSaverLevel = arguments["dataSaverLevel"] as? String ?? "balanced"
    storageSafetyLevel = arguments["storageSafetyLevel"] as? String ?? dataSaverLevel
    storageConstrained = arguments["storageConstrained"] as? Bool ?? false
    storageSafetyReason = arguments["storageSafetyReason"] as? String ?? "normal"
    workloadProtectionPolicy = arguments["workloadProtectionPolicy"] as? String ?? "balanced_workload"
    maxLocalPhotoBytes = arguments["maxLocalPhotoBytes"] as? Int ?? maxLocalPhotoBytes
    nativeCaptureMemoryPolicy = arguments["nativeCaptureMemoryPolicy"] as? String ?? nativeCaptureMemoryPolicy
    nativeControlContractTags = arguments["nativeControlContractTags"] as? [String] ?? []
    liveAnalysisEnabled = arguments["liveAnalysisEnabled"] as? Bool ?? true
    edgeDetectionEnabled = arguments["edgeDetectionEnabled"] as? Bool ?? true
    edgeOverlayEnabled = arguments["edgeOverlayEnabled"] as? Bool ?? true
    tapFocusEnabled = arguments["tapFocusEnabled"] as? Bool ?? true
    pinchZoomEnabled = arguments["pinchZoomEnabled"] as? Bool ?? true
    exposureSliderEnabled = arguments["exposureSliderEnabled"] as? Bool ?? true
    exposureResetEnabled = arguments["exposureResetEnabled"] as? Bool ?? true
    lowLightWarningEnabled = arguments["lowLightWarningEnabled"] as? Bool ?? true
    glareWarningEnabled = arguments["glareWarningEnabled"] as? Bool ?? true
    dirtyLensWarningEnabled = arguments["dirtyLensWarningEnabled"] as? Bool ?? true
    motionBlurWarningEnabled = arguments["motionBlurWarningEnabled"] as? Bool ?? true
    shadowWarningEnabled = arguments["shadowWarningEnabled"] as? Bool ?? true
    tooFarTooCloseWarningEnabled = arguments["tooFarTooCloseWarningEnabled"] as? Bool ?? true
    receiptFullyVisibleWarningEnabled = arguments["receiptFullyVisibleWarningEnabled"] as? Bool ?? true
    textTooSmallWarningEnabled = arguments["textTooSmallWarningEnabled"] as? Bool ?? true
    autoExposureAssistEnabled = arguments["autoExposureAssistEnabled"] as? Bool ?? true
    perspectiveCorrectionEnabled = arguments["perspectiveCorrectionEnabled"] as? Bool ?? true
    manualCropAfterCapture = arguments["manualCropAfterCapture"] as? Bool ?? true
    autoCropSuggestionEnabled = arguments["autoCropSuggestionEnabled"] as? Bool ?? true
    grayscalePreviewEnabled = arguments["grayscalePreviewEnabled"] as? Bool ?? true
    contrastBoostEnabled = arguments["contrastBoostEnabled"] as? Bool ?? true
    sharpeningEnabled = arguments["sharpeningEnabled"] as? Bool ?? true
    shadowReductionEnabled = arguments["shadowReductionEnabled"] as? Bool ?? true
    adaptiveThresholdEnabled = arguments["adaptiveThresholdEnabled"] as? Bool ?? true
    orientationCorrectionEnabled = arguments["orientationCorrectionEnabled"] as? Bool ?? true
    saveOriginalTemporarily = arguments["saveOriginalTemporarily"] as? Bool ?? true
    queueAcceptedCaptureLocally = arguments["queueAcceptedCaptureLocally"] as? Bool ?? true
    ocrUsesOriginalFirst = arguments["ocrUsesOriginalFirst"] as? Bool ?? true
    if let gap = arguments["analysisGapMs"] as? Double {
      analysisGapMs = min(max(gap, 250), 2500)
    } else if let gap = arguments["analysisGapMs"] as? Int {
      analysisGapMs = Double(min(max(gap, 250), 2500))
    }
    if let hold = arguments["readyHoldMs"] as? Double {
      readyHoldMs = min(max(hold, 250), 3000)
    } else if let hold = arguments["readyHoldMs"] as? Int {
      readyHoldMs = Double(min(max(hold, 250), 3000))
    }
    assistedShotCount = min(max(arguments["assistedShotCount"] as? Int ?? 4, 1), 12)
    bestShotCandidateCount = min(max(arguments["bestShotCandidateCount"] as? Int ?? 3, 1), 12)
    cameraResolutionTier = arguments["cameraResolutionTier"] as? String ?? "high"
    cameraWorkloadTier = arguments["cameraWorkloadTier"] as? String ?? "balanced"
    previewExposurePolicy = arguments["previewExposurePolicy"] as? String ?? previewExposurePolicy
    previewBrightnessGuardPolicy = arguments["previewBrightnessGuardPolicy"] as? String ?? previewBrightnessGuardPolicy
    shutterSpeedPolicy = arguments["shutterSpeedPolicy"] as? String ?? shutterSpeedPolicy
    tapToFocusPolicy = arguments["tapToFocusPolicy"] as? String ?? tapToFocusPolicy
    zoomGesturePolicy = arguments["zoomGesturePolicy"] as? String ?? zoomGesturePolicy
    autoCapturePolicy = arguments["autoCapturePolicy"] as? String ?? autoCapturePolicy
    autoCaptureStableFrameTarget = min(
      max(arguments["autoCaptureStableFrameTarget"] as? Int ?? autoCaptureStableFrameTarget, 2),
      8
    )
    autoCaptureMaxMotionScore = min(max(
      doubleArgument("autoCaptureMaxMotionScore", fallback: autoCaptureMaxMotionScore),
      3
    ), 18)
    autoCaptureMinBrightness = min(max(
      doubleArgument("autoCaptureMinBrightness", fallback: autoCaptureMinBrightness),
      72
    ), 180)
    autoCaptureMaxBrightness = min(max(
      doubleArgument("autoCaptureMaxBrightness", fallback: autoCaptureMaxBrightness),
      autoCaptureMinBrightness + 20
    ), 252)
    autoCaptureCooldownMs = min(max(
      doubleArgument("autoCaptureCooldownMs", fallback: autoCaptureCooldownMs),
      1200
    ), 6000)
    preCaptureExposurePolicy = arguments["preCaptureExposurePolicy"] as? String ?? preCaptureExposurePolicy
    maxLiveAnalysisPixels = max(arguments["maxLiveAnalysisPixels"] as? Int ?? 0, 0)
    maxCleanupPixels = max(arguments["maxCleanupPixels"] as? Int ?? 10000000, 0)
    maxStitchOutputPixels = max(arguments["maxStitchOutputPixels"] as? Int ?? 14000000, 0)
    maxStitchOutputHeight = max(arguments["maxStitchOutputHeight"] as? Int ?? 18000, 0)
    sessionMinZoom = arguments["minZoom"] as? Double ?? 1.0
    sessionMaxZoom = arguments["maxZoom"] as? Double ?? 1.0
    sessionMinExposureOffset = arguments["minExposureOffset"] as? Double ?? 0.0
    sessionMaxExposureOffset = arguments["maxExposureOffset"] as? Double ?? 0.0
    if let sectionLimit = arguments["maxSectionCount"] as? Int {
      maxSectionCount = min(max(sectionLimit, 1), 24)
    }
    if !canUseLongReceiptMode() {
      longReceiptMode = false
    }
    readPreviousSectionArguments()
  }

  private func readPreviousSectionArguments() {
    if let path = arguments["previousSectionGuidePhotoPath"] as? String,
       !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      previousSectionGuidePhotoPath = path
    }
    if let reason = arguments["previousSectionReasonCode"] as? String,
       !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      previousSectionReasonCode = reason.trimmingCharacters(in: .whitespacesAndNewlines)
    } else if previousSectionGuidePhotoPath != nil {
      previousSectionReasonCode = "continue_long_receipt"
    }
    if let guidance = arguments["previousSectionGuidance"] as? String,
       !guidance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      previousSectionGuidance = guidance.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    previousSectionGhostSourceStartFraction = boundedFraction(
      arguments["previousSectionGhostSourceStartFraction"] as? Double,
      fallback: previousSectionGhostSourceStartFraction
    )
    previousSectionGhostSourceHeightFraction = boundedFraction(
      arguments["previousSectionGhostSourceHeightFraction"] as? Double,
      fallback: previousSectionGhostSourceHeightFraction
    )
    previousSectionGhostOverlayTopFraction = boundedFraction(
      arguments["previousSectionGhostOverlayTopFraction"] as? Double,
      fallback: previousSectionGhostOverlayTopFraction
    )
    previousSectionGhostOverlayHeightFraction = boundedFraction(
      arguments["previousSectionGhostOverlayHeightFraction"] as? Double,
      fallback: previousSectionGhostOverlayHeightFraction
    )
    previousSectionGhostOpacity = boundedFraction(
      arguments["previousSectionGhostOpacity"] as? Double,
      fallback: previousSectionGhostOpacity
    )
  }

  private func doubleArgument(_ key: String, fallback: Double) -> Double {
    if let value = arguments[key] as? Double {
      return value
    }
    if let value = arguments[key] as? Int {
      return Double(value)
    }
    if let value = arguments[key] as? NSNumber {
      return value.doubleValue
    }
    return fallback
  }

  private func boundedFraction(_ value: Double?, fallback: CGFloat) -> CGFloat {
    guard let value, value.isFinite else { return fallback }
    return CGFloat(min(max(value, 0), 1))
  }
}
