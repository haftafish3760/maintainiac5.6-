package com.maintainiac

import android.Manifest
import android.app.Service
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.BatteryManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.util.UUID

class TripTrackingForegroundService : Service() {
    companion object {
        const val intervalMillisExtra = "intervalMillis"
        const val minimumDisplacementExtra = "minimumDisplacementMeters"
        const val activityRecognitionEnabledExtra = "activityRecognitionEnabled"
        const val allowBackgroundExtra = "allowBackground"
        const val samplingUpdateExtra = "samplingUpdate"
        const val activityEpochExtra = "activityEpoch"
        private const val stopAction = "com.maintainiac.trip_tracking.STOP"
        private const val notificationId = 7313
        private const val heartbeatIntervalMillis = 60_000L
        @Volatile
        var isRunning = false
            private set

        // Activity Recognition broadcasts can be buffered after a user stops
        // tracking. Bind each subscription to the current foreground-service
        // epoch so an old walking classification cannot influence a later trip.
        @Volatile
        private var activeActivityEpoch: String? = null

        @Volatile
        private var activeActivityStartedAtMillis: Long? = null

        fun isActivityEpochActive(epoch: String): Boolean =
            isRunning && activeActivityEpoch == epoch

        fun isActivityEpochActive(epoch: String, observedAtMillis: Long): Boolean {
            val startedAtMillis = activeActivityStartedAtMillis ?: return false
            return isRunning && activeActivityEpoch == epoch &&
                observedAtMillis >= startedAtMillis
        }

        /// Called by the Flutter bridge before an explicit stop request. This
        /// closes the short interval before Android invokes onDestroy, when a
        /// queued fused or activity callback could otherwise still emit.
        fun retireForExplicitStop() {
            isRunning = false
            activeActivityEpoch = null
            activeActivityStartedAtMillis = null
        }

        fun consumeRecoveryStatus(context: Context): String? {
            return TripTrackingRecoveryState.consumeStatus(context)
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var trackingStartedAtMillis: Long? = null
    private var backgroundTrackingRequired = false
    private var userPauseRequested = false
    private val heartbeatHandler = Handler(Looper.getMainLooper())
    private val heartbeatRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            if (stopForCriticalBatteryIfNeeded()) return
            if (stopForLocationPermissionRevokedIfNeeded()) return
            if (stopForBackgroundLocationPermissionRevokedIfNeeded()) return
            if (stopForLocationServicesDisabledIfNeeded()) return
            stopActivityRecognitionIfPermissionRevoked()
            // Liveness only: no coordinates, mileage, stop evidence, or
            // identity crosses this status boundary.
            TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
            heartbeatHandler.postDelayed(this, heartbeatIntervalMillis)
        }
    }
    private var activityEpoch: String? = null
    private var activityPendingIntent: PendingIntent? = null
    private var activityRecognitionUnavailableReported = false

