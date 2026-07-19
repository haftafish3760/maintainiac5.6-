import AVFoundation
import UIKit

extension ReceiptCameraViewController {
  func registerSessionRecoveryObservers() {
    guard sessionObservers.isEmpty else { return }
    let center = NotificationCenter.default
    sessionObservers = [
      center.addObserver(
        forName: .AVCaptureSessionWasInterrupted,
        object: session,
        queue: .main
      ) { [weak self] notification in
        self?.handleSessionInterruption(notification)
      },
      center.addObserver(
        forName: .AVCaptureSessionInterruptionEnded,
        object: session,
        queue: .main
      ) { [weak self] _ in
        self?.handleSessionInterruptionEnded()
      },
      center.addObserver(
        forName: .AVCaptureSessionRuntimeError,
        object: session,
        queue: .main
      ) { [weak self] notification in
        self?.handleSessionRuntimeError(notification)
      },
    ]
  }

  func removeSessionRecoveryObservers() {
    let center = NotificationCenter.default
    sessionObservers.forEach(center.removeObserver)
    sessionObservers.removeAll()
  }

  func handleSessionInterruption(_ notification: Notification) {
    guard !closeResultDelivered else { return }
    sessionWasInterrupted = true
    sessionInterruptionCount += 1
    lastSessionRecoveryStatus = sessionInterruptionReason(notification)
    shutterButton.isEnabled = false
    addPhotoButton.isEnabled = false
    guidanceLabel.text = "Receipt camera paused. Maintainiac will resume it when available."
  }

  func handleSessionInterruptionEnded() {
    guard !closeResultDelivered else { return }
    sessionWasInterrupted = false
    lastSessionRecoveryStatus = "interruption_ended"
    restartSessionAfterInterruption()
  }

  func handleSessionRuntimeError(_ notification: Notification) {
    guard !closeResultDelivered else { return }
    sessionRuntimeErrorCount += 1
    let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
    lastSessionRecoveryStatus = error?.code == .mediaServicesWereReset
      ? "media_services_reset"
      : "runtime_error"
    restartSessionAfterInterruption()
  }

  func restartSessionAfterInterruption() {
    guard isCameraSessionUsable, !closingCamera else { return }
    guard sessionRecoveryAttemptCount < 2 else {
      lastSessionRecoveryStatus = "recovery_exhausted"
      shutterButton.isEnabled = false
      addPhotoButton.isEnabled = false
      guidanceLabel.text = "Receipt camera is unavailable. Go back to choose another receipt source."
      return
    }
    sessionRecoveryAttemptCount += 1
    lastSessionRecoveryStatus = "recovery_started"
    sessionQueue.async { [weak self] in
      guard let self, self.isCameraSessionUsable, !self.closingCamera else { return }
      if !self.session.isRunning {
        self.session.startRunning()
      }
      let recovered = self.session.isRunning
      DispatchQueue.main.async {
        guard self.isCameraUiUsable else { return }
        self.lastSessionRecoveryStatus = recovered ? "recovered" : "recovery_failed"
        if recovered {
          self.sessionRecoveryAttemptCount = 0
        }
        self.shutterButton.isEnabled = recovered
        self.addPhotoButton.isEnabled =
          recovered && self.capturedPhotoPaths.count < self.maxSectionCount
        self.updateDoneButton()
        self.guidanceLabel.text = recovered
          ? self.guidanceText()
          : "Receipt camera did not resume. Go back to choose another receipt source."
      }
    }
  }

  func sessionInterruptionReason(_ notification: Notification) -> String {
    guard
      let rawReason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? NSNumber,
      let reason = AVCaptureSession.InterruptionReason(rawValue: rawReason.intValue)
    else {
      return "interrupted_unknown"
    }
    switch reason {
    case .audioDeviceInUseByAnotherClient:
      return "interrupted_audio_in_use"
    case .videoDeviceInUseByAnotherClient:
      return "interrupted_video_in_use"
    case .videoDeviceNotAvailableWithMultipleForegroundApps:
      return "interrupted_multiple_foreground_apps"
    case .videoDeviceNotAvailableDueToSystemPressure:
      return "interrupted_system_pressure"
    case .videoDeviceNotAvailableInBackground:
      return "interrupted_background"
    @unknown default:
      return "interrupted_unknown"
    }
  }
}
