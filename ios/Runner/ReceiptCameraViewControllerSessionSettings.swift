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
      self.session.commitConfiguration()
      DispatchQueue.main.async {
        guard self.isCameraUiUsable else { return }
        self.torchButton.isEnabled = device.hasTorch
        self.configureExposureControls(for: device)
      }
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

  @objc func showReceiptCameraSettings() {
    settingsOpenCount += 1
    let alert = UIAlertController(
      title: "Receipt Camera Settings",
      message: settingsSummary(),
      preferredStyle: .actionSheet
    )
    alert.addAction(UIAlertAction(
      title: assistedReceiptFill ? "Turn assisted receipt fill off" : "Turn assisted receipt fill on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.assistedReceiptFill.toggle()
      self.guidanceLabel.text = self.guidanceText()
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: longReceiptMode ? "Turn long receipt mode off" : "Turn long receipt mode on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      if !self.longReceiptMode && !self.canUseLongReceiptMode() {
        self.longReceiptMode = false
        self.guidanceLabel.text = "Long receipt mode is unavailable for this device or storage setting."
        self.updateDoneButton()
        self.updateSettingsStatusStrip()
        return
      }
      self.longReceiptMode.toggle()
      self.guidanceLabel.text = self.guidanceText()
      self.updateDoneButton()
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: autoCaptureEnabled ? "Turn automatic capture off" : "Turn automatic capture on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      guard self.isAutoCaptureCurrentlyAllowed() else {
        self.autoCaptureEnabled = false
        self.autoCaptureStableFrameCount = 0
        self.guidanceLabel.text = self.autoCaptureBlockedMessage()
        self.updateSettingsStatusStrip()
        return
      }
      self.autoCaptureEnabled.toggle()
      self.guidanceLabel.text = self.autoCaptureEnabled
        ? "Automatic capture is on. Hold steady, or capture anytime."
        : self.guidanceText()
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: autoExposureAssistEnabled ? "Turn auto brightness assist off" : "Turn auto brightness assist on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.autoExposureAssistEnabled.toggle()
      self.guidanceLabel.text = self.autoExposureAssistEnabled
        ? "Auto brightness assist is on."
        : "Auto brightness assist is off. Use Brightness manually."
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: edgeDetectionEnabled ? "Turn receipt edge guidance off" : "Turn receipt edge guidance on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.edgeDetectionEnabled.toggle()
      if !self.edgeDetectionEnabled && self.autoCaptureEnabled {
        self.autoCaptureEnabled = false
        self.autoCaptureStableFrameCount = 0
        self.latestAutoCaptureStatus = "edge_detection_off"
      }
      self.receiptFrameGuide.isHidden = !(self.edgeDetectionEnabled && self.edgeOverlayEnabled)
      self.guidanceLabel.text = self.edgeDetectionEnabled
        ? "Receipt edge guidance is on."
        : "Receipt edge guidance is off. Take the clearest photo you can."
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: receiptGuidanceWarningsEnabled()
        ? "Turn receipt framing checks off"
        : "Turn receipt framing checks on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.setReceiptGuidanceWarningsEnabled(!self.receiptGuidanceWarningsEnabled())
      self.guidanceLabel.text = self.receiptGuidanceWarningsEnabled()
        ? "Receipt framing checks are on."
        : "Receipt framing checks are off. Manual shutter still works."
      self.updateSettingsStatusStrip()
    })
    alert.addAction(UIAlertAction(
      title: receiptCameraText(
        "Receipt details style: prices only",
        "Estilo de detalles del recibo: solo precios"
      ),
      style: .default
    ) { [weak self] _ in
      self?.setReceiptReviewStyle("pricesOnly")
    })
    alert.addAction(UIAlertAction(
      title: receiptCameraText(
        "Receipt details style: detailed lines",
        "Estilo de detalles del recibo: líneas detalladas"
      ),
      style: .default
    ) { [weak self] _ in
      self?.setReceiptReviewStyle("detailedLines")
    })
    if !capturedPhotoPaths.isEmpty {
      alert.addAction(UIAlertAction(
        title: receiptCameraText(
          "Save-space proof: local original",
          "Prueba para ahorrar espacio: original local"
        ),
        style: .default
      ) { [weak self] _ in
        self?.setDataSaverLevel("original")
      })
      alert.addAction(UIAlertAction(
        title: receiptCameraText(
          "Save-space proof: high quality",
          "Prueba para ahorrar espacio: alta calidad"
        ),
        style: .default
      ) { [weak self] _ in
        self?.setDataSaverLevel("light")
      })
      alert.addAction(UIAlertAction(
        title: receiptCameraText(
          "Save-space proof: normal proof",
          "Prueba para ahorrar espacio: normal"
        ),
        style: .default
      ) { [weak self] _ in
        self?.setDataSaverLevel("balanced")
      })
      alert.addAction(UIAlertAction(
        title: receiptCameraText(
          "Save-space proof: low storage",
          "Prueba para ahorrar espacio: ahorro de espacio"
        ),
        style: .default
      ) { [weak self] _ in
        self?.setDataSaverLevel("strong")
      })
      alert.addAction(UIAlertAction(
        title: receiptCameraText(
          "Save-space proof: tiny proof",
          "Prueba para ahorrar espacio: muy pequeña"
        ),
        style: .default
      ) { [weak self] _ in
        self?.setDataSaverLevel("maximum")
      })
    }
    alert.addAction(UIAlertAction(title: "Reset receipt camera defaults", style: .default) { [weak self] _ in
      self?.resetReceiptCameraDefaults()
    })
    alert.addAction(UIAlertAction(title: "Reset brightness", style: .default) { [weak self] _ in
      self?.resetExposure()
    })
    alert.addAction(UIAlertAction(title: "Close settings", style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = torchButton
      popover.sourceRect = torchButton.bounds
    }
    present(alert, animated: true)
  }

  func resetReceiptCameraDefaults() {
    settingsResetCount += 1
    // Receipt Assist remains opt-in, even after restoring camera defaults.
    assistedReceiptFill = false
    longReceiptMode = canUseLongReceiptMode()
    autoCaptureEnabled = false
    reviewDepth = "pricesOnly"
    dataSaverLevel = "balanced"
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