    private fun reportActivityRecognitionUnavailable(message: String) {
        // Location collection remains independent from optional walking
        // assistance. Emit this degraded-mode signal only once per native
        // service lifetime so sampling updates cannot spam the Flutter bridge.
        if (activityRecognitionUnavailableReported) return
        activityRecognitionUnavailableReported = true
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to "trip_tracking_activity_unavailable",
                "errorMessage" to message,
            ),
        )
    }

    private fun activityRecognitionPendingIntent(): PendingIntent {
        val epoch = activityEpoch ?: UUID.randomUUID().toString().also {
            activityEpoch = it
            activeActivityEpoch = it
            activeActivityStartedAtMillis = System.currentTimeMillis()
        }
        return activityPendingIntent ?: PendingIntent.getBroadcast(
            this,
            7314,
            Intent(this, TripTrackingActivityReceiver::class.java)
                // PendingIntent identity includes data, which prevents a
                // delayed broadcast for a previous session from being reused.
                .setData(Uri.parse("maintainiac://trip_tracking/activity/$epoch"))
                .putExtra(activityEpochExtra, epoch),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        ).also { activityPendingIntent = it }
    }

    private fun removeActivityRecognitionUpdates() {
        val pendingIntent = activityPendingIntent ?: return
        try {
            ActivityRecognition.getClient(this).removeActivityUpdates(pendingIntent)
        } catch (_: Exception) {
            // Location cleanup and the explicit opt-out remain authoritative
            // if Play Services is temporarily unavailable.
        }
    }

    private fun retireActivityRecognitionEpoch() {
        activeActivityEpoch = null
        activeActivityStartedAtMillis = null
        activityEpoch = null
        activityPendingIntent = null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A service recreation without the original, driver-approved request
        // must never fall through to default GPS settings and restart
        // collection. Dart retains the local trip for recovery/review.
        if (intent == null) {
            retireForExplicitStop()
            stopSelf(startId)
            return START_NOT_STICKY
        }
        if (intent.action == stopAction) {
            // The persistent notification must give the driver an immediate,
            // visible way to pause GPS collection without falsely implying
            // that the odometer-review workflow has been completed.
            userPauseRequested = true
            TripTrackingRecoveryState.recordUserPause(this)
            stopSelf()
            return START_NOT_STICKY
        }
        // The bridge verifies the collector before requesting a cadence
        // update, but it can still disappear in the tiny interval afterward.
        // An update intent is never authorization to create a new collector.
        val samplingUpdate = intent.getBooleanExtra(samplingUpdateExtra, false)
        if (samplingUpdate && !isRunning) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        // Android may redeliver a start command or a native caller may replay
        // one after the collector is already live. Treat that as idempotent:
        // never replace the callback, reset the session boundary, or count the
        // same movement twice. Sampling changes use the explicit update path.
        if (!samplingUpdate && isRunning) {
            TripTrackingEventEmitter.emit(
                mapOf("type" to "status", "status" to "tracking"),
            )
            return START_NOT_STICKY
        }
        userPauseRequested = false
        backgroundTrackingRequired =
            intent.getBooleanExtra(allowBackgroundExtra, false)
        try {
            startForeground(
                notificationId,
                TripTrackingNotificationFactory.active(this, stopAction),
            )
        } catch (error: SecurityException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_foreground_service_denied", "errorMessage" to "Android blocked the trip-tracking foreground service: ${error.message ?: "permission denied"}"))
            stopSelf()
            return START_NOT_STICKY
        }
        if (!hasLocation()) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_denied", "errorMessage" to "Location permission was removed while tracking."))
            stopSelf()
            return START_NOT_STICKY
        }
        if (stopForBackgroundLocationPermissionRevokedIfNeeded()) {
            return START_NOT_STICKY
        }
        if (stopForCriticalBatteryIfNeeded()) return START_NOT_STICKY
        val interval = intent?.getLongExtra(intervalMillisExtra, 5000L)?.coerceIn(1000L, 60000L) ?: 5000L
        val displacement = intent?.getFloatExtra(minimumDisplacementExtra, 5f)?.coerceIn(1f, 100f) ?: 5f
        val activityEnabled = intent?.getBooleanExtra(activityRecognitionEnabledExtra, false) == true
        if (!locationServicesEnabled()) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_gps_unavailable", "errorMessage" to "GPS is unavailable. Turn on device location to continue tracking."))
            stopSelf()
            return START_NOT_STICKY
        }
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        stopLocationUpdates()
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, interval)
            .setMinUpdateIntervalMillis((interval / 2).coerceAtLeast(1000L))
            .setMinUpdateDistanceMeters(displacement)
            .setWaitForAccurateLocation(false)
            .build()
        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                // Fused Location can dispatch a callback that was already
                // queued when this request was replaced or retired. Do not
                // let that old request contribute a coordinate to the active
                // trip after a stop/start boundary.
                if (!isRunning || locationCallback !== this) return
                for (location in result.locations) emitLocation(location)
            }
        }
        locationCallback = callback
        // A fused provider may deliver a cached first fix immediately. Mark
        // the service live before registering so that credible first evidence
        // is not lost between registration and the tracking status event.
        // Keep a session boundary as well: a buffered fix from before this
        // collection must not become mileage in a newly started trip.
        trackingStartedAtMillis = System.currentTimeMillis()
        isRunning = true
        TripTrackingRecoveryState.markTrackingStarted(this)
        @Suppress("MissingPermission")
        try {
            fusedLocationClient.requestLocationUpdates(
                request,
                callback,
                Looper.getMainLooper(),
            ).addOnFailureListener { error ->
                // A delayed failure from a replaced or stopped request must
                // never interrupt a newer GPS session.
                if (!isRunning || locationCallback !== callback) return@addOnFailureListener
                TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android could not register location updates: ${error.message ?: "provider unavailable"}"))
                stopSelf(startId)
            }
        } catch (error: SecurityException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android could not register location updates: ${error.message ?: "permission denied"}"))
            stopSelf()
            return START_NOT_STICKY
        }
        if (activityEnabled && hasActivityRecognition()) {
            activityRecognitionUnavailableReported = false
            val pendingIntent = activityRecognitionPendingIntent()
            val requestEpoch = activityEpoch
            ActivityRecognition.getClient(this).requestActivityUpdates(
                5000,
                pendingIntent,
            )
                .addOnFailureListener { error ->
                    // Play Services can report a registration failure after
                    // the driver has disabled motion assistance or a newer
                    // collector has taken ownership. Do not let that stale
                    // callback degrade the active trip.
                    if (!isRunning || requestEpoch == null ||
                        !isActivityEpochActive(requestEpoch)) return@addOnFailureListener
                    reportActivityRecognitionUnavailable(
                        "Activity recognition is unavailable: ${error.message ?: "request failed"}",
                    )
                }
        } else if (activityEnabled) {
            // The app can receive a start/redelivery request after the driver
            // revoked Android activity recognition in Settings. GPS remains
            // active, but Flutter must be told that walking-assisted evidence
            // is unavailable rather than leaving the stale preference looking
            // operational until the next heartbeat.
            removeActivityRecognitionUpdates()
            retireActivityRecognitionEpoch()
            reportActivityRecognitionUnavailable(
                "Activity recognition permission is unavailable; GPS tracking continues without walking-assisted stop evidence.",
            )
        } else {
            // Sampling updates can revoke motion assistance while the trip
            // remains active. Stop the sensor immediately; location tracking
            // must never keep collecting activity data after that opt-out.
            // A later explicit opt-in is a new consent attempt and must be
            // able to surface a fresh unavailable-permission diagnosis.
            activityRecognitionUnavailableReported = false
            removeActivityRecognitionUpdates()
            // A later re-enable is a new consent window. Retiring the token
            // prevents a delayed broadcast from before opt-out from becoming
            // valid again when motion assistance is turned back on.
            retireActivityRecognitionEpoch()
        }
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
        startHeartbeat()
        // Re-deliver only the driver-approved request after Android restarts
        // this foreground service, retaining its sampling and sensor consent.
        return START_REDELIVER_INTENT
    }

    private fun emitLocation(location: Location) {
        if (stopForCriticalBatteryIfNeeded()) return
        if (stopForBackgroundLocationPermissionRevokedIfNeeded()) return
        if (stopForLocationServicesDisabledIfNeeded()) return
        val startedAtMillis = trackingStartedAtMillis ?: return
        if (!isRunning || !location.hasAccuracy() ||
            !location.latitude.isFinite() || !location.longitude.isFinite() ||
            location.latitude !in -90.0..90.0 ||
            location.longitude !in -180.0..180.0) return
        val accuracyMeters = location.accuracy.toDouble()
        val reportedSpeed = if (location.hasSpeed()) location.speed.toDouble() else null
        val reportedSpeedAccuracy = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && location.hasSpeedAccuracy()) location.speedAccuracyMetersPerSecond.toDouble() else null
        val reportedBearing = if (location.hasBearing()) location.bearing.toDouble() else null
        // Reject malformed native metadata before it crosses the platform
        // boundary. Dart validates again, but the foreground service should
        // not keep forwarding a corrupt cached fix on every callback.
        if (location.time < startedAtMillis ||
            location.time > System.currentTimeMillis() + 120_000L ||
            !accuracyMeters.isFinite() || accuracyMeters <= 0 ||
            (reportedSpeed != null && (!reportedSpeed.isFinite() || reportedSpeed < 0))) return
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "location",
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "recordedAt" to location.time,
                "horizontalAccuracyMeters" to accuracyMeters,
                "speedMetersPerSecond" to reportedSpeed,
                "speedAccuracyMetersPerSecond" to reportedSpeedAccuracy?.takeIf { it.isFinite() && it >= 0 && it <= 1000 },
                "bearingDegrees" to reportedBearing?.takeIf { it.isFinite() && it >= 0 && it < 360 },
                "monotonicElapsedNanos" to location.elapsedRealtimeNanos.takeIf { it > 0 },
                "mockedLocation" to location.isFromMockProvider,
            ),
        )
    }

    override fun onDestroy() {
        // A fused callback may already be queued while Android tears down the
        // service. Retire collection before unregistering so that a late fix
        // cannot cross the native boundary after the driver stopped tracking.
        retireForExplicitStop()
        stopHeartbeat()
        stopLocationUpdates()
        removeActivityRecognitionUpdates()
        retireActivityRecognitionEpoch()
        trackingStartedAtMillis = null
        backgroundTrackingRequired = false
        if (userPauseRequested) {
            TripTrackingRecoveryState.recordUserPause(this)
        } else {
            TripTrackingRecoveryState.recordSystemPauseIfActive(this)
        }
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "status",
                "status" to if (userPauseRequested) "paused" else "stopped",
            ),
        )
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startHeartbeat() {
        heartbeatHandler.removeCallbacks(heartbeatRunnable)
        heartbeatHandler.postDelayed(heartbeatRunnable, heartbeatIntervalMillis)
    }

    private fun stopHeartbeat() {
        heartbeatHandler.removeCallbacks(heartbeatRunnable)
    }

    /// Flutter may be suspended while Android keeps this foreground collector
    /// alive. Enforce the hard below-ten-percent cutoff while unplugged. The
    /// emitted event cannot close a TripLog day or alter the odometer.
    private fun stopForCriticalBatteryIfNeeded(): Boolean {
        if (!isBatteryCriticallyLow()) return false
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to "trip_tracking_battery_critical",
                "errorMessage" to "Battery is critically low. Plug in the phone or charge above 10% to resume GPS assistance.",
            ),
        )
        stopSelf()
        return true
    }

    private fun isBatteryCriticallyLow(): Boolean {
        val battery = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return false
        val status = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val charging =
            status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL ||
                plugged != 0
        if (charging) return false
        val level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        if (level < 0 || scale <= 0) return false
        return level * 100 / scale < 10
    }

    private fun stopForLocationServicesDisabledIfNeeded(): Boolean {
        if (locationServicesEnabled()) return false
        TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_gps_disabled", "errorMessage" to "Device location was turned off while tracking."))
        stopSelf()
        return true
    }

    /// Android can revoke all location access while this foreground service is
    /// alive. Approximate access remains advisory and is classified by Dart;
    /// only total permission loss retires the collector.
    private fun stopForLocationPermissionRevokedIfNeeded(): Boolean {
        if (hasLocation()) return false
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to "trip_tracking_location_denied",
                "errorMessage" to "Location permission was removed while tracking.",
            ),
        )
        stopSelf()
        return true
    }

    private fun stopForBackgroundLocationPermissionRevokedIfNeeded(): Boolean {
        if (!backgroundTrackingRequired || hasBackgroundLocation()) return false
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to "trip_tracking_background_location_denied",
                "errorMessage" to "Background location permission was removed while tracking.",
            ),
        )
        stopSelf()
        return true
    }

    private fun locationServicesEnabled(): Boolean {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            manager.isLocationEnabled
        } else {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    private fun stopLocationUpdates() {
        if (!::fusedLocationClient.isInitialized) return
        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
        locationCallback = null
    }

    override fun onCreate() {
        super.onCreate()
        TripTrackingNotificationFactory.ensureChannel(this)
    }

    private fun hasFineLocation() = ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_FINE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED

    private fun hasLocation() =
        hasFineLocation() ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED

    private fun hasBackgroundLocation() =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED

    private fun hasActivityRecognition() = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED

    private fun stopActivityRecognitionIfPermissionRevoked() {
        // Android can revoke the optional activity permission while a trip is
        // active. Keep GPS and TripLog intact, but immediately retire walking
        // assistance and report the change once through the native boundary.
        if (activityPendingIntent == null || hasActivityRecognition()) return
        removeActivityRecognitionUpdates()
        retireActivityRecognitionEpoch()
        reportActivityRecognitionUnavailable(
            "Activity recognition permission was removed; GPS tracking continues without walking-assisted stop evidence.",
        )
    }
}
