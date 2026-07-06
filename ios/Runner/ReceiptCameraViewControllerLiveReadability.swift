import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

private let receiptQualityReviewReadabilitySignals: Set<String> = [
  "shadow_risk",
  "dirty_lens_or_haze",
]

extension ReceiptCameraViewController {
  var isCameraSessionUsable: Bool {
    return isViewLoaded && !closeResultDelivered && !isBeingDismissed
  }

  var isCameraUiUsable: Bool {
    return isCameraSessionUsable && !cameraViewClosing
  }

  func applyLiveReadability(
    _ brightness: Double,
    framing: LiveReceiptFraming,
    motionScore: Double,
    shadowScore: Double,
    nowMs: Double
  ) {
    latestFrameBrightness = brightness
    autoAdjustExposureForLiveFrame(
      brightness: brightness,
      nowMs: nowMs,
      framing: framing
    )
    let hasReceiptTarget = !edgeDetectionEnabled || hasUsableLiveFramingBounds(framing)
    if !hasReceiptTarget {
      latestMotionSignal = "waiting_for_receipt_target"
      latestReadabilitySignal = "waiting_for_receipt_target"
      resetExperimentalReceiptQualityCandidate()
      resetExperimentalReceiptQualityGuidanceIfNeeded()
      return
    }
    if !hasExperimentalReceiptQualityWarningsEnabled() {
      latestMotionSignal = "neutral_workflow_guidance_only"
      latestReadabilitySignal = "neutral_workflow_guidance_only"
      resetExperimentalReceiptQualityCandidate()
      resetExperimentalReceiptQualityGuidanceIfNeeded()
      return
    }
    if !brightness.isFinite || !motionScore.isFinite || !shadowScore.isFinite {
      latestMotionSignal = "unknown"
      latestReadabilitySignal = "readability_unknown"
      updateExperimentalReceiptQualityGuidance(
        signal: "readability_unknown",
        message: "Receipt quality needs another look. Keep it flat and readable."
      )
    } else if motionBlurWarningEnabled && motionScore > 22 {
      latestMotionSignal = "moving_too_much"
      updateExperimentalReceiptQualityGuidance(
        signal: "moving_too_much",
        message: "Hold steady so the receipt text stays sharp."
      )
    } else if lowLightWarningEnabled && brightness >= 0 && brightness <= 58 {
      latestReadabilitySignal = "low_light"
      updateExperimentalReceiptQualityGuidance(
        signal: "low_light",
        message: "Receipt looks dark. Add light or raise Brightness."
      )
    } else if glareWarningEnabled && brightness >= 246 {
      latestReadabilitySignal = "glare_or_overbright"
      updateExperimentalReceiptQualityGuidance(
        signal: "glare_or_overbright",
        message: "Receipt is very bright. Tilt it or lower Brightness."
      )
    } else if shadowWarningEnabled && shadowScore >= 150 {
      latestReadabilitySignal = "shadow_risk"
      updateExperimentalReceiptQualityGuidance(
        signal: "shadow_risk",
        message: "Receipt has heavy shadows. Move it into even light."
      )
    } else if dirtyLensWarningEnabled && brightness >= 120 && brightness <= 235 &&
        shadowScore >= 0 && shadowScore <= 24 && motionScore >= 0 && motionScore <= 7 {
      latestReadabilitySignal = "dirty_lens_or_haze"
      updateExperimentalReceiptQualityGuidance(
        signal: "dirty_lens_or_haze",
        message: "Lens may be smudged. Wipe it if the receipt looks hazy."
      )
    } else {
      latestMotionSignal = motionScore >= 0 ? "steady" : "unknown"
      latestReadabilitySignal = "lighting_ok"
      resetExperimentalReceiptQualityCandidate()
      resetExperimentalReceiptQualityGuidanceIfNeeded()
    }
  }

  func hasExperimentalReceiptQualityWarningsEnabled() -> Bool {
    return motionBlurWarningEnabled ||
        lowLightWarningEnabled ||
        glareWarningEnabled ||
        shadowWarningEnabled ||
        dirtyLensWarningEnabled
  }

