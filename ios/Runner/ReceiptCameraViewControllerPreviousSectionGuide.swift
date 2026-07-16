import UIKit

extension ReceiptCameraViewController {
  func buildPreviousSectionGuide() -> UIView {
    previousSectionGuidePanel.axis = .vertical
    previousSectionGuidePanel.spacing = 4
    previousSectionGuidePanel.backgroundColor = UIColor(white: 0.02, alpha: 0.52)
    previousSectionGuidePanel.layoutMargins = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    previousSectionGuidePanel.isLayoutMarginsRelativeArrangement = true
    previousSectionGuidePanel.translatesAutoresizingMaskIntoConstraints = false
    previousSectionGuidePanel.isHidden = true

    let title = UILabel()
    title.text = previousSectionGhostGuideTitle()
    title.textColor = .white
    title.font = .boldSystemFont(ofSize: 12)
    previousSectionGuidePanel.addArrangedSubview(title)

    previousSectionGuideImageView.contentMode = .scaleAspectFill
    previousSectionGuideImageView.alpha = previousSectionGhostOpacity
    previousSectionGuideImageView.clipsToBounds = true
    previousSectionGuideImageView.accessibilityLabel = "Previous receipt section overlap guide"
    previousSectionGuidePanel.addArrangedSubview(previousSectionGuideImageView)

    nextSectionGuideImageView.contentMode = .scaleAspectFill
    nextSectionGuideImageView.alpha = 0.28
    nextSectionGuideImageView.clipsToBounds = true
    nextSectionGuideImageView.accessibilityLabel = "Next receipt section overlap guide"
    nextSectionGuideImageView.isHidden = true
    previousSectionGuidePanel.addArrangedSubview(nextSectionGuideImageView)
    constrainNextSectionGuideImage()

    let detail = UILabel()
    detail.text = previousSectionGhostGuideInstruction()
    detail.textColor = UIColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 1)
    detail.textAlignment = .center
    detail.font = .boldSystemFont(ofSize: 11)
    previousSectionGuidePanel.addArrangedSubview(detail)
    updatePreviousSectionGuide(previousSectionGuidePhotoPath)
    updateNextSectionGuide(nextSectionGuidePhotoPath)
    return previousSectionGuidePanel
  }

  func updatePreviousSectionGuide(_ path: String?) {
    guard
      let path,
      !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      if nextSectionGuidePhotoPath == nil {
        previousSectionGuidePanel.isHidden = true
      }
      updateViewerInfoStackVisibility()
      return
    }
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      (trimmedPath as NSString).isAbsolutePath,
      isPreviousSectionGuideImagePath(trimmedPath),
      FileManager.default.fileExists(atPath: trimmedPath),
      let image = UIImage(contentsOfFile: trimmedPath)
    else {
      previousSectionGuidePanel.isHidden = true
      updateViewerInfoStackVisibility()
      return
    }
    previousSectionGuideImageView.image = previousSectionGhostSliceImage(image) ?? image
    previousSectionGuideImageView.alpha = previousSectionGhostOpacity
    previousSectionGuideImageView.accessibilityLabel =
      "\(previousSectionGhostGuideTitle()). \(previousSectionGhostGuideInstruction())"
    previousSectionGuidePanel.isHidden = false
    updateViewerInfoStackVisibility()
  }

  func updateNextSectionGuide(_ path: String?) {
    guard
      let path,
      !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      nextSectionGuideImageView.isHidden = true
      if previousSectionGuidePhotoPath == nil {
        previousSectionGuidePanel.isHidden = true
      }
      updateViewerInfoStackVisibility()
      return
    }
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      (trimmedPath as NSString).isAbsolutePath,
      isPreviousSectionGuideImagePath(trimmedPath),
      FileManager.default.fileExists(atPath: trimmedPath),
      let image = UIImage(contentsOfFile: trimmedPath)
    else {
      nextSectionGuideImageView.isHidden = true
      updateViewerInfoStackVisibility()
      return
    }
    nextSectionGuideImageView.image = nextSectionGhostSliceImage(image) ?? image
    nextSectionGuideImageView.alpha = 0.28
    nextSectionGuideImageView.isHidden = false
    previousSectionGuidePanel.isHidden = false
    updateViewerInfoStackVisibility()
  }

  private func constrainNextSectionGuideImage() {
    nextSectionGuideImageView.heightAnchor.constraint(equalToConstant: 34).isActive = true
  }

  func isPreviousSectionGuideImagePath(_ path: String) -> Bool {
    let lowerPath = path.lowercased()
    return lowerPath.hasSuffix(".jpg") ||
      lowerPath.hasSuffix(".jpeg") ||
      lowerPath.hasSuffix(".png") ||
      lowerPath.hasSuffix(".heic") ||
      lowerPath.hasSuffix(".webp")
  }

  func previousSectionGhostSliceImage(_ image: UIImage) -> UIImage? {
    let normalizedImage = normalizedReceiptGhostGuideImage(image) ?? image
    guard let cgImage = normalizedImage.cgImage else { return nil }
    let height = CGFloat(cgImage.height)
    let width = CGFloat(cgImage.width)
    guard width > 0, height > 0 else { return image }
    let sourceStartFraction = previousSectionGhostSourceStartFraction.isFinite
      ? min(max(previousSectionGhostSourceStartFraction, 0), 1)
      : 0.80
    let sourceHeightFraction = previousSectionGhostSourceHeightFraction.isFinite
      ? min(max(previousSectionGhostSourceHeightFraction, 0), 1)
      : 0.20
    let startY = min(max(floor(height * sourceStartFraction), 0), height - 1)
    let requestedHeight = max(ceil(height * sourceHeightFraction), 1)
    let sliceHeight = min(requestedHeight, height - startY)
    let rect = CGRect(x: 0, y: startY, width: width, height: sliceHeight)
    guard let cropped = cgImage.cropping(to: rect) else { return nil }
    return UIImage(cgImage: cropped, scale: normalizedImage.scale, orientation: .up)
  }

  func nextSectionGhostSliceImage(_ image: UIImage) -> UIImage? {
    let normalizedImage = normalizedReceiptGhostGuideImage(image) ?? image
    guard let cgImage = normalizedImage.cgImage else { return nil }
    let height = CGFloat(cgImage.height)
    let width = CGFloat(cgImage.width)
    guard width > 0, height > 0 else { return image }
    let sliceHeight = min(max(ceil(height * 0.20), 1), height)
    let rect = CGRect(x: 0, y: 0, width: width, height: sliceHeight)
    guard let cropped = cgImage.cropping(to: rect) else { return nil }
    return UIImage(cgImage: cropped, scale: normalizedImage.scale, orientation: .up)
  }

  func normalizedReceiptGhostGuideImage(_ image: UIImage) -> UIImage? {
    guard image.size.width > 0, image.size.height > 0 else { return nil }
    guard image.imageOrientation != .up else { return image }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale
    format.opaque = false
    return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  func previousSectionGhostGuideTitle() -> String {
    if previousSectionGuideUsesNextContext() {
      return "Match the next section"
    }
    if previousSectionReasonCode == "missing_bottom_edge_and_totals" {
      return "Match the bottom section"
    }
    return "Match receipt sections"
  }

  func previousSectionGhostGuideInstruction() -> String {
    let trimmed = previousSectionGuidance.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }
    if previousSectionGuideUsesNextContext() {
      return "Use the top of the next receipt section as context, then confirm the retake still joins cleanly in photo review."
    }
    if previousSectionReasonCode == "missing_bottom_edge_and_totals" {
      return "Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines so subtotal, total, and final lines can be matched."
    }
    return "Repeat 3-5 readable lines near the top ghost slice of this photo."
  }

  func previousSectionGuideUsesNextContext() -> Bool {
    return previousSectionReasonCode == "retake_top_with_next_context"
  }

  func previousSectionGhostGuidePolicy() -> String {
    if previousSectionGuideUsesNextContext() {
      return "next_section_top_context_ghost_at_top_repeat_3_to_5_lines"
    }
    if previousSectionReasonCode == "missing_bottom_edge_and_totals" {
      return "bottom_overlap_ghost_at_top_repeat_3_to_5_lines"
    }
    return "section_overlap_ghost_at_top_repeat_3_to_5_lines"
  }

  func previousSectionGhostGuideMatchTarget() -> String {
    if previousSectionGuideUsesNextContext() {
      return "next_section_top_lines"
    }
    if previousSectionReasonCode == "missing_bottom_edge_and_totals" {
      return "subtotal_total_and_final_lines"
    }
    return "repeated_receipt_lines"
  }

  func addSectionButtonTitle() -> String {
    return "Add Another Photo"
  }

  func addSectionButtonAccessibilityLabel() -> String {
    return "Add another receipt photo if this receipt continues"
  }
}
