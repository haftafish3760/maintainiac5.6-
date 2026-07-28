import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  @objc func openReceiptCameraSettingsFullScreen() {
    settingsOpenCount += 1
    let settings = ReceiptCameraFullScreenSettingsViewController(camera: self)
    settings.modalPresentationStyle = .fullScreen
    present(settings, animated: true)
  }

  func configureSession() {
    lastSessionRecoveryStatus = "configuring"
    sessionQueue.async { [weak self] in
      guard let self, self.isCameraSessionUsable else { return }
      self.session.beginConfiguration()
      self.session.sessionPreset = .photo
      guard
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
        let input = try? AVCaptureDeviceInput(device: device),
        self.session.canAddInput(input),
        self.session.canAddOutput(self.photoOutput)
      else {
        DispatchQueue.main.async {
          self.lastSessionRecoveryStatus = "configuration_failed"
          self.shutterButton.isEnabled = false
          self.guidanceLabel.text = "The receipt camera could not open."
        }
        self.session.commitConfiguration()
        return
      }
      self.cameraDevice = device
      self.configureInitialFocusAndExposure(for: device)
      self.session.addInput(input)
      self.photoOutput.isHighResolutionCaptureEnabled = true
      if #available(iOS 13.0, *) {
      self.photoOutput.maxPhotoQualityPrioritization = .quality
      }
      self.session.addOutput(self.photoOutput)
      self.configureVideoAnalysisIfNeeded()
      self.applySessionInitialZoom(for: device)
      self.session.commitConfiguration()
      DispatchQueue.main.async {
        guard self.isCameraUiUsable else { return }
        self.lastSessionRecoveryStatus = "configured"
        self.torchButton.isEnabled = device.hasTorch
        self.configureExposureControls(for: device)
        self.updateCaptureOrientation()
      }
    }
  }

  func applySessionInitialZoom(for device: AVCaptureDevice) {
    guard pinchZoomEnabled else {
      lastZoomRatio = 1.0
      return
    }
    let minimumZoom = effectiveMinZoom(for: device)
    let maximumZoom = effectiveMaxZoom(for: device)
    guard maximumZoom > minimumZoom else {
      if minimumZoom.isFinite {
        lastZoomRatio = roundedDiagnostic(Double(minimumZoom))
      }
      return
    }
    let initialZoom = min(max(CGFloat(sessionInitialZoom), minimumZoom), maximumZoom)
    do {
      try device.lockForConfiguration()
      device.videoZoomFactor = initialZoom
      device.unlockForConfiguration()
      lastZoomRatio = roundedDiagnostic(Double(initialZoom))
      guidanceLabel.text = String(format: "Zoom %.1fx", initialZoom)
    } catch {
      lastZoomRatio = roundedDiagnostic(Double(minimumZoom))
      guidanceLabel.text = "Receipt camera preview is ready."
    }
  }

  func configureInitialFocusAndExposure(for device: AVCaptureDevice) {
    do {
      try device.lockForConfiguration()
      if continuousFocusEnabled,
         focusMode == "continuous",
         device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
        lastFocusStatus = "continuous_autofocus_configured"
      } else if focusMode == "continuous" {
        lastFocusStatus = "continuous_autofocus_unavailable"
      } else {
        lastFocusStatus = "continuous_focus_not_requested"
      }
      if exposureMode == "auto", device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      } else if exposureMode == "auto", device.isExposureModeSupported(.autoExpose) {
        device.exposureMode = .autoExpose
      }
      device.unlockForConfiguration()
    } catch {
      lastFocusStatus = "continuous_autofocus_configuration_failed"
    }
  }

  func configureVideoAnalysisIfNeeded() {
    let experimentalQualityWarningsEnabled =
      experimentalLiveReceiptQualityPolicyEnabled() &&
      (
        lowLightWarningEnabled ||
        glareWarningEnabled ||
        motionBlurWarningEnabled ||
        shadowWarningEnabled ||
        dirtyLensWarningEnabled
      )
    guard
      liveAnalysisEnabled,
      experimentalQualityWarningsEnabled ||
        edgeDetectionEnabled ||
        tooFarTooCloseWarningEnabled ||
        receiptFullyVisibleWarningEnabled ||
        textTooSmallWarningEnabled ||
        autoExposureAssistEnabled
    else { return }
    guard session.canAddOutput(videoOutput) else { return }
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ]
    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    session.addOutput(videoOutput)
  }

  func configureExposureControls(for device: AVCaptureDevice) {
    let minBias = effectiveMinExposureBias(for: device)
    let maxBias = effectiveMaxExposureBias(for: device)
    exposureSlider.minimumValue = minBias
    exposureSlider.maximumValue = maxBias
    exposureSlider.value = clampExposureBias(device.exposureTargetBias, for: device)
    let exposureAvailable = minBias < maxBias
    exposureSlider.isEnabled = exposureSliderEnabled && exposureAvailable
    exposureSlider.alpha = exposureSlider.isEnabled ? 1 : 0.45
    exposureResetButton.isEnabled = exposureResetEnabled && exposureAvailable
    exposureResetButton.alpha = exposureResetButton.isEnabled ? 1 : 0.45
  }

  @objc func cancelCapture() {
    closeRequestCount += 1
    lastBackDispatchPath = "top_bar_back_button"
    if closeResultDelivered {
      closeRetryCount += 1
      if presentingViewController != nil {
        dismiss(animated: true)
      }
      return
    }
    if captureInFlight {
      closeDuringCaptureCount += 1
      pendingCloseAfterCapture = true
      latestAutoCaptureStatus = "closing_after_capture"
      shutterButton.isEnabled = false
      guidanceLabel.text = "Saving this receipt photo before opening review."
      return
    }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if !capturedPhotoPaths.isEmpty {
      finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")
      return
    }
    cancelWithoutCapturedPhoto(reason: "back_no_photo_cancel")
  }

  func resetReceiptCameraDefaults() {
    settingsResetCount += 1
    // Receipt Assist belongs to Expense Settings; camera reset must preserve it.
    longReceiptMode = canUseLongReceiptMode()
    autoCaptureEnabled = false
    autoExposureAssistEnabled = true
    liveAnalysisEnabled = true
    edgeDetectionEnabled = true
    edgeOverlayEnabled = true
    setReceiptGuidanceWarningsEnabled(true)
    perspectiveCorrectionEnabled = true
    manualCropAfterCapture = true
    autoCropSuggestionEnabled = true
    grayscalePreviewEnabled = true
    contrastBoostEnabled = true
    sharpeningEnabled = true
    shadowReductionEnabled = true
    adaptiveThresholdEnabled = true
    orientationCorrectionEnabled = true
    autoCaptureStableFrameCount = 0
    latestAutoCaptureStatus = "reset_to_manual_capture"
    userExposureOverride = false
    resetExposure()
    receiptFrameGuide.isHidden = !(edgeDetectionEnabled && edgeOverlayEnabled)
    updateDoneButton()
    updateSettingsStatusStrip()
    guidanceLabel.text = "Receipt camera defaults restored. Manual shutter is ready."
  }
}
