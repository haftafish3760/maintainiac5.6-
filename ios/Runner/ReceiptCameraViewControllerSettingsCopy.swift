import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func settingsSummary() -> String {
    let review = reviewDepth == "detailedLines"
      ? receiptCameraText("Detailed receipt lines", "Líneas detalladas del recibo")
      : receiptCameraText("Price-only receipt lines", "Líneas del recibo solo con precios")
    return """
    Maintainiac receipt camera: this uses the phone's native camera baseline with Maintainiac receipt workflow controls layered on top.
    Assisted receipt fill: \(assistedReceiptFill ? "On" : "Off")
    Long receipt mode: \(longReceiptMode ? "On" : "Off"). Start at the top, add sections in order, and repeat a few readable lines so Maintainiac can match the receipt pieces.
    Automatic capture: \(autoCaptureEnabled ? "On" : "Off")
    \(autoCaptureDetail())
    Auto brightness assist: \(autoExposureAssistEnabled ? "On" : "Off")
    Receipt edge guidance: \(edgeDetectionEnabled ? "On" : "Off")
    Receipt framing checks: \(receiptGuidanceWarningsEnabled() ? "On" : "Off")
    Capture quality: take the clearest receipt photo first. Save-space proof size is applied only after Maintainiac reads the clearest source.
    Image cleanup: crop, straighten, grayscale, contrast, and shadow cleanup after capture.
    Review style: \(review)
    \(capturedPhotoPaths.isEmpty
      ? receiptCameraText(
          "Saved proof size appears after your first receipt photo is captured. Capture first, then review the saved proof size with real receipt proof.",
          "El tamaño de la prueba guardada aparece después de capturar la primera foto del recibo. Capture primero y luego revise el tamaño con una prueba real."
        )
      : receiptCameraText(
          "Saved proof size: \(dataSaverLabel()) for proof and cloud backup",
          "Tamaño de la prueba guardada: \(dataSaverLabel()) para comprobante y respaldo en la nube"
        ))
    \(capturedPhotoPaths.isEmpty
      ? receiptCameraText(
          "Maintainiac reads the temporary full-quality photo first. Saved proof size stays hidden until there is real receipt proof to review.",
          "Maintainiac primero lee la foto temporal de calidad completa. El tamaño de la prueba guardada permanece oculto hasta que exista una prueba real para revisar."
        )
      : receiptCameraText(
          "Maintainiac reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt has been read.",
          "Maintainiac primero lee la foto temporal de calidad completa. Las copias de prueba más pequeñas se crean después de leer el recibo."
        ))
    Manual shutter always works immediately. Automatic capture is optional.

    Hold steady for the phone camera's autofocus. Pinch to zoom if the print is small. Use Brightness anytime.
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
    let safeBias = bias.isFinite ? bias : 0
    return min(
      max(safeBias, effectiveMinExposureBias(for: device)),
      effectiveMaxExposureBias(for: device)
    )
  }

  func receiptGuidanceWarningsEnabled() -> Bool {
    tooFarTooCloseWarningEnabled ||
      receiptFullyVisibleWarningEnabled ||
      textTooSmallWarningEnabled
  }

  func experimentalLiveReceiptQualityPolicyEnabled() -> Bool {
    readabilityGuidancePolicy == "native_camera_receipt_quality_guidance_v1" ||
      readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"
  }

  func setReceiptGuidanceWarningsEnabled(_ enabled: Bool) {
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
    textTooSmallWarningEnabled = enabled
  }
}
