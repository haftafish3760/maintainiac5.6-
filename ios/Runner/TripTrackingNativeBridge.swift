import CoreLocation
import CoreMotion
import Flutter
import UIKit

private let tripTrackingCommandChannel = "maintainiac/trip_tracking/commands"
private let tripTrackingEventChannel = "maintainiac/trip_tracking/events"

/// Native source for location samples. It does not estimate distance or decide
/// trip boundaries; those rules remain in the tested Dart trip engine.
final class TripTrackingNativeBridge: NSObject, FlutterStreamHandler {
  let locationManager = CLLocationManager()
  private let motionManager = CMMotionActivityManager()
  private let pedometer = CMPedometer()
  private var eventSink: FlutterEventSink?
  var pendingAuthorizationResult: FlutterResult?
  var requestedBackgroundAuthorization = false
  var backgroundAuthorizationRequested = false
  var tracking = false
  // Separate from a driver-approved trip. This mode emits only dedicated
  // possible-drive evidence for App Assistant review.
  var automaticEvidenceObserving = false
  // Core Location has no registration-success callback equivalent to Android's
  // fused provider. A credible delegate callback is the first evidence that
  // the requested collector is actually live.
  var providerRegistered = false
  var trackingStartedAt: Date?
  var automaticEvidenceStartedAt: Date?
  private var activityRecognitionEnabled = false
  private var activityRecognitionGeneration = 0
  private var activityRecognitionUnavailableReported = false
  private var pedometerBaselineSteps: Int?
  private var lastPedometerEvidenceSteps = 0
  private var heartbeatTimer: Timer?

  override init() {
    super.init()
    locationManager.delegate = self
  }

  deinit {
    // A Flutter engine/plugin replacement must not leave Core Location or
    // Core Motion running without the Dart controller that owns persistence.
    stopNativeCollection()
    locationManager.delegate = nil
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
    let status = tracking
      ? (providerRegistered ? "tracking" : "starting")
      : automaticEvidenceObserving ? "automatic_evidence_observing" : "idle"
    emit(["type": "status", "status": status])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
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
    case "startAutomaticEvidence":
      startAutomaticEvidence(result: result)
    case "stopAutomaticEvidence":
      stopAutomaticEvidenceObservation()
      result(nil)
    case "isAutomaticEvidenceRunning":
      result(automaticEvidenceObserving)
    case "update":
      update(call, result: result)
    case "stop":
      stopNativeCollection()
      emit(["type": "status", "status": "stopped"])
      result(nil)
    case "isTracking":
      result(tracking)
    case "consumeRecoveryStatus":
      // iOS has no native notification action that pauses this collector while
      // Dart is detached. Keep the cross-platform recovery contract explicit.
      result(nil)
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
    guard !tracking else {
      result(FlutterError(code: "trip_tracking_native_already_running", message: "A GPS collector is already running. Recover or stop it before starting another trip.", details: nil))
      return
    }
    // A user-approved trip owns the sole native location collector. Retire any
    // lower-frequency possible-drive observer before starting that session.
    stopAutomaticEvidenceObservation()
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
    let arguments = call.arguments as? [String: Any]
    let profile = arguments?["profile"] as? String
    let allowBackground = arguments?["allowBackground"] as? Bool ?? false
    guard state == "always" || (!allowBackground && state == "whileInUse") else {
      result(FlutterError(code: "trip_tracking_background_location_denied", message: "Background location permission is required for this tracking mode.", details: authorization))
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
    providerRegistered = false
    locationManager.startUpdatingLocation()
    setActivityRecognitionEnabled(activityEnabled)
    emit(["type": "status", "status": "starting"])
    result(true)
  }

  private func startAutomaticEvidence(result: @escaping FlutterResult) {
    guard !tracking else {
      result(false)
      return
    }
    if automaticEvidenceObserving {
      result(true)
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result(false)
      return
    }
    let authorization = authorizationMap()
    guard authorization["state"] as? String == "always" else {
      // Do not request permissions implicitly from a background observer.
      result(false)
      return
    }
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager.distanceFilter = 30
    locationManager.activityType = .automotiveNavigation
    locationManager.pausesLocationUpdatesAutomatically = true
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = true
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = true
    }
    automaticEvidenceStartedAt = Date()
    automaticEvidenceObserving = true
    locationManager.startUpdatingLocation()
    result(true)
  }

