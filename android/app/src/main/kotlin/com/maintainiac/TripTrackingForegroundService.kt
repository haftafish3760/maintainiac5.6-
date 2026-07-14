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
        private const val notificationChannelId = "maintainiac_trip_tracking"
        private const val notificationId = 7313
        var isRunning = false
            private set
    }

    private lateinit var locationManager: LocationManager
    private val activityPendingIntent by lazy {
        PendingIntent.getBroadcast(
            this,
            7314,
            Intent(this, TripTrackingActivityReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(notificationId, notification())
        if (!hasFineLocation()) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_location_denied", "errorMessage" to "Location permission was removed while tracking."))
            stopSelf()
            return START_NOT_STICKY
        }
        val interval = intent?.getLongExtra(intervalMillisExtra, 5000L)?.coerceIn(1000L, 60000L) ?: 5000L
        val displacement = intent?.getFloatExtra(minimumDisplacementExtra, 5f)?.coerceIn(0f, 100f) ?: 5f
        val activityEnabled = intent?.getBooleanExtra(activityRecognitionEnabledExtra, true) == true
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            TripTrackingEventEmitter.emit(mapOf("type" to "error", "errorCode" to "trip_tracking_gps_unavailable", "errorMessage" to "GPS is unavailable. Turn on device location to continue tracking."))
            stopSelf()
            return START_NOT_STICKY
        }
        locationManager.removeUpdates(this)
        @Suppress("MissingPermission")
        locationManager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            interval,
            displacement,
            this,
            Looper.getMainLooper(),
        )
        if (activityEnabled && hasActivityRecognition()) {
            ActivityRecognition.getClient(this).requestActivityUpdates(5000, activityPendingIntent)
        }
        isRunning = true
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "tracking"))
        return START_NOT_STICKY
    }

    override fun onLocationChanged(location: Location) {
        if (!location.hasAccuracy() || !location.latitude.isFinite() || !location.longitude.isFinite()) return
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
    }

    override fun onDestroy() {
        if (::locationManager.isInitialized) locationManager.removeUpdates(this)
        ActivityRecognition.getClient(this).removeActivityUpdates(activityPendingIntent)
        isRunning = false
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to "stopped"))
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun notification() = NotificationCompat.Builder(this, notificationChannelId)
        .setSmallIcon(android.R.drawable.ic_menu_mylocation)
        .setContentTitle("Maintainiac trip tracking")
        .setContentText("GPS-assisted trip tracking is active")
        .setOngoing(true)
        .build()

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
