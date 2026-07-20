package com.maintainiac

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.ImageFormat
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.content.pm.PackageManager
import android.util.DisplayMetrics
import androidx.core.performance.play.services.PlayServicesDevicePerformance
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class DeviceCapabilityBridge(private val activity: Activity) {
    private val context = activity.applicationContext
    private val devicePerformance: PlayServicesDevicePerformance
        get() = sharedDevicePerformance(context)

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "readRuntimeCapabilities" -> result.success(readRuntimeCapabilities())
                "readCameraCapabilities" -> result.success(readCameraSummary())
                "readExtendedCapabilities" -> result.success(readExtendedCapabilities())
                "readDynamicCapabilities" -> result.success(readDynamicCapabilities())
                "readBluetoothCapabilities" -> result.success(readBluetoothCapabilities())
                else -> result.notImplemented()
            }
        }
        DeviceCapabilityEvents(context).register(messenger)
    }

    private fun readRuntimeCapabilities(): Map<String, Any> {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "physicalRamMb" to memory.totalMem / bytesPerMb,
            "availableRamMb" to memory.availMem / bytesPerMb,
            "applicationHeapMb" to manager.memoryClass,
            "mediaPerformanceClass" to devicePerformance.mediaPerformanceClass,
            "cpuArchitecture" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"),
            "powerSaving" to power.isPowerSaveMode,
            "thermalState" to thermalState(power),
        )
    }

    private fun readExtendedCapabilities(): Map<String, Any> = mapOf(
        "cameraLenses" to readCameraLenses(),
        "sensors" to readSensors(),
        "battery" to readBattery(),
        "display" to readDisplay(),
        "media" to readMedia(),
        "graphics" to readGraphics(),
        "connectivity" to readConnectivity(),
    )

    private fun readDynamicCapabilities(): Map<String, Any> = mapOf(
        "battery" to readBattery(),
        "connectivity" to readConnectivity(),
    )

    private fun readBluetoothCapabilities(): Map<String, Any> {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = manager?.adapter
        val authorized = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED
        val authorization = if (authorized) "authorized" else "notRequested"
        val poweredOn = if (authorized) adapter?.isEnabled == true else false
        return mapOf(
            "adapterAvailable" to (adapter != null),
            "poweredOn" to poweredOn,
            "authorization" to authorization,
            // Connection identity is supplied only by a future user-approved
            // adapter; generic Android discovery is not reliable vehicle identity.
            "supportsApprovedDeviceObservation" to false,
        )
    }

    private fun readCameraSummary(): Map<String, Any> {
        val lenses = readCameraLenses()
        val rear = lenses.filter { it["position"] == "rear" }
        val front = lenses.filter { it["position"] == "front" }
        return mapOf(
            "available" to lenses.isNotEmpty(),
            "cameraCount" to lenses.size,
            "hasRearCamera" to rear.isNotEmpty(),
            "hasFrontCamera" to front.isNotEmpty(),
            "supportsTapFocus" to lenses.any { it["supportsAutofocus"] == true },
            "supportsContinuousFocus" to lenses.any { it["supportsAutofocus"] == true },
            "supportsExposureCompensation" to lenses.any {
                it["supportsExposureCompensation"] == true
            },
            "supportsZoom" to lenses.any { (it["maxDigitalZoom"] as? Double ?: 1.0) > 1.0 },
            "supportsMacroSelection" to false,
            "supportsTorch" to lenses.any { it["supportsTorch"] == true },
            "supportsRaw" to lenses.any { it["supportsRaw"] == true },
            "maxStillWidth" to (lenses.maxOfOrNull { it["maxStillWidth"] as Int } ?: 0),
            "maxStillHeight" to (lenses.maxOfOrNull { it["maxStillHeight"] as Int } ?: 0),
        )
    }

    private fun readCameraLenses(): List<Map<String, Any>> {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val result = mutableListOf<Map<String, Any>>()
        val physicalIds = if (Build.VERSION.SDK_INT >= 29) {
            manager.cameraIdList.flatMap { id ->
                runCatching { manager.getCameraCharacteristics(id).physicalCameraIds }
                    .getOrDefault(emptySet())
            }.toSet()
        } else emptySet()
        manager.cameraIdList.forEach { id ->
            val characteristics = runCatching { manager.getCameraCharacteristics(id) }.getOrNull()
                ?: return@forEach
            val memberIds = if (Build.VERSION.SDK_INT >= 29) {
                characteristics.physicalCameraIds
            } else emptySet()
            if (id !in physicalIds) {
                result += cameraLensMap(characteristics, memberIds.size.coerceAtLeast(1))
            }
            memberIds.forEach { physicalId ->
                runCatching { manager.getCameraCharacteristics(physicalId) }.getOrNull()?.let {
                    result += cameraLensMap(it, 1)
                }
            }
        }
        return result.distinct()
    }

    private fun cameraLensMap(c: CameraCharacteristics, physicalCount: Int): Map<String, Any> {
        val facing = when (c.get(CameraCharacteristics.LENS_FACING)) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "rear"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
            else -> "unknown"
        }
        val focal = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
            ?.map(Float::toDouble).orEmpty()
        val apertures = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)
            ?.map(Float::toDouble).orEmpty()
        val still = c.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?.getOutputSizes(ImageFormat.JPEG)?.maxByOrNull { it.width.toLong() * it.height }
        val capabilities = c.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
            ?.toSet().orEmpty()
        val focusModes = c.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)
            ?.toSet().orEmpty()
        val exposureRange = c.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
        val maxFps = c.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
            ?.maxOfOrNull { it.upper } ?: 0
        val maxZoom = c.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM)
            ?.toDouble() ?: 1.0
        val opticalZoom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            c.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)?.upper?.toDouble()
        } else null
        return mapOf(
            "position" to facing,
            "lensType" to if (physicalCount > 1) "logical_multi_camera"
                else lensType(facing, focal.minOrNull()),
            "physicalLensCount" to physicalCount,
            "maxStillWidth" to (still?.width ?: 0),
            "maxStillHeight" to (still?.height ?: 0),
            "minFocalLengthMm" to (focal.minOrNull() ?: 0.0),
            "maxFocalLengthMm" to (focal.maxOrNull() ?: 0.0),
            "minAperture" to (apertures.minOrNull() ?: 0.0),
            "maxOpticalOrSensorZoom" to (opticalZoom ?: 1.0),
            "maxDigitalZoom" to maxZoom,
            "maxVideoFps" to maxFps,
            "supportsAutofocus" to focusModes.any { it != CameraCharacteristics.CONTROL_AF_MODE_OFF },
            "supportsExposureCompensation" to (
                exposureRange != null && exposureRange.lower < exposureRange.upper
            ),
            "supportsStabilization" to supportsStabilization(c),
            "supportsRaw" to capabilities.contains(
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW,
            ),
            "supportsDepth" to capabilities.contains(
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT,
            ),
            "supportsHdr" to supportsTenBitHdr(capabilities),
            "supportsTorch" to (c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true),
        )
    }

    private fun supportsStabilization(c: CameraCharacteristics): Boolean {
        val optical = c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION)
            ?.contains(CameraCharacteristics.LENS_OPTICAL_STABILIZATION_MODE_ON) == true
        val video = c.get(CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES)
            ?.contains(CameraCharacteristics.CONTROL_VIDEO_STABILIZATION_MODE_ON) == true
        return optical || video
    }

    private fun supportsTenBitHdr(capabilities: Set<Int>): Boolean =
        Build.VERSION.SDK_INT >= 33 && capabilities.contains(
            CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DYNAMIC_RANGE_TEN_BIT,
        )

    private fun lensType(position: String, focalLength: Double?): String {
        if (position == "front") return "front"
        if (focalLength == null) return "unknown"
        return when {
            focalLength <= 2.5 -> "inferred_ultrawide"
            focalLength > 7.0 -> "inferred_telephoto"
            else -> "inferred_wide"
        }
    }

    private fun readSensors(): Map<String, Any> {
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensors = manager.getSensorList(Sensor.TYPE_ALL)
        val types = sensors.map { sensorType(it.type) }.distinct().sorted()
        val declaredBodySensors = buildSet {
            val packageManager = context.packageManager
            if (packageManager.hasSystemFeature("android.hardware.sensor.heartrate")) {
                add("heart_rate")
            }
            if (packageManager.hasSystemFeature("android.hardware.sensor.heartrate.ecg")) {
                add("heart_rate_ecg")
            }
        }
        return mapOf(
            "sensorCount" to sensors.size,
            "types" to types,
            "permissionGatedTypes" to declaredBodySensors.filterNot(types::contains).sorted(),
        )
    }

    @Suppress("DEPRECATION")
    private fun sensorType(type: Int): String = when (type) {
        Sensor.TYPE_ACCELEROMETER -> "accelerometer"
        Sensor.TYPE_MAGNETIC_FIELD -> "magnetometer"
        Sensor.TYPE_ORIENTATION -> "orientation_legacy"
        Sensor.TYPE_GYROSCOPE -> "gyroscope"
        Sensor.TYPE_PRESSURE -> "barometer"
        Sensor.TYPE_LIGHT -> "ambient_light"
        Sensor.TYPE_PROXIMITY -> "proximity"
        Sensor.TYPE_GRAVITY -> "gravity"
        Sensor.TYPE_LINEAR_ACCELERATION -> "linear_acceleration"
        Sensor.TYPE_ROTATION_VECTOR -> "rotation_vector"
        Sensor.TYPE_RELATIVE_HUMIDITY -> "humidity"
        Sensor.TYPE_AMBIENT_TEMPERATURE -> "ambient_temperature"
        14 -> "magnetometer_uncalibrated"
        15 -> "game_rotation_vector"
        16 -> "gyroscope_uncalibrated"
        Sensor.TYPE_SIGNIFICANT_MOTION -> "significant_motion"
        Sensor.TYPE_STEP_DETECTOR -> "step_detector"
        Sensor.TYPE_STEP_COUNTER -> "step_counter"
        20 -> "geomagnetic_rotation_vector"
        Sensor.TYPE_HEART_RATE -> "heart_rate"
        22 -> "tilt_detector"
        23 -> "wake_gesture"
        24 -> "glance_gesture"
        25 -> "pickup_gesture"
        26 -> "wrist_tilt_gesture"
        27 -> "device_orientation"
        28 -> "pose_6dof"
        29 -> "stationary_detect"
        30 -> "motion_detect"
        31 -> "heart_beat"
        32 -> "dynamic_sensor_metadata"
        33 -> "additional_sensor_info"
        34 -> "low_latency_offbody_detect"
        35 -> "accelerometer_uncalibrated"
        36 -> "hinge_angle"
        37 -> "head_tracker"
        38 -> "limited_axes_accelerometer"
        39 -> "limited_axes_gyroscope"
        40 -> "limited_axes_accelerometer_uncalibrated"
        41 -> "limited_axes_gyroscope_uncalibrated"
        42 -> "heading"
        else -> "type_$type"
    }

    private fun readBattery(): Map<String, Any> {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val percent = if (level >= 0 && scale > 0) (level * 100.0 / scale).roundToInt() else null
        val manager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val chargeMicroAh = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
        val remainingMah = chargeMicroAh.takeIf { it > 0 }?.div(1000)
        val estimatedFull = if (remainingMah != null && percent != null && percent > 0) {
            (remainingMah * 100.0 / percent).roundToInt()
        } else null
        val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return mapOf(
            "levelPercent" to (percent ?: -1),
            "isCharging" to (status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL),
            "powerSource" to powerSource(plugged),
            "health" to batteryHealth(intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)),
            "temperatureCelsius" to ((intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
                ?: 0) / 10.0),
            "remainingChargeMah" to (remainingMah ?: -1),
            "estimatedFullCapacityMah" to (estimatedFull ?: -1),
            "capacityEstimateReliable" to false,
        )
    }

    private fun powerSource(value: Int): String = when (value) {
        BatteryManager.BATTERY_PLUGGED_AC -> "ac"
        BatteryManager.BATTERY_PLUGGED_USB -> "usb"
        BatteryManager.BATTERY_PLUGGED_WIRELESS -> "wireless"
        else -> "battery"
    }

    private fun batteryHealth(value: Int?): String = when (value) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheating"
        BatteryManager.BATTERY_HEALTH_DEAD -> "failure"
        BatteryManager.BATTERY_HEALTH_COLD,
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE,
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "degraded"
        else -> "unknown"
    }

    @Suppress("DEPRECATION")
    private fun readDisplay(): Map<String, Any> {
        val display = activity.windowManager.defaultDisplay
        val metrics = DisplayMetrics().also(display::getRealMetrics)
        val hdr = if (Build.VERSION.SDK_INT >= 24) display.hdrCapabilities.supportedHdrTypes.isNotEmpty()
        else false
        val wideColor = Build.VERSION.SDK_INT >= 26 && display.isWideColorGamut
        val maxRefresh = if (Build.VERSION.SDK_INT >= 23) {
            display.supportedModes.maxOfOrNull { it.refreshRate.toDouble() } ?: display.refreshRate.toDouble()
        } else display.refreshRate.toDouble()
        return mapOf(
            "widthPixels" to metrics.widthPixels,
            "heightPixels" to metrics.heightPixels,
            "densityScale" to metrics.density.toDouble(),
            "maxRefreshRateHz" to maxRefresh,
            "supportsHdr" to hdr,
            "supportsWideColor" to wideColor,
        )
    }

    private fun readMedia(): Map<String, Any> {
        val decode = mutableSetOf<String>()
        val encode = mutableSetOf<String>()
        MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos.forEach { info ->
            if (!isHardwareCodec(info)) return@forEach
            info.supportedTypes.mapNotNull(::normalizedCodec).forEach { codec ->
                if (info.isEncoder) encode += codec else decode += codec
            }
        }
        return mapOf(
            "hardwareDecodeTypes" to decode.sorted(),
            "hardwareEncodeTypes" to encode.sorted(),
        )
    }

    private fun isHardwareCodec(info: MediaCodecInfo): Boolean {
        if (Build.VERSION.SDK_INT >= 29) return info.isHardwareAccelerated
        val name = info.name.lowercase()
        return !name.startsWith("omx.google") && !name.startsWith("c2.android") &&
            !name.contains("ffmpeg")
    }

    private fun normalizedCodec(mime: String): String? = when (mime.lowercase()) {
        "video/avc" -> "h264"
        "video/hevc" -> "hevc"
        "video/x-vnd.on2.vp9" -> "vp9"
        "video/av01" -> "av1"
        "image/jpeg" -> "jpeg"
        else -> null
    }

    private fun readGraphics(): Map<String, Any> {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val openGlVersion = manager.deviceConfigurationInfo.reqGlEsVersion
        val major = openGlVersion shr 16
        val minor = openGlVersion and 0xffff
        val packageManager = context.packageManager
        val hasVulkan = Build.VERSION.SDK_INT >= 24 && packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL,
        )
        val vulkanVersion = if (Build.VERSION.SDK_INT >= 24) {
            packageManager.systemAvailableFeatures.firstOrNull {
                it.name == android.content.pm.PackageManager.FEATURE_VULKAN_HARDWARE_VERSION
            }?.version
        } else null
        return mapOf(
            "apiName" to if (hasVulkan) "vulkan+opengl_es" else "opengl_es",
            "apiVersion" to "$major.$minor",
            "featureLevel" to (vulkanVersion?.let { "vulkan_$it" } ?: "gles_$major$minor"),
            "supportsCompute" to (hasVulkan || major > 3 || (major == 3 && minor >= 1)),
            "supportsRayTracing" to false,
        )
    }

    private fun readConnectivity(): Map<String, Any> {
        val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = manager.activeNetwork
        val caps = network?.let(manager::getNetworkCapabilities)
        val transports = mutableListOf<String>()
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) transports += "wifi"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true) transports += "cellular"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true) transports += "ethernet"
        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true) transports += "vpn"
        val connected = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        return mapOf(
            "transports" to transports,
            "isConnected" to connected,
            "isMetered" to manager.isActiveNetworkMetered,
            "isConstrained" to (caps?.hasCapability(
                NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED,
            ) == false),
            "downstreamKbps" to (caps?.linkDownstreamBandwidthKbps ?: -1),
            "upstreamKbps" to (caps?.linkUpstreamBandwidthKbps ?: -1),
        )
    }

    private fun thermalState(power: PowerManager): String {
        if (Build.VERSION.SDK_INT < 29) return "unknown"
        return when (power.currentThermalStatus) {
            PowerManager.THERMAL_STATUS_NONE -> "nominal"
            PowerManager.THERMAL_STATUS_LIGHT,
            PowerManager.THERMAL_STATUS_MODERATE -> "fair"
            PowerManager.THERMAL_STATUS_SEVERE,
            PowerManager.THERMAL_STATUS_CRITICAL -> "serious"
            PowerManager.THERMAL_STATUS_EMERGENCY,
            PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
            else -> "unknown"
        }
    }

    companion object {
        private const val channelName = "maintainiac/device_capabilities"
        private const val bytesPerMb = 1_048_576L
        @Volatile
        private var performanceInstance: PlayServicesDevicePerformance? = null

        private fun sharedDevicePerformance(context: Context): PlayServicesDevicePerformance {
            return performanceInstance ?: synchronized(this) {
                performanceInstance ?: PlayServicesDevicePerformance(context.applicationContext)
                    .also { performanceInstance = it }
            }
        }
    }
}
