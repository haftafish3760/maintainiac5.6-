extension ReceiptCameraViewController {
  func capturedBrightnessBucket(_ luma: Double) -> String {
    if !luma.isFinite || luma < 0 { return "unknown" }
    if luma < 70 { return "captured_too_dark" }
    if luma < 105 { return "captured_dim" }
    if luma < 205 { return "captured_readable" }
    if luma < 246 { return "captured_bright" }
    return "captured_glare_risk"
  }

  func roundedDiagnostic(_ value: Double) -> Double {
    if !value.isFinite || value < 0 { return -1 }
    return (value * 10).rounded() / 10
  }

  func capturedSharpnessBucket(_ edgeScore: Double) -> String {
    if !edgeScore.isFinite || edgeScore < 0 { return "unknown" }
    if edgeScore < 5.5 { return "captured_soft_blur_risk" }
    if edgeScore < 10 { return "captured_usable_soft" }
    if edgeScore < 24 { return "captured_sharp" }
    return "captured_high_contrast_edges"
  }

  func capturedQualitySignal(
    brightnessBucket: String,
    sharpnessBucket: String
  ) -> String {
    if brightnessBucket == "unknown" || sharpnessBucket == "unknown" { return "unknown" }
    if brightnessBucket == "captured_too_dark" || brightnessBucket == "captured_glare_risk" {
      return "retake_brightness_risk"
    }
    if sharpnessBucket == "captured_soft_blur_risk" { return "retake_blur_risk" }
    if brightnessBucket == "captured_dim" || sharpnessBucket == "captured_usable_soft" {
      return "review_before_saving"
    }
    return "captured_readable"
  }

  func capturedVerticalQualitySignal(_ sample: CapturedPhotoQualitySample) -> String {
    if sample.bottomLuma < 0 || sample.topLuma < 0 || sample.middleLuma < 0 {
      return "unknown"
    }
    let upperLuma = (sample.topLuma + sample.middleLuma) / 2
    if sample.bottomLuma < 70 {
      return "bottom_too_dark"
    }
    if sample.bottomEdgeScore >= 0 && sample.bottomEdgeScore <= 5.5 && sample.edgeScore >= 8 {
      return "bottom_soft_blur_risk"
    }
    if upperLuma - sample.bottomLuma >= 28 {
      return "bottom_darker_than_upper"
    }
    if sample.bottomLuma - upperLuma >= 42 {
      return "bottom_glare_than_upper"
    }
    return "vertical_quality_even"
  }

  func capturedBottomTopLumaDelta(_ sample: CapturedPhotoQualitySample) -> Double {
    if sample.bottomLuma < 0 || sample.topLuma < 0 { return -10000 }
    return roundedDiagnostic(sample.bottomLuma - sample.topLuma)
  }

  func capturedBottomTopLumaDeltaBucket(_ delta: Double) -> String {
    if !delta.isFinite || delta < -999 { return "unknown" }
    if delta <= -42 { return "bottom_much_darker_than_top" }
    if delta <= -24 { return "bottom_darker_than_top" }
    if delta >= 42 { return "bottom_much_brighter_than_top" }
    if delta >= 24 { return "bottom_brighter_than_top" }
    return "top_bottom_brightness_close"
  }

  func receiptBottomEdgeDetected() -> Bool {
    receiptBottomEdgeStatus() == "bottom_visible"
  }

  func hasLiveReceiptCutOffRisk() -> Bool {
    latestFramingSignal.elementsEqual("possibly_cut_off") ||
      latestPerspectiveReadiness == "perspective_skipped_cut_off_risk"
  }

  func hasLiveReceiptFramingOk() -> Bool {
    latestFramingSignal.elementsEqual("framing_ok")
  }

  func receiptBottomEdgeStatus() -> String {
    if hasLiveReceiptCutOffRisk() {
      return "possibly_cut_off"
    }
    if latestCapturedBottomEdgeScore >= 0 &&
      latestCapturedBottomEdgeScore <= 5.5 &&
      latestCapturedEdgeScore >= 8 {
      return "bottom_soft_or_missing"
    }
    if latestCapturedBottomEdgeScore >= 10 {
      return "bottom_visible"
    }
    if latestEdgeCoverage >= 0.70 && hasLiveReceiptFramingOk() {
      return "bottom_visible"
    }
    if latestCapturedBottomEdgeScore >= 0 {
      return "bottom_uncertain"
    }
    return "not_evaluated"
  }

  func capturedLiveToSavedLumaDelta(
    liveBrightnessAtShutter: Double,
    capturedAverageLuma: Double
  ) -> Double {
    if !liveBrightnessAtShutter.isFinite ||
      !capturedAverageLuma.isFinite ||
      liveBrightnessAtShutter < 0 ||
      capturedAverageLuma < 0 {
      return -10000
    }
    return roundedDiagnostic(capturedAverageLuma - liveBrightnessAtShutter)
  }

  func capturedLiveToSavedLumaDeltaBucket(_ delta: Double) -> String {
    if !delta.isFinite || delta <= -9999 { return "unknown" }
    if delta <= -58 { return "saved_much_darker_than_preview" }
    if delta <= -32 { return "saved_darker_than_preview" }
    if delta >= 58 { return "saved_much_brighter_than_preview" }
    if delta >= 32 { return "saved_brighter_than_preview" }
    return "saved_matches_preview"
  }

  func capturedPreviewParitySignal(
    deltaBucket: String,
    capturedBrightnessBucket: String
  ) -> String {
    if deltaBucket == "unknown" || capturedBrightnessBucket == "unknown" {
      return "unknown"
    }
    if deltaBucket == "saved_much_darker_than_preview" ||
      (deltaBucket == "saved_darker_than_preview" &&
        (capturedBrightnessBucket == "captured_dim" ||
          capturedBrightnessBucket == "captured_too_dark")) {
      return "saved_photo_darker_than_preview_review_needed"
    }
    if deltaBucket == "saved_darker_than_preview" {
      return "saved_photo_darker_than_preview_watch"
    }
    if deltaBucket == "saved_much_brighter_than_preview" ||
      (deltaBucket == "saved_brighter_than_preview" &&
        capturedBrightnessBucket == "captured_glare_risk") {
      return "saved_photo_brighter_than_preview_review_needed"
    }
    if deltaBucket == "saved_brighter_than_preview" {
      return "saved_photo_brighter_than_preview_watch"
    }
    return "saved_photo_matches_preview"
  }

  func capturedExposureMismatch(
    liveBrightness: Double,
    capturedBrightnessBucket: String,
    preCaptureDecision: String
  ) -> String {
    if !liveBrightness.isFinite || liveBrightness < 0 ||
      capturedBrightnessBucket == "unknown" {
      return "unknown"
    }
    let liveBucket = brightnessBucket(liveBrightness)
    if liveBucket == "unknown" { return "unknown" }
    let preCaptureAdjusted = preCaptureDecision == "brightened_before_capture" ||
      preCaptureDecision == "brightening_before_capture"
    if preCaptureAdjusted && capturedBrightnessBucket == "captured_too_dark" {
      return "pre_capture_brightened_still_too_dark"
    }
    if preCaptureAdjusted && capturedBrightnessBucket == "captured_dim" {
      return "pre_capture_brightened_still_dim"
    }
    if liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_too_dark" {
      return "live_ok_capture_too_dark"
    }
    if liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_dim" {
      return "live_ok_capture_dim"
    }
    if (liveBucket == "too_dark_warning" || liveBucket == "dark_assisted") &&
      capturedBrightnessBucket == "captured_readable" {
      return "live_dark_capture_readable"
    }
    if (liveBucket == "glare_warning" || liveBucket == "bright_receipt_ok") &&
      capturedBrightnessBucket == "captured_readable" {
      return "live_bright_capture_readable"
    }
    return "live_capture_aligned"
  }

  func capturedLightingEvidence(
    brightnessBucket: String,
    verticalQualitySignal: String,
    bottomTopDeltaBucket: String,
    exposureMismatch: String
  ) -> String {
    if brightnessBucket == "unknown" || exposureMismatch == "unknown" { return "unknown" }
    if exposureMismatch == "pre_capture_brightened_still_too_dark" ||
      brightnessBucket == "captured_too_dark" {
      return "capture_too_dark"
    }
    if exposureMismatch == "pre_capture_brightened_still_dim" ||
      exposureMismatch == "live_ok_capture_dim" ||
      brightnessBucket == "captured_dim" {
      return "capture_dim_review_needed"
    }
    if verticalQualitySignal == "bottom_too_dark" ||
      verticalQualitySignal == "bottom_darker_than_upper" ||
      bottomTopDeltaBucket == "bottom_darker_than_top" ||
      bottomTopDeltaBucket == "bottom_much_darker_than_top" {
      return "bottom_lighting_risk"
    }
    if brightnessBucket == "captured_glare_risk" { return "capture_glare_risk" }
    return "lighting_readable"
  }

  func byteSizeBucket(_ bytes: Int) -> String {
    if bytes <= 0 { return "unknown" }
    if bytes < 350_000 { return "tiny_under_350kb" }
    if bytes < 1_000_000 { return "small_under_1mb" }
    if bytes < 3_000_000 { return "normal_1mb_to_3mb" }
    if bytes < 8_000_000 { return "large_3mb_to_8mb" }
    return "very_large_over_8mb"
  }

  func megapixelBucket(width: Int, height: Int) -> String {
    if width <= 0 || height <= 0 { return "unknown" }
    let megapixels = Double(width * height) / 1_000_000.0
    if megapixels < 4.0 { return "low_under_4mp" }
    if megapixels < 9.0 { return "medium_4mp_to_9mp" }
    if megapixels < 18.0 { return "high_9mp_to_18mp" }
    if megapixels < 40.0 { return "very_high_18mp_to_40mp" }
    return "extreme_over_40mp"
  }
}
