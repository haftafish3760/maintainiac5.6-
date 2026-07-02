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
    preview.videoGravity = .resizeAspect
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
    let settingsButton = iconButton(title: "Receipt camera settings", symbol: "slider.horizontal.3")
    settingsButton.addTarget(self, action: #selector(showReceiptCameraSettings), for: .touchUpInside)
    torchButton.setTitle("", for: .normal)
    torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
    torchButton.tintColor = .white
    torchButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    torchButton.layer.cornerRadius = 8
    torchButton.accessibilityLabel = "Turn light on"
    torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
    doneButton.setTitle("Next", for: .normal)
    doneButton.setTitleColor(.white, for: .normal)
    doneButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    doneButton.layer.cornerRadius = 8
    doneButton.accessibilityLabel = "Review captured receipt photos in Maintainiac"
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
    guidanceLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.50)
    guidanceLabel.layer.cornerRadius = 8
    guidanceLabel.layer.masksToBounds = true
    guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(guidanceLabel)
    view.addSubview(buildSettingsStatusStrip())
    let previousSectionGuide = buildPreviousSectionGuide()
    view.addSubview(previousSectionGuide)
    view.addSubview(buildExposureControls())

    let bottomBar = UIStackView()
    bottomBar.axis = .horizontal
    bottomBar.alignment = .center
    bottomBar.distribution = .fill
    bottomBar.spacing = 12
    bottomBar.backgroundColor = UIColor(white: 0.02, alpha: 0.53)
    bottomBar.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 14, right: 12)
    bottomBar.isLayoutMarginsRelativeArrangement = true
    bottomBar.translatesAutoresizingMaskIntoConstraints = false

    shutterButton.setTitle("", for: .normal)
    shutterButton.setImage(UIImage(systemName: "doc.text.viewfinder"), for: .normal)
    shutterButton.tintColor = .black
    shutterButton.backgroundColor = .white
    shutterButton.layer.cornerRadius = 36
    shutterButton.accessibilityLabel = "Take receipt photo"
    shutterButton.addTarget(self, action: #selector(capturePrimaryPhoto), for: .touchUpInside)

    addPhotoButton.setTitle("Add Next", for: .normal)
    addPhotoButton.setTitleColor(.white, for: .normal)
    addPhotoButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    addPhotoButton.layer.cornerRadius = 8
    addPhotoButton.accessibilityLabel = "Add next receipt section photo"
    addPhotoButton.isEnabled = false
    addPhotoButton.isHidden = true
    addPhotoButton.addTarget(self, action: #selector(captureAdditionalPhoto), for: .touchUpInside)
    bottomBar.addArrangedSubview(addPhotoButton)
    bottomBar.addArrangedSubview(shutterButton)
    bottomReviewButton.setTitle("Next", for: .normal)
    bottomReviewButton.setTitleColor(.white, for: .normal)
    bottomReviewButton.backgroundColor = UIColor(white: 0.06, alpha: 0.88)
    bottomReviewButton.layer.cornerRadius = 8
    bottomReviewButton.accessibilityLabel = "Review captured receipt photos in Maintainiac"
    bottomReviewButton.isEnabled = false
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
      doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
      doneButton.heightAnchor.constraint(equalToConstant: 48),
      addPhotoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 82),
      addPhotoButton.heightAnchor.constraint(equalToConstant: 54),
      torchButton.widthAnchor.constraint(equalToConstant: 48),
      torchButton.heightAnchor.constraint(equalToConstant: 48),

      receiptFrameGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
      receiptFrameGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
      receiptFrameGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
      receiptFrameGuide.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -52),

      guidanceLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
      guidanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      guidanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),

      settingsStatusStrip.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 8),
      settingsStatusStrip.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      settingsStatusStrip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      settingsStatusStrip.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),

      exposureSlider.superview!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      exposureSlider.superview!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      exposureSlider.superview!.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
      exposureSlider.superview!.heightAnchor.constraint(equalToConstant: 48),

      bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      bottomBar.heightAnchor.constraint(equalToConstant: 104),
      shutterButton.widthAnchor.constraint(equalToConstant: 72),
      shutterButton.heightAnchor.constraint(equalToConstant: 72),
      bottomReviewButton.heightAnchor.constraint(equalToConstant: 54)
    ])
    NSLayoutConstraint.activate([
      previousSectionGuide.topAnchor.constraint(equalTo: settingsStatusStrip.bottomAnchor, constant: 8),
      previousSectionGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      previousSectionGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      previousSectionGuide.heightAnchor.constraint(equalToConstant: 102)
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
