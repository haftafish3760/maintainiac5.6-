import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

final class ReceiptCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
  var onCapture: (([String], String, [String: Any]) -> Void)?
  var onCancel: (() -> Void)?

  private let arguments: [String: Any]
  private let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let sessionQueue = DispatchQueue(label: "maintainiac.receipt.camera.session")
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var cameraDevice: AVCaptureDevice?
  private var torchOn = false
  private var captureInFlight = false
  private var closingCamera = false
  private var pendingCloseAfterCapture = false
  private var closeResultDelivered = false
  private let shutterButton = UIButton(type: .system)
  private let torchButton = UIButton(type: .system)
  private let doneButton = UIButton(type: .system)
  private let guidanceLabel = UILabel()
  private let receiptFrameGuide = UIView()
  private let exposureSlider = UISlider()
  private let exposureResetButton = UIButton(type: .system)
  private let previousSectionGuidePanel = UIStackView()
  private let previousSectionGuideImageView = UIImageView()
  private var lastZoomFactor: CGFloat = 1
  private var assistedReceiptFill = true
  private var longReceiptMode = true
  private var autoCaptureEnabled = false
  private var autoCaptureAllowed = false
  private var reviewDepth = "pricesOnly"
  private var focusMode = "continuous"
  private var exposureMode = "auto"
  private var whiteBalanceMode = "auto"
  private var dataSaverLevel = "balanced"
  private var storageSafetyLevel = "balanced"
  private var storageConstrained = false
  private var storageSafetyReason = "normal"
  private var previousSectionGuidePhotoPath: String?
  private var liveAnalysisEnabled = true
  private var edgeDetectionEnabled = true
  private var edgeOverlayEnabled = true
  private var lowLightWarningEnabled = true
  private var glareWarningEnabled = true
  private var motionBlurWarningEnabled = true
  private var shadowWarningEnabled = true
  private var tooFarTooCloseWarningEnabled = true
  private var receiptFullyVisibleWarningEnabled = true
  private var textTooSmallWarningEnabled = true
  private var tapFocusEnabled = true
  private var pinchZoomEnabled = true
  private var exposureSliderEnabled = true
  private var exposureResetEnabled = true
  private var autoExposureAssistEnabled = true
  private var perspectiveCorrectionEnabled = true
  private var manualCropAfterCapture = true
  private var autoCropSuggestionEnabled = true
  private var grayscalePreviewEnabled = true
  private var contrastBoostEnabled = true
  private var sharpeningEnabled = true
  private var shadowReductionEnabled = true
  private var adaptiveThresholdEnabled = true
  private var orientationCorrectionEnabled = true
  private var analysisGapMs = 720.0
  private var lastLiveAnalysisAt = 0.0
  private var latestFrameBrightness = -1.0
  private var latestShadowScore = -1.0
  private var latestReadabilitySignal = "unknown"
  private var latestFramingSignal = "unknown"
  private var latestFramingConfidence = "unknown"
  private var latestEdgeCoverage = -1.0
  private var latestPerspectiveReadiness = "unknown"
  private var latestMotionSignal = "unknown"
  private var latestMotionScore = -1.0
  private var previousLiveLumaSamples: [Int] = []
  private var userExposureOverride = false
  private var autoExposureAdjustmentCount = 0
  private var lastAutoExposureAdjustmentAt = 0.0
  private var lastAutoExposureDecision = "not_evaluated"
  private var lastAutoExposureBrightnessBucket = "unknown"
  private var lastAutoExposureCandidate = "none"
  private var autoExposureCandidateFrameCount = 0
  private var lastAutoExposureBias: Float = 0
  private var tapFocusCount = 0
  private var tapFocusSuppressedAfterZoomCount = 0
  private var zoomChangeCount = 0
  private var manualExposureChangeCount = 0
  private var lastFocusStatus = "not_used"
  private var suppressTapFocusUntil = Date.distantPast
  private var focusLockAttemptCount = 0
  private var focusLockSuccessCount = 0
  private var exposureLockSuccessCount = 0
  private var whiteBalanceLockAttemptCount = 0
  private var whiteBalanceLockSuccessCount = 0
  private var whiteBalanceLockStatus = "not_requested"
  private var autoCaptureStableFrameCount = 0
  private var autoCaptureTriggerCount = 0
  private var autoCaptureCooldownUntilMs = 0.0
  private var latestAutoCaptureStatus = "off"
  private var closeAction = "open"
  private var closeRetryCount = 0
  private var maxSectionCount = 8
  private var capturedPhotoPaths: [String] = []
  private var firstCapturedAt: String?
  private var totalCapturedByteSize = 0
  private var latestCapturedPhotoWidth = 0
  private var latestCapturedPhotoHeight = 0
  private var latestCapturedMegapixelBucket = "unknown"
  private var latestCapturedByteBucket = "unknown"
  private var latestCapturedBrightnessBucket = "unknown"
  private var latestCapturedSharpnessBucket = "unknown"
  private var latestCapturedQualitySignal = "unknown"
  private var latestCapturedExposureMismatch = "unknown"

  init(arguments: [String: Any]) {
    self.arguments = arguments
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    readSessionArguments()
    buildLayout()
    configureSession()
  }

  private func readSessionArguments() {
    assistedReceiptFill = arguments["assistedReceiptFill"] as? Bool ?? true
    longReceiptMode = arguments["longReceiptMode"] as? Bool ?? true
    autoCaptureEnabled = arguments["autoCaptureEnabled"] as? Bool ?? false
    autoCaptureAllowed = arguments["autoCaptureAllowed"] as? Bool ?? autoCaptureEnabled
    if !autoCaptureAllowed {
      autoCaptureEnabled = false
    }
    reviewDepth = arguments["reviewDepth"] as? String ?? "pricesOnly"
    focusMode = arguments["focusMode"] as? String ?? "continuous"
    exposureMode = arguments["exposureMode"] as? String ?? "auto"
    whiteBalanceMode = arguments["whiteBalanceMode"] as? String ?? "auto"
    dataSaverLevel = arguments["dataSaverLevel"] as? String ?? "balanced"
    storageSafetyLevel = arguments["storageSafetyLevel"] as? String ?? dataSaverLevel
    storageConstrained = arguments["storageConstrained"] as? Bool ?? false
    storageSafetyReason = arguments["storageSafetyReason"] as? String ?? "normal"
    liveAnalysisEnabled = arguments["liveAnalysisEnabled"] as? Bool ?? true
    edgeDetectionEnabled = arguments["edgeDetectionEnabled"] as? Bool ?? true
    edgeOverlayEnabled = arguments["edgeOverlayEnabled"] as? Bool ?? true
    tapFocusEnabled = arguments["tapFocusEnabled"] as? Bool ?? true
    pinchZoomEnabled = arguments["pinchZoomEnabled"] as? Bool ?? true
    exposureSliderEnabled = arguments["exposureSliderEnabled"] as? Bool ?? true
    exposureResetEnabled = arguments["exposureResetEnabled"] as? Bool ?? true
    lowLightWarningEnabled = arguments["lowLightWarningEnabled"] as? Bool ?? true
    glareWarningEnabled = arguments["glareWarningEnabled"] as? Bool ?? true
    motionBlurWarningEnabled = arguments["motionBlurWarningEnabled"] as? Bool ?? true
    shadowWarningEnabled = arguments["shadowWarningEnabled"] as? Bool ?? true
    tooFarTooCloseWarningEnabled = arguments["tooFarTooCloseWarningEnabled"] as? Bool ?? true
    receiptFullyVisibleWarningEnabled = arguments["receiptFullyVisibleWarningEnabled"] as? Bool ?? true
    textTooSmallWarningEnabled = arguments["textTooSmallWarningEnabled"] as? Bool ?? true
    autoExposureAssistEnabled = arguments["autoExposureAssistEnabled"] as? Bool ?? true
    perspectiveCorrectionEnabled = arguments["perspectiveCorrectionEnabled"] as? Bool ?? true
    manualCropAfterCapture = arguments["manualCropAfterCapture"] as? Bool ?? true
    autoCropSuggestionEnabled = arguments["autoCropSuggestionEnabled"] as? Bool ?? true
    grayscalePreviewEnabled = arguments["grayscalePreviewEnabled"] as? Bool ?? true
    contrastBoostEnabled = arguments["contrastBoostEnabled"] as? Bool ?? true
    sharpeningEnabled = arguments["sharpeningEnabled"] as? Bool ?? true
    shadowReductionEnabled = arguments["shadowReductionEnabled"] as? Bool ?? true
    adaptiveThresholdEnabled = arguments["adaptiveThresholdEnabled"] as? Bool ?? true
    orientationCorrectionEnabled = arguments["orientationCorrectionEnabled"] as? Bool ?? true
    if let gap = arguments["analysisGapMs"] as? Double {
      analysisGapMs = min(max(gap, 250), 2500)
    } else if let gap = arguments["analysisGapMs"] as? Int {
      analysisGapMs = Double(min(max(gap, 250), 2500))
    }
    if let sectionLimit = arguments["maxSectionCount"] as? Int {
      maxSectionCount = min(max(sectionLimit, 1), 24)
    }
    if let path = arguments["previousSectionGuidePhotoPath"] as? String,
       !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      previousSectionGuidePhotoPath = path
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sessionQueue.async { [weak self] in
      guard let self, !self.session.isRunning else { return }
      self.session.startRunning()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.session.stopRunning()
    }
    super.viewWillDisappear(animated)
  }

  private func buildLayout() {
    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    view.layer.addSublayer(preview)
    previewLayer = preview
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndMeter(_:)))
    tapGesture.isEnabled = tapFocusEnabled
    view.addGestureRecognizer(tapGesture)
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomPreview(_:)))
    pinchGesture.isEnabled = pinchZoomEnabled
    view.addGestureRecognizer(pinchGesture)

    receiptFrameGuide.translatesAutoresizingMaskIntoConstraints = false
    receiptFrameGuide.isUserInteractionEnabled = false
    receiptFrameGuide.layer.borderWidth = 2
    receiptFrameGuide.layer.borderColor = UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.76).cgColor
    receiptFrameGuide.layer.cornerRadius = 14
    receiptFrameGuide.isHidden = !(edgeDetectionEnabled && edgeOverlayEnabled)
    view.addSubview(receiptFrameGuide)

    let topBar = UIStackView()
    topBar.axis = .horizontal
    topBar.alignment = .center
    topBar.spacing = 8
    topBar.translatesAutoresizingMaskIntoConstraints = false

    let backButton = iconButton(title: "Back", symbol: "chevron.left")
    backButton.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
    let settingsButton = iconButton(title: "Receipt camera settings", symbol: "slider.horizontal.3")
    settingsButton.addTarget(self, action: #selector(showSettingsPlaceholder), for: .touchUpInside)
    torchButton.setTitle("", for: .normal)
    torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
    torchButton.tintColor = .white
    torchButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    torchButton.layer.cornerRadius = 8
    torchButton.accessibilityLabel = "Turn light on"
    torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
    doneButton.setTitle("Done", for: .normal)
    doneButton.setTitleColor(.white, for: .normal)
    doneButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    doneButton.layer.cornerRadius = 8
    doneButton.accessibilityLabel = "Finish receipt photos"
    doneButton.isEnabled = false
    doneButton.isHidden = !longReceiptMode
    doneButton.addTarget(self, action: #selector(finishWithCapturedPhotos), for: .touchUpInside)

    let spacer = UIView()
    topBar.addArrangedSubview(backButton)
    topBar.addArrangedSubview(spacer)
    topBar.addArrangedSubview(doneButton)
    topBar.addArrangedSubview(settingsButton)
    topBar.addArrangedSubview(torchButton)
    view.addSubview(topBar)

    guidanceLabel.text = guidanceText()
    guidanceLabel.textColor = .white
    guidanceLabel.font = .boldSystemFont(ofSize: 15)
    guidanceLabel.numberOfLines = 2
    guidanceLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.84)
    guidanceLabel.layer.cornerRadius = 8
    guidanceLabel.layer.masksToBounds = true
    guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(guidanceLabel)
    let previousSectionGuide = buildPreviousSectionGuide()
    view.addSubview(previousSectionGuide)
    view.addSubview(buildExposureControls())

    let bottomBar = UIStackView()
    bottomBar.axis = .horizontal
    bottomBar.alignment = .center
    bottomBar.distribution = .fill
    bottomBar.spacing = 14
    bottomBar.backgroundColor = UIColor(white: 0.02, alpha: 0.84)
    bottomBar.layoutMargins = UIEdgeInsets(top: 14, left: 12, bottom: 16, right: 12)
    bottomBar.isLayoutMarginsRelativeArrangement = true
    bottomBar.translatesAutoresizingMaskIntoConstraints = false

    shutterButton.setTitle("", for: .normal)
    shutterButton.setImage(UIImage(systemName: "doc.text.viewfinder"), for: .normal)
    shutterButton.tintColor = .black
    shutterButton.backgroundColor = .white
    shutterButton.layer.cornerRadius = 39
    shutterButton.accessibilityLabel = "Take receipt photo"
    shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

    bottomBar.addArrangedSubview(modeLabel("Assisted receipt", "Review before saving"))
    bottomBar.addArrangedSubview(shutterButton)
    bottomBar.addArrangedSubview(modeLabel(dataSaverLabel(), storageSafetyDetail()))
    view.addSubview(bottomBar)

    NSLayoutConstraint.activate([
      topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      backButton.widthAnchor.constraint(equalToConstant: 52),
      backButton.heightAnchor.constraint(equalToConstant: 52),
      settingsButton.widthAnchor.constraint(equalToConstant: 52),
      settingsButton.heightAnchor.constraint(equalToConstant: 52),
      doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
      doneButton.heightAnchor.constraint(equalToConstant: 52),
      torchButton.widthAnchor.constraint(equalToConstant: 52),
      torchButton.heightAnchor.constraint(equalToConstant: 52),

      receiptFrameGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 146),
      receiptFrameGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
      receiptFrameGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
      receiptFrameGuide.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -82),

      guidanceLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 14),
      guidanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      guidanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      exposureSlider.superview!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      exposureSlider.superview!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      exposureSlider.superview!.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
      exposureSlider.superview!.heightAnchor.constraint(equalToConstant: 58),

      bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bottomBar.heightAnchor.constraint(equalToConstant: 132),
      shutterButton.widthAnchor.constraint(equalToConstant: 78),
      shutterButton.heightAnchor.constraint(equalToConstant: 78)
    ])
    NSLayoutConstraint.activate([
      previousSectionGuide.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 10),
      previousSectionGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      previousSectionGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      previousSectionGuide.heightAnchor.constraint(equalToConstant: 116)
    ])
  }

  private func buildPreviousSectionGuide() -> UIView {
    previousSectionGuidePanel.axis = .vertical
    previousSectionGuidePanel.spacing = 4
    previousSectionGuidePanel.backgroundColor = UIColor(white: 0.02, alpha: 0.74)
    previousSectionGuidePanel.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    previousSectionGuidePanel.isLayoutMarginsRelativeArrangement = true
    previousSectionGuidePanel.translatesAutoresizingMaskIntoConstraints = false
    previousSectionGuidePanel.isHidden = true

    let title = UILabel()
    title.text = "Line up the next section"
    title.textColor = .white
    title.font = .boldSystemFont(ofSize: 12)
    previousSectionGuidePanel.addArrangedSubview(title)

    previousSectionGuideImageView.contentMode = .scaleAspectFill
    previousSectionGuideImageView.alpha = 0.58
    previousSectionGuideImageView.clipsToBounds = true
    previousSectionGuideImageView.accessibilityLabel = "Previous receipt section overlap guide"
    previousSectionGuidePanel.addArrangedSubview(previousSectionGuideImageView)

    let detail = UILabel()
    detail.text = "Repeat 3-5 readable lines near the top of this photo."
    detail.textColor = UIColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 1)
    detail.textAlignment = .center
    detail.font = .boldSystemFont(ofSize: 11)
    previousSectionGuidePanel.addArrangedSubview(detail)
    updatePreviousSectionGuide(previousSectionGuidePhotoPath)
    return previousSectionGuidePanel
  }

  private func updatePreviousSectionGuide(_ path: String?) {
    guard
      let path,
      !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      FileManager.default.fileExists(atPath: path),
      let image = UIImage(contentsOfFile: path)
    else {
      previousSectionGuidePanel.isHidden = true
      return
    }
    previousSectionGuideImageView.image = image
    previousSectionGuidePanel.isHidden = false
  }

  private func buildExposureControls() -> UIView {
    let panel = UIStackView()
    panel.axis = .horizontal
    panel.alignment = .center
    panel.spacing = 10
    panel.backgroundColor = UIColor(white: 0.02, alpha: 0.76)
    panel.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    panel.isLayoutMarginsRelativeArrangement = true
    panel.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = "Brightness"
    label.textColor = .white
    label.font = .boldSystemFont(ofSize: 12)
    panel.addArrangedSubview(label)

    exposureSlider.minimumValue = -1
    exposureSlider.maximumValue = 1
    exposureSlider.value = 0
    exposureSlider.isEnabled = false
    exposureSlider.addTarget(self, action: #selector(exposureChanged(_:)), for: .valueChanged)
    panel.addArrangedSubview(exposureSlider)

    exposureResetButton.setTitle("Reset", for: .normal)
    exposureResetButton.setTitleColor(.white, for: .normal)
    exposureResetButton.isEnabled = false
    exposureResetButton.addTarget(self, action: #selector(resetExposure), for: .touchUpInside)
    panel.addArrangedSubview(exposureResetButton)
    return panel
  }

  private func configureSession() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
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
      self.session.addInput(input)
      self.photoOutput.isHighResolutionCaptureEnabled = true
      if #available(iOS 13.0, *) {
        self.photoOutput.maxPhotoQualityPrioritization = .quality
      }
      self.session.addOutput(self.photoOutput)
      self.configureVideoAnalysisIfNeeded()
      self.session.commitConfiguration()
      DispatchQueue.main.async {
        self.torchButton.isEnabled = device.hasTorch
        self.configureExposureControls(for: device)
      }
    }
  }

  private func configureVideoAnalysisIfNeeded() {
    guard
      liveAnalysisEnabled,
      lowLightWarningEnabled ||
        glareWarningEnabled ||
        motionBlurWarningEnabled ||
        shadowWarningEnabled ||
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

  private func configureExposureControls(for device: AVCaptureDevice) {
    exposureSlider.minimumValue = device.minExposureTargetBias
    exposureSlider.maximumValue = device.maxExposureTargetBias
    exposureSlider.value = device.exposureTargetBias
    let exposureAvailable = device.minExposureTargetBias < device.maxExposureTargetBias
    exposureSlider.isEnabled = exposureSliderEnabled && exposureAvailable
    exposureSlider.alpha = exposureSlider.isEnabled ? 1 : 0.45
    exposureResetButton.isEnabled = exposureResetEnabled && exposureAvailable
    exposureResetButton.alpha = exposureResetButton.isEnabled ? 1 : 0.45
  }

  @objc private func cancelCapture() {
    if closeResultDelivered {
      closeRetryCount += 1
      if presentingViewController != nil {
        dismiss(animated: true)
      }
      return
    }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if captureInFlight {
      pendingCloseAfterCapture = true
      shutterButton.isEnabled = false
      doneButton.isEnabled = false
      guidanceLabel.text = "Finishing this receipt photo before closing."
      return
    }
    if !capturedPhotoPaths.isEmpty {
      finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")
      return
    }
    closeAction = "back_no_photo_cancel"
    closeResultDelivered = true
    dismiss(animated: true) { [weak self] in
      self?.onCancel?()
    }
  }

  @objc private func showSettingsPlaceholder() {
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
    })
    alert.addAction(UIAlertAction(
      title: longReceiptMode ? "Turn long receipt mode off" : "Turn long receipt mode on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.longReceiptMode.toggle()
      self.guidanceLabel.text = self.guidanceText()
      self.updateDoneButton()
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
        return
      }
      self.autoCaptureEnabled.toggle()
      self.guidanceLabel.text = self.autoCaptureEnabled
        ? "Automatic capture is on. Hold steady, or tap the shutter anytime."
        : self.guidanceText()
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
    })
    alert.addAction(UIAlertAction(
      title: receiptGuidanceWarningsEnabled()
        ? "Turn receipt guidance warnings off"
        : "Turn receipt guidance warnings on",
      style: .default
    ) { [weak self] _ in
      guard let self else { return }
      self.setReceiptGuidanceWarningsEnabled(!self.receiptGuidanceWarningsEnabled())
      self.guidanceLabel.text = self.receiptGuidanceWarningsEnabled()
        ? "Receipt guidance warnings are on."
        : "Receipt guidance warnings are off. Manual shutter still works."
    })
    alert.addAction(UIAlertAction(title: "Reset brightness", style: .default) { [weak self] _ in
      self?.resetExposure()
    })
    alert.addAction(UIAlertAction(title: "Done", style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = torchButton
      popover.sourceRect = torchButton.bounds
    }
    present(alert, animated: true)
  }

  @objc private func toggleTorch() {
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

  @objc private func focusAndMeter(_ recognizer: UITapGestureRecognizer) {
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
    let shouldLockWhiteBalance = whiteBalanceMode == "locked"
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

  private func lockFocusAndExposureIfSupported(
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

  @objc private func zoomPreview(_ recognizer: UIPinchGestureRecognizer) {
    guard pinchZoomEnabled else { return }
    guard let cameraDevice else { return }
    if recognizer.state == .began {
      lastZoomFactor = cameraDevice.videoZoomFactor
    }
    let maximumZoom = min(cameraDevice.maxAvailableVideoZoomFactor, 10)
    let nextZoom = min(max(lastZoomFactor * recognizer.scale, 1), maximumZoom)
    do {
      try cameraDevice.lockForConfiguration()
      cameraDevice.videoZoomFactor = nextZoom
      cameraDevice.unlockForConfiguration()
      zoomChangeCount += 1
      suppressTapFocusUntil = Date().addingTimeInterval(0.35)
      guidanceLabel.text = String(format: "Zoom %.1fx", nextZoom)
    } catch {
      guidanceLabel.text = "Zoom could not be adjusted right now."
    }
  }

  @objc private func exposureChanged(_ slider: UISlider) {
    guard exposureSliderEnabled else { return }
    guard let cameraDevice else { return }
    userExposureOverride = true
    manualExposureChangeCount += 1
    setExposureBias(slider.value, message: String(format: "Brightness %.1f", slider.value))
  }

  @objc private func resetExposure() {
    guard exposureResetEnabled else { return }
    exposureSlider.value = 0
    userExposureOverride = false
    manualExposureChangeCount += 1
    setExposureBias(0, message: "Brightness reset.")
  }

  private func setExposureBias(_ bias: Float, message: String) {
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

  @objc private func capturePhoto() {
    guard !captureInFlight, !closingCamera, !isBeingDismissed else { return }
    captureInFlight = true
    shutterButton.isEnabled = false
    let settings = AVCapturePhotoSettings()
    settings.isHighResolutionPhotoEnabled = true
    if #available(iOS 13.0, *) {
      settings.photoQualityPrioritization = .quality
    }
    if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
      settings.embeddedThumbnailPhotoFormat = [
        AVVideoCodecKey: AVVideoCodecType.jpeg
      ]
    }
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if error != nil {
      captureInFlight = false
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      captureInFlight = false
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
      return
    }
    do {
      let url = try newReceiptCaptureUrl()
      try data.write(to: url, options: .atomic)
      let capturedAt = ISO8601DateFormatter().string(from: Date())
      if firstCapturedAt == nil {
        firstCapturedAt = capturedAt
      }
      capturedPhotoPaths.append(url.path)
      totalCapturedByteSize += data.count
      recordCapturedPhotoQuality(data: data)
      autoCaptureCooldownUntilMs = Date().timeIntervalSince1970 * 1000 + 2600
      if pendingCloseAfterCapture {
        pendingCloseAfterCapture = false
        captureInFlight = false
        finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")
        return
      }
      if longReceiptMode && capturedPhotoPaths.count < maxSectionCount {
        captureInFlight = false
        shutterButton.isEnabled = true
        updateDoneButton()
        updatePreviousSectionGuide(url.path)
        guidanceLabel.text =
          "Section \(capturedPhotoPaths.count) saved. Add the next section, or tap Done."
      } else {
        finishWithCapturedPhotos()
      }
    } catch {
      captureInFlight = false
      pendingCloseAfterCapture = false
      shutterButton.isEnabled = true
      guidanceLabel.text = "That photo did not save. Try again."
    }
  }

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
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
      guard let self else { return }
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

  private func sampleLiveLumaGrid(_ pixelBuffer: CVPixelBuffer) -> [Int] {
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

  private func evaluateLiveMotion(_ samples: [Int]) -> Double {
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

  private func estimateShadowScore(_ samples: [Int]) -> Double {
    guard let minSample = samples.min(), let maxSample = samples.max() else {
      return -1
    }
    return Double(maxSample - minSample)
  }

  private func averageLuma(_ pixelBuffer: CVPixelBuffer) -> Double {
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

  private func estimateReceiptFraming(_ pixelBuffer: CVPixelBuffer) -> LiveReceiptFraming {
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

  private func applyLiveFraming(_ framing: LiveReceiptFraming) {
    latestFramingConfidence = framing.confidenceBucket
    latestEdgeCoverage = framing.edgeCoverage
    latestPerspectiveReadiness = perspectiveReadiness(for: framing)
    if !framing.found {
      latestFramingSignal = "receipt_not_found"
      setFrameGuideColor(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.76))
      if receiptFullyVisibleWarningEnabled {
        guidanceLabel.text = "Place the receipt inside the frame. Manual capture still works."
      }
      return
    }
    if framing.widthRatio < 0.42 || framing.heightRatio < 0.36 {
      latestFramingSignal = "move_closer"
      setFrameGuideColor(UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.84))
      if textTooSmallWarningEnabled || tooFarTooCloseWarningEnabled {
        guidanceLabel.text = "Move closer until receipt text fills the guide."
      }
      return
    }
    if framing.touchesEdge {
      latestFramingSignal = "possibly_cut_off"
      setFrameGuideColor(UIColor(red: 1, green: 0.69, blue: 0.13, alpha: 0.88))
      if receiptFullyVisibleWarningEnabled {
        guidanceLabel.text = "Full receipt may be cut off. Leave a little paper edge visible."
      }
      return
    }
    latestFramingSignal = "framing_ok"
    setFrameGuideColor(UIColor(red: 0.56, green: 0.96, blue: 0.64, alpha: 0.82))
    if receiptFullyVisibleWarningEnabled {
      guidanceLabel.text = framingGuidanceCopy(framing.confidenceBucket)
    }
  }

  private func perspectiveReadiness(for framing: LiveReceiptFraming) -> String {
    if !perspectiveCorrectionEnabled {
      return "perspective_skipped_setting_off"
    }
    if !edgeDetectionEnabled {
      return "perspective_skipped_edge_detection_off"
    }
    if !framing.found {
      return "perspective_skipped_no_receipt_bounds"
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

  private func framingGuidanceCopy(_ confidenceBucket: String) -> String {
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

  private func framingConfidenceBucket(_ score: Double) -> String {
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

  private func setFrameGuideColor(_ color: UIColor) {
    receiptFrameGuide.layer.borderColor = color.cgColor
  }

  private func applyLiveReadability(
    _ brightness: Double,
    framing: LiveReceiptFraming,
    motionScore: Double,
    shadowScore: Double,
    nowMs: Double
  ) {
    latestFrameBrightness = brightness
    autoAdjustExposureForLiveFrame(
      brightness: brightness,
      nowMs: nowMs,
      framing: framing
    )
    let currentGuidance = guidanceLabel.text ?? ""
    if motionBlurWarningEnabled && motionScore > 22 {
      latestMotionSignal = "moving_too_much"
      guidanceLabel.text = "Hold steady so the receipt text stays sharp."
    } else if lowLightWarningEnabled && brightness >= 0 && brightness <= 58 {
      latestReadabilitySignal = "low_light"
      guidanceLabel.text = "Receipt looks dark. Add light or raise Brightness."
    } else if glareWarningEnabled && brightness >= 246 {
      latestReadabilitySignal = "glare_or_overbright"
      guidanceLabel.text = "Receipt is very bright. Tilt it or lower Brightness."
    } else if shadowWarningEnabled && shadowScore >= 150 {
      latestReadabilitySignal = "shadow_risk"
      guidanceLabel.text = "Receipt has heavy shadows. Move it into even light."
    } else {
      latestMotionSignal = motionScore >= 0 ? "steady" : "unknown"
      latestReadabilitySignal = "lighting_ok"
      if currentGuidance.hasPrefix("Receipt looks dark") ||
          currentGuidance.hasPrefix("Receipt is very bright") ||
          currentGuidance.hasPrefix("Hold steady") {
        guidanceLabel.text = guidanceText()
      }
    }
  }

  private func autoAdjustExposureForLiveFrame(
    brightness: Double,
    nowMs: Double,
    framing: LiveReceiptFraming
  ) {
    lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
    guard brightness >= 0 else {
      lastAutoExposureDecision = "brightness_unknown"
      resetAutoExposureCandidate()
      return
    }
    guard edgeDetectionEnabled, framing.found else {
      if brightness <= 58 {
        guard stableAutoExposureCandidate("fallback_brighten", requiredFrames: 4) else { return }
        autoAdjustExposureForLiveFrame(
          brighten: true,
          strongCorrection: true,
          nowMs: nowMs
        )
      } else if brightness >= 246 {
        guard stableAutoExposureCandidate("fallback_dim", requiredFrames: 4) else { return }
        autoAdjustExposureForLiveFrame(
          brighten: false,
          strongCorrection: true,
          nowMs: nowMs
        )
      } else {
        lastAutoExposureDecision = "waiting_for_receipt_target"
        resetAutoExposureCandidate()
      }
      return
    }
    if brightness <= 96 {
      guard stableAutoExposureCandidate("brighten") else { return }
      autoAdjustExposureForLiveFrame(
        brighten: true,
        strongCorrection: brightness <= 58,
        nowMs: nowMs
      )
    } else if brightness >= 246 {
      guard stableAutoExposureCandidate("dim") else { return }
      autoAdjustExposureForLiveFrame(
        brighten: false,
        strongCorrection: brightness >= 252,
        nowMs: nowMs
      )
    } else {
      lastAutoExposureDecision = "lighting_ok"
      resetAutoExposureCandidate()
    }
  }

  private func stableAutoExposureCandidate(
    _ candidate: String,
    requiredFrames: Int = 2
  ) -> Bool {
    if lastAutoExposureCandidate == candidate {
      autoExposureCandidateFrameCount += 1
    } else {
      lastAutoExposureCandidate = candidate
      autoExposureCandidateFrameCount = 1
    }
    guard autoExposureCandidateFrameCount >= requiredFrames else {
      lastAutoExposureDecision = "stabilizing_\(candidate)"
      return false
    }
    return true
  }

  private func resetAutoExposureCandidate() {
    lastAutoExposureCandidate = "none"
    autoExposureCandidateFrameCount = 0
  }

  private func maybeAutoCapture(
    framing: LiveReceiptFraming,
    brightness: Double,
    motionScore: Double,
    nowMs: Double
  ) {
    guard autoCaptureEnabled else {
      autoCaptureStableFrameCount = 0
      latestAutoCaptureStatus = "off"
      return
    }
    if closingCamera || isBeingDismissed {
      autoCaptureStableFrameCount = 0
      latestAutoCaptureStatus = "closing"
      return
    }
    if captureInFlight || nowMs < autoCaptureCooldownUntilMs {
      latestAutoCaptureStatus = "cooling_down"
      return
    }
    let edgesReady =
      framing.found &&
      !framing.touchesEdge &&
      (framing.confidenceBucket == "strong_edges" ||
        framing.confidenceBucket == "usable_edges")
    let steady = motionScore >= 0 && motionScore <= 7.5
    let lightReady = brightness >= 68 && brightness <= 245
    guard edgesReady, steady, lightReady else {
      autoCaptureStableFrameCount = 0
      if !edgesReady {
        latestAutoCaptureStatus = "waiting_for_edges"
      } else if !steady {
        latestAutoCaptureStatus = "waiting_for_steady"
      } else if !lightReady {
        latestAutoCaptureStatus = "waiting_for_light"
      } else {
        latestAutoCaptureStatus = "waiting"
      }
      return
    }
    autoCaptureStableFrameCount += 1
    latestAutoCaptureStatus = "ready_\(autoCaptureStableFrameCount)_of_3"
    guard autoCaptureStableFrameCount >= 3 else { return }
    autoCaptureStableFrameCount = 0
    autoCaptureTriggerCount += 1
    autoCaptureCooldownUntilMs = nowMs + 2600
    latestAutoCaptureStatus = "capturing"
    guidanceLabel.text = "Receipt looks steady. Taking photo."
    capturePhoto()
  }

  private func autoAdjustExposureForLiveFrame(
    brighten: Bool,
    strongCorrection: Bool,
    nowMs: Double
  ) {
    guard autoExposureAssistEnabled else {
      lastAutoExposureDecision = "off"
      return
    }
    guard !userExposureOverride else {
      lastAutoExposureDecision = "manual_override"
      return
    }
    guard nowMs - lastAutoExposureAdjustmentAt >= 900 else {
      lastAutoExposureDecision = "cooling_down"
      return
    }
    guard let cameraDevice else {
      lastAutoExposureDecision = "camera_unavailable"
      return
    }
    guard cameraDevice.minExposureTargetBias < cameraDevice.maxExposureTargetBias else {
      lastAutoExposureDecision = "not_supported"
      return
    }
    let current = cameraDevice.exposureTargetBias
    lastAutoExposureBias = current
    let step: Float = strongCorrection ? 0.50 : 0.25
    let target = brighten
      ? min(current + step, cameraDevice.maxExposureTargetBias)
      : max(current - step, cameraDevice.minExposureTargetBias)
    guard abs(target - current) >= 0.01 else {
      lastAutoExposureDecision = brighten ? "already_at_brightest" : "already_at_dimmest"
      return
    }
    exposureSlider.value = target
    setExposureBias(target, message: brighten ? "Brightness assisted." : "Glare reduced.")
    autoExposureAdjustmentCount += 1
    lastAutoExposureAdjustmentAt = nowMs
    lastAutoExposureBias = target
    resetAutoExposureCandidate()
    lastAutoExposureDecision = brighten
      ? (strongCorrection ? "brightened_strong" : "brightened")
      : (strongCorrection ? "dimmed_strong" : "dimmed")
  }

  private func brightnessBucket(_ brightness: Double) -> String {
    if brightness < 0 {
      return "unknown"
    }
    if brightness <= 58 {
      return "too_dark_warning"
    }
    if brightness <= 96 {
      return "dark_assisted"
    }
    if brightness >= 246 {
      return "glare_warning"
    }
    if brightness >= 232 {
      return "bright_receipt_ok"
    }
    return "lighting_ok"
  }

  private func exposureAssistStatus() -> String {
    guard let device = cameraDevice else {
      return "camera_unavailable"
    }
    if device.minExposureTargetBias == device.maxExposureTargetBias {
      return "not_supported"
    }
    if userExposureOverride {
      return "manual_override"
    }
    if !autoExposureAssistEnabled {
      return "off"
    }
    if autoExposureAdjustmentCount > 0 {
      return "auto_adjusted"
    }
    return "ready"
  }

  @objc private func finishWithCapturedPhotos(closeReason: String = "done_returned_captured_sections") {
    guard !closeResultDelivered else { return }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    guard !capturedPhotoPaths.isEmpty else {
      closeAction = "done_no_photo_cancel"
      closeResultDelivered = true
      dismiss(animated: true) { [weak self] in
        self?.onCancel?()
      }
      return
    }
    closeAction = closeReason
    closeResultDelivered = true
    let capturedAt = firstCapturedAt ?? ISO8601DateFormatter().string(from: Date())
    let diagnostics = nativeCaptureDiagnostics(
      photoByteSize: totalCapturedByteSize,
      capturedAt: capturedAt
    )
    dismiss(animated: true) { [weak self] in
      guard let self else { return }
      self.onCapture?(self.capturedPhotoPaths, capturedAt, diagnostics)
    }
  }

  private func updateDoneButton() {
    doneButton.isHidden = !longReceiptMode
    doneButton.isEnabled = !capturedPhotoPaths.isEmpty
    let title = capturedPhotoPaths.isEmpty
      ? "Done"
      : "Done (\(capturedPhotoPaths.count))"
    doneButton.setTitle(title, for: .normal)
  }

  private func newReceiptCaptureUrl() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("receipt_camera", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("receipt_\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
  }

  private func recordCapturedPhotoQuality(data: Data) {
    latestCapturedByteBucket = byteSizeBucket(data.count)
    guard let image = UIImage(data: data) else {
      latestCapturedPhotoWidth = 0
      latestCapturedPhotoHeight = 0
      latestCapturedMegapixelBucket = "unknown"
      return
    }
    latestCapturedPhotoWidth = Int(image.size.width * image.scale)
    latestCapturedPhotoHeight = Int(image.size.height * image.scale)
    latestCapturedMegapixelBucket = megapixelBucket(
      width: latestCapturedPhotoWidth,
      height: latestCapturedPhotoHeight
    )
    let sample = sampleCapturedImageQuality(image)
    latestCapturedBrightnessBucket = capturedBrightnessBucket(sample.averageLuma)
    latestCapturedSharpnessBucket = capturedSharpnessBucket(sample.edgeScore)
    latestCapturedQualitySignal = capturedQualitySignal(
      brightnessBucket: latestCapturedBrightnessBucket,
      sharpnessBucket: latestCapturedSharpnessBucket
    )
    latestCapturedExposureMismatch = capturedExposureMismatch(
      liveBrightness: latestFrameBrightness,
      capturedBrightnessBucket: latestCapturedBrightnessBucket
    )
  }

  private struct CapturedPhotoQualitySample {
    let averageLuma: Double
    let edgeScore: Double
  }

  private func sampleCapturedImageQuality(_ image: UIImage) -> CapturedPhotoQualitySample {
    guard let cgImage = image.cgImage else {
      return CapturedPhotoQualitySample(averageLuma: -1, edgeScore: -1)
    }
    let sampleWidth = max(2, min(96, cgImage.width))
    let sampleHeight = max(2, min(128, cgImage.height))
    let bytesPerPixel = 4
    let bytesPerRow = sampleWidth * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var rendered = false
    pixels.withUnsafeMutableBytes { buffer in
      guard let baseAddress = buffer.baseAddress,
            let context = CGContext(
              data: baseAddress,
              width: sampleWidth,
              height: sampleHeight,
              bitsPerComponent: 8,
              bytesPerRow: bytesPerRow,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
        return
      }
      context.interpolationQuality = .low
      context.draw(
        cgImage,
        in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
      )
      rendered = true
    }
    if !rendered {
      return CapturedPhotoQualitySample(averageLuma: -1, edgeScore: -1)
    }
    var lumaTotal = 0.0
    var edgeTotal = 0.0
    var edgeCount = 0
    var previousRow = [Double](repeating: -1, count: sampleWidth)
    for y in 0..<sampleHeight {
      var previousLuma = -1.0
      for x in 0..<sampleWidth {
        let index = (y * bytesPerRow) + (x * bytesPerPixel)
        let luma = (Double(pixels[index]) * 0.299) +
          (Double(pixels[index + 1]) * 0.587) +
          (Double(pixels[index + 2]) * 0.114)
        lumaTotal += luma
        if previousLuma >= 0 {
          edgeTotal += abs(luma - previousLuma)
          edgeCount += 1
        }
        if previousRow[x] >= 0 {
          edgeTotal += abs(luma - previousRow[x])
          edgeCount += 1
        }
        previousRow[x] = luma
        previousLuma = luma
      }
    }
    let pixelCount = Double(sampleWidth * sampleHeight)
    return CapturedPhotoQualitySample(
      averageLuma: pixelCount <= 0 ? -1 : lumaTotal / pixelCount,
      edgeScore: edgeCount <= 0 ? -1 : edgeTotal / Double(edgeCount)
    )
  }

  private func capturedBrightnessBucket(_ luma: Double) -> String {
    if luma < 0 { return "unknown" }
    if luma < 70 { return "captured_too_dark" }
    if luma < 105 { return "captured_dim" }
    if luma < 205 { return "captured_readable" }
    if luma < 246 { return "captured_bright" }
    return "captured_glare_risk"
  }

  private func capturedSharpnessBucket(_ edgeScore: Double) -> String {
    if edgeScore < 0 { return "unknown" }
    if edgeScore < 5.5 { return "captured_soft_blur_risk" }
    if edgeScore < 10 { return "captured_usable_soft" }
    if edgeScore < 24 { return "captured_sharp" }
    return "captured_high_contrast_edges"
  }

  private func capturedQualitySignal(
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

  private func capturedExposureMismatch(
    liveBrightness: Double,
    capturedBrightnessBucket: String
  ) -> String {
    if liveBrightness < 0 || capturedBrightnessBucket == "unknown" { return "unknown" }
    let liveBucket = brightnessBucket(liveBrightness)
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

  private func byteSizeBucket(_ bytes: Int) -> String {
    if bytes <= 0 { return "unknown" }
    if bytes < 350_000 { return "tiny_under_350kb" }
    if bytes < 1_000_000 { return "small_under_1mb" }
    if bytes < 3_000_000 { return "normal_1mb_to_3mb" }
    if bytes < 8_000_000 { return "large_3mb_to_8mb" }
    return "very_large_over_8mb"
  }

  private func megapixelBucket(width: Int, height: Int) -> String {
    if width <= 0 || height <= 0 { return "unknown" }
    let megapixels = Double(width * height) / 1_000_000.0
    if megapixels < 4.0 { return "low_under_4mp" }
    if megapixels < 9.0 { return "medium_4mp_to_9mp" }
    if megapixels < 18.0 { return "high_9mp_to_18mp" }
    if megapixels < 40.0 { return "very_high_18mp_to_40mp" }
    return "extreme_over_40mp"
  }

  private func iconButton(title: String, symbol: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle("", for: .normal)
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    button.layer.cornerRadius = 8
    button.accessibilityLabel = title
    return button
  }

  private func modeLabel(_ title: String, _ detail: String) -> UILabel {
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

  private func guidanceText() -> String {
    if longReceiptMode {
      return "Fill the screen with readable receipt text. Use more photos for long receipts."
    }
    if autoCaptureEnabled {
      return "Hold steady. Manual capture is always available."
    }
    return "Fill the screen with readable receipt text, then tap the shutter."
  }

  private func dataSaverLabel() -> String {
    switch storageSafetyLevel {
    case "original":
      return "Local original"
    case "light":
      return "High quality"
    case "strong":
      return "Low storage"
    case "maximum":
      return "Tiny backup"
    default:
      return "Normal backup"
    }
  }

  private func storageSafetyDetail() -> String {
    if storageConstrained {
      return "Keeps long receipts lighter"
    }
    return "OCR uses clear source first"
  }

  private func nativeCaptureDiagnostics(
    photoByteSize: Int,
    capturedAt: String
  ) -> [String: Any] {
    let device = cameraDevice
    return [
      "engine": "avFoundation",
      "captureSurface": "maintainiac_native_ios",
      "captureMode": "manual",
      "captureQualityMode": "quality",
      "capturedAt": capturedAt,
      "photoByteSize": photoByteSize,
      "photoByteSizeBucket": byteSizeBucket(photoByteSize),
      "latestCapturedPhotoWidth": latestCapturedPhotoWidth,
      "latestCapturedPhotoHeight": latestCapturedPhotoHeight,
      "latestCapturedMegapixelBucket": latestCapturedMegapixelBucket,
      "latestCapturedByteBucket": latestCapturedByteBucket,
      "latestCapturedBrightnessBucket": latestCapturedBrightnessBucket,
      "latestCapturedSharpnessBucket": latestCapturedSharpnessBucket,
      "latestCapturedQualitySignal": latestCapturedQualitySignal,
      "latestCapturedExposureMismatch": latestCapturedExposureMismatch,
      "photoCount": capturedPhotoPaths.count,
      "maxSectionCount": maxSectionCount,
      "liveAnalysisEnabled": liveAnalysisEnabled,
      "autoExposureAssistEnabled": autoExposureAssistEnabled,
      "edgeDetectionEnabled": edgeDetectionEnabled,
      "edgeOverlayEnabled": edgeOverlayEnabled,
      "shadowWarningEnabled": shadowWarningEnabled,
      "textTooSmallWarningEnabled": textTooSmallWarningEnabled,
      "perspectiveCorrectionEnabled": perspectiveCorrectionEnabled,
      "manualCropAfterCapture": manualCropAfterCapture,
      "autoCropSuggestionEnabled": autoCropSuggestionEnabled,
      "grayscalePreviewEnabled": grayscalePreviewEnabled,
      "contrastBoostEnabled": contrastBoostEnabled,
      "sharpeningEnabled": sharpeningEnabled,
      "shadowReductionEnabled": shadowReductionEnabled,
      "adaptiveThresholdEnabled": adaptiveThresholdEnabled,
      "orientationCorrectionEnabled": orientationCorrectionEnabled,
      "receiptGuidanceWarningsEnabled": receiptGuidanceWarningsEnabled(),
      "autoExposureAdjustmentCount": autoExposureAdjustmentCount,
      "lastAutoExposureDecision": lastAutoExposureDecision,
      "lastAutoExposureBrightnessBucket": lastAutoExposureBrightnessBucket,
      "lastAutoExposureCandidate": lastAutoExposureCandidate,
      "autoExposureCandidateFrameCount": autoExposureCandidateFrameCount,
      "lastAutoExposureBias": Double(lastAutoExposureBias),
      "tapFocusCount": tapFocusCount,
      "tapFocusSuppressedAfterZoomCount": tapFocusSuppressedAfterZoomCount,
      "zoomChangeCount": zoomChangeCount,
      "manualExposureChangeCount": manualExposureChangeCount,
      "lastFocusStatus": lastFocusStatus,
      "focusMode": focusMode,
      "exposureMode": exposureMode,
      "whiteBalanceMode": whiteBalanceMode,
      "focusLockAttemptCount": focusLockAttemptCount,
      "focusLockSuccessCount": focusLockSuccessCount,
      "exposureLockSuccessCount": exposureLockSuccessCount,
      "whiteBalanceLockAttemptCount": whiteBalanceLockAttemptCount,
      "whiteBalanceLockSuccessCount": whiteBalanceLockSuccessCount,
      "whiteBalanceLockStatus": whiteBalanceLockStatus,
      "autoCaptureStableFrameCount": autoCaptureStableFrameCount,
      "autoCaptureTriggerCount": autoCaptureTriggerCount,
      "latestAutoCaptureStatus": latestAutoCaptureStatus,
      "closeAction": closeAction,
      "closeRetryCount": closeRetryCount,
      "closingCamera": closingCamera,
      "pendingCloseAfterCapture": pendingCloseAfterCapture,
      "closeResultDelivered": closeResultDelivered,
      "exposureAssistStatus": exposureAssistStatus(),
      "userExposureOverride": userExposureOverride,
      "analysisGapMs": analysisGapMs,
      "latestFrameBrightness": latestFrameBrightness,
      "latestShadowScore": latestShadowScore,
      "latestBrightnessBucket": brightnessBucket(latestFrameBrightness),
      "latestReadabilitySignal": latestReadabilitySignal,
      "latestFramingSignal": latestFramingSignal,
      "latestFramingConfidence": latestFramingConfidence,
      "latestEdgeCoverage": latestEdgeCoverage,
      "latestPerspectiveReadiness": latestPerspectiveReadiness,
      "latestMotionSignal": latestMotionSignal,
      "latestMotionScore": latestMotionScore,
      "assistedReceiptFill": assistedReceiptFill,
      "longReceiptMode": longReceiptMode,
      "autoCaptureEnabled": autoCaptureEnabled,
      "autoCaptureAllowed": autoCaptureAllowed,
      "autoCaptureCurrentlyAllowed": isAutoCaptureCurrentlyAllowed(),
      "reviewDepth": reviewDepth,
      "dataSaverLevel": dataSaverLevel,
      "storageSafetyLevel": storageSafetyLevel,
      "storageConstrained": storageConstrained,
      "storageSafetyReason": storageSafetyReason,
      "hasPreviousSectionGuide": previousSectionGuidePhotoPath != nil,
      "torchOn": torchOn,
      "hasTorch": device?.hasTorch ?? false,
      "exposureTargetBias": Double(device?.exposureTargetBias ?? 0),
      "minExposureTargetBias": Double(device?.minExposureTargetBias ?? 0),
      "maxExposureTargetBias": Double(device?.maxExposureTargetBias ?? 0),
      "zoomRatio": Double(device?.videoZoomFactor ?? 1),
      "minZoomRatio": 1,
      "maxZoomRatio": Double(device?.maxAvailableVideoZoomFactor ?? 1),
      "tapFocusEnabled": tapFocusEnabled,
      "pinchZoomEnabled": pinchZoomEnabled,
      "exposureSliderEnabled": exposureSliderEnabled,
      "exposureResetEnabled": exposureResetEnabled,
      "manualShutterAlwaysAvailable": arguments["manualShutterAlwaysAvailable"] as? Bool ?? true,
      "ocrUsesOriginalFirst": true
    ]
  }

  private func settingsSummary() -> String {
    let review = reviewDepth == "detailedLines"
      ? "Detailed receipt lines"
      : "Price-only receipt lines"
    return """
    Assisted receipt fill: \(assistedReceiptFill ? "On" : "Off")
    Long receipt mode: \(longReceiptMode ? "On" : "Off")
    Automatic capture: \(autoCaptureEnabled ? "On" : "Off")
    \(autoCaptureDetail())
    Auto brightness assist: \(autoExposureAssistEnabled ? "On" : "Off")
    Receipt edge guidance: \(edgeDetectionEnabled ? "On" : "Off")
    Receipt guidance warnings: \(receiptGuidanceWarningsEnabled() ? "On" : "Off")
    Image cleanup: crop, straighten, grayscale, contrast, and shadow cleanup after capture.
    Review style: \(review)
    Save-space backup: \(dataSaverLabel())

    Tap receipt text to focus. Pinch to zoom. Use Brightness anytime.
    """
  }

  private func autoCaptureDetail() -> String {
    if isAutoCaptureCurrentlyAllowed() {
      return "Automatic capture waits for several steady, readable frames. Manual shutter always works."
    }
    if !edgeDetectionEnabled {
      return "Turn receipt edge guidance on before using automatic capture."
    }
    return "Manual capture is safest for this device or storage mode."
  }

  private func autoCaptureBlockedMessage() -> String {
    if !edgeDetectionEnabled {
      return "Receipt edge guidance is off, so automatic capture is held back. Tap the shutter when ready."
    }
    if storageConstrained {
      return "Storage is tight, so automatic capture is held back. Tap the shutter when ready."
    }
    return "Automatic capture is held back on this device. Tap the shutter when ready."
  }

  private func isAutoCaptureCurrentlyAllowed() -> Bool {
    return autoCaptureAllowed && edgeDetectionEnabled
  }

  private func receiptGuidanceWarningsEnabled() -> Bool {
    lowLightWarningEnabled ||
      glareWarningEnabled ||
      motionBlurWarningEnabled ||
      tooFarTooCloseWarningEnabled ||
      receiptFullyVisibleWarningEnabled
  }

  private func setReceiptGuidanceWarningsEnabled(_ enabled: Bool) {
    lowLightWarningEnabled = enabled
    glareWarningEnabled = enabled
    motionBlurWarningEnabled = enabled
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
  }
}

private struct LiveReceiptFraming {
  var found = false
  var widthRatio = 0.0
  var heightRatio = 0.0
  var edgeCoverage = 0.0
  var confidenceBucket = "unknown"
  var touchesEdge = false
}
