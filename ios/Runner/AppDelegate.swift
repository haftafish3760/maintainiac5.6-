import AVFoundation
import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let receiptCameraChannelName = "maintainiac/receipt_camera"
  private var pendingReceiptCameraResult: FlutterResult?
  private var tripTrackingBridge: TripTrackingNativeBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerReceiptCameraBridge(with: engineBridge.pluginRegistry)
    let bridge = TripTrackingNativeBridge()
    bridge.register(with: engineBridge.pluginRegistry)
    tripTrackingBridge = bridge
  }

  private func registerReceiptCameraBridge(with pluginRegistry: FlutterPluginRegistry) {
    guard let registrar = pluginRegistry.registrar(forPlugin: "ReceiptNativeCameraPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: receiptCameraChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(
          code: "native_camera_unavailable",
          message: "Maintainiac receipt camera bridge is no longer available.",
          details: nil
        ))
        return
      }
      switch call.method {
      case "readCapabilities":
        result(self.readReceiptCameraCapabilities())
      case "captureReceipt":
        self.openReceiptCamera(result: result, arguments: call.arguments as? [String: Any])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func readReceiptCameraCapabilities() -> [String: Any] {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera
      ],
      mediaType: .video,
      position: .unspecified
    )
    let devices = discovery.devices
    guard !devices.isEmpty else {
      return unavailableReceiptCameraCapabilities()
    }

    let rearCamera = devices.first(where: { $0.position == .back })
    let frontCamera = devices.contains(where: { $0.position == .front })
    let camera = rearCamera ?? devices.first
    let permissionGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    let minExposureBias = camera?.minExposureTargetBias ?? 0
    let maxExposureBias = camera?.maxExposureTargetBias ?? 0
    let supportsExposureBias = minExposureBias < maxExposureBias
    let supportsMacro = devices.contains(where: {
      $0.position == .back && $0.deviceType == .builtInUltraWideCamera
    })
    let stillDimensions = maxStillDimensions(for: camera)

    return [
      "engine": "avFoundation",
      "available": rearCamera != nil,
      "cameraPermissionGranted": permissionGranted,
      "cameraCount": devices.count,
      "hasRearCamera": rearCamera != nil,
      "hasFrontCamera": frontCamera,
      "supportsTapFocus": camera?.isFocusPointOfInterestSupported ?? false,
      "supportsContinuousFocus": camera?.isFocusModeSupported(.continuousAutoFocus) ?? false,
      "supportsFocusLock": camera?.isFocusModeSupported(.locked) ?? false,
      "supportsManualFocusDistance": camera?.isLockingFocusWithCustomLensPositionSupported ?? false,
      "supportsExposureCompensation": supportsExposureBias,
      "supportsExposureLock": camera?.isExposureModeSupported(.locked) ?? false,
      "supportsManualShutter": camera?.isExposureModeSupported(.custom) ?? false,
      "supportsIsoControl": camera?.isExposureModeSupported(.custom) ?? false,
      "supportsWhiteBalanceLock": camera?.isWhiteBalanceModeSupported(.locked) ?? false,
      "supportsManualWhiteBalance": camera?.isLockingWhiteBalanceWithCustomDeviceGainsSupported ?? false,
      "supportsTorch": camera?.hasTorch ?? false,
      "supportsFlashAuto": camera?.hasFlash ?? false,
      "supportsZoom": (camera?.maxAvailableVideoZoomFactor ?? 1) > 1,
      "supportsMacroSelection": supportsMacro,
      "supportsYuvLiveFrames": true,
      "supportsRaw": false,
      // The Maintainiac AVFoundation receipt surface computes framing signals
      // from live YUV frames; expose that capability so automatic capture can
      // be enabled when the user's settings and device tier allow it.
      "supportsNativeEdgeSignals": true,
      "minZoom": 1,
      "maxZoom": Double(camera?.maxAvailableVideoZoomFactor ?? 1),
      "minExposureOffset": Double(minExposureBias),
      "maxExposureOffset": Double(maxExposureBias),
      "maxStillWidth": stillDimensions.width,
      "maxStillHeight": stillDimensions.height
    ]
  }

  private func maxStillDimensions(for camera: AVCaptureDevice?) -> (width: Int, height: Int) {
    guard let camera else { return (0, 0) }
    return camera.formats.reduce((width: 0, height: 0)) { current, format in
      let dimensions = format.highResolutionStillImageDimensions
      let width = Int(dimensions.width)
      let height = Int(dimensions.height)
      guard width > 0 && height > 0 else { return current }
      let pixels = width * height
      let currentPixels = current.width * current.height
      return pixels > currentPixels ? (width, height) : current
    }
  }

  private func unavailableReceiptCameraCapabilities() -> [String: Any] {
    return [
      "engine": "avFoundation",
      "available": false,
      "cameraPermissionGranted": AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
      "cameraCount": 0,
      "hasRearCamera": false,
      "hasFrontCamera": false
    ]
  }

  private func openReceiptCamera(result: @escaping FlutterResult, arguments: [String: Any]?) {
    if pendingReceiptCameraResult != nil {
      result(FlutterError(
        code: "native_camera_busy",
        message: "Maintainiac receipt camera is already open.",
        details: nil
      ))
      return
    }
    if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
      result(FlutterError(
        code: "native_camera_permission",
        message: "Camera permission is needed to photograph receipts.",
        details: nil
      ))
      return
    }
    guard let presenter = topReceiptCameraPresenter() else {
      result(FlutterError(
        code: "native_camera_no_presenter",
        message: "Maintainiac could not open the receipt camera screen.",
        details: nil
      ))
      return
    }
    pendingReceiptCameraResult = result
    let controller = ReceiptCameraViewController(arguments: arguments ?? [:])
    controller.onCancel = { [weak self] closeAction in
      guard let self else { return }
      let pending = self.pendingReceiptCameraResult
      self.pendingReceiptCameraResult = nil
      pending?(FlutterError(
        code: "native_camera_cancelled",
        message: "Receipt photo capture was cancelled.",
        details: ["closeAction": closeAction]
      ))
    }
    controller.onCapture = { [weak self] paths, capturedAt, diagnostics in
      guard let self else { return }
      let pending = self.pendingReceiptCameraResult
      self.pendingReceiptCameraResult = nil
      pending?([
        "originalPhotoPaths": paths,
        "temporaryCaptureIds": paths.map { URL(fileURLWithPath: $0).lastPathComponent },
        "capturedAt": capturedAt,
        "captureDiagnostics": diagnostics
      ])
    }
    presenter.present(controller, animated: true)
  }

  private func topReceiptCameraPresenter() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let root = scene?.windows.first { $0.isKeyWindow }?.rootViewController
      ?? window?.rootViewController
    var presenter = root
    while let presented = presenter?.presentedViewController {
      presenter = presented
    }
    return presenter
  }
}
