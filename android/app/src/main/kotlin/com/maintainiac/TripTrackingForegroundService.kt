package com.maintainiac

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.BatteryManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class TripTrackingForegroundService : Service() {
    companion object {
        const val intervalMillisExtra = "intervalMillis"
        const val minimumDisplacementExtra = "minimumDisplacementMeters"
        const val activityRecognitionEnabledExtra = "activityRecognitionEnabled"
        private const val stopAction = "com.maintainiac.trip_tracking.STOP"
        private const val notificationChannelId = "maintainiac_trip_tracking"
        private const val notificationId = 7313
        private const val heartbeatIntervalMillis = 60_000L
        var isRunning = false
            private set
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var userPauseRequested = false
    private val heartbeatHandler = Handler(Looper.getMainLooper())
    private val heartbeatRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            if (stopForCriticalBatteryIfNeeded()) return
            if (stopForLocationServicesDisabledIfNeeded()) return
            // Liveness only: no coordinates, mileage, stop evidence, or
            // identity crosses this status boundary.
            TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
            heartbeatHandler.postDelayed(this, heartbeatIntervalMillis)
        }
    }
    private val activityPendingIntent by lazy {
        PendingIntent.getBroadcast(
            this,
            7314,
            Intent(this, TripTrackingActivityReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == stopAction) {
            // The persistent notification must give the driver an immediate,
            // visible way to end tracking without reopening the app.
            userPauseRequested = true
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            startForeground(notificationId, notification())
        } catch (error: SecurityException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_foreground_service_denied", "errorMessage" to "Android blocked the trip-tracking foreground service: ${error.message ?: "permission denied"}"))
            stopSelf()
            return START_NOT_STICKY
        }
        if (!hasFineLocation()) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_denied", "errorMessage" to "Location permission was removed while tracking."))
            stopSelf()
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
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (location in result.locations) emitLocation(location)
            }
        }
        // A fused provider may deliver a cached first fix immediately. Mark
        // the service live before registering so that credible first evidence
        // is not lost between registration and the tracking status event.
        isRunning = true
        @Suppress("MissingPermission")
        try {
            fusedLocationClient.requestLocationUpdates(
                request,
                requireNotNull(locationCallback),
                Looper.getMainLooper(),
            ).addOnFailureListener { error ->
                TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android could not register location updates: ${error.message ?: "provider unavailable"}"))
                stopSelf()
            }
        } catch (error: SecurityException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android could not register location updates: ${error.message ?: "permission denied"}"))
            stopSelf()
            return START_NOT_STICKY
        }
        if (activityEnabled && hasActivityRecognition()) {
            ActivityRecognition.getClient(this).requestActivityUpdates(5000, activityPendingIntent)
                .addOnFailureListener { error ->
                    TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_activity_unavailable", "errorMessage" to "Activity recognition is unavailable: ${error.message ?: "request failed"}"))
                }
        } else {
            // Sampling updates can revoke motion assistance while the trip
            // remains active. Stop the sensor immediately; location tracking
            // must never keep collecting activity data after that opt-out.
            try {
                ActivityRecognition.getClient(this).removeActivityUpdates(activityPendingIntent)
            } catch (_: Exception) {
                // Location cleanup and the explicit opt-out remain authoritative
                // if Play Services is temporarily unavailable.
            }
        }
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
        startHeartbeat()
        return START_NOT_STICKY
    }

    private fun emitLocation(location: Location) {
        if (stopForCriticalBatteryIfNeeded()) return
        if (stopForLocationServicesDisabledIfNeeded()) return
        if (!isRunning || !location.hasAccuracy() || !location.latitude.isFinite() || !location.longitude.isFinite()) return
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "location",
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "recordedAt" to location.time,
                "horizontalAccuracyMeters" to location.accuracy.toDouble(),
                "speedMetersPerSecond" to if (location.hasSpeed()) location.speed.toDouble() else null,
                "mockedLocation" to location.isFromMockProvider,
            ),
        )
    }

    override fun onDestroy() {
        stopHeartbeat()
        stopLocationUpdates()
        try {
            ActivityRecognition.getClient(this).removeActivityUpdates(activityPendingIntent)
        } catch (_: Exception) {
            // Location cleanup remains authoritative if Play Services is unavailable.
        }
        isRunning = false
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
    /// alive. Enforce the hard below-ten-percent cutoff here as well. The
    /// emitted event cannot close a TripLog day or alter the odometer.
    private fun stopForCriticalBatteryIfNeeded(): Boolean {
        if (!isBatteryCriticallyLow()) return false
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to "trip_tracking_battery_critical",
                "errorMessage" to "Battery is critically low. GPS-assisted tracking is paused below 10%.",
            ),
        )
        stopSelf()
        return true
    }

    private fun isBatteryCriticallyLow(): Boolean {
        val battery = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return false
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

    private fun notification(): android.app.Notification {
        val stopIntent = PendingIntent.getService(
            this,
            7315,
            Intent(this, TripTrackingForegroundService::class.java).setAction(stopAction),
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Maintainiac trip tracking")
            .setContentText("GPS-assisted trip tracking is active")
            .setOngoing(true)
            .addAction(0, "Stop trip tracking", stopIntent)
            .build()
    }

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(notificationChannelId, "Trip tracking", NotificationManager.IMPORTANCE_LOW),
            )
        }
    }

    private fun hasFineLocation() = ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_FINE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED

    private fun hasActivityRecognition() = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
}
