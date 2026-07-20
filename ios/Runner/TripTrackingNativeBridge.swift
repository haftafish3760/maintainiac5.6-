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
  private var trackingStartedAt: Date?
  private var activityRecognitionEnabled = false
  private var activityRecognitionGeneration = 0
  private var activityRecognitionUnavailableReported = false
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
    // Toggling system Location Services can be reported alongside an
    // authorization transition. Retire immediately instead of waiting for a
    // timer or a future coordinate callback that may never arrive.
    if tracking && stopForLocationServicesDisabledIfNeeded() { return }
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
      stopNativeCollection()
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
    guard tracking, let trackingStartedAt else { return }
    if stopForLocationServicesDisabledIfNeeded() { return }
    if stopForCriticalBatteryIfNeeded() { return }
    for location in locations {
      // The delegate is shared across collection sessions. A callback queued
      // before stopUpdatingLocation can arrive after a new start, so do not
      // treat a coordinate predating this collector as current-trip evidence.
      guard location.timestamp >= trackingStartedAt else { continue }
      guard CLLocationCoordinate2DIsValid(location.coordinate),
            location.horizontalAccuracy > 0,
            location.horizontalAccuracy.isFinite,
            location.timestamp.timeIntervalSince1970 > 0 else { continue }
      let reportedSpeed = location.speed >= 0 && location.speed.isFinite
        ? location.speed
        : nil
      let reportedSpeedAccuracy = location.speedAccuracy >= 0 && location.speedAccuracy.isFinite
        ? location.speedAccuracy
        : nil
      let reportedBearing = location.course >= 0 &&
        location.course.isFinite && location.course < 360
        ? location.course
        : nil
      let simulated = isSimulatedLocation(location)
      emit([
        "type": "location",
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "recordedAt": ISO8601DateFormatter().string(from: location.timestamp),
        "horizontalAccuracyMeters": location.horizontalAccuracy,
        "speedMetersPerSecond": reportedSpeed ?? NSNull(),
        "speedAccuracyMetersPerSecond": reportedSpeedAccuracy ?? NSNull(),
        "bearingDegrees": reportedBearing ?? NSNull(),
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
      stopNativeCollection()
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
    stopNativeCollection()
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
      stopNativeCollection()
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
    guard CLLocationManager.locationServicesEnabled() else {
      result(FlutterError(code: "trip_tracking_gps_unavailable", message: "Device location is unavailable. Turn on Location Services before starting trip tracking.", details: nil))
      return
    }
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
    // Core Location may return a cached fix as soon as collection starts.
    // Mark this native collector live first so the first credible fix is not
    // discarded solely because the start callback and delegate race.
    trackingStartedAt = Date()
    tracking = true
    locationManager.startUpdatingLocation()
    setActivityRecognitionEnabled(activityEnabled)
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
    let eligible = activityRecognitionIsEligible()
    let shouldEnable = enabled && eligible
    if enabled && !eligible {
      if !activityRecognitionUnavailableReported {
        activityRecognitionUnavailableReported = true
        emit([
          "type": "error",
          "errorCode": "trip_tracking_activity_unavailable",
          "errorMessage": "Motion activity permission is unavailable for GPS-assisted stop evidence.",
        ])
      }
    } else {
      activityRecognitionUnavailableReported = false
    }
    guard shouldEnable != activityRecognitionEnabled else { return }
    // Core Motion callbacks can be queued across stop/start boundaries. A
    // new consent window gets a new generation so a delayed walking signal
    // cannot influence a later tracking session or re-enabled sensor.
    activityRecognitionGeneration += 1
    let generation = activityRecognitionGeneration
    activityRecognitionEnabled = shouldEnable
    guard shouldEnable else {
      motionManager.stopActivityUpdates()
      return
    }
    motionManager.startActivityUpdates(to: .main) { [weak self] motion in
      guard let self,
            self.activityRecognitionEnabled,
            self.activityRecognitionGeneration == generation,
            let motion else { return }
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

  private func activityRecognitionIsEligible() -> Bool {
    guard CMMotionActivityManager.isActivityAvailable() else { return false }
    if #available(iOS 11.0, *) {
      // `notDetermined` must remain eligible to start: Core Motion presents
      // its one-time authorization prompt on first use. Only a known denial
      // or system restriction means motion assistance cannot be requested.
      let status = CMMotionActivityManager.authorizationStatus()
      return status != .denied && status != .restricted
    }
    return true
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
      if self.stopForLocationServicesDisabledIfNeeded() { return }
      if self.stopForCriticalBatteryIfNeeded() { return }
      if self.activityRecognitionEnabled && !self.activityRecognitionIsEligible() {
        self.setActivityRecognitionEnabled(true)
      }
      // Liveness only. No coordinates, sensor evidence, stops, or mileage
      // leave the native bridge in this status event.
      self.emit(["type": "status", "status": "tracking"])
    }
  }

  private func stopHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
  }

  /// Core Location can stop delivering fixes when system Location Services is
  /// switched off. Treat that as an interrupted collector rather than leaving
  /// the Dart session falsely healthy until a future callback happens.
  private func stopForLocationServicesDisabledIfNeeded() -> Bool {
    guard !CLLocationManager.locationServicesEnabled() else { return false }
    stopNativeCollection()
    emit([
      "type": "error",
      "errorCode": "trip_tracking_gps_disabled",
      "errorMessage": "Device location was turned off while tracking.",
    ])
    return true
  }

  /// Retire the collector before telling Core Location or Core Motion to stop.
  /// Both frameworks may have a buffered callback already queued, and a late
  /// callback must never influence a completed or replacement Dart session.
  private func stopNativeCollection() {
    tracking = false
    trackingStartedAt = nil
    stopHeartbeat()
    locationManager.stopUpdatingLocation()
    setActivityRecognitionEnabled(false)
  }

  private func capabilities() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return [
      "schemaVersion": 1,
      "locationAvailable": CLLocationManager.locationServicesEnabled(),
      "backgroundTrackingAvailable": true,
      "activityRecognitionAvailable": activityRecognitionIsEligible(),
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
    stopNativeCollection()
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
