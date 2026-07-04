import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
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
      return "Fill the screen with readable receipt text. Use more photos for long receipts."
    }
    if autoCaptureEnabled {
      return "Hold steady. Manual capture is always available."
    }
    return "Fill the screen with readable receipt text, then tap the shutter."
  }

  func settingsStatusText() -> String {
    let fillMode = assistedReceiptFill ? "Assist on" : "Manual fill"
    let reviewMode = reviewDepth == "detailedLines" ? "Detailed lines" : "Price-only lines"
    let receiptMode = longReceiptMode ? "Long receipt" : "Single photo"
    let brightnessMode = autoExposureAssistEnabled ? "Brightness assist" : "Manual brightness"
    return "Maintainiac receipt camera | \(fillMode) | \(reviewMode) | \(receiptMode) | \(brightnessMode) | \(dataSaverLabel()) saved proof\nOCR reads the original photo first."
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
    guidanceLabel.text = value == "detailedLines"
      ? "Detailed receipt details are on. OCR will show item details when it can."
      : "Price-only receipt details are on. OCR will focus on line prices and totals."
    updateSettingsStatusStrip()
  }

  func setDataSaverLevel(_ value: String) {
    dataSaverLevel = value
    guidanceLabel.text = "Save-space proof size set to \(dataSaverLabel()). OCR still reads the original photo first."
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
      "status"
    ]
    if !torchButton.isHidden && torchButton.isEnabled {
      controls.append("light")
    }
    if exposureSliderEnabled {
      controls.append("brightness")
    }
    if longReceiptMode {
      controls.append("long_receipt_done")
    }
    if !addPhotoButton.isHidden && addPhotoButton.isEnabled {
      controls.append("add_photo")
    }
    if previousSectionGuidePhotoPath != nil {
      controls.append("section_ghost_guide")
    }
    if edgeDetectionEnabled && edgeOverlayEnabled {
      controls.append("edge_guide")
    }
    return controls.joined(separator: "|")
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
    return focusMode == "locked"
  }

  var exposureLockEnabled: Bool {
    return exposureMode == "locked"
  }

  func nativeControlReadinessSummary() -> String {
    let statuses = [
      backControlActualStatus(),
      settingsControlActualStatus(),
      manualShutterControlActualStatus()
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
