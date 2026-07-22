import MobileCoreServices
import UniformTypeIdentifiers
import UIKit

private let shareKey = "ShareKey"
private let shareMessageKey = "ShareMessageKey"
private let appGroupKey = "AppGroupId"
private let schemePrefix = "ShareMedia"
private let maxSharedReceiptItems = 20
private let maxSharedReceiptFileBytes = 25 * 1024 * 1024
private let maxSharedReceiptImageBytes = 15 * 1024 * 1024
private let maxSharedReceiptTextCharacters = 100000
private let supportedSharedFileExtensions: Set<String> = [
  "pdf",
  "png",
  "jpg",
  "jpeg",
  "heic",
  "heif",
  "webp",
  "txt",
  "text"
]
private let supportedSharedMimeTypes: Set<String> = [
  "application/pdf",
  "image/png",
  "image/jpeg",
  "image/heic",
  "image/heif",
  "image/webp",
  "text/plain"
]

final class ShareViewController: UIViewController {
  private var sharedMedia: [SharedMediaFile] = []
  private var shareMessages: [String] = []
  private var didReportShareLimit = false
  private var hasProcessedShare = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !hasProcessedShare else { return }
    hasProcessedShare = true
    processSharedItems()
  }

  private func processSharedItems() {
    guard
      let items = extensionContext?.inputItems as? [NSExtensionItem],
      !items.isEmpty
    else {
      finish()
      return
    }

    let group = DispatchGroup()
    for item in items {
      if let text = item.attributedContentText?.string,
         !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        appendShareMessage(text)
      }
      guard let attachments = item.attachments else { continue }
      for provider in attachments {
        if provider.hasItemConformingToTypeIdentifier(SharedMediaType.image.typeIdentifier) {
          load(provider, as: .image, group: group)
        } else if provider.hasItemConformingToTypeIdentifier(SharedMediaType.pdf.typeIdentifier) {
          load(provider, as: .pdf, group: group)
        } else if provider.hasItemConformingToTypeIdentifier(SharedMediaType.file.typeIdentifier) {
          load(provider, as: .file, group: group)
        } else if provider.hasItemConformingToTypeIdentifier(SharedMediaType.url.typeIdentifier) {
          load(provider, as: .url, group: group)
        } else if provider.hasItemConformingToTypeIdentifier(SharedMediaType.text.typeIdentifier) {
          load(provider, as: .text, group: group)
        } else {
          shareMessages.append("One shared item could not be imported. Share a PDF, receipt photo, or receipt text instead.")
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      let message = self?.shareMessages.isEmpty == true
        ? nil
        : self?.shareMessages.joined(separator: "\n")
      self?.saveAndRedirect(message: message)
    }
  }

  private func load(
    _ provider: NSItemProvider,
    as type: SharedMediaType,
    group: DispatchGroup
  ) {
    group.enter()
    provider.loadItem(forTypeIdentifier: type.typeIdentifier, options: nil) { [weak self] item, _ in
      defer { group.leave() }
      guard let self else { return }

      switch (type, item) {
      case (.text, let text as String):
        appendText(text)
      case (.url, let url as URL):
        append(path: url.absoluteString, mimeType: nil, type: .url)
      case (.image, let image as UIImage):
        saveImage(image)
      case (.pdf, let url as URL):
        saveFile(url, type: .file)
      case (.pdf, let data as Data):
        saveData(data, name: provider.suggestedName ?? "receipt-pdf", fileExtension: "pdf", mimeType: "application/pdf", type: .file)
      case (_, let url as URL):
        saveFile(url, type: type)
      case (_, let data as Data):
        saveData(data, name: provider.suggestedName ?? "shared-file", fileExtension: "", mimeType: nil, type: type)
      default:
        break
      }
    }
  }

  private func saveImage(_ image: UIImage) {
    guard let destination = containerURL()?.appendingPathComponent(uniqueName("receipt-image", "png")),
          let data = image.pngData()
    else { return }

    guard data.count <= maxSharedReceiptImageBytes else {
      shareMessages.append("One receipt image was too large to import. Share an image under 15 MB.")
      return
    }

    do {
      try data.write(to: destination, options: .atomic)
      append(path: destination.absoluteString, mimeType: "image/png", type: .image)
    } catch {
      return
    }
  }

  private func saveFile(_ url: URL, type: SharedMediaType) {
    guard let destination = containerURL()?.appendingPathComponent(uniqueName(url)) else {
      return
    }

    let mimeType = url.mimeType()
    guard isSupportedSharedFile(url, mimeType: mimeType) else {
      shareMessages.append("One shared file could not be imported. Share a PDF, receipt photo, or receipt text instead.")
      return
    }

    let scoped = url.startAccessingSecurityScopedResource()
    defer {
      if scoped {
        url.stopAccessingSecurityScopedResource()
      }
    }

    guard let byteCount = fileByteSize(url),
          byteCount <= maxSharedBytes(for: url, mimeType: mimeType)
    else {
      shareMessages.append("One shared file was too large to import. Share a PDF under 25 MB or an image under 15 MB.")
      return
    }

    do {
      try FileManager.default.copyItem(at: url, to: destination)
      append(path: destination.absoluteString, mimeType: mimeType, type: type)
    } catch {
      return
    }
  }

  private func saveData(
    _ data: Data,
    name: String,
    fileExtension pathExtension: String,
    mimeType: String?,
    type: SharedMediaType
  ) {
    guard !data.isEmpty,
          let destination = containerURL()?.appendingPathComponent(uniqueName(name, pathExtension))
    else { return }

    let resolvedMimeType = mimeType ?? destination.mimeType()
    guard isSupportedSharedFile(destination, mimeType: resolvedMimeType),
          data.count <= maxSharedBytes(for: destination, mimeType: resolvedMimeType)
    else {
      shareMessages.append("One shared file could not be imported. Share a supported receipt file that is under the size limit.")
      return
    }

    do {
      try data.write(to: destination, options: .atomic)
      append(path: destination.absoluteString, mimeType: resolvedMimeType, type: type)
    } catch {
      return
    }
  }

  private func appendText(_ text: String) {
    guard text.count <= maxSharedReceiptTextCharacters else {
      shareMessages.append("One shared text item was too large to import. Share shorter receipt notes.")
      return
    }
    append(path: text, mimeType: "text/plain", type: .text)
  }

  private func appendShareMessage(_ message: String) {
    guard message.count <= maxSharedReceiptTextCharacters else {
      shareMessages.append("One shared text item was too large to import. Share shorter receipt notes.")
      return
    }
    shareMessages.append(message)
  }

  private func append(path: String, mimeType: String?, type: SharedMediaType) {
    guard sharedMedia.count < maxSharedReceiptItems else {
      if !didReportShareLimit {
        didReportShareLimit = true
        shareMessages.append("Maintainiac can review \(maxSharedReceiptItems) shared receipt items at a time. Extra items were left out so the import stays stable.")
      }
      return
    }
    sharedMedia.append(
      SharedMediaFile(path: path, mimeType: mimeType, type: type)
    )
  }

  private func isSupportedSharedFile(_ url: URL, mimeType: String) -> Bool {
    let fileExtension = url.pathExtension.lowercased()
    if supportedSharedFileExtensions.contains(fileExtension) {
      return true
    }
    return supportedSharedMimeTypes.contains(mimeType.lowercased())
  }

  private func maxSharedBytes(for url: URL, mimeType: String) -> Int {
    let lowerMimeType = mimeType.lowercased()
    let fileExtension = url.pathExtension.lowercased()
    if lowerMimeType.hasPrefix("image/") ||
       ["png", "jpg", "jpeg", "heic", "heif", "webp"].contains(fileExtension) {
      return maxSharedReceiptImageBytes
    }
    return maxSharedReceiptFileBytes
  }

  private func fileByteSize(_ url: URL) -> Int? {
    if let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
       let size = values.fileSize {
      return size
    }
    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
    return attributes?[.size] as? Int
  }

  private func saveAndRedirect(message: String?) {
    let defaults = UserDefaults(suiteName: appGroupId())
    defaults?.set(try? JSONEncoder().encode(sharedMedia), forKey: shareKey)
    defaults?.set(message, forKey: shareMessageKey)
    defaults?.synchronize()
    redirectToHostApp()
  }

  private func redirectToHostApp() {
    guard let url = URL(string: "\(schemePrefix)-\(hostAppBundleIdentifier()):share") else {
      finish()
      return
    }

    var responder: UIResponder? = self
    let selector = sel_registerName("openURL:")
    while let current = responder {
      if current.responds(to: selector) {
        _ = current.perform(selector, with: url)
        finish()
        return
      }
      responder = current.next
    }

    finish()
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private func containerURL() -> URL? {
    FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId()
    )
  }

  private func appGroupId() -> String {
    let custom = Bundle.main.object(forInfoDictionaryKey: appGroupKey) as? String
    return custom ?? "group.\(hostAppBundleIdentifier())"
  }

  private func hostAppBundleIdentifier() -> String {
    let extensionId = Bundle.main.bundleIdentifier ?? "com.maintainiac.ShareExtension"
    return extensionId.components(separatedBy: ".").dropLast().joined(separator: ".")
  }

  private func uniqueName(_ url: URL) -> String {
    uniqueName(url.deletingPathExtension().lastPathComponent, url.pathExtension)
  }

  private func uniqueName(_ baseName: String, _ pathExtension: String) -> String {
    let safeBase = sanitizedFileName(baseName).isEmpty
      ? UUID().uuidString
      : sanitizedFileName(baseName)
    let safeExtension = sanitizedFileName(pathExtension)
    let suffix = safeExtension.isEmpty ? "" : ".\(safeExtension)"
    return "\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString)-\(safeBase)\(suffix)"
  }

  private func sanitizedFileName(_ value: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    let scalars = value.unicodeScalars.map { scalar in
      allowed.contains(scalar) ? Character(scalar) : "_"
    }
    let collapsed = String(scalars)
      .replacingOccurrences(
        of: "_+",
        with: "_",
        options: .regularExpression
      )
      .trimmingCharacters(in: CharacterSet(charactersIn: "._-"))
    if collapsed.count <= 90 { return collapsed }
    return String(collapsed.prefix(90))
  }
}

