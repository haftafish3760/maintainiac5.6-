import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard isCameraSessionUsable, !closingCamera, !closeResultDelivered else { return }
    let now = Date().timeIntervalSince1970 * 1000
    guard now - lastLiveAnalysisAt >= analysisGapMs else { return }
    lastLiveAnalysisAt = now
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let lumaSamples = sampleLiveLumaGrid(pixelBuffer)
    let motionScore = evaluateLiveMotion(lumaSamples)
    let shadowScore = estimateShadowScore(lumaSamples)
    let brightness = averageLuma(pixelBuffer)
    latestShadowScore = shadowScore
    let framing = edgeDetectionEnabled
      ? estimateReceiptFraming(pixelBuffer)
      : LiveReceiptFraming(edgeCoverage: -1, confidenceBucket: "off")
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isCameraUiUsable else { return }
      if self.edgeDetectionEnabled {
        self.applyLiveFraming(framing)
        self.maybeAutoCapture(
          framing: framing,
          brightness: brightness,
          motionScore: motionScore,
          nowMs: now
        )
      } else {
        self.latestFramingSignal = "edge_detection_off"
        self.latestFramingConfidence = "off"
        self.latestEdgeCoverage = -1
        self.latestPerspectiveReadiness = "perspective_skipped_edge_detection_off"
        self.autoCaptureStableFrameCount = 0
        self.latestAutoCaptureStatus = self.autoCaptureEnabled ? "waiting_for_edges" : "off"
      }
      self.applyLiveReadability(
        brightness,
        framing: framing,
        motionScore: motionScore,
        shadowScore: shadowScore,
        nowMs: now
      )
    }
  }

  func sampleLiveLumaGrid(_ pixelBuffer: CVPixelBuffer) -> [Int] {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
    let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
    guard
      width > 0,
      height > 0,
      let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
    else {
      return []
    }
    let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
    let rowStep = max(1, height / 12)
    let columnStep = max(1, width / 12)
    var samples: [Int] = []
    var row = rowStep / 2
    while row < height {
      var column = columnStep / 2
      while column < width {
        samples.append(Int(pointer[row * bytesPerRow + column]))
        column += columnStep
      }
      row += rowStep
    }
    return samples
  }

  func evaluateLiveMotion(_ samples: [Int]) -> Double {
    guard !samples.isEmpty else { return -1 }
    defer { previousLiveLumaSamples = samples }
    guard previousLiveLumaSamples.count == samples.count else {
      latestMotionScore = -1
      latestMotionSignal = "unknown"
      return -1
    }
    var totalDelta = 0.0
    for index in samples.indices {
      totalDelta += Double(abs(samples[index] - previousLiveLumaSamples[index]))
    }
    let score = totalDelta / Double(samples.count)
    latestMotionScore = score
    return score
  }

  func estimateShadowScore(_ samples: [Int]) -> Double {
    guard let minSample = samples.min(), let maxSample = samples.max() else {
      return -1
    }
    return Double(maxSample - minSample)
  }

  func averageLuma(_ pixelBuffer: CVPixelBuffer) -> Double {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
    let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
    guard
      width > 0,
      height > 0,
      let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
    else {
      return -1
    }
    let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
    let rowStep = max(1, height / 48)
    let columnStep = max(1, width / 48)
    var sum = 0
    var count = 0
    var row = 0
    while row < height {
      var column = 0
      while column < width {
        sum += Int(pointer[row * bytesPerRow + column])
        count += 1
        column += columnStep
      }
      row += rowStep
    }
    return count == 0 ? -1 : Double(sum) / Double(count)
  }

  func estimateReceiptFraming(_ pixelBuffer: CVPixelBuffer) -> LiveReceiptFraming {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
    let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
    guard
      width > 0,
      height > 0,
      let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
    else {
      return LiveReceiptFraming()
    }
    let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
    let rowStep = max(2, height / 72)
    let columnStep = max(2, width / 72)
    var left = width
    var top = height
    var right = 0
    var bottom = 0
    var hits = 0
    var totalSamples = 0
    var row = 0
    while row < height {
      var column = 0
      while column < width {
        totalSamples += 1
        let luma = Int(pointer[row * bytesPerRow + column])
        if luma > 188 || luma < 82 {
          hits += 1
          left = min(left, column)
          right = max(right, column)
          top = min(top, row)
          bottom = max(bottom, row)
        }
        column += columnStep
      }
      row += rowStep
    }
    guard hits >= 40, right > left, bottom > top else {
      return LiveReceiptFraming()
    }
    let widthRatio = Double(right - left) / Double(width)
    let heightRatio = Double(bottom - top) / Double(height)
    let edgeCoverage = min(max(widthRatio * heightRatio, 0), 1)
    let hitDensity = totalSamples <= 0 ? 0 : Double(hits) / Double(totalSamples)
    let confidenceScore = min(max((edgeCoverage * 0.72) + (hitDensity * 0.28), 0), 1)
    let touchesEdge =
      left < Int(Double(width) * 0.035) ||
      top < Int(Double(height) * 0.035) ||
      right > Int(Double(width) * 0.965) ||
      bottom > Int(Double(height) * 0.965)
    return LiveReceiptFraming(
      found: true,
      widthRatio: widthRatio,
      heightRatio: heightRatio,
      edgeCoverage: edgeCoverage,
      confidenceBucket: framingConfidenceBucket(confidenceScore),
      touchesEdge: touchesEdge
    )
  }

  func applyLiveFraming(_ framing: LiveReceiptFraming) {
    latestFramingConfidence = framing.confidenceBucket
    latestEdgeCoverage = framing.edgeCoverage
    latestFramingWidthRatio = framing.widthRatio
    latestFramingHeightRatio = framing.heightRatio
    latestPerspectiveReadiness = perspectiveReadiness(for: framing)
    if !framing.found {
      latestFramingSignal = "receipt_not_found"
      setFrameGuideColor(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.76))
      if receiptFullyVisibleWarningEnabled {
        guidanceLabel.text = "Place the receipt inside the frame. Manual capture still works."
      }
      return
    }
    if !hasUsableLiveFramingBounds(framing) {
      latestFramingSignal = "receipt_bounds_invalid"
      setFrameGuideColor(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.76))
      if receiptFullyVisibleWarningEnabled {
        guidanceLabel.text = "Receipt edges need another look. Keep the paper flat and visible."
      }
      return
    }
    if framing.widthRatio < 0.42 || framing.heightRatio < 0.36 {
      latestFramingSignal = "move_closer"
      setFrameGuideColor(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.84))
      if textTooSmallWarningEnabled || tooFarTooCloseWarningEnabled {
        guidanceLabel.text = "Move closer if text looks small; tap shutter if readable."
      }
      return
    }
    if framing.touchesEdge {
      latestFramingSignal = "possibly_cut_off"
      setFrameGuideColor(UIColor(red: 1, green: 0.69, blue: 0.13, alpha: 0.88))
      if receiptFullyVisibleWarningEnabled {
        guidanceLabel.text = "Receipt may be cut off. Leave paper edge visible, or tap shutter if readable."
      }
      return
    }
    latestFramingSignal = "framing_ok"
    setFrameGuideColor(UIColor(red: 0.56, green: 0.96, blue: 0.64, alpha: 0.82))
    if receiptFullyVisibleWarningEnabled {
      guidanceLabel.text = framingGuidanceCopy(framing.confidenceBucket)
    }
  }

  func perspectiveReadiness(for framing: LiveReceiptFraming) -> String {
    if !perspectiveCorrectionEnabled {
      return "perspective_skipped_setting_off"
    }
    if !edgeDetectionEnabled {
      return "perspective_skipped_edge_detection_off"
    }
    if !framing.found {
      return "perspective_skipped_no_receipt_bounds"
    }
    if !hasUsableLiveFramingBounds(framing) {
      return "perspective_skipped_invalid_bounds"
    }
    if framing.widthRatio < 0.34 || framing.heightRatio < 0.34 {
      return "perspective_skipped_bounds_too_small"
    }
    if framing.touchesEdge {
      return "perspective_skipped_cut_off_risk"
    }
    if framing.confidenceBucket != "strong_edges" &&
      framing.confidenceBucket != "usable_edges" {
      return "perspective_skipped_weak_edges"
    }
    return "perspective_ready_safe_bounds"
  }

  func framingGuidanceCopy(_ confidenceBucket: String) -> String {
    switch confidenceBucket {
    case "strong_edges":
      return "Receipt edges found. Hold steady and tap the shutter."
    case "usable_edges":
      return "Receipt edges look usable. Tap the shutter if the text is clear."
    case "weak_edges":
      return "Receipt edges are weak. Leave paper edges visible if you can."
    default:
    return "Receipt edge hint found. Make sure all text is readable."
    }
  }

  func hasUsableLiveFramingBounds(_ framing: LiveReceiptFraming) -> Bool {
    if !framing.found { return false }
    let ratios = [
      framing.widthRatio,
      framing.heightRatio,
      framing.edgeCoverage
    ]
    if ratios.contains(where: { !$0.isFinite }) { return false }
    return framing.widthRatio > 0 &&
      framing.heightRatio > 0 &&
      framing.edgeCoverage >= 0 &&
      framing.edgeCoverage <= 1
  }

  func framingConfidenceBucket(_ score: Double) -> String {
    if score >= 0.72 {
      return "strong_edges"
    }
    if score >= 0.48 {
      return "usable_edges"
    }
    if score >= 0.28 {
      return "weak_edges"
    }
    return "edge_hint_only"
  }

  func setFrameGuideColor(_ color: UIColor) {
    receiptFrameGuide.layer.borderColor = color.cgColor
  }
}
