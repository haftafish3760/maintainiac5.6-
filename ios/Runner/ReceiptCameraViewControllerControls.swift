import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func toggleExposureControls() {
    guard exposureSliderEnabled, exposureSlider.isEnabled else {
      guidanceLabel.text = "Brightness adjustment is not available on this camera."
      return
    }
    let visible = !(exposurePanel?.isHidden ?? true)
    exposurePanel?.isHidden = visible
    guidanceLabel.text = visible
      ? guidanceText()
      : "Adjust Brightness. The phone still controls autofocus and exposure timing."
  }

  @objc func toggleTorch() {
    guard let cameraDevice, cameraDevice.hasTorch else { return }
    do {
      try cameraDevice.lockForConfiguration()
      torchOn.toggle()
      cameraDevice.torchMode = torchOn ? .on : .off
      cameraDevice.unlockForConfiguration()
      torchButton.setImage(
        UIImage(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill"),
        for: .normal
      )
      torchButton.accessibilityLabel = torchOn ? "Turn light off" : "Turn light on"
    } catch {
      guidanceLabel.text = "The light is not available right now."
    }
  }

  @objc func zoomPreview(_ recognizer: UIPinchGestureRecognizer) {
    guard pinchZoomEnabled else {
      lastZoomStatus = "disabled"
      return
    }
    guard let cameraDevice else {
      zoomUnavailableCount += 1
      lastZoomStatus = "camera_unavailable"
      return
    }
    if recognizer.state == .began {
      zoomGestureStartCount += 1
      lastZoomFactor = cameraDevice.videoZoomFactor
      lastZoomStatus = "gesture_started"
    }
    let minimumZoom = effectiveMinZoom(for: cameraDevice)
    let maximumZoom = effectiveMaxZoom(for: cameraDevice)
    guard lastZoomFactor.isFinite, recognizer.scale.isFinite else {
      zoomUnavailableCount += 1
      lastZoomStatus = "zoom_invalid_scale"
      return
    }
    let nextZoom = min(max(lastZoomFactor * recognizer.scale, minimumZoom), maximumZoom)
    guard nextZoom.isFinite else {
      zoomUnavailableCount += 1
      lastZoomStatus = "zoom_invalid_scale"
      return
    }
    if abs(maximumZoom - minimumZoom) < 0.01 {
      zoomUnavailableCount += 1
      lastZoomStatus = "zoom_range_locked"
      return
    }
    do {
      try cameraDevice.lockForConfiguration()
      cameraDevice.videoZoomFactor = nextZoom
      cameraDevice.unlockForConfiguration()
      zoomChangeCount += 1
      lastZoomRatio = roundedDiagnostic(Double(nextZoom))
      lastZoomStatus = "zoom_changed"
      guidanceLabel.text = String(format: "Zoom %.1fx", nextZoom)
    } catch {
      zoomUnavailableCount += 1
      lastZoomStatus = "zoom_failed"
      guidanceLabel.text = "Zoom could not be adjusted right now."
    }
    if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
      restoreWorkflowGuidanceIfNeeded()
    }
  }

  @objc func exposureChanged(_ slider: UISlider) {
    guard exposureSliderEnabled else { return }
    guard let cameraDevice else { return }
    userExposureOverride = true
    manualExposureChangeCount += 1
    let bias = clampExposureBias(slider.value, for: cameraDevice)
    setExposureBias(bias, message: String(format: "Brightness %.1f", bias))
  }

  @objc func resetExposure() {
    guard exposureResetEnabled else { return }
    guard let cameraDevice else { return }
    let resetBias = clampExposureBias(0, for: cameraDevice)
    exposureSlider.value = resetBias
    userExposureOverride = false
    manualExposureChangeCount += 1
    setExposureBias(resetBias, message: "Brightness reset.")
  }

  @objc func exposureInteractionEnded() {
    restoreWorkflowGuidanceIfNeeded()
  }

  func setExposureBias(_ bias: Float, message: String) {
    guard let cameraDevice else { return }
    guard bias.isFinite else {
      guidanceLabel.text = "Brightness could not be adjusted right now."
      return
    }
    do {
      try cameraDevice.lockForConfiguration()
      cameraDevice.setExposureTargetBias(bias, completionHandler: nil)
      cameraDevice.unlockForConfiguration()
      guidanceLabel.text = message
    } catch {
      guidanceLabel.text = "Brightness could not be adjusted right now."
    }
  }
}
