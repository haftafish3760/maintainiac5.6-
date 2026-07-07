import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    readSessionArguments()
    buildLayout()
    configureSession()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    cameraViewClosing = false
    sessionQueue.async { [weak self] in
      guard let self, self.isCameraSessionUsable, !self.session.isRunning else { return }
      self.session.startRunning()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    cameraViewClosing = true
    closingCamera = true
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.session.stopRunning()
    }
    super.viewWillDisappear(animated)
  }

  func buildLayout() {
    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    view.layer.addSublayer(preview)
    previewLayer = preview
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomPreview(_:)))
    pinchGesture.isEnabled = pinchZoomEnabled
    view.addGestureRecognizer(pinchGesture)

    receiptFrameGuide.translatesAutoresizingMaskIntoConstraints = false
    receiptFrameGuide.isUserInteractionEnabled = false
    receiptFrameGuide.layer.borderWidth = 2
    receiptFrameGuide.layer.borderColor = UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.56).cgColor
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
    let settingsButton = iconButton(title: "Receipt camera settings", symbol: "gearshape.fill")
    settingsButton.addTarget(self, action: #selector(showReceiptCameraSettings), for: .touchUpInside)
    torchButton.setTitle("", for: .normal)
    torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
    torchButton.tintColor = .white
    torchButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    torchButton.layer.cornerRadius = 8
    torchButton.accessibilityLabel = "Turn light on"
    torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)

    let spacer = UIView()
    topBar.addArrangedSubview(backButton)
    topBar.addArrangedSubview(spacer)
    topBar.addArrangedSubview(settingsButton)
    topBar.addArrangedSubview(torchButton)
    view.addSubview(topBar)

    guidanceLabel.text = guidanceText()
    guidanceLabel.textColor = .white
    guidanceLabel.font = .boldSystemFont(ofSize: 15)
    guidanceLabel.numberOfLines = 2
    guidanceLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.50)
    guidanceLabel.layer.cornerRadius = 8
    guidanceLabel.layer.masksToBounds = true
    guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(guidanceLabel)
    viewerInfoStack.axis = .vertical
    viewerInfoStack.spacing = 8
    viewerInfoStack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(viewerInfoStack)
    viewerInfoStack.addArrangedSubview(buildSettingsStatusStrip())
    let previousSectionGuide = buildPreviousSectionGuide()
    viewerInfoStack.addArrangedSubview(previousSectionGuide)
    view.addSubview(buildExposureControls())

    let bottomBar = UIStackView()
    bottomBar.axis = .horizontal
    bottomBar.alignment = .center
    bottomBar.distribution = .fill
    bottomBar.spacing = 12
    bottomBar.backgroundColor = .clear
    bottomBar.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 10, right: 12)
    bottomBar.isLayoutMarginsRelativeArrangement = true
    bottomBar.translatesAutoresizingMaskIntoConstraints = false

    shutterButton.setTitle("", for: .normal)
    shutterButton.setImage(UIImage(systemName: "doc.text.viewfinder"), for: .normal)
    shutterButton.tintColor = .black
    shutterButton.backgroundColor = .white
    shutterButton.layer.cornerRadius = 36
    shutterButton.accessibilityLabel = "Take receipt photo"
    shutterButton.addTarget(self, action: #selector(capturePrimaryPhoto), for: .touchUpInside)

    addPhotoButton.setTitle("Add Photo", for: .normal)
    addPhotoButton.setTitleColor(.white, for: .normal)
    addPhotoButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    addPhotoButton.layer.cornerRadius = 8
    addPhotoButton.accessibilityLabel = "Add another receipt photo"
    addPhotoButton.isEnabled = false
    addPhotoButton.isHidden = true
    addPhotoButton.addTarget(self, action: #selector(captureAdditionalPhoto), for: .touchUpInside)
    let leftSpacer = UIView()
    bottomBar.addArrangedSubview(leftSpacer)
    leftSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    leftSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    leftSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
    leftSpacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
    bottomBar.setCustomSpacing(16, after: leftSpacer)
    bottomBar.addArrangedSubview(addPhotoButton)
    bottomBar.addArrangedSubview(shutterButton)
    let rightSpacer = UIView()
    bottomBar.addArrangedSubview(rightSpacer)
    rightSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    rightSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    rightSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
    rightSpacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
    bottomReviewButton.setTitle("Done", for: .normal)
    bottomReviewButton.setTitleColor(.white, for: .normal)
    bottomReviewButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    bottomReviewButton.layer.cornerRadius = 8
    bottomReviewButton.accessibilityLabel = "Done: review captured receipt photos in Maintainiac"
    bottomReviewButton.isEnabled = false
    bottomReviewButton.isHidden = true
    bottomReviewButton.addTarget(self, action: #selector(finishWithCapturedPhotos), for: .touchUpInside)
    bottomBar.addArrangedSubview(bottomReviewButton)
    view.addSubview(bottomBar)

    NSLayoutConstraint.activate([
      topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
      topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      backButton.widthAnchor.constraint(equalToConstant: 48),
      backButton.heightAnchor.constraint(equalToConstant: 48),
      settingsButton.widthAnchor.constraint(equalToConstant: 48),
      settingsButton.heightAnchor.constraint(equalToConstant: 48),
      torchButton.widthAnchor.constraint(equalToConstant: 48),
      torchButton.heightAnchor.constraint(equalToConstant: 48),

      receiptFrameGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
      receiptFrameGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
      receiptFrameGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
      receiptFrameGuide.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -52),

      guidanceLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
      guidanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      guidanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),

      viewerInfoStack.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 8),
      viewerInfoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      viewerInfoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      settingsStatusStrip.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),

      exposureSlider.superview!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      exposureSlider.superview!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      exposureSlider.superview!.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
      exposureSlider.superview!.heightAnchor.constraint(equalToConstant: 48),

      bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
      bottomBar.heightAnchor.constraint(equalToConstant: 84),
      addPhotoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
      addPhotoButton.heightAnchor.constraint(equalToConstant: 48),
      shutterButton.widthAnchor.constraint(equalToConstant: 72),
      shutterButton.heightAnchor.constraint(equalToConstant: 72),
      bottomReviewButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
      bottomReviewButton.heightAnchor.constraint(equalToConstant: 48),
    ])
    NSLayoutConstraint.activate([
      previousSectionGuide.heightAnchor.constraint(equalToConstant: 102),
    ])
  }

  func buildSettingsStatusStrip() -> UILabel {
    settingsStatusStrip.text = settingsStatusText()
    settingsStatusStrip.textColor = UIColor(red: 1.0, green: 0.86, blue: 0.52, alpha: 1)
    settingsStatusStrip.font = .boldSystemFont(ofSize: 12)
    settingsStatusStrip.numberOfLines = 2
    settingsStatusStrip.backgroundColor = UIColor(white: 0.02, alpha: 0.41)
    settingsStatusStrip.layer.cornerRadius = 8
    settingsStatusStrip.layer.masksToBounds = true
    settingsStatusStrip.textAlignment = .center
    settingsStatusStrip.accessibilityLabel = "Receipt camera active settings"
    settingsStatusStrip.translatesAutoresizingMaskIntoConstraints = false
    settingsStatusStrip.isHidden = !shouldShowSettingsStatusStrip()
    return settingsStatusStrip
  }

  func buildExposureControls() -> UIView {
    let panel = UIStackView()
    panel.axis = .horizontal
    panel.alignment = .center
    panel.spacing = 10
    panel.backgroundColor = UIColor(white: 0.02, alpha: 0.46)
    panel.layoutMargins = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    panel.isLayoutMarginsRelativeArrangement = true
    panel.translatesAutoresizingMaskIntoConstraints = false
    panel.isHidden = true

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
}
