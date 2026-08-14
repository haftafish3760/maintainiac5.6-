// Opt-in Android foreground observer for App Assistant drive evidence.
//
// Owns low-frequency, review-only possible-drive samples. It does not create
// trips, calculate mileage, retain routes, or confirm records. Consumed by the
// Flutter automatic-evidence runtime through TripTrackingEventEmitter. Active
// trip tracking must stop this observer before it starts its own collector.
package com.maintainiac

import android.Manifest
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
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

class TripAutomaticEvidenceForegroundService : Service() {
    companion object {
        const val stopAction = "com.maintainiac.trip_tracking.STOP_AUTOMATIC_EVIDENCE"
        private const val notificationId = 7317

        @Volatile
        var isRunning = false
            private set

        @Volatile
        private var isStarting = false

        val isCollectorActive: Boolean
            get() = isRunning || isStarting

        @Volatile
        private var activeActivityEpoch: String? = null

        @Volatile
        private var activeActivityStartedAtMillis: Long? = null

        fun isActivityEpochActive(epoch: String, observedAtMillis: Long): Boolean {
            val startedAt = activeActivityStartedAtMillis ?: return false
            return isRunning && activeActivityEpoch == epoch && observedAtMillis >= startedAt
        }

        fun stop(context: Context) {
            isRunning = false
            isStarting = false
            activeActivityEpoch = null
            activeActivityStartedAtMillis = null
            context.stopService(Intent(context, TripAutomaticEvidenceForegroundService::class.java))
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var observationStartedAtMillis: Long = 0
    private var activityEpoch: String? = null
    private var activityPendingIntent: PendingIntent? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == stopAction) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (isCollectorActive) return START_NOT_STICKY
        if (!hasBackgroundLocationPermission() || !locationServicesEnabled()) {
            emitUnavailable("automatic_evidence_permission_or_location_unavailable")
            stopSelf(startId)
            return START_NOT_STICKY
        }
        try {
            TripTrackingNotificationFactory.ensureChannel(this)
            startForeground(
                notificationId,
                TripTrackingNotificationFactory.automaticEvidence(this, stopAction),
            )
        } catch (error: SecurityException) {
            emitUnavailable("automatic_evidence_foreground_service_denied")
            stopSelf(startId)
            return START_NOT_STICKY
        }
        observationStartedAtMillis = System.currentTimeMillis()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        val request = LocationRequest.Builder(
            Priority.PRIORITY_BALANCED_POWER_ACCURACY,
            60_000L,
        )
            .setMinUpdateIntervalMillis(30_000L)
            .setMinUpdateDistanceMeters(30f)
            .setWaitForAccurateLocation(false)
            .build()
        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                if (!isRunning || locationCallback !== this) return
                result.locations.forEach(::emitEvidenceLocation)
            }
        }
        locationCallback = callback
        isStarting = true
        val activityEnabled =
            intent?.getBooleanExtra(
                TripTrackingForegroundService.activityRecognitionEnabledExtra,
                false,
            ) == true
        @Suppress("MissingPermission")
        fusedLocationClient.requestLocationUpdates(request, callback, Looper.getMainLooper())
            .addOnSuccessListener {
                if (!isStarting || locationCallback !== callback) return@addOnSuccessListener
                isStarting = false
                isRunning = true
                TripTrackingEventEmitter.emit(
                    mapOf(
                        "type" to "automaticEvidenceStatus",
                        "status" to "automatic_evidence_observing",
                    ),
                )
                if (activityEnabled) startActivityRecognition()
            }
            .addOnFailureListener {
                if (!isStarting || locationCallback !== callback) return@addOnFailureListener
                isStarting = false
                emitUnavailable("automatic_evidence_location_registration_failed")
                stopSelf()
            }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        isStarting = false
        stopActivityRecognition()
        locationCallback?.let { callback ->
            try {
                fusedLocationClient.removeLocationUpdates(callback)
            } catch (_: Exception) {
                // The service is ending; no callback can authorize a record.
            }
        }
        locationCallback = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun emitEvidenceLocation(location: Location) {
        // Permission or provider state can change while the foreground service
        // is alive. Stop before a late callback can become App Assistant evidence.
        if (!hasBackgroundLocationPermission() || !locationServicesEnabled()) {
            emitUnavailable("automatic_evidence_permission_or_location_unavailable")
            stopSelf()
            return
        }
        if (activityPendingIntent != null && !hasActivityRecognitionPermission()) {
            stopActivityRecognition()
            emitActivityUnavailable("automatic_evidence_activity_permission_removed")
        }
        if (location.time < observationStartedAtMillis ||
            isMocked(location) ||
            !location.hasAccuracy() ||
            !location.latitude.isFinite() ||
            !location.longitude.isFinite() ||
            location.latitude !in -90.0..90.0 ||
            location.longitude !in -180.0..180.0 ||
            !location.accuracy.isFinite() ||
            location.accuracy <= 0f
        ) return
        val reportedSpeed = location.takeIf { it.hasSpeed() }?.speed
        if (reportedSpeed != null && (!reportedSpeed.isFinite() || reportedSpeed < 0f)) return
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "automaticEvidenceLocation",
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "recordedAt" to location.time,
                "horizontalAccuracyMeters" to location.accuracy,
                "speedMetersPerSecond" to reportedSpeed,
                "mockedLocation" to isMocked(location),
            ),
        )
    }

    private fun hasBackgroundLocationPermission(): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun locationServicesEnabled(): Boolean =
        (getSystemService(Context.LOCATION_SERVICE) as? LocationManager)
            ?.isLocationEnabled == true

    private fun startActivityRecognition() {
        if (!hasActivityRecognitionPermission()) {
            emitActivityUnavailable("automatic_evidence_activity_permission_unavailable")
            return
        }
        val epoch = UUID.randomUUID().toString()
        activityEpoch = epoch
        activeActivityEpoch = epoch
        activeActivityStartedAtMillis = System.currentTimeMillis()
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            7319,
            Intent(this, TripTrackingActivityReceiver::class.java)
                .setData(Uri.parse("maintainiac://trip_tracking/automatic_activity/$epoch"))
                .putExtra(TripTrackingForegroundService.activityEpochExtra, epoch)
                .putExtra(
                    TripTrackingActivityReceiver.activityOwnerExtra,
                    TripTrackingActivityReceiver.automaticEvidenceOwner,
                ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        activityPendingIntent = pendingIntent
        ActivityRecognition.getClient(this).requestActivityUpdates(15_000L, pendingIntent)
            .addOnFailureListener {
                if (activityEpoch != epoch) return@addOnFailureListener
                stopActivityRecognition()
                emitActivityUnavailable("automatic_evidence_activity_registration_failed")
            }
    }

    private fun stopActivityRecognition() {
        val pendingIntent = activityPendingIntent
        activityPendingIntent = null
        activityEpoch = null
        activeActivityEpoch = null
        activeActivityStartedAtMillis = null
        if (pendingIntent != null) {
            try {
                ActivityRecognition.getClient(this).removeActivityUpdates(pendingIntent)
            } catch (_: Exception) {
                // The activity epoch is already retired, so a delayed callback
                // cannot cross this consent boundary.
            }
        }
    }

    private fun hasActivityRecognitionPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) == PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun isMocked(location: Location): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) location.isMock else location.isFromMockProvider

    private fun emitUnavailable(reason: String) {
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to reason,
                "errorMessage" to "App Assistant could not observe possible drives.",
            ),
        )
    }

    private fun emitActivityUnavailable(reason: String) {
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "error",
                "errorCode" to reason,
                "errorMessage" to "App Assistant continues with location evidence only.",
            ),
        )
    }
}
