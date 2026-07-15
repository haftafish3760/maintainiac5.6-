import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  @objc func capturePrimaryPhoto() {
    capturePhoto(trigger: "manual_shutter")
  }

  @objc func captureAdditionalPhoto() {
    capturePhoto(trigger: "manual_add_photo")
  }

  func capturePhoto(trigger: String) {
    lastCaptureTrigger = trigger
    lastCaptureBlockReason = "none"
    if trigger == "manual_shutter" {
      manualShutterTapCount += 1
    } else if trigger == "auto_capture" {
      autoCaptureAttemptCount += 1
    }
    if captureInFlight {
      captureBlockedBusyCount += 1
      lastCaptureBlockReason = "capture_in_flight"
      return
    }
    if closingCamera {
      captureBlockedClosingCount += 1
      lastCaptureBlockReason = "closing_camera"
      return
    }
    if !isCameraUiUsable {
      captureBlockedSurfaceInactiveCount += 1
      lastCaptureBlockReason = "camera_surface_inactive"
      return
    }
    if cameraDevice == nil {
      captureBlockedNoCameraCount += 1
      lastCaptureBlockReason = "no_camera"
      return
    }
    if trigger == "manual_shutter" {
      manualCaptureStartedCount += 1
    } else if trigger == "auto_capture" {
      autoCaptureStartedCount += 1
    }
    captureInFlight = true
    latestCaptureStartedAt = Date().timeIntervalSince1970 * 1000
    latestCaptureToSavedMs = -1
    latestCaptureToReviewReadyMs = -1
    latestCaptureLatencyBucket = "capture_started"
    latestCaptureLiveBrightnessAtShutter = latestFrameBrightness
    shutterButton.isEnabled = false
    prepareExposureBeforeCapture { [weak self] in
      self?.capturePhotoAfterExposurePrep()
    }
  }

  func capturePhotoAfterExposurePrep() {
    guard isCameraUiUsable else {
      captureInFlight = false
      pendingCloseAfterCapture = false
      shutterButton.isEnabled = true
      return
    }
    let settings = AVCapturePhotoSettings()
    settings.isHighResolutionPhotoEnabled = true
    if #available(iOS 13.0, *) {
      stillCaptureModeLabel = "receipt_fast_document_shutter"
      settings.photoQualityPrioritization = .balanced
    }
    if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
      settings.embeddedThumbnailPhotoFormat = [
        AVVideoCodecKey: AVVideoCodecType.jpeg
      ]
    }
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  func prepareExposureBeforeCapture(_ onReady: @escaping () -> Void) {
    lastPreCaptureExposureSkipReason = "none"
    lastPreCaptureExposureAbortReason = "none"
    guard autoExposureAssistEnabled else {
      lastPreCaptureExposureDecision = "assist_off"
      lastPreCaptureExposureSkipReason = "assist_off"
      onReady()
      return
    }
    guard !userExposureOverride else {
      lastPreCaptureExposureDecision = "manual_override"
      lastPreCaptureExposureSkipReason = "manual_override"
      onReady()
      return
    }
    guard let cameraDevice, latestFrameBrightness.isFinite, latestFrameBrightness >= 0 else {
      lastPreCaptureExposureDecision = "brightness_unknown"
      lastPreCaptureExposureSkipReason = "brightness_unknown"
      onReady()
      return
    }
    let current = cameraDevice.exposureTargetBias
    let minBias = effectiveMinExposureBias(for: cameraDevice)
    let maxBias = effectiveMaxExposureBias(for: cameraDevice)
    let target = preCaptureExposureTarget(
      current: current,
      minBias: minBias,
      maxBias: maxBias
    )
    guard abs(target - current) >= 0.01 else {
      lastPreCaptureExposureDecision = preCaptureExposureSkipDecision()
      lastPreCaptureExposureSkipReason = lastPreCaptureExposureDecision
      onReady()
      return
    }
    lastPreCaptureExposureDecision = target > current
      ? "brightening_before_capture"
      : "dimming_before_capture"
    preCaptureExposureAdjustmentCount += 1
    lastPreCaptureExposureTargetBias = target
    lastAutoExposureBias = target
    do {
      try cameraDevice.lockForConfiguration()
      cameraDevice.setExposureTargetBias(target) { [weak self] _ in
        DispatchQueue.main.async {
          guard let self else { return }
          if !self.isCameraUiUsable {
            self.captureInFlight = false
            self.pendingCloseAfterCapture = false
            self.preCaptureExposureAbortCount += 1
            self.lastPreCaptureExposureDecision = "aborted_camera_closing"
            self.lastPreCaptureExposureAbortReason = self.closeResultDelivered
              ? "result_already_delivered"
              : "camera_ui_inactive"
            return
          }
          self.lastPreCaptureExposureDecision = target > current
            ? "brightened_before_capture"
            : "dimmed_before_capture"
          self.preCaptureExposureAdjustmentConfirmedCount += 1
          onReady()
        }
      }
      cameraDevice.unlockForConfiguration()
      exposureSlider.value = target
    } catch {
      lastPreCaptureExposureDecision = "adjustment_not_confirmed"
      onReady()
    }
  }

  func preCaptureExposureTarget(
    current: Float,
    minBias: Float,
    maxBias: Float
  ) -> Float {
    if latestFrameBrightness <= 55 {
      return min(current + 1.25, maxBias)
    }
    if latestFrameBrightness <= 70 {
      return min(current + 1.0, maxBias)
    }
    // Let the device exposure system keep normal paper at its native baseline. A
    // last-second lift can slow the shutter and soften small thermal print.
    if latestFrameBrightness <= 104 {
      return min(current + 0.5, maxBias)
    }
    // Last-second prep should not dim readable bright receipts. Native AE, live assist,
    // and glare guidance handle that while the manual shutter remains predictable.
    if latestFrameBrightness >= 238 {
      return current
    }
    return current
  }

  func preCaptureExposureSkipDecision() -> String {
    if latestFrameBrightness >= 104 && latestFrameBrightness <= 238 {
      return "native_auto_exposure_kept_for_capture"
    }
    if latestFrameBrightness > 238 {
      return "pre_capture_dimming_skipped_native_auto"
    }
    return "already_at_limit"
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    guard isCameraSessionUsable || pendingCloseAfterCapture else {
      captureInFlight = false
      pendingCloseAfterCapture = false
      return
    }
    if error != nil {
      captureInFlight = false
      guard isCameraUiUsable || pendingCloseAfterCapture else { return }
      if pendingCloseAfterCapture {
        finishPendingCloseAfterCaptureFailure()
        return
      }
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      captureInFlight = false
      guard isCameraUiUsable || pendingCloseAfterCapture else { return }
      if pendingCloseAfterCapture {
        finishPendingCloseAfterCaptureFailure()
        return
      }
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
      return
    }
    do {
      guard isCameraSessionUsable || pendingCloseAfterCapture else {
        captureInFlight = false
        pendingCloseAfterCapture = false
        return
      }
      let url = try newReceiptCaptureUrl()
      try data.write(to: url, options: .atomic)
      let capturedAt = ISO8601DateFormatter().string(from: Date())
      latestCaptureToSavedMs = captureElapsedSinceStart()
      latestCaptureLatencyBucket = captureLatencyBucket(latestCaptureToSavedMs)
      if maxLocalPhotoBytes > 0 && totalCapturedByteSize + data.count > maxLocalPhotoBytes {
        let shouldReturnExistingSections = pendingCloseAfterCapture && !capturedPhotoPaths.isEmpty
        try? FileManager.default.removeItem(at: url)
        latestCaptureLatencyBucket = "capture_rejected_over_byte_budget"
        lastCaptureBlockReason = "native_capture_over_byte_budget"
        latestAutoCaptureStatus = "native_capture_over_byte_budget"
        pendingCloseAfterCapture = false
        captureInFlight = false
        shutterButton.isEnabled = true
        updateDoneButton()
        guidanceLabel.text =
          "That receipt photo was too large for this device setting. Try again with the receipt closer and clearer."
        if shouldReturnExistingSections {
          finishWithCapturedPhotos(closeReason: "back_capture_failed_returned_existing_sections")
        }
        return
      }
      if firstCapturedAt == nil {
        firstCapturedAt = capturedAt
      }
      capturedPhotoPaths.append(url.path)
      totalCapturedByteSize += data.count
      recordCapturedPhotoQuality(data: data)
      autoCaptureCooldownUntilMs =
        Date().timeIntervalSince1970 * 1000 + Double(autoCaptureCooldownMs)
      if pendingCloseAfterCapture {
        pendingCloseAfterCapture = false
        captureInFlight = false
        finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")
        return
      }
      finishWithCapturedPhotos(closeReason: "capture_saved_open_review")
    } catch {
      captureInFlight = false
      if pendingCloseAfterCapture {
        finishPendingCloseAfterCaptureFailure()
        return
      }
      guard isCameraUiUsable else { return }
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
    }
  }
}