  func updateExperimentalReceiptQualityGuidance(
    signal: String,
    message: String
  ) {
    if stableExperimentalReceiptQualitySignal(signal) {
      guidanceLabel.text = message
    } else {
      resetExperimentalReceiptQualityGuidanceIfNeeded()
    }
  }

  func stableExperimentalReceiptQualitySignal(_ signal: String) -> Bool {
    if experimentalReceiptQualityCandidateSignal == signal {
      experimentalReceiptQualityCandidateCount += 1
    } else {
      experimentalReceiptQualityCandidateSignal = signal
      experimentalReceiptQualityCandidateCount = 1
    }
    return experimentalReceiptQualityCandidateCount >= 2
  }

  func resetExperimentalReceiptQualityCandidate() {
    experimentalReceiptQualityCandidateSignal = "none"
    experimentalReceiptQualityCandidateCount = 0
  }

  func resetExperimentalReceiptQualityGuidanceIfNeeded() {
    let currentGuidance = guidanceLabel.text ?? ""
    if currentGuidance.hasPrefix("Receipt quality needs another look") ||
        currentGuidance.hasPrefix("Hold steady so the receipt text stays sharp") ||
        currentGuidance.hasPrefix("Receipt looks dark") ||
        currentGuidance.hasPrefix("Receipt is very bright") ||
        currentGuidance.hasPrefix("Receipt has heavy shadows") ||
        currentGuidance.hasPrefix("Lens may be smudged") {
      guidanceLabel.text = guidanceText()
    }
  }

  func autoAdjustExposureForLiveFrame(
    brightness: Double,
    nowMs: Double,
    framing: LiveReceiptFraming
  ) {
    lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
    guard brightness.isFinite, brightness >= 0 else {
      lastAutoExposureDecision = "brightness_unknown"
      resetAutoExposureCandidate()
      return
    }
    guard edgeDetectionEnabled, framing.found else {
      if brightness <= 104 {
        guard stableAutoExposureCandidate("fallback_brighten", requiredFrames: 4) else { return }
        autoAdjustExposureForLiveFrame(
          brighten: true,
          strongCorrection: brightness <= 70,
          nowMs: nowMs
        )
      } else if brightness >= 252 {
        guard stableAutoExposureCandidate("fallback_dim", requiredFrames: 5) else { return }
        autoAdjustExposureForLiveFrame(
          brighten: false,
          strongCorrection: brightness >= 254,
          nowMs: nowMs
        )
      } else {
        lastAutoExposureDecision = "waiting_for_receipt_target"
        resetAutoExposureCandidate()
      }
      return
    }
    if brightness <= 150 {
      guard stableAutoExposureCandidate("brighten") else { return }
      autoAdjustExposureForLiveFrame(
        brighten: true,
        strongCorrection: brightness <= 104,
        nowMs: nowMs
      )
    } else if brightness >= 250 {
      guard stableAutoExposureCandidate("dim", requiredFrames: 5) else { return }
      autoAdjustExposureForLiveFrame(
        brighten: false,
        strongCorrection: brightness >= 254,
        nowMs: nowMs
      )
    } else {
      lastAutoExposureDecision = "lighting_ok"
      resetAutoExposureCandidate()
    }
  }

  func stableAutoExposureCandidate(
    _ candidate: String,
    requiredFrames: Int = 2
  ) -> Bool {
    if lastAutoExposureCandidate == candidate {
      autoExposureCandidateFrameCount += 1
    } else {
      lastAutoExposureCandidate = candidate
      autoExposureCandidateFrameCount = 1
    }
    guard autoExposureCandidateFrameCount >= requiredFrames else {
      lastAutoExposureDecision = "stabilizing_\(candidate)"
      return false
    }
    return true
  }

  func resetAutoExposureCandidate() {
    lastAutoExposureCandidate = "none"
    autoExposureCandidateFrameCount = 0
  }

