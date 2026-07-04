import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func settingsSummary() -> String {
    let review = reviewDepth == "detailedLines"
      ? "Detailed receipt lines"
      : "Price-only receipt lines"
    return """
    Maintainiac receipt camera: these settings control this receipt scanner, not the phone's regular camera app.
    Assisted receipt fill: \(assistedReceiptFill ? "On" : "Off")
    Long receipt mode: \(longReceiptMode ? "On" : "Off"). Start at the top, add sections in order, and repeat a few readable lines so Maintainiac can match the receipt pieces.
    Automatic capture: \(autoCaptureEnabled ? "On" : "Off")
    \(autoCaptureDetail())
    Auto brightness assist: \(autoExposureAssistEnabled ? "On" : "Off")
    Receipt edge guidance: \(edgeDetectionEnabled ? "On" : "Off")
    Receipt guidance warnings: \(receiptGuidanceWarningsEnabled() ? "On" : "Off")
    Capture quality: take the clearest receipt photo for OCR first. Save-space proof size is applied only after receipt assistance uses the clearest source.
    Image cleanup: crop, straighten, grayscale, contrast, and shadow cleanup after capture.
    Review style: \(review)
    Saved proof size: \(dataSaverLabel()) for proof and cloud backup
    OCR reads the original photo first. Smaller saved proof copies are made after the receipt has been read.
    Manual shutter always works immediately. Automatic capture is optional.

    Hold steady for continuous focus. Move closer, reduce glare, or use Brightness if the receipt stays hard to read. Pinch to zoom anytime.
    """
  }

  func autoCaptureDetail() -> String {
    if isAutoCaptureCurrentlyAllowed() {
      return "Off by default. Automatic capture waits for several steady, readable frames. Manual shutter always works."
    }
    if !edgeDetectionEnabled {
      return "Turn receipt edge guidance on before using automatic capture."
    }
    return "Manual capture is safest for this device or storage mode."
  }

  func autoCaptureBlockedMessage() -> String {
    if !edgeDetectionEnabled {
      return "Receipt edge guidance is off, so automatic capture is held back. Tap the shutter when ready."
    }
    if storageConstrained {
      return "Storage is tight, so automatic capture is held back. Tap the shutter when ready."
    }
    return "Automatic capture is held back on this device. Tap the shutter when ready."
  }

  func isAutoCaptureCurrentlyAllowed() -> Bool {
    return autoCaptureAllowed && edgeDetectionEnabled
  }

  func canUseLongReceiptMode() -> Bool {
    return maxSectionCount > 1
  }

  func effectiveMinZoom(for device: AVCaptureDevice) -> CGFloat {
    return max(CGFloat(sessionMinZoom), CGFloat(1))
  }

  func effectiveMaxZoom(for device: AVCaptureDevice) -> CGFloat {
    let cameraMax = min(device.maxAvailableVideoZoomFactor, 10)
    return max(effectiveMinZoom(for: device), min(CGFloat(sessionMaxZoom), cameraMax))
  }

  func effectiveMinExposureBias(for device: AVCaptureDevice) -> Float {
    return max(device.minExposureTargetBias, Float(sessionMinExposureOffset))
  }

  func effectiveMaxExposureBias(for device: AVCaptureDevice) -> Float {
    return max(
      effectiveMinExposureBias(for: device),
      min(device.maxExposureTargetBias, Float(sessionMaxExposureOffset))
    )
  }

  func clampExposureBias(_ bias: Float, for device: AVCaptureDevice) -> Float {
    return min(max(bias, effectiveMinExposureBias(for: device)), effectiveMaxExposureBias(for: device))
  }

  func receiptGuidanceWarningsEnabled() -> Bool {
    lowLightWarningEnabled ||
      glareWarningEnabled ||
      dirtyLensWarningEnabled ||
      motionBlurWarningEnabled ||
      shadowWarningEnabled ||
      tooFarTooCloseWarningEnabled ||
      receiptFullyVisibleWarningEnabled ||
      textTooSmallWarningEnabled
  }

  func setReceiptGuidanceWarningsEnabled(_ enabled: Bool) {
    lowLightWarningEnabled = enabled
    glareWarningEnabled = enabled
    dirtyLensWarningEnabled = enabled
    motionBlurWarningEnabled = enabled
    shadowWarningEnabled = enabled
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
    textTooSmallWarningEnabled = enabled
  }
}
