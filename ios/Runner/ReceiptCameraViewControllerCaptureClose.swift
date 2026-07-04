import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func brightnessBucket(_ brightness: Double) -> String {
    if brightness < 0 {
      return "unknown"
    }
    if brightness <= 70 {
      return "too_dark_warning"
    }
    if brightness <= 138 {
      return "dark_assisted"
    }
    if brightness >= 246 {
      return "glare_warning"
    }
    if brightness >= 232 {
      return "bright_receipt_ok"
    }
    return "lighting_ok"
  }

  func exposureAssistStatus() -> String {
    guard let device = cameraDevice else {
      return "camera_unavailable"
    }
    if device.minExposureTargetBias == device.maxExposureTargetBias {
      return "not_supported"
    }
    if userExposureOverride {
      return "manual_override"
    }
    if !autoExposureAssistEnabled {
      return "off"
    }
    if autoExposureAdjustmentCount > 0 {
      return "auto_adjusted"
    }
    return "ready"
  }

  func preCaptureExposureOutcome() -> String {
    switch lastPreCaptureExposureDecision {
    case "brightened_before_capture", "brightening_before_capture":
      return "lifted_for_dim_receipt"
    case "dimmed_before_capture", "dimming_before_capture":
      return "dimmed_for_glare_risk"
    case "native_auto_exposure_kept_for_capture",
         "pre_capture_dimming_skipped_native_auto":
      return "kept_native_auto"
    case "manual_override":
      return "manual_brightness_used"
    case "assist_off":
      return "assist_off"
    case "not_supported":
      return "not_supported"
    case "brightness_unknown":
      return "brightness_unknown"
    case "adjustment_not_confirmed":
      return "adjustment_not_confirmed"
    case "already_at_limit":
      return "already_at_limit"
    case "aborted_camera_closing":
      return "aborted_camera_closing"
    default:
      return "not_evaluated"
    }
  }

  func closeCapturedPhotoOutcome() -> String {
    if closeAction == "back_returned_captured_sections" {
      return "back_returned_captured_sections"
    }
    if closeAction == "done_returned_captured_sections" {
      return "next_returned_captured_sections"
    }
    if closeAction == "back_capture_failed_returned_existing_sections" {
      return "capture_failed_returned_existing_sections"
    }
    if closeAction.contains("capture_failed") {
      return "capture_failed_after_close"
    }
    if closeAction.hasSuffix("no_photo_cancel") {
      return "closed_without_photo"
    }
    if pendingCloseAfterCapture {
      return "waiting_for_in_flight_capture"
    }
    if closeRetryCount > 0 {
      return "close_already_delivered"
    }
    return "open_or_not_closed"
  }

  @objc func finishWithCapturedPhotos(closeReason: String = "done_returned_captured_sections") {
    guard !closeResultDelivered else { return }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    guard !capturedPhotoPaths.isEmpty else {
      cancelWithoutCapturedPhoto(reason: "done_no_photo_cancel")
      return
    }
    closeAction = closeReason
    if closeReason == "back_returned_captured_sections" ||
      closeReason == "back_capture_failed_returned_existing_sections" {
      closeReturnedSectionsCount += 1
    }
    latestCaptureToReviewReadyMs = captureElapsedSinceStart()
    latestCaptureLatencyBucket = captureReviewLatencyBucket(latestCaptureToReviewReadyMs)
    closeResultDelivered = true
    let capturedAt = firstCapturedAt ?? ISO8601DateFormatter().string(from: Date())
    let diagnostics = nativeCaptureDiagnostics(
      photoByteSize: totalCapturedByteSize,
      capturedAt: capturedAt
    )
    dismiss(animated: true) { [weak self] in
      guard let self else { return }
      self.onCapture?(self.capturedPhotoPaths, capturedAt, diagnostics)
    }
  }

  func finishPendingCloseAfterCaptureFailure() {
    pendingCloseAfterCapture = false
    if !capturedPhotoPaths.isEmpty {
      guidanceLabel.text =
        "That last photo did not save. Opening review with the receipt photos already captured."
      finishWithCapturedPhotos(
        closeReason: "back_capture_failed_returned_existing_sections"
      )
      return
    }
    cancelWithoutCapturedPhoto(reason: "back_capture_failed_cancel")
  }

  func cancelWithoutCapturedPhoto(reason: String) {
    guard !closeResultDelivered else { return }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    closeAction = reason
    closeNoPhotoCancelCount += 1
    closeResultDelivered = true
    dismiss(animated: true) { [weak self] in
      self?.onCancel?(reason)
    }
  }

  func captureElapsedSinceStart() -> Int {
    guard latestCaptureStartedAt > 0 else { return -1 }
    let elapsed = Int((Date().timeIntervalSince1970 * 1000) - latestCaptureStartedAt)
    return max(0, elapsed)
  }

  func captureLatencyBucket(_ milliseconds: Int) -> String {
    if milliseconds < 0 { return "unknown" }
    if milliseconds <= 450 { return "save_fast_under_450ms" }
    if milliseconds <= 900 { return "save_good_under_900ms" }
    if milliseconds <= 1600 { return "save_review_under_1600ms" }
    if milliseconds <= 2800 { return "save_slow_under_2800ms" }
    return "save_very_slow_over_2800ms"
  }

  func captureReviewLatencyBucket(_ milliseconds: Int) -> String {
    if milliseconds < 0 { return latestCaptureLatencyBucket }
    if milliseconds <= 700 { return "review_fast_under_700ms" }
    if milliseconds <= 1200 { return "review_good_under_1200ms" }
    if milliseconds <= 2200 { return "review_watch_under_2200ms" }
    if milliseconds <= 3800 { return "review_slow_under_3800ms" }
    return "review_very_slow_over_3800ms"
  }

  func updateDoneButton() {
    doneButton.isHidden = !longReceiptMode
    doneButton.isEnabled = !capturedPhotoPaths.isEmpty
    let title: String
    if capturedPhotoPaths.isEmpty {
      title = "Next"
    } else if capturedPhotoPaths.count == 1 {
      title = "Next"
    } else {
      title = "Next (\(capturedPhotoPaths.count) photos)"
    }
    doneButton.setTitle(title, for: .normal)
    addPhotoButton.isHidden = capturedPhotoPaths.isEmpty
    addPhotoButton.isEnabled = !capturedPhotoPaths.isEmpty && capturedPhotoPaths.count < maxSectionCount
    addPhotoButton.setTitle(addSectionButtonTitle(), for: .normal)
    addPhotoButton.accessibilityLabel = addSectionButtonAccessibilityLabel()
    shutterButton.accessibilityLabel = capturedPhotoPaths.isEmpty
      ? "Take receipt photo"
      : "Add receipt section \(nextReceiptSectionNumber())"
    bottomReviewButton.isEnabled = !capturedPhotoPaths.isEmpty
    bottomReviewButton.setTitle(title, for: .normal)
    bottomReviewButton.accessibilityLabel = "Next: review captured receipt photos in Maintainiac"
    doneButton.accessibilityLabel = "Next: review captured receipt photos in Maintainiac"
    updateSettingsStatusStrip()
  }

  func updateSettingsStatusStrip() {
    settingsStatusStrip.text = settingsStatusText()
  }

  func newReceiptCaptureUrl() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("receipt_camera", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("receipt_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString).jpg")
  }
}
