import CoreLocation

extension TripTrackingNativeBridge: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if (tracking || automaticEvidenceObserving) && stopForLocationServicesDisabledIfNeeded() { return }
    let authorization = authorizationMap()
    emit(["type": "authorization"] .merging(authorization) { _, latest in latest })
    let state = authorization["state"] as? String
    let canKeepBackgroundTracking = tracking
      ? (!requestedBackgroundAuthorization || state == "always")
      : !automaticEvidenceObserving || state == "always"
    if (tracking || automaticEvidenceObserving) && (
      state == "denied" ||
      state == "restricted" ||
      !canKeepBackgroundTracking
    ) {
      let automaticEvidenceOnly = automaticEvidenceObserving && !tracking
      stopNativeCollection()
      emit([
        "type": "error",
        "errorCode": automaticEvidenceOnly
          ? (canKeepBackgroundTracking
              ? "automatic_evidence_location_denied"
              : "automatic_evidence_background_location_denied")
          : (canKeepBackgroundTracking
              ? "trip_tracking_location_denied"
              : "trip_tracking_background_location_denied"),
        "errorMessage": canKeepBackgroundTracking
          ? "Location permission was removed while tracking."
          : "Background location permission was removed while tracking.",
      ])
    }
    guard let result = pendingAuthorizationResult else { return }
    if state == "whileInUse" &&
      requestedBackgroundAuthorization &&
      !backgroundAuthorizationRequested {
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
    guard tracking || automaticEvidenceObserving else { return }
    let collectionStartedAt = trackingStartedAt ?? automaticEvidenceStartedAt
    guard let collectionStartedAt else { return }
    if stopForLocationServicesDisabledIfNeeded() { return }
    if stopForCriticalBatteryIfNeeded() { return }
    let callbackReceivedAt = Date()
    for location in locations {
      guard location.timestamp >= collectionStartedAt else { continue }
      guard CLLocationCoordinate2DIsValid(location.coordinate),
            location.coordinate.latitude.isFinite,
            location.coordinate.longitude.isFinite,
            location.horizontalAccuracy > 0,
            location.horizontalAccuracy.isFinite,
            location.timestamp.timeIntervalSince1970 > 0,
            location.timestamp <= callbackReceivedAt.addingTimeInterval(120) else { continue }
      if tracking && !providerRegistered {
        // Only a credible Core Location callback proves the collector became
        // live. This precedes the sample event but does not make that sample
        // canonical mileage; Dart still applies its own evidence rules.
        confirmProviderRegistration()
      }
      let reportedSpeed = location.speed >= 0 && location.speed.isFinite
        ? location.speed
        : nil
      let reportedSpeedAccuracy = location.speedAccuracy >= 0 &&
        location.speedAccuracy.isFinite && location.speedAccuracy <= 1000
        ? location.speedAccuracy
        : nil
      let reportedBearing = location.course >= 0 &&
        location.course.isFinite && location.course < 360
        ? location.course
        : nil
      let simulated = isSimulatedLocation(location)
      var event: [String: Any] = [
        "type": tracking ? "location" : "automaticEvidenceLocation",
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "recordedAt": ISO8601DateFormatter().string(from: location.timestamp),
        "horizontalAccuracyMeters": location.horizontalAccuracy,
        "speedMetersPerSecond": reportedSpeed ?? NSNull(),
        "speedAccuracyMetersPerSecond": reportedSpeedAccuracy ?? NSNull(),
        "bearingDegrees": reportedBearing ?? NSNull(),
        "mockedLocation": simulated,
      ]
      if let monotonicElapsedNanos = monotonicElapsedNanos(
        for: location,
        observedAt: callbackReceivedAt
      ) {
        event["monotonicElapsedNanos"] = monotonicElapsedNanos
      }
      emit(event)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard tracking || automaticEvidenceObserving else { return }
    if let locationError = error as? CLError, locationError.code == .locationUnknown {
      return
    }
    if let locationError = error as? CLError, locationError.code == .denied {
      let automaticEvidenceOnly = automaticEvidenceObserving && !tracking
      stopNativeCollection()
      emit([
        "type": "error",
        "errorCode": automaticEvidenceOnly
          ? "automatic_evidence_location_denied"
          : "trip_tracking_location_denied",
        "errorMessage": "Location permission was removed while tracking.",
      ])
      return
    }
    let automaticEvidenceOnly = automaticEvidenceObserving && !tracking
    stopNativeCollection()
    emit([
      "type": "error",
      "errorCode": automaticEvidenceOnly
        ? "automatic_evidence_location_error"
        : "trip_tracking_location_error",
      "errorMessage": "Core Location could not continue trip tracking.",
    ])
  }

  private func monotonicElapsedNanos(
    for location: CLLocation,
    observedAt: Date
  ) -> Int64? {
    let wallAge = max(0, observedAt.timeIntervalSince(location.timestamp))
    let sampleUptime = ProcessInfo.processInfo.systemUptime - wallAge
    let maximumUptime = Double(Int64.max) / 1_000_000_000
    guard sampleUptime.isFinite, sampleUptime > 0, sampleUptime <= maximumUptime else {
      return nil
    }
    return Int64(sampleUptime * 1_000_000_000)
  }

  private func isSimulatedLocation(_ location: CLLocation) -> Bool {
    if #available(iOS 15.0, *) {
      return location.sourceInformation?.isSimulatedBySoftware == true
    }
    return false
  }
}
