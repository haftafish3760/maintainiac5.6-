import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  var usesSpanishReceiptCameraUi: Bool {
    return uiLocale.lowercased().hasPrefix("es")
  }

  func receiptCameraText(_ english: String, _ spanish: String) -> String {
    return usesSpanishReceiptCameraUi ? spanish : english
  }

  func iconButton(title: String, symbol: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle("", for: .normal)
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    button.layer.cornerRadius = 8
    button.accessibilityLabel = title
    return button
  }

  func modeLabel(_ title: String, _ detail: String) -> UILabel {
    let label = UILabel()
    label.text = "\(title)\n\(detail)"
    label.textColor = .white
    label.font = .boldSystemFont(ofSize: 12)
    label.numberOfLines = 2
    label.textAlignment = .center
    label.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    label.layer.cornerRadius = 8
    label.layer.masksToBounds = true
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return label
  }

  func guidanceText() -> String {
    if longReceiptMode {
      return receiptCameraText(
        "Fill the screen with readable receipt text. Use more photos for long receipts.",
        "Llene la pantalla con texto legible del recibo. Use más fotos para recibos largos."
      )
    }
    if autoCaptureEnabled {
      return receiptCameraText(
        "Fill the screen with readable receipt text. Auto capture can help when the receipt is steady.",
        "Llene la pantalla con texto legible del recibo. La captura automática ayuda cuando el recibo está estable."
      )
    }
    return receiptCameraText(
      "Fill the screen with readable receipt text, then tap the shutter.",
      "Llene la pantalla con texto legible del recibo y luego toque el disparador."
    )
  }

  func isTemporaryControlGuidance(_ message: String) -> Bool {
    return message.hasPrefix("Zoom ") || message.hasPrefix("Brightness ")
  }

  func restoreWorkflowGuidanceIfNeeded() {
    let current = guidanceLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if isTemporaryControlGuidance(current) {
      guidanceLabel.text = guidanceText()
    }
  }

  func settingsStatusText() -> String {
    let fillMode = assistedReceiptFill ? "Assist on" : "Manual fill"
    let reviewMode = reviewDepth == "detailedLines" ? "Detailed lines" : "Price-only lines"
    let receiptMode = longReceiptMode ? "Long receipt" : "Single photo"
    let lightMode = autoExposureAssistEnabled ? "Auto light" : "Manual light"
    return "\(fillMode) • \(reviewMode) • \(receiptMode) • \(lightMode)"
  }

  func shouldShowSettingsStatusStrip() -> Bool {
    // Keep the live preview chrome minimal. The full settings summary stays
    // inside the dedicated receipt camera settings surface instead.
    return false
  }

  func dataSaverLabel() -> String {
    switch dataSaverLevel {
    case "original":
      return "Local original"
    case "light":
      return "High quality"
    case "strong":
      return "Low storage"
    case "maximum":
      return "Tiny proof"
    default:
      return "Normal proof"
    }
  }

  func setReceiptReviewStyle(_ value: String) {
    reviewDepth = value
    updateSettingsStatusStrip()
  }

  func setDataSaverLevel(_ value: String) {
    dataSaverLevel = value
    updateSettingsStatusStrip()
  }

  func storageSafetyDetail() -> String {
    if storageConstrained {
      return "Keeps long receipts lighter"
    }
    return "OCR uses clear source first"
  }

  func visibleControlSet() -> String {
    var controls = [
      "back",
      "settings",
      "manual_shutter",
    ]
    if !torchButton.isHidden && torchButton.isEnabled {
      controls.append("light")
    }
    if exposureControlsVisible() {
      controls.append("brightness")
    }
    if reviewNextControlReady() {
      controls.append("long_receipt_done")
    }
    if !addPhotoButton.isHidden && addPhotoButton.isEnabled {
      controls.append("add_photo")
    }
    if !previousSectionGuidePanel.isHidden {
      controls.append("section_ghost_guide")
    }
    if edgeDetectionEnabled && edgeOverlayEnabled {
      controls.append("edge_guide")
    }
    return controls.joined(separator: "|")
  }

  func reviewNextControlReady() -> Bool {
    let bottomReady = !bottomReviewButton.isHidden && bottomReviewButton.isEnabled
    return bottomReady
  }

  func exposureControlsVisible() -> Bool {
    guard let parent = exposureSlider.superview else {
      return false
    }
    return !exposureSlider.isHidden && !parent.isHidden
  }

  func controlStatus(visible: Bool, enabled: Bool) -> String {
    if visible && enabled {
      return "ready"
    }
    if visible {
      return "visible_disabled"
    }
    return "missing"
  }

  var focusLockEnabled: Bool {
    return false
  }

  var exposureLockEnabled: Bool {
    return false
  }

  func nativeControlReadinessSummary() -> String {
    let statuses = [
      backControlActualStatus(),
      settingsControlActualStatus(),
      manualShutterControlActualStatus(),
      reviewNextControlActualStatus()
    ]
    return statuses.contains("missing") || statuses.contains("visible_disabled")
      ? "review_needed"
      : "ready"
  }

  func backControlActualStatus() -> String {
    return controlStatus(visible: true, enabled: !closeResultDelivered)
  }

  func settingsControlActualStatus() -> String {
    return controlStatus(visible: true, enabled: !closeResultDelivered)
  }

  func manualShutterControlActualStatus() -> String {
    return controlStatus(
      visible: shutterButton.superview != nil,
      enabled: shutterButton.isEnabled && !closingCamera && !closeResultDelivered
    )
  }

  func reviewNextControlActualStatus() -> String {
    if capturedPhotoPaths.isEmpty {
      return "ready"
    }
    let bottomVisible = !bottomReviewButton.isHidden
    let visible = bottomVisible
    let enabled = bottomVisible && bottomReviewButton.isEnabled
    return controlStatus(visible: visible, enabled: enabled)
  }

  func tapFocusControlActualStatus() -> String {
    return controlStatus(visible: false, enabled: false)
  }

  func pinchZoomControlActualStatus() -> String {
    return controlStatus(
      visible: pinchZoomEnabled,
      enabled: pinchZoomEnabled && cameraDevice != nil && isCameraUiUsable
    )
  }

  func exposureSliderControlActualStatus() -> String {
    return controlStatus(
      visible: exposureSliderEnabled,
      enabled: exposureSlider.isEnabled
    )
  }

  func exposureResetControlActualStatus() -> String {
    return controlStatus(
      visible: exposureResetEnabled,
      enabled: exposureResetButton.isEnabled
    )
  }

  func torchControlActualStatus() -> String {
    let hasTorch = cameraDevice?.hasTorch ?? false
    return controlStatus(
      visible: hasTorch,
      enabled: !torchButton.isHidden && torchButton.isEnabled && cameraDevice != nil && !closeResultDelivered
    )
  }

  func focusLockControlActualStatus() -> String {
    return controlStatus(visible: false, enabled: false)
  }

  func exposureLockControlActualStatus() -> String {
    return controlStatus(visible: false, enabled: false)
  }

  func whiteBalanceLockControlActualStatus() -> String {
    return controlStatus(visible: false, enabled: false)
  }

  func nextReceiptSectionNumber() -> Int {
    return min(capturedPhotoPaths.count + 1, maxSectionCount)
  }

  func previousSectionGhostGuideVisible() -> Bool {
    return longReceiptMode && !capturedPhotoPaths.isEmpty && capturedPhotoPaths.count < maxSectionCount
  }
}