  func maybeAutoCapture(
    framing: LiveReceiptFraming,
    brightness: Double,
    motionScore: Double,
    nowMs: Double
  ) {
    guard autoCaptureEnabled else {
      autoCaptureStableFrameCount = 0
      latestAutoCaptureStatus = "off"
      return
    }
    if closingCamera || isBeingDismissed {
      autoCaptureStableFrameCount = 0
      latestAutoCaptureStatus = "closing"
      return
    }
    if captureInFlight || nowMs < autoCaptureCooldownUntilMs {
      latestAutoCaptureStatus = "cooling_down"
      return
    }
    let edgesReady =
      framing.found &&
      hasUsableLiveFramingBounds(framing) &&
      !framing.touchesEdge &&
      (framing.confidenceBucket == "strong_edges" ||
        framing.confidenceBucket == "usable_edges")
    let steady = motionScore >= 0 && motionScore <= autoCaptureMaxMotionScore
    let lightReady =
      brightness >= autoCaptureMinBrightness &&
      brightness <= autoCaptureMaxBrightness
    let qualityReviewNeeded =
      receiptQualityReviewReadabilitySignals.contains(latestReadabilitySignal)
    guard edgesReady, steady, lightReady, !qualityReviewNeeded else {
      autoCaptureStableFrameCount = 0
      if !edgesReady {
        latestAutoCaptureStatus = "waiting_for_edges"
      } else if !steady {
        latestAutoCaptureStatus = "waiting_for_steady"
      } else if !lightReady {
        latestAutoCaptureStatus = "waiting_for_light"
      } else if qualityReviewNeeded {
        latestAutoCaptureStatus = "waiting_for_quality_review"
      } else {
        latestAutoCaptureStatus = "waiting"
      }
      return
    }
    autoCaptureStableFrameCount += 1
    latestAutoCaptureStatus =
      "ready_\(autoCaptureStableFrameCount)_of_\(autoCaptureStableFrameTarget)"
    guard autoCaptureStableFrameCount >= autoCaptureStableFrameTarget else { return }
    autoCaptureStableFrameCount = 0
    autoCaptureTriggerCount += 1
    autoCaptureCooldownUntilMs = nowMs + autoCaptureCooldownMs
    latestAutoCaptureStatus = "capturing"
    guidanceLabel.text = "Receipt looks steady. Taking photo."
    capturePhoto(trigger: "auto_capture")
  }

  func autoAdjustExposureForLiveFrame(
    brighten: Bool,
    strongCorrection: Bool,
    nowMs: Double
  ) {
    guard autoExposureAssistEnabled else {
      lastAutoExposureDecision = "off"
      return
    }
    guard !userExposureOverride else {
      lastAutoExposureDecision = "manual_override"
      return
    }
    guard nowMs - lastAutoExposureAdjustmentAt >= 900 else {
      lastAutoExposureDecision = "cooling_down"
      return
    }
    guard let cameraDevice else {
      lastAutoExposureDecision = "camera_unavailable"
      return
    }
    let minBias = effectiveMinExposureBias(for: cameraDevice)
    let maxBias = effectiveMaxExposureBias(for: cameraDevice)
    guard minBias < maxBias else {
      lastAutoExposureDecision = "not_supported"
      return
    }
    let current = cameraDevice.exposureTargetBias
    lastAutoExposureBias = current
    let step: Float = strongCorrection ? 0.50 : 0.25
    let target = brighten
      ? min(current + step, maxBias)
      : max(current - step, minBias)
    guard abs(target - current) >= 0.01 else {
      lastAutoExposureDecision = brighten ? "already_at_brightest" : "already_at_dimmest"
      return
    }
    exposureSlider.value = target
    setExposureBias(target, message: brighten ? "Brightness assisted." : "Glare reduced.")
    autoExposureAdjustmentCount += 1
    lastAutoExposureAdjustmentAt = nowMs
    lastAutoExposureBias = target
    resetAutoExposureCandidate()
    lastAutoExposureDecision = brighten
      ? (strongCorrection ? "brightened_strong" : "brightened")
      : (strongCorrection ? "dimmed_strong" : "dimmed")
  }
}
