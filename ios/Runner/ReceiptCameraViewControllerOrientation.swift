import AVFoundation
import UIKit

extension ReceiptCameraViewController {
  func updateCaptureOrientation() {
    guard
      isViewLoaded,
      let interfaceOrientation = view.window?.windowScene?.interfaceOrientation,
      let captureOrientation = captureVideoOrientation(interfaceOrientation)
    else {
      return
    }
    let connections = [
      previewLayer?.connection,
      photoOutput.connection(with: .video),
      videoOutput.connection(with: .video),
    ]
    var updated = false
    for connection in connections.compactMap({ $0 }) {
      guard connection.isVideoOrientationSupported else { continue }
      connection.videoOrientation = captureOrientation
      updated = true
    }
    guard updated else { return }
    captureOrientationUpdateCount += 1
    lastCaptureOrientation = captureOrientationLabel(captureOrientation)
  }

  func captureVideoOrientation(
    _ interfaceOrientation: UIInterfaceOrientation
  ) -> AVCaptureVideoOrientation? {
    switch interfaceOrientation {
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    default:
      return nil
    }
  }

  func captureOrientationLabel(
    _ orientation: AVCaptureVideoOrientation
  ) -> String {
    switch orientation {
    case .portrait:
      return "portrait"
    case .portraitUpsideDown:
      return "portrait_upside_down"
    case .landscapeLeft:
      return "landscape_left"
    case .landscapeRight:
      return "landscape_right"
    @unknown default:
      return "unknown"
    }
  }
}