private struct SharedMediaFile: Codable {
  let path: String
  let mimeType: String?
  let thumbnail: String?
  let duration: Double?
  let message: String?
  let type: SharedMediaType

  init(
    path: String,
    mimeType: String?,
    thumbnail: String? = nil,
    duration: Double? = nil,
    message: String? = nil,
    type: SharedMediaType
  ) {
    self.path = path
    self.mimeType = mimeType
    self.thumbnail = thumbnail
    self.duration = duration
    self.message = message
    self.type = type
  }
}

private enum SharedMediaType: String, Codable {
  case image
  case text
  case file
  case pdf
  case url

  var typeIdentifier: String {
    if #available(iOS 14.0, *) {
      switch self {
      case .image:
        return UTType.image.identifier
      case .text:
        return UTType.text.identifier
      case .file:
        return UTType.fileURL.identifier
      case .pdf:
        return UTType.pdf.identifier
      case .url:
        return UTType.url.identifier
      }
    }

    switch self {
    case .image:
      return kUTTypeImage as String
    case .text:
      return kUTTypeText as String
    case .file:
      return kUTTypeFileURL as String
    case .pdf:
      return kUTTypePDF as String
    case .url:
      return kUTTypeURL as String
    }
  }
}

private extension URL {
  func mimeType() -> String {
    if #available(iOS 14.0, *),
       let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
      return mimeType
    }
    return "application/octet-stream"
  }
}
