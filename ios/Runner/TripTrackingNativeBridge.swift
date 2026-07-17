import CoreLocation
import CoreMotion
import Flutter
import UIKit

private let tripTrackingCommandChannel = "maintainiac/trip_tracking/commands"
private let tripTrackingEventChannel = "maintainiac/trip_tracking/events"

/// Native source for location samples. It does not estimate distance or decide
/// trip boundaries; those rules remain in the tested Dart trip engine.
final class TripTrackingNativeBridge: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private let motionManager = CMMotionActivityManager()
  private var eventSink: FlutterEventSink?
  private var pendingAuthorizationResult: FlutterResult?
  private var requestedBackgroundAuthorization = false
  private var backgroundAuthorizationRequested = false
  private var tracking = false

  override init() {
    super.init()
    locationManager.delegate = self
  }

  func register(with pluginRegistry: FlutterPluginRegistry) {
    guard let registrar = pluginRegistry.registrar(forPlugin: "TripTrackingNativePlugin") else {
      return
    }
    let commands = FlutterMethodChannel(
      name: tripTrackingCommandChannel,
      binaryMessenger: registrar.messenger()
    )
    commands.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    let events = FlutterEventChannel(
      name: tripTrackingEventChannel,
      binaryMessenger: registrar.messenger()
    )
    events.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emit(["type": "status", "status": tracking ? "tracking" : "idle"])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let authorization = authorizationMap()
    emit(["type": "authorization"] .merging(authorization) { _, latest in latest })
    let state = authorization["state"] as? String
    if tracking && (state == "denied" || state == "restricted") {
      locationManager.stopUpdatingLocation()
      motionManager.stopActivityUpdates()
      tracking = false
      emit([
        "type": "error",
        "errorCode": "trip_tracking_location_denied",
        "errorMessage": "Location permission was removed while tracking.",
      ])
    }
    guard let result = pendingAuthorizationResult else { return }
    if state == "whileInUse" && requestedBackgroundAuthorization && !backgroundAuthorizationRequested {
      backgroundAuthorizationRequested = true
      locationManager.requestAlwaysAuthorization()
      return
    }
    if state != "notDetermined" {
      pendingAuthorizationResult = nil
      result(authorization)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations where location.horizontalAccuracy >= 0 {
      let simulated = isSimulatedLocation(location)
      emit([
        "type": "location",
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "recordedAt": ISO8601DateFormatter().string(from: location.timestamp),
        "horizontalAccuracyMeters": location.horizontalAccuracy,
        "speedMetersPerSecond": location.speed >= 0 ? location.speed : NSNull(),
        "mockedLocation": simulated,
      ])
    }
  }

  private func isSimulatedLocation(_ location: CLLocation) -> Bool {
    if #available(iOS 15.0, *) {
      return location.sourceInformation?.isSimulatedBySoftware == true
    }
    return false
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let locationError = error as? CLError, locationError.code == .denied {
      locationManager.stopUpdatingLocation()
      motionManager.stopActivityUpdates()
      tracking = false
      emit([
        "type": "error",
        "errorCode": "trip_tracking_location_denied",
        "errorMessage": "Location permission was removed while tracking.",
      ])
      return
    }
    emit([
      "type": "error",
      "errorCode": "trip_tracking_location_error",
      "errorMessage": error.localizedDescription,
    ])
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "readCapabilities":
      result(capabilities())
    case "readBatterySnapshot":
      result(batterySnapshot())
    case "requestAuthorization":
      requestAuthorization(call, result: result)
    case "start":
      start(call, result: result)
    case "update":
      update(call, result: result)
    case "stop":
      locationManager.stopUpdatingLocation()
      motionManager.stopActivityUpdates()
      tracking = false
      emit(["type": "status", "status": "stopped"])
      result(nil)
    case "isTracking":
      result(tracking)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAuthorization(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if pendingAuthorizationResult != nil {
      result(FlutterError(code: "trip_tracking_permission_busy", message: "A location permission request is already active.", details: nil))
      return
    }
    let allowBackground = (call.arguments as? [String: Any])?["allowBackground"] as? Bool == true
    let current = authorizationMap()
    let state = current["state"] as? String
    if state == "always" || (!allowBackground && state == "whileInUse") {
      result(current)
      return
    }
    if state == "denied" || state == "restricted" {
      result(current)
      return
    }
    pendingAuthorizationResult = result
    requestedBackgroundAuthorization = allowBackground
    backgroundAuthorizationRequested = false
    // Apple requires foreground authorization before escalation to Always.
    // Requesting in this order keeps the system prompt tied to the active trip.
    if state == "whileInUse" && allowBackground {
      backgroundAuthorizationRequested = true
      locationManager.requestAlwaysAuthorization()
    } else {
      locationManager.requestWhenInUseAuthorization()
    }
  }

  private func start(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let authorization = authorizationMap()
    let state = authorization["state"] as? String
    guard state == "whileInUse" || state == "always" else {
      result(FlutterError(code: "trip_tracking_location_denied", message: "Location permission is required before starting trip tracking.", details: authorization))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let profile = arguments?["profile"] as? String
    let intervalMillis = (arguments?["intervalMillis"] as? NSNumber)?.int64Value ?? 5000
    let displacement = arguments?["minimumDisplacementMeters"] as? Double ?? 5
    let activityEnabled = arguments?["activityRecognitionEnabled"] as? Bool ?? false
    applySampling(intervalMillis: intervalMillis, displacement: displacement)
    locationManager.activityType = isRoadStyleProfile(profile) ? .automotiveNavigation : .otherNavigation
    locationManager.pausesLocationUpdatesAutomatically = false
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = state == "always"
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = state == "always"
    }
    locationManager.startUpdatingLocation()
    if activityEnabled && CMMotionActivityManager.isActivityAvailable() {
      motionManager.startActivityUpdates(to: .main) { [weak self] motion in
        guard let self, let motion else { return }
        self.emit([
          "type": "activity",
          "activity": self.tripActivity(for: motion),
          "confidence": self.confidence(for: motion.confidence),
          "recordedAt": ISO8601DateFormatter().string(from: motion.startDate),
        ])
      }
    }
    tracking = true
    emit(["type": "status", "status": "tracking"])
    result(true)
  }

  private func update(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard tracking else {
      result(false)
      return
    }
    let arguments = call.arguments as? [String: Any]
    let intervalMillis = (arguments?["intervalMillis"] as? NSNumber)?.int64Value ?? 5000
    let displacement = arguments?["minimumDisplacementMeters"] as? Double ?? 5
    applySampling(intervalMillis: intervalMillis, displacement: displacement)
    result(true)
  }

  private func isRoadStyleProfile(_ profile: String?) -> Bool {
    switch profile {
    case "roadVehicle", "rideshareVehicle", "deliveryVehicle", "contractorVehicle":
      return true
    default:
      return false
    }
  }

  /// Core Location has no fixed polling interval. The requested interval is
  /// translated into an accuracy tier while the displacement filter remains
  /// the hard movement bound. This keeps economy/balanced/precision requests
  /// meaningful on iOS without inventing timer-based location samples.
  private func applySampling(intervalMillis: Int64, displacement: Double) {
    let boundedInterval = min(max(intervalMillis, 1000), 60000)
    if boundedInterval <= 2500 {
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    } else if boundedInterval <= 7000 {
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    } else {
      locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    locationManager.distanceFilter = max(0, displacement)
  }

  private func capabilities() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    [
      "locationAvailable": CLLocationManager.locationServicesEnabled(),
      "backgroundTrackingAvailable": true,
      "activityRecognitionAvailable": CMMotionActivityManager.isActivityAvailable(),
      "batteryStateAvailable": UIDevice.current.batteryState != .unknown,
      "lowPowerModeAvailable": true,
    ]
  }

  private func batterySnapshot() -> [String: Any?] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel
    let percent: Int? = batteryLevel >= 0 ? Int(round(batteryLevel * 100)) : nil
    return [
      "batteryPercent": percent,
      "isCharging": UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full,
      "lowPowerModeEnabled": ProcessInfo.processInfo.isLowPowerModeEnabled,
    ]
  }

  private func authorizationMap() -> [String: Any] {
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    let state: String
    switch status {
    case .authorizedAlways: state = "always"
    case .authorizedWhenInUse: state = "whileInUse"
    case .denied: state = "denied"
    case .restricted: state = "restricted"
    default: state = "notDetermined"
    }
    let precise: Bool
    if #available(iOS 14.0, *) {
      precise = locationManager.accuracyAuthorization == .fullAccuracy
    } else {
      precise = true
    }
    return ["state": state, "preciseLocation": precise]
  }

  private func emit(_ event: [String: Any]) {
    eventSink?(event)
  }

  private func tripActivity(for motion: CMMotionActivity) -> String {
    if motion.automotive { return "automotive" }
    if motion.walking { return "walking" }
    if motion.running { return "running" }
    if motion.cycling { return "cycling" }
    if motion.stationary { return "still" }
    return "unknown"
  }

  private func confidence(for confidence: CMMotionActivityConfidence) -> Int {
    switch confidence {
    case .high: return 90
    case .medium: return 60
    case .low: return 30
    @unknown default: return 0
    }
  }
}
