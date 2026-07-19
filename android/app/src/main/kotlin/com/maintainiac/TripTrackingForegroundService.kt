package com.maintainiac

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition

class TripTrackingForegroundService : Service(), LocationListener {
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

    private lateinit var locationManager: LocationManager
    private var userPauseRequested = false
    private val heartbeatHandler = Handler(Looper.getMainLooper())
    private val heartbeatRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
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
        val interval = intent?.getLongExtra(intervalMillisExtra, 5000L)?.coerceIn(1000L, 60000L) ?: 5000L
        val displacement = intent?.getFloatExtra(minimumDisplacementExtra, 5f)?.coerceIn(1f, 100f) ?: 5f
        val activityEnabled = intent?.getBooleanExtra(activityRecognitionEnabledExtra, false) == true
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_gps_unavailable", "errorMessage" to "GPS is unavailable. Turn on device location to continue tracking."))
            stopSelf()
            return START_NOT_STICKY
        }
        locationManager.removeUpdates(this)
        @Suppress("MissingPermission")
        try {
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                interval,
                displacement,
                this,
                Looper.getMainLooper(),
            )
        } catch (error: SecurityException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android could not register GPS updates: ${error.message ?: "permission denied"}"))
            stopSelf()
            return START_NOT_STICKY
        } catch (error: IllegalArgumentException) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_registration_failed", "errorMessage" to "Android rejected the GPS provider: ${error.message ?: "provider unavailable"}"))
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
        isRunning = true
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
        startHeartbeat()
        return START_NOT_STICKY
    }

    override fun onLocationChanged(location: Location) {
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

    override fun onProviderDisabled(provider: String) {
        TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_gps_disabled", "errorMessage" to "GPS was turned off while tracking."))
        // Stop independently of the Flutter event channel. The Dart controller
        // will preserve a recoverable trip when it receives the error, but a
        // detached UI must never leave a location collector running.
        stopSelf()
    }

    override fun onDestroy() {
        stopHeartbeat()
        if (::locationManager.isInitialized) locationManager.removeUpdates(this)
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
