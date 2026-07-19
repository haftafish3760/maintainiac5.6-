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
  private var activityRecognitionEnabled = false
  private var heartbeatTimer: Timer?

  override init() {
    super.init()
    locationManager.delegate = self
  }

  deinit {
    // The timer captures this bridge weakly, but explicit teardown keeps the
    // native liveness loop bounded if Flutter replaces the engine/plugin.
    stopHeartbeat()
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
    let hasPreciseLocation = authorization["preciseLocation"] as? Bool == true
    let canKeepBackgroundTracking = !requestedBackgroundAuthorization || state == "always"
    if tracking && (
      state == "denied" ||
      state == "restricted" ||
      !hasPreciseLocation ||
      !canKeepBackgroundTracking
    ) {
      stopHeartbeat()
      locationManager.stopUpdatingLocation()
      setActivityRecognitionEnabled(false)
      tracking = false
      let errorCode: String
      let errorMessage: String
      if !hasPreciseLocation {
        errorCode = "trip_tracking_location_accuracy_reduced"
        errorMessage = "Precise location was reduced while tracking."
      } else if !canKeepBackgroundTracking {
        errorCode = "trip_tracking_background_location_denied"
        errorMessage = "Background location permission was removed while tracking."
      } else {
        errorCode = "trip_tracking_location_denied"
        errorMessage = "Location permission was removed while tracking."
      }
      emit([
        "type": "error",
        "errorCode": errorCode,
        "errorMessage": errorMessage,
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
    // Core Location can deliver a buffered callback after stopUpdatingLocation.
    // Do not let a retired session emit a late coordinate into Flutter, even
    // though the Dart controller independently rejects inactive-session data.
    guard tracking else { return }
    if stopForCriticalBatteryIfNeeded() { return }
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
    // Ignore deferred Core Location failures from a session that was already
    // stopped or replaced. A late error must not interrupt a newer trip.
    guard tracking else { return }
    if let locationError = error as? CLError, locationError.code == .locationUnknown {
      // Core Location documents this as transient and will keep trying. Do
      // not manufacture a platform error, interruption, or UI alarm from a
      // normal recovery path. The validated next fix remains the evidence.
      return
    }
    if let locationError = error as? CLError, locationError.code == .denied {
      stopHeartbeat()
      locationManager.stopUpdatingLocation()
      setActivityRecognitionEnabled(false)
      tracking = false
      emit([
        "type": "error",
        "errorCode": "trip_tracking_location_denied",
        "errorMessage": "Location permission was removed while tracking.",
      ])
      return
    }
    // Any other Core Location failure leaves the current fix stream
    // indeterminate. End native collection and let the Dart lifecycle keep
    // the local trip recoverable rather than silently continuing with stale
    // state. This never creates mileage, a stop, or an odometer update.
    stopHeartbeat()
    locationManager.stopUpdatingLocation()
    setActivityRecognitionEnabled(false)
    tracking = false
    emit([
      "type": "error",
      "errorCode": "trip_tracking_location_error",
      "errorMessage": "Core Location could not continue trip tracking.",
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
      stopHeartbeat()
      locationManager.stopUpdatingLocation()
      setActivityRecognitionEnabled(false)
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
    guard authorization["preciseLocation"] as? Bool == true else {
      result(FlutterError(code: "trip_tracking_location_accuracy_reduced", message: "Precise location permission is required before starting trip tracking.", details: authorization))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let profile = arguments?["profile"] as? String
    let allowBackground = arguments?["allowBackground"] as? Bool ?? false
    guard state == "always" || (!allowBackground && state == "whileInUse") else {
      result(FlutterError(code: "trip_tracking_location_denied", message: "Background location permission is required for this tracking mode.", details: authorization))
      return
    }
    if stopForCriticalBatteryIfNeeded() {
      result(false)
      return
    }
    let intervalMillis = (arguments?["intervalMillis"] as? NSNumber)?.int64Value ?? 5000
    let displacement = arguments?["minimumDisplacementMeters"] as? Double ?? 5
    let activityEnabled = arguments?["activityRecognitionEnabled"] as? Bool ?? false
    applySampling(intervalMillis: intervalMillis, displacement: displacement)
    locationManager.activityType = isRoadStyleProfile(profile) ? .automotiveNavigation : .otherNavigation
    locationManager.pausesLocationUpdatesAutomatically = false
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = allowBackground && state == "always"
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = allowBackground && state == "always"
    }
    locationManager.startUpdatingLocation()
    setActivityRecognitionEnabled(activityEnabled)
    tracking = true
    emit(["type": "status", "status": "tracking"])
    startHeartbeat()
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
    let activityEnabled = arguments?["activityRecognitionEnabled"] as? Bool ?? false
    applySampling(intervalMillis: intervalMillis, displacement: displacement)
    setActivityRecognitionEnabled(activityEnabled)
    result(true)
  }

  /// Motion assistance is optional stop evidence, never a reason to keep a
  /// sensor live after the driver turns it off. This remains independent from
  /// GPS collection so a privacy opt-out cannot accidentally end a trip.
  private func setActivityRecognitionEnabled(_ enabled: Bool) {
    let shouldEnable = enabled && CMMotionActivityManager.isActivityAvailable()
    guard shouldEnable != activityRecognitionEnabled else { return }
    activityRecognitionEnabled = shouldEnable
    guard shouldEnable else {
      motionManager.stopActivityUpdates()
      return
    }
    motionManager.startActivityUpdates(to: .main) { [weak self] motion in
      guard let self, self.activityRecognitionEnabled, let motion else { return }
      let observedAt = motion.startDate
      guard observedAt.timeIntervalSince1970 > 0,
            observedAt <= Date().addingTimeInterval(120) else { return }
      self.emit([
        "type": "activity",
        "activity": self.tripActivity(for: motion),
        "confidence": self.confidence(for: motion.confidence),
        "recordedAt": ISO8601DateFormatter().string(from: observedAt),
      ])
    }
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
    locationManager.distanceFilter = min(max(1, displacement), 100)
  }

  private func startHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      guard let self, self.tracking else { return }
      if self.stopForCriticalBatteryIfNeeded() { return }
      // Liveness only. No coordinates, sensor evidence, stops, or mileage
      // leave the native bridge in this status event.
      self.emit(["type": "status", "status": "tracking"])
    }
  }

  private func stopHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
  }

  private func capabilities() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return [
      "schemaVersion": 1,
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
      "schemaVersion": 1,
      "batteryPercent": percent,
      "isCharging": UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full,
      "lowPowerModeEnabled": ProcessInfo.processInfo.isLowPowerModeEnabled,
    ]
  }

  /// Core Location can keep running while Dart is background-suspended.
  /// Mirror the hard below-ten-percent safety rule without changing TripLog
  /// history or the authoritative odometer.
  private func stopForCriticalBatteryIfNeeded() -> Bool {
    let snapshot = batterySnapshot()
    guard let percent = snapshot["batteryPercent"] as? Int,
          percent >= 0,
          percent < 10 else { return false }
    stopHeartbeat()
    locationManager.stopUpdatingLocation()
    setActivityRecognitionEnabled(false)
    tracking = false
    emit([
      "type": "error",
      "errorCode": "trip_tracking_battery_critical",
      "errorMessage": "Battery is critically low. GPS-assisted tracking is paused below 10%.",
    ])
    return true
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
    return ["schemaVersion": 1, "state": state, "preciseLocation": precise]
  }

  private func emit(_ event: [String: Any]) {
    eventSink?(event.merging(["schemaVersion": 1]) { _, latest in latest })
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
