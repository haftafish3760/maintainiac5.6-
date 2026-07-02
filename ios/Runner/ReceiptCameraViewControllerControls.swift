import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
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

  @objc func focusAndMeter(_ recognizer: UITapGestureRecognizer) {
    guard tapFocusEnabled else { return }
    guard recognizer.state == .ended, let cameraDevice, let previewLayer else { return }
    if Date() < suppressTapFocusUntil {
      tapFocusSuppressedAfterZoomCount += 1
      lastFocusStatus = "tap_focus_suppressed_after_zoom"
      return
    }
    let point = recognizer.location(in: view)
    let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
    let shouldLockFocus = focusMode == "locked"
    let shouldLockExposure = exposureMode == "locked"
    let shouldLockWhiteBalance = whiteBalanceLockEnabled && whiteBalanceMode == "locked"
    do {
      try cameraDevice.lockForConfiguration()
      if cameraDevice.isFocusPointOfInterestSupported {
        cameraDevice.focusPointOfInterest = devicePoint
        if cameraDevice.isFocusModeSupported(.continuousAutoFocus) {
          cameraDevice.focusMode = .continuousAutoFocus
        } else if cameraDevice.isFocusModeSupported(.autoFocus) {
          cameraDevice.focusMode = .autoFocus
        }
      }
      if cameraDevice.isExposurePointOfInterestSupported {
        cameraDevice.exposurePointOfInterest = devicePoint
        if cameraDevice.isExposureModeSupported(.continuousAutoExposure) {
          cameraDevice.exposureMode = .continuousAutoExposure
        } else if cameraDevice.isExposureModeSupported(.autoExpose) {
          cameraDevice.exposureMode = .autoExpose
        }
      }
      cameraDevice.unlockForConfiguration()
      tapFocusCount += 1
      lastFocusStatus = "requested"
      guidanceLabel.text = "Focus set. Hold steady, then tap the shutter."
      if shouldLockFocus || shouldLockExposure || shouldLockWhiteBalance {
        focusLockAttemptCount += 1
        if shouldLockWhiteBalance {
          whiteBalanceLockAttemptCount += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
          self?.lockFocusAndExposureIfSupported(
            lockFocus: shouldLockFocus,
            lockExposure: shouldLockExposure,
            lockWhiteBalance: shouldLockWhiteBalance
          )
        }
      }
    } catch {
      guidanceLabel.text = "Focus could not be adjusted right now."
    }
  }

  func lockFocusAndExposureIfSupported(
    lockFocus: Bool,
    lockExposure: Bool,
    lockWhiteBalance: Bool
  ) {
    guard let cameraDevice, !closingCamera, !isBeingDismissed else { return }
    do {
      try cameraDevice.lockForConfiguration()
      if lockFocus, cameraDevice.isFocusModeSupported(.locked) {
        cameraDevice.focusMode = .locked
        focusLockSuccessCount += 1
      }
      if lockExposure, cameraDevice.isExposureModeSupported(.locked) {
        cameraDevice.exposureMode = .locked
        exposureLockSuccessCount += 1
      }
      if lockWhiteBalance {
        if cameraDevice.isWhiteBalanceModeSupported(.locked) {
          cameraDevice.whiteBalanceMode = .locked
          whiteBalanceLockSuccessCount += 1
          whiteBalanceLockStatus = "locked"
        } else {
          whiteBalanceLockStatus = "not_supported"
        }
      } else {
        whiteBalanceLockStatus = "not_requested"
      }
      cameraDevice.unlockForConfiguration()
      if lockFocus || lockExposure || lockWhiteBalance {
        lastFocusStatus = focusLockSuccessCount > 0 ||
          exposureLockSuccessCount > 0 ||
          whiteBalanceLockSuccessCount > 0
          ? "locked"
          : "lock_not_supported"
        if lastFocusStatus == "locked" {
          guidanceLabel.text = "Focus locked. Tap the shutter when the receipt is readable."
        }
      }
    } catch {
      lastFocusStatus = "lock_failed"
      if lockWhiteBalance {
        whiteBalanceLockStatus = "lock_failed"
      }
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
    let nextZoom = min(max(lastZoomFactor * recognizer.scale, minimumZoom), maximumZoom)
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
      suppressTapFocusUntil = Date().addingTimeInterval(0.35)
      guidanceLabel.text = String(format: "Zoom %.1fx", nextZoom)
    } catch {
      zoomUnavailableCount += 1
      lastZoomStatus = "zoom_failed"
      guidanceLabel.text = "Zoom could not be adjusted right now."
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

  func setExposureBias(_ bias: Float, message: String) {
    guard let cameraDevice else { return }
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