  private func stopAutomaticEvidenceObservation() {
    guard automaticEvidenceObserving else { return }
    automaticEvidenceObserving = false
    automaticEvidenceStartedAt = nil
    guard !tracking else { return }
    locationManager.stopUpdatingLocation()
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = false
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = false
    }
  }

  private func update(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard tracking else {
      result(false)
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result(FlutterError(code: "trip_tracking_gps_unavailable", message: "Device location is unavailable. Turn on Location Services before updating trip tracking.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let intervalMillis = (arguments?["intervalMillis"] as? NSNumber)?.int64Value ?? 5000
    let displacement = arguments?["minimumDisplacementMeters"] as? Double ?? 5
    let allowBackground = arguments?["allowBackground"] as? Bool ?? false
    let activityEnabled = arguments?["activityRecognitionEnabled"] as? Bool ?? false
    let authorization = authorizationMap()
    let state = authorization["state"] as? String
    guard state == "whileInUse" || state == "always" else {
      result(FlutterError(code: "trip_tracking_location_denied", message: "Location permission is required before updating trip tracking.", details: authorization))
      return
    }
    guard state == "always" || (!allowBackground && state == "whileInUse") else {
      result(FlutterError(code: "trip_tracking_background_location_denied", message: "Background location permission is required for this tracking mode.", details: authorization))
      return
    }
    applySampling(intervalMillis: intervalMillis, displacement: displacement)
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = allowBackground && state == "always"
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = allowBackground && state == "always"
    }
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
      pedometer.stopUpdates()
      pedometerBaselineSteps = nil
      lastPedometerEvidenceSteps = 0
      return
    }
    motionManager.startActivityUpdates(to: .main) { [weak self] motion in
      guard let self,
            self.activityRecognitionEnabled,
            self.activityRecognitionGeneration == generation,
            let trackingStartedAt = self.trackingStartedAt,
            let motion else { return }
      let observedAt = motion.startDate
      let now = Date()
      guard observedAt >= trackingStartedAt,
            observedAt.timeIntervalSince1970 > 0,
            observedAt >= now.addingTimeInterval(-120),
            observedAt <= now.addingTimeInterval(120) else { return }
      self.emit([
        "type": "activity",
        "activity": self.tripActivity(for: motion),
        "confidence": self.confidence(for: motion.confidence),
        "recordedAt": ISO8601DateFormatter().string(from: observedAt),
      ])
    }
    startPedometerWalkingEvidence(generation: generation)
  }

  /// CMMotionActivity reports state transitions and may emit only one
  /// "walking began" callback. Step-count updates provide bounded persistence
  /// evidence so the Dart debounce policy can require multiple observations
  /// without depending on duplicate activity callbacks. No step totals leave
  /// this bridge; emitted walking observations remain advisory-only.
  private func startPedometerWalkingEvidence(generation: Int) {
    pedometer.stopUpdates()
    pedometerBaselineSteps = nil
    lastPedometerEvidenceSteps = 0
    guard CMPedometer.isStepCountingAvailable() else { return }
    pedometer.startUpdates(from: Date()) { [weak self] data, _ in
      guard let self, let data else { return }
      DispatchQueue.main.async { [weak self] in
        guard let self,
              self.activityRecognitionEnabled,
              self.activityRecognitionGeneration == generation,
              let trackingStartedAt = self.trackingStartedAt else { return }
        let totalSteps = data.numberOfSteps.intValue
        if self.pedometerBaselineSteps == nil {
          self.pedometerBaselineSteps = totalSteps
          return
        }
        let walkingSteps = max(0, totalSteps - (self.pedometerBaselineSteps ?? totalSteps))
        guard walkingSteps - self.lastPedometerEvidenceSteps >= 5 else { return }
        let observedAt = data.endDate
        let now = Date()
        guard observedAt >= trackingStartedAt,
              observedAt >= now.addingTimeInterval(-120),
              observedAt <= now.addingTimeInterval(120) else { return }
        self.lastPedometerEvidenceSteps = walkingSteps
        self.emit([
          "type": "activity",
          "activity": "walking",
          "confidence": 90,
          "recordedAt": ISO8601DateFormatter().string(from: observedAt),
        ])
      }
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
      guard let self, self.tracking, self.providerRegistered else { return }
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

  /// Core Location registration is only evidenced by the first credible
  /// delegate callback. This is idempotent because duplicate callbacks must
  /// not restart the heartbeat or create a second live transition.
  func confirmProviderRegistration() {
    guard tracking, !providerRegistered else { return }
    providerRegistered = true
    emit(["type": "status", "status": "tracking"])
    startHeartbeat()
  }

  private func stopHeartbeat() {
    heartbeatTimer?.invalidate()
    heartbeatTimer = nil
  }

  /// Core Location can stop delivering fixes when system Location Services is
  /// switched off. Treat that as an interrupted collector rather than leaving
  /// the Dart session falsely healthy until a future callback happens.
  func stopForLocationServicesDisabledIfNeeded() -> Bool {
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
  func stopNativeCollection() {
    tracking = false
    automaticEvidenceObserving = false
    providerRegistered = false
    trackingStartedAt = nil
    automaticEvidenceStartedAt = nil
    stopHeartbeat()
    locationManager.stopUpdatingLocation()
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = false
    }
    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = false
    }
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
  /// Mirror the hard below-ten-percent safety rule while unplugged without
  /// changing TripLog history or the authoritative odometer.
  func stopForCriticalBatteryIfNeeded() -> Bool {
    let snapshot = batterySnapshot()
    guard snapshot["isCharging"] as? Bool != true,
          let percent = snapshot["batteryPercent"] as? Int,
          percent >= 0,
          percent < 10 else { return false }
    stopNativeCollection()
    emit([
      "type": "error",
      "errorCode": "trip_tracking_battery_critical",
      "errorMessage": "Battery is critically low. Plug in the phone or charge above 10% to resume GPS assistance.",
    ])
    return true
  }

  func authorizationMap() -> [String: Any] {
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

  func emit(_ event: [String: Any]) {
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
