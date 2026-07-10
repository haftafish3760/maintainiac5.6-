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
    close.setTitle("Done", for: .normal)
    close.setTitleColor(.black, for: .normal)
    close.backgroundColor = UIColor(red: 1, green: 0.82, blue: 0.4, alpha: 1)
    close.layer.cornerRadius = 7
    close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
    let title = UILabel()
    title.text = "Receipt Camera Settings"
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
    content.addArrangedSubview(note("Camera settings are separate from the live view. Brightness and light stay on the camera screen."))
    content.addArrangedSubview(section("RECEIPT ASSIST"))
    content.addArrangedSubview(toggle("Help fill receipt details", value: camera.assistedReceiptFill) { [weak self] enabled in
      camera.assistedReceiptFill = enabled
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(section("CAPTURE FLOW"))
    content.addArrangedSubview(toggle("Long receipt mode", value: camera.longReceiptMode) { [weak self] enabled in
      camera.longReceiptMode = enabled && camera.canUseLongReceiptMode()
      camera.updateDoneButton()
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(toggle("Automatic capture", value: camera.autoCaptureEnabled) { [weak self] enabled in
      camera.autoCaptureEnabled = enabled && camera.isAutoCaptureCurrentlyAllowed()
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(toggle("Receipt edge guidance", value: camera.edgeDetectionEnabled) { [weak self] enabled in
      camera.edgeDetectionEnabled = enabled
      camera.receiptFrameGuide.isHidden = !(enabled && camera.edgeOverlayEnabled)
      camera.updateSettingsStatusStrip()
      self?.reloadContent()
    })
    content.addArrangedSubview(section("REVIEW"))
    content.addArrangedSubview(action("Receipt details: Prices only", selected: camera.reviewDepth == "pricesOnly") { [weak self] in
      camera.setReceiptReviewStyle("pricesOnly")
      self?.reloadContent()
    })
    content.addArrangedSubview(action("Receipt details: Detailed lines", selected: camera.reviewDepth == "detailedLines") { [weak self] in
      camera.setReceiptReviewStyle("detailedLines")
      self?.reloadContent()
    })
    content.addArrangedSubview(action("Reset receipt camera defaults", selected: false) { [weak self] in
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
