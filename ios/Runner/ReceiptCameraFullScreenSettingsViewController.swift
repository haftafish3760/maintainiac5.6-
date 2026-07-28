import UIKit

final class ReceiptCameraFullScreenSettingsViewController: UIViewController {
  private weak var camera: ReceiptCameraViewController?
  private let content = UIStackView()

  init(camera: ReceiptCameraViewController) {
    self.camera = camera
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.03, alpha: 1)
    content.axis = .vertical
    content.spacing = 10
    buildLayout()
    reloadContent()
  }

  private func buildLayout() {
    let close = UIButton(type: .system)
    close.setTitle(camera?.receiptCameraText("Done", "Listo") ?? "Done", for: .normal)
    close.setTitleColor(.black, for: .normal)
    close.backgroundColor = UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 1)
    close.layer.cornerRadius = 7
    close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
    let title = UILabel()
    title.text = camera?.receiptCameraText("Receipt Camera Settings", "Configuración de la cámara de recibos") ?? "Receipt Camera Settings"
    title.textColor = .white
    title.font = .boldSystemFont(ofSize: 20)
    let header = UIStackView(arrangedSubviews: [title, UIView(), close])
    header.alignment = .center
    header.translatesAutoresizingMaskIntoConstraints = false
    close.widthAnchor.constraint(equalToConstant: 68).isActive = true
    close.heightAnchor.constraint(equalToConstant: 40).isActive = true

    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    content.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(content)
    view.addSubview(header)
    view.addSubview(scroll)
    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 14),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
      content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
      content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
      content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
    ])
  }

  private func reloadContent() {
    guard let camera else { return }
    content.arrangedSubviews.forEach { $0.removeFromSuperview() }
    content.addArrangedSubview(note(camera.receiptCameraText(
      "These controls apply while this camera is open. Set your usual receipt defaults in Receipt Settings.",
      "Estos controles se aplican mientras esta cámara está abierta. Configure sus valores predeterminados de recibos en Configuración de recibos."
    )))
    content.addArrangedSubview(section(camera.receiptCameraText("CAPTURE FLOW", "FLUJO DE CAPTURA")))
    content.addArrangedSubview(toggle(camera.receiptCameraText("Automatic capture", "Captura automática"), value: camera.autoCaptureEnabled) { [weak self] enabled in
      guard enabled else {
        camera.autoCaptureEnabled = false
        camera.autoCaptureStableFrameCount = 0
        camera.latestAutoCaptureStatus = "off"
        camera.updateSettingsStatusStrip()
        self?.reloadContent()
        return
      }
      guard camera.isAutoCaptureCurrentlyAllowed() else {
        camera.autoCaptureEnabled = false
        camera.autoCaptureStableFrameCount = 0
        camera.latestAutoCaptureStatus = "not_allowed"
        camera.guidanceLabel.text = camera.autoCaptureBlockedMessage()
        camera.updateSettingsStatusStrip()
        self?.reloadContent()
        return
      }
      camera.autoCaptureEnabled = true
      camera.guidanceLabel.text = camera.receiptCameraText(
        "Automatic capture is on. Hold steady, or capture anytime.",
        "La captura automática está activada. Mantenga firme el teléfono o capture en cualquier momento."
      )
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(toggle(camera.receiptCameraText("Receipt framing checks", "Revisiones de encuadre del recibo"), value: camera.receiptGuidanceWarningsEnabled()) { [weak self] enabled in
      camera.setReceiptGuidanceWarningsEnabled(enabled)
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(toggle(camera.receiptCameraText("Receipt edge guidance", "Guía de bordes del recibo"), value: camera.edgeDetectionEnabled) { [weak self] enabled in
      camera.edgeDetectionEnabled = enabled
      if !enabled && camera.autoCaptureEnabled {
        camera.autoCaptureEnabled = false
        camera.autoCaptureStableFrameCount = 0
        camera.latestAutoCaptureStatus = "edge_detection_off"
        camera.guidanceLabel.text = camera.receiptCameraText(
          "Automatic capture needs receipt edge guidance. Manual capture is still ready.",
          "La captura automática necesita la guía de bordes del recibo. La captura manual sigue lista."
        )
      }
      camera.receiptFrameGuide.isHidden = !(enabled && camera.edgeOverlayEnabled)
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(section(camera.receiptCameraText("CAMERA CONTROLS", "CONTROLES DE CÁMARA")))
    content.addArrangedSubview(toggle(camera.receiptCameraText("Auto brightness assist", "Asistencia automática de brillo"), value: camera.autoExposureAssistEnabled) { [weak self] enabled in
      camera.autoExposureAssistEnabled = enabled
      if enabled {
        camera.userExposureOverride = false
        camera.resetExposure()
      }
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    let imageCleanupEnabled = camera.perspectiveCorrectionEnabled &&
      camera.manualCropAfterCapture &&
      camera.autoCropSuggestionEnabled &&
      camera.orientationCorrectionEnabled &&
      camera.contrastBoostEnabled &&
      camera.sharpeningEnabled &&
      camera.shadowReductionEnabled
    content.addArrangedSubview(toggle(camera.receiptCameraText("Image cleanup", "Limpieza de imagen"), value: imageCleanupEnabled) { [weak self] enabled in
      camera.perspectiveCorrectionEnabled = enabled
      camera.manualCropAfterCapture = enabled
      camera.autoCropSuggestionEnabled = enabled
      camera.orientationCorrectionEnabled = enabled
      camera.grayscalePreviewEnabled = enabled
      camera.contrastBoostEnabled = enabled
      camera.sharpeningEnabled = enabled
      camera.shadowReductionEnabled = enabled
      camera.adaptiveThresholdEnabled = enabled
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(note(camera.receiptCameraText(
      "Image cleanup prepares crop, straighten, grayscale, contrast, sharpness, and shadow corrections for receipt review.",
      "La limpieza de imagen prepara correcciones de recorte, enderezado, escala de grises, contraste, nitidez y sombras para revisar el recibo."
    )))
    content.addArrangedSubview(note(camera.receiptCameraText(
      "Your phone handles autofocus. Pinch to zoom, and use the shutter anytime. Maintainiac does not use tap-to-focus.",
      "El teléfono controla el enfoque automático. Pellizque para acercar y use el disparador en cualquier momento. Maintainiac no usa tocar para enfocar."
    )))
    content.addArrangedSubview(action(camera.receiptCameraText("Reset this camera session", "Restablecer esta sesión de cámara"), selected: false) { [weak self] in
      camera.resetReceiptCameraDefaults()
      self?.reloadContent()
    })
  }

  private func section(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.textColor = UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 1)
    label.font = .boldSystemFont(ofSize: 12)
    return label
  }

  private func note(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.textColor = UIColor(white: 0.88, alpha: 1)
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.numberOfLines = 0
    return label
  }

  private func toggle(_ title: String, value: Bool, action: @escaping (Bool) -> Void) -> UIView {
    let label = note(title)
    let control = UISwitch()
    control.isOn = value
    control.addAction(UIAction { sender in action((sender as? UISwitch)?.isOn ?? value) }, for: .valueChanged)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.alignment = .center
    return row
  }

  private func action(_ title: String, selected: Bool, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle((selected ? "✓ " : "") + title, for: .normal)
    button.contentHorizontalAlignment = .left
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = UIColor(white: 0.1, alpha: 1)
    button.layer.cornerRadius = 7
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }
}
