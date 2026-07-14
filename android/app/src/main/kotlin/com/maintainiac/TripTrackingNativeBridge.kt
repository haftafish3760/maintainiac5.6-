package com.maintainiac

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val tripTrackingCommandChannel = "maintainiac/trip_tracking/commands"
private const val tripTrackingEventChannel = "maintainiac/trip_tracking/events"
private const val tripTrackingPermissionRequestCode = 7312

/** The foreground service reports location/lifecycle events through this sink. */
object TripTrackingEventEmitter {
    private var sink: EventChannel.EventSink? = null

    fun attach(nextSink: EventChannel.EventSink?) {
        sink = nextSink
    }

    fun emit(event: Map<String, Any?>) {
        sink?.success(event)
    }
}

class TripTrackingNativeBridge(
    private val activity: Activity,
) : EventChannel.StreamHandler {
    private var pendingAuthorizationResult: MethodChannel.Result? = null
    private var pendingBackgroundAuthorization = false
    private var pendingActivityAuthorization = false
    private var locationPermissionRequested = false
    private var activityPermissionRequested = false
    private var notificationPermissionRequested = false

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, tripTrackingCommandChannel).setMethodCallHandler(::handle)
        EventChannel(messenger, tripTrackingEventChannel).setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        TripTrackingEventEmitter.attach(events)
        TripTrackingEventEmitter.emit(mapOf("type" to "status", "status" to if (isTracking()) "tracking" else "idle"))
    }

    override fun onCancel(arguments: Any?) {
        TripTrackingEventEmitter.attach(null)
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != tripTrackingPermissionRequestCode) return false
        continueAuthorizationRequest()
        return true
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readCapabilities" -> result.success(capabilities())
            "requestAuthorization" -> requestAuthorization(call, result)
            "start" -> start(call, result)
            "update" -> update(call, result)
            "stop" -> {
                activity.stopService(Intent(activity, TripTrackingForegroundService::class.java))
                result.success(null)
            }
            "isTracking" -> result.success(isTracking())
            else -> result.notImplemented()
        }
    }

    private fun requestAuthorization(call: MethodCall, result: MethodChannel.Result) {
        if (pendingAuthorizationResult != null) {
            result.error("trip_tracking_permission_busy", "A location permission request is already active.", null)
            return
        }
        val allowBackground = call.argument<Boolean>("allowBackground") == true
        pendingActivityAuthorization = call.argument<Boolean>("activityRecognitionEnabled") == true
        locationPermissionRequested = false
        activityPermissionRequested = false
        notificationPermissionRequested = false
        pendingAuthorizationResult = result
        pendingBackgroundAuthorization = allowBackground
        continueAuthorizationRequest()
    }

    private fun completeAuthorizationRequest() {
        val result = pendingAuthorizationResult ?: return
        pendingAuthorizationResult = null
        pendingBackgroundAuthorization = false
        pendingActivityAuthorization = false
        result.success(authorizationMap())
    }

    private fun continueAuthorizationRequest() {
        if (pendingAuthorizationResult == null) return
        if (!hasFineLocation()) {
            if (locationPermissionRequested) {
                completeAuthorizationRequest()
                return
            }
            locationPermissionRequested = true
            activity.requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                tripTrackingPermissionRequestCode,
            )
            return
        }
        // Android 13+ does not require this permission to launch a foreground
        // service, but asking keeps the ongoing tracking indicator visible in
        // the notification drawer. A denial must never silently block mileage
        // tracking after the user approved location.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !hasNotificationPermission() &&
            !notificationPermissionRequested
        ) {
            notificationPermissionRequested = true
            activity.requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                tripTrackingPermissionRequestCode,
            )
            return
        }
        if (pendingActivityAuthorization && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasActivityRecognition() && !activityPermissionRequested) {
            activityPermissionRequested = true
            activity.requestPermissions(arrayOf(Manifest.permission.ACTIVITY_RECOGNITION), tripTrackingPermissionRequestCode)
            return
        }
        if (pendingBackgroundAuthorization && hasFineLocation() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundLocation()) {
            pendingBackgroundAuthorization = false
            activity.requestPermissions(arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), tripTrackingPermissionRequestCode)
            return
        }
        completeAuthorizationRequest()
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        if (!hasFineLocation()) {
            result.error("trip_tracking_location_denied", "Precise location permission is required before starting trip tracking.", authorizationMap())
            return
        }
        val interval = (call.argument<Number>("intervalMillis")?.toLong() ?: 5000L).coerceIn(1000L, 60000L)
        val displacement = (call.argument<Number>("minimumDisplacementMeters")?.toFloat() ?: 5f).coerceIn(0f, 100f)
        val intent = Intent(activity, TripTrackingForegroundService::class.java).apply {
            putExtra(TripTrackingForegroundService.intervalMillisExtra, interval)
            putExtra(TripTrackingForegroundService.minimumDisplacementExtra, displacement)
            putExtra(
                TripTrackingForegroundService.activityRecognitionEnabledExtra,
                call.argument<Boolean>("activityRecognitionEnabled") == true,
            )
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                activity.startForegroundService(intent)
            } else {
                activity.startService(intent)
            }
            result.success(true)
        } catch (error: SecurityException) {
            result.error(
                "trip_tracking_foreground_service_denied",
                "Android blocked the trip-tracking foreground service: ${error.message ?: "permission denied"}",
                null,
            )
        } catch (error: IllegalStateException) {
            // Android can reject foreground-service starts when its background
            // launch policy changes between permission approval and this call.
            result.error(
                "trip_tracking_foreground_service_denied",
                "Android blocked the trip-tracking foreground service: ${error.message ?: "start not allowed"}",
                null,
            )
        }
    }

    private fun update(call: MethodCall, result: MethodChannel.Result) {
        if (!isTracking()) {
            result.success(false)
            return
        }
        val intent = Intent(activity, TripTrackingForegroundService::class.java).apply {
            putExtra(TripTrackingForegroundService.intervalMillisExtra, (call.argument<Number>("intervalMillis")?.toLong() ?: 5000L).coerceIn(1000L, 60000L))
            putExtra(TripTrackingForegroundService.minimumDisplacementExtra, (call.argument<Number>("minimumDisplacementMeters")?.toFloat() ?: 5f).coerceIn(0f, 100f))
            putExtra(TripTrackingForegroundService.activityRecognitionEnabledExtra, call.argument<Boolean>("activityRecognitionEnabled") == true)
        }
        activity.startService(intent)
        result.success(true)
    }

    private fun capabilities(): Map<String, Any> {
        val manager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return mapOf(
            "locationAvailable" to manager.isProviderEnabled(LocationManager.GPS_PROVIDER),
            "backgroundTrackingAvailable" to true,
            "activityRecognitionAvailable" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || ContextCompat.checkSelfPermission(activity, Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED),
        )
    }

    private fun authorizationMap(): Map<String, Any> = mapOf(
        "state" to when {
            !hasFineLocation() -> "denied"
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && hasBackgroundLocation() -> "always"
            else -> "whileInUse"
        },
        "preciseLocation" to hasFineLocation(),
    )

    private fun hasFineLocation(): Boolean = ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.ACCESS_FINE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED

    private fun hasBackgroundLocation(): Boolean = ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.ACCESS_BACKGROUND_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED

    private fun hasNotificationPermission(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.POST_NOTIFICATIONS,
    ) == PackageManager.PERMISSION_GRANTED

    private fun hasActivityRecognition(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.ACTIVITY_RECOGNITION,
    ) == PackageManager.PERMISSION_GRANTED

    private fun isTracking(): Boolean = TripTrackingForegroundService.isRunning
}
