import AVFoundation
import CoreBluetooth
import CoreMotion
import Flutter
import Metal
import Network
import UIKit
import VideoToolbox

final class DeviceCapabilityBridge {
  private let events = DeviceCapabilityEvents()
  private let pathMonitor = NWPathMonitor()
  private let pathQueue = DispatchQueue(label: "com.maintainiac.device-capability-network")
  private let pathLock = NSLock()
  private var latestPath: NWPath?

  init() {
    pathMonitor.pathUpdateHandler = { [weak self] path in
      self?.pathLock.lock()
      self?.latestPath = path
      self?.pathLock.unlock()
    }
    pathMonitor.start(queue: pathQueue)
  }

  deinit {
    pathMonitor.cancel()
  }

  func register(with pluginRegistry: FlutterPluginRegistry) {
    guard let registrar = pluginRegistry.registrar(forPlugin: "DeviceCapabilityPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(
          code: "device_capability_unavailable",
          message: "Maintainiac device capability bridge is unavailable.",
          details: nil
        ))
        return
      }
      switch call.method {
      case "readRuntimeCapabilities":
        result(self.readRuntimeCapabilities())
      case "readCameraCapabilities":
        result(self.readCameraSummary())
      case "readExtendedCapabilities":
        result(self.readExtendedCapabilities())
      case "readDynamicCapabilities":
        result(self.readDynamicCapabilities())
      case "readBluetoothCapabilities":
        result(self.readBluetoothCapabilities())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    events.register(with: registrar.messenger())
  }

  private func readRuntimeCapabilities() -> [String: Any] {
    let processInfo = ProcessInfo.processInfo
    return [
      "physicalRamMb": Int(processInfo.physicalMemory / 1_048_576),
      "powerSaving": processInfo.isLowPowerModeEnabled,
      "thermalState": thermalStateName(processInfo.thermalState)
    ]
  }

  private func readExtendedCapabilities() -> [String: Any] {
    return [
      "cameraLenses": readCameraLenses(),
      "sensors": readSensors(),
      "battery": readBattery(),
      "display": readDisplay(),
      "media": readMedia(),
      "graphics": readGraphics(),
      "connectivity": readConnectivity()
    ]
  }

  private func readDynamicCapabilities() -> [String: Any] {
    return [
      "battery": readBattery(),
      "connectivity": readConnectivity()
    ]
  }

  private func readBluetoothCapabilities() -> [String: Any] {
    let authorization: String
    switch CBCentralManager.authorization {
    case .allowedAlways:
      authorization = "authorized"
    case .denied:
      authorization = "denied"
    case .restricted:
      authorization = "restricted"
    case .notDetermined:
      authorization = "notRequested"
    @unknown default:
      authorization = "unknown"
    }
    return [
      "adapterAvailable": true,
      // Do not create a central manager or prompt merely to populate a
      // capabilities screen. A user-approved adapter owns live observation.
      "poweredOn": false,
      "authorization": authorization,
      "supportsApprovedDeviceObservation": false
    ]
  }

  private func cameraDevices() -> [AVCaptureDevice] {
    let types: [AVCaptureDevice.DeviceType] = [
      .builtInWideAngleCamera,
      .builtInUltraWideCamera,
      .builtInTelephotoCamera,
      .builtInDualCamera,
      .builtInDualWideCamera,
      .builtInTripleCamera,
      .builtInTrueDepthCamera,
      .builtInLiDARDepthCamera
    ]
    return AVCaptureDevice.DiscoverySession(
      deviceTypes: types,
      mediaType: .video,
      position: .unspecified
    ).devices
  }

  private func readCameraSummary() -> [String: Any] {
    let devices = cameraDevices()
    let dimensions = devices.map(maxStillDimensions)
    return [
      "available": !devices.isEmpty,
      "cameraCount": devices.count,
      "hasRearCamera": devices.contains { $0.position == .back },
      "hasFrontCamera": devices.contains { $0.position == .front },
      "supportsTapFocus": devices.contains { $0.isFocusPointOfInterestSupported },
      "supportsContinuousFocus": devices.contains {
        $0.isFocusModeSupported(.continuousAutoFocus)
      },
      "supportsExposureCompensation": devices.contains {
        $0.maxExposureTargetBias > $0.minExposureTargetBias
      },
      "supportsZoom": devices.contains { $0.maxAvailableVideoZoomFactor > 1 },
      "supportsMacroSelection": devices.contains { $0.deviceType == .builtInUltraWideCamera },
      "supportsTorch": devices.contains { $0.hasTorch },
      "supportsRaw": false,
      "maxStillWidth": dimensions.map(\.width).max() ?? 0,
      "maxStillHeight": dimensions.map(\.height).max() ?? 0
    ]
  }

  private func readCameraLenses() -> [[String: Any]] {
    return cameraDevices().map { device in
      let dimensions = maxStillDimensions(device)
      let maxFps = device.formats.flatMap(\.videoSupportedFrameRateRanges)
        .map(\.maxFrameRate).max() ?? 0
      return [
        "position": positionName(device.position),
        "lensType": lensType(device.deviceType),
        "physicalLensCount": max(1, device.constituentDevices.count),
        "maxStillWidth": dimensions.width,
        "maxStillHeight": dimensions.height,
        "maxOpticalOrSensorZoom": device.virtualDeviceSwitchOverVideoZoomFactors.last?.doubleValue ?? 1,
        "maxDigitalZoom": Double(device.maxAvailableVideoZoomFactor),
        "maxVideoFps": Int(maxFps.rounded()),
        "supportsAutofocus": device.isFocusModeSupported(.autoFocus) ||
          device.isFocusModeSupported(.continuousAutoFocus),
        "supportsStabilization": false,
        "supportsRaw": false,
        "supportsDepth": device.formats.contains { !$0.supportedDepthDataFormats.isEmpty },
        "supportsHdr": device.formats.contains(where: \.isVideoHDRSupported)
      ]
    }
  }

  private func maxStillDimensions(_ device: AVCaptureDevice) -> (width: Int, height: Int) {
    var best = (width: 0, height: 0)
    for format in device.formats {
      let dimensions: CMVideoDimensions
      if #available(iOS 16.0, *), let maximum = format.supportedMaxPhotoDimensions.max(by: {
        Int64($0.width) * Int64($0.height) < Int64($1.width) * Int64($1.height)
      }) {
        dimensions = maximum
      } else {
        dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      }
      if Int64(dimensions.width) * Int64(dimensions.height) > Int64(best.width) * Int64(best.height) {
        best = (Int(dimensions.width), Int(dimensions.height))
      }
    }
    return best
  }

  private func positionName(_ position: AVCaptureDevice.Position) -> String {
    switch position {
    case .back: return "rear"
    case .front: return "front"
    case .unspecified: return "unknown"
    @unknown default: return "unknown"
    }
  }

  private func lensType(_ type: AVCaptureDevice.DeviceType) -> String {
    switch type {
    case .builtInUltraWideCamera: return "ultrawide"
    case .builtInTelephotoCamera: return "telephoto"
    case .builtInTrueDepthCamera: return "true_depth"
    case .builtInLiDARDepthCamera: return "lidar"
    case .builtInDualCamera: return "dual"
    case .builtInDualWideCamera: return "dual_wide"
    case .builtInTripleCamera: return "triple"
    case .builtInWideAngleCamera: return "wide"
    default: return "unknown"
    }
  }

  private func readSensors() -> [String: Any] {
    let motion = CMMotionManager()
    var types: [String] = []
    if motion.isAccelerometerAvailable { types.append("accelerometer") }
    if motion.isGyroAvailable { types.append("gyroscope") }
    if motion.isMagnetometerAvailable { types.append("magnetometer") }
    if motion.isDeviceMotionAvailable { types.append("device_motion") }
    if CMPedometer.isStepCountingAvailable() { types.append("step_counter") }
    if CMPedometer.isDistanceAvailable() { types.append("walking_distance") }
    if CMPedometer.isFloorCountingAvailable() { types.append("floor_counting") }
    if CMPedometer.isPaceAvailable() { types.append("walking_pace") }
    if CMPedometer.isCadenceAvailable() { types.append("walking_cadence") }
    if CMPedometer.isPedometerEventTrackingAvailable() {
      types.append("pedometer_event_tracking")
    }
    if CMMotionActivityManager.isActivityAvailable() {
      types.append("activity_recognition")
    }
    if CMAltimeter.isRelativeAltitudeAvailable() {
      types.append("barometer")
      types.append("relative_altitude")
    }
    return ["sensorCount": types.count, "types": types]
  }

  private func readBattery() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let state = UIDevice.current.batteryState
    let charging = state == .charging || state == .full
    return [
      "levelPercent": level >= 0 ? Int((level * 100).rounded()) : -1,
      "isCharging": charging,
      "isExternalPowerConnected": charging,
      "powerSource": charging ? "external" : "battery",
      "health": "unknown",
      "capacityEstimateReliable": false
    ]
  }

  private func readDisplay() -> [String: Any] {
    let screen = UIScreen.main
    let bounds = screen.nativeBounds
    let supportsHdr: Bool
    if #available(iOS 16.0, *) {
      supportsHdr = screen.potentialEDRHeadroom > 1
    } else {
      supportsHdr = false
    }
    return [
      "widthPixels": Int(bounds.width.rounded()),
      "heightPixels": Int(bounds.height.rounded()),
      "densityScale": Double(screen.nativeScale),
      "maxRefreshRateHz": Double(screen.maximumFramesPerSecond),
      "supportsHdr": supportsHdr,
      "supportsWideColor": screen.traitCollection.displayGamut == .P3
    ]
  }

  private func readMedia() -> [String: Any] {
    let codecs: [(String, CMVideoCodecType)] = [
      ("h264", kCMVideoCodecType_H264),
      ("hevc", kCMVideoCodecType_HEVC),
      ("vp9", fourCC("vp09")),
      ("av1", fourCC("av01"))
    ]
    return [
      "hardwareDecodeTypes": codecs.compactMap {
        VTIsHardwareDecodeSupported($0.1) ? $0.0 : nil
      },
      "hardwareEncodeTypes": hardwareEncoderTypes()
    ]
  }

  private func hardwareEncoderTypes() -> [String] {
    var rawEncoders: CFArray?
    guard VTCopyVideoEncoderList(nil, &rawEncoders) == noErr,
          let encoders = rawEncoders as? [[CFString: Any]] else {
      return []
    }
    return Array(Set(encoders.compactMap { encoder in
      guard encoder[kVTVideoEncoderList_IsHardwareAccelerated] as? Bool == true,
            let number = encoder[kVTVideoEncoderList_CodecType] as? NSNumber else {
        return nil
      }
      return codecName(CMVideoCodecType(number.uint32Value))
    })).sorted()
  }

  private func codecName(_ value: CMVideoCodecType) -> String? {
    switch value {
    case kCMVideoCodecType_H264: return "h264"
    case kCMVideoCodecType_HEVC: return "hevc"
    case fourCC("vp09"): return "vp9"
    case fourCC("av01"): return "av1"
    default: return nil
    }
  }

  private func fourCC(_ value: String) -> CMVideoCodecType {
    return value.utf8.reduce(0) { ($0 << 8) | CMVideoCodecType($1) }
  }

  private func readGraphics() -> [String: Any] {
    guard let device = MTLCreateSystemDefaultDevice() else {
      return [
        "apiName": "unknown",
        "apiVersion": "unknown",
        "featureLevel": "unknown",
        "supportsCompute": false,
        "supportsRayTracing": false
      ]
    }
    let families: [(String, MTLGPUFamily)] = [
      ("apple10", .apple10), ("apple9", .apple9), ("apple8", .apple8),
      ("apple7", .apple7), ("apple6", .apple6), ("apple5", .apple5),
      ("apple4", .apple4), ("apple3", .apple3), ("apple2", .apple2),
      ("apple1", .apple1)
    ]
    return [
      "apiName": "metal",
      "apiVersion": "current",
      "featureLevel": families.first { device.supportsFamily($0.1) }?.0 ?? "unknown",
      "supportsCompute": true,
      "supportsRayTracing": device.supportsRaytracing
    ]
  }

  private func readConnectivity() -> [String: Any] {
    pathLock.lock()
    let path = latestPath
    pathLock.unlock()
    var transports: [String] = []
    if path?.usesInterfaceType(.wifi) == true { transports.append("wifi") }
    if path?.usesInterfaceType(.cellular) == true { transports.append("cellular") }
    if path?.usesInterfaceType(.wiredEthernet) == true { transports.append("ethernet") }
    return [
      "transports": transports,
      "isConnected": path?.status == .satisfied,
      "isMetered": path?.isExpensive ?? false,
      "isConstrained": path?.isConstrained ?? false
    ]
  }

  private func thermalStateName(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
  }

  private static let channelName = "maintainiac/device_capabilities"
}
