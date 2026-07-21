package com.maintainiac

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
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
        sink?.success(event + mapOf("schemaVersion" to 1))
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
            "readBatterySnapshot" -> result.success(batterySnapshot())
            "requestAuthorization" -> requestAuthorization(call, result)
            "start" -> start(call, result)
            "update" -> update(call, result)
            "stop" -> {
                // Retire callbacks before stopService returns. Android may
                // invoke onDestroy asynchronously after this bridge reply.
                TripTrackingForegroundService.retireForExplicitStop()
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
        val allowBackground = call.argument<Boolean>("allowBackground") == true
        if (allowBackground && !hasBackgroundLocation()) {
            result.error("trip_tracking_location_denied", "Background location permission is required for this tracking mode.", authorizationMap())
            return
        }
        val interval = (call.argument<Number>("intervalMillis")?.toLong() ?: 5000L).coerceIn(1000L, 60000L)
        val displacement = (call.argument<Number>("minimumDisplacementMeters")?.toFloat() ?: 5f).coerceIn(1f, 100f)
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
        if (!hasFineLocation()) {
            result.error("trip_tracking_location_denied", "Precise location permission is required before updating trip tracking.", authorizationMap())
            return
        }
        val allowBackground = call.argument<Boolean>("allowBackground") == true
        if (allowBackground && !hasBackgroundLocation()) {
            result.error("trip_tracking_location_denied", "Background location permission is required for this tracking mode.", authorizationMap())
            return
        }
        val intent = Intent(activity, TripTrackingForegroundService::class.java).apply {
            putExtra(TripTrackingForegroundService.intervalMillisExtra, (call.argument<Number>("intervalMillis")?.toLong() ?: 5000L).coerceIn(1000L, 60000L))
            putExtra(TripTrackingForegroundService.minimumDisplacementExtra, (call.argument<Number>("minimumDisplacementMeters")?.toFloat() ?: 5f).coerceIn(1f, 100f))
            putExtra(TripTrackingForegroundService.activityRecognitionEnabledExtra, call.argument<Boolean>("activityRecognitionEnabled") == true)
            putExtra(TripTrackingForegroundService.samplingUpdateExtra, true)
        }
        try {
            activity.startService(intent)
            result.success(true)
        } catch (error: SecurityException) {
            result.error(
                "trip_tracking_sampling_update_failed",
                "Android blocked the GPS sampling update: ${error.message ?: "permission denied"}",
                null,
            )
        } catch (error: IllegalStateException) {
            // The service can disappear between the local running check and
            // this update. Return a recoverable bridge error rather than
            // throwing through the channel or pretending the cadence changed.
            result.error(
                "trip_tracking_sampling_update_failed",
                "Android could not apply the GPS sampling update: ${error.message ?: "service unavailable"}",
                null,
            )
        }
    }

    private fun capabilities(): Map<String, Any> {
        val manager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val batteryManager = activity.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return mapOf(
            "schemaVersion" to 1,
            // Match the foreground collector: Fused Location may legitimately
            // use a non-GPS provider, so capability reporting must describe
            // system location availability rather than one provider toggle.
            "locationAvailable" to locationServicesEnabled(manager),
            "backgroundTrackingAvailable" to true,
            "activityRecognitionAvailable" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || ContextCompat.checkSelfPermission(activity, Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED),
            "batteryStateAvailable" to (batteryManager != null),
            "lowPowerModeAvailable" to (powerManager != null),
        )
    }

    private fun batterySnapshot(): Map<String, Any?> {
        val batteryManager = activity.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val percent = batteryManager
            ?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            ?.takeIf { it in 0..100 }
        val batteryStatus = activity.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return mapOf(
            "schemaVersion" to 1,
            "batteryPercent" to percent,
            "isCharging" to (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL),
            "lowPowerModeEnabled" to (powerManager?.isPowerSaveMode == true),
        )
    }

    private fun authorizationMap(): Map<String, Any> = mapOf(
        "schemaVersion" to 1,
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

    private fun locationServicesEnabled(manager: LocationManager): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            manager.isLocationEnabled
        } else {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }

    private fun isTracking(): Boolean = TripTrackingForegroundService.isRunning
}
