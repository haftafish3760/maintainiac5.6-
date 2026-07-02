package com.maintainiac

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Bundle
import android.util.Size
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val receiptCameraChannelName = "maintainiac/receipt_camera"
    private val receiptCameraRequestCode = 7301
    private var pendingReceiptCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            receiptCameraChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readCapabilities" -> readReceiptCameraCapabilities(result)
                "captureReceipt" -> openReceiptCamera(result, call.arguments as? Map<*, *>)
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != receiptCameraRequestCode) return
        val pendingResult = pendingReceiptCameraResult ?: return
        pendingReceiptCameraResult = null
        if (resultCode != RESULT_OK || data == null) {
            val closeAction = data?.getStringExtra(ReceiptCameraActivity.extraCloseAction)
                ?: "unknown_cancel"
            pendingResult.error(
                "native_camera_cancelled",
                "Receipt photo capture was cancelled.",
                mapOf("closeAction" to closeAction),
            )
            return
        }
        val paths = data.getStringArrayListExtra(ReceiptCameraActivity.extraOriginalPhotoPaths)
            ?: arrayListOf()
        if (paths.isEmpty()) {
            pendingResult.error(
                "native_camera_no_photo",
                "Maintainiac receipt camera did not return a photo.",
                null,
            )
            return
        }
        pendingResult.success(
            mapOf(
                "originalPhotoPaths" to paths,
                "temporaryCaptureIds" to paths.map { it.substringAfterLast('/') },
                "capturedAt" to data.getStringExtra(ReceiptCameraActivity.extraCapturedAt),
                "captureDiagnostics" to receiptCaptureDiagnostics(data),
            ),
        )
    }

    @Suppress("DEPRECATION")
    private fun receiptCaptureDiagnostics(data: Intent): Map<*, *> {
        return data.getSerializableExtra(ReceiptCameraActivity.extraCaptureDiagnostics)
            as? HashMap<*, *>
            ?: mapOf(
                "engine" to "cameraX",
                "captureMode" to "manual",
                "captureSurface" to "maintainiac_native_android",
            )
    }

    private fun readReceiptCameraCapabilities(result: MethodChannel.Result) {
        val providerFuture = ProcessCameraProvider.getInstance(this)
        providerFuture.addListener(
            {
                try {
                    providerFuture.get()
                    val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                    val hasRearCamera = hasCameraFacing(
                        cameraManager,
                        CameraCharacteristics.LENS_FACING_BACK,
                    )
                    val hasFrontCamera = hasCameraFacing(
                        cameraManager,
                        CameraCharacteristics.LENS_FACING_FRONT,
                    )
                    val rearCharacteristics = findRearCameraCharacteristics(cameraManager)
                    val zoomRange = rearCharacteristics
                        ?.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)
                    val exposureRange = rearCharacteristics
                        ?.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
                    val flashAvailable =
                        rearCharacteristics?.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                    val focusModes = rearCharacteristics
                        ?.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)
                        ?.toSet()
                        ?: emptySet()
                    val whiteBalanceModes = rearCharacteristics
                        ?.get(CameraCharacteristics.CONTROL_AWB_AVAILABLE_MODES)
                        ?.toSet()
                        ?: emptySet()
                    val maxStillSize = maxJpegStillSize(rearCharacteristics)
                    result.success(
                        mapOf(
                            "engine" to "cameraX",
                            "available" to hasRearCamera,
                            "cameraPermissionGranted" to hasCameraPermission(),
                            "cameraCount" to cameraManager.cameraIdList.size,
                            "hasRearCamera" to hasRearCamera,
                            "hasFrontCamera" to hasFrontCamera,
                            "supportsTapFocus" to focusModes.isNotEmpty(),
                            "supportsContinuousFocus" to focusModes.contains(
                                CameraCharacteristics.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
                            ),
                            "supportsFocusLock" to focusModes.isNotEmpty(),
                            "supportsManualFocusDistance" to focusModes.contains(
                                CameraCharacteristics.CONTROL_AF_MODE_OFF,
                            ),
                            "supportsExposureCompensation" to (
                                exposureRange != null && exposureRange.lower < exposureRange.upper
                            ),
                            "supportsExposureLock" to true,
                            "supportsManualShutter" to false,
                            "supportsIsoControl" to false,
                            "supportsWhiteBalanceLock" to whiteBalanceModes.isNotEmpty(),
                            "supportsManualWhiteBalance" to false,
                            "supportsTorch" to flashAvailable,
                            "supportsFlashAuto" to flashAvailable,
                            "supportsZoom" to (zoomRange != null && zoomRange.upper > 1f),
                            "supportsMacroSelection" to false,
                            "supportsYuvLiveFrames" to true,
                            "supportsRaw" to false,
                            "supportsNativeEdgeSignals" to false,
                            "minZoom" to (zoomRange?.lower ?: 1f).toDouble(),
                            "maxZoom" to (zoomRange?.upper ?: 1f).toDouble(),
                            "minExposureOffset" to (exposureRange?.lower ?: 0).toDouble(),
                            "maxExposureOffset" to (exposureRange?.upper ?: 0).toDouble(),
                            "maxStillWidth" to (maxStillSize?.width ?: 0),
                            "maxStillHeight" to (maxStillSize?.height ?: 0),
                        ),
                    )
                } catch (error: Throwable) {
                    result.success(unavailableCapabilities())
                }
            },
            ContextCompat.getMainExecutor(this),
        )
    }

    private fun findRearCameraCharacteristics(
        cameraManager: CameraManager,
    ): CameraCharacteristics? {
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (lensFacing == CameraCharacteristics.LENS_FACING_BACK) {
                return characteristics
            }
        }
        return null
    }

    private fun hasCameraFacing(cameraManager: CameraManager, lensFacing: Int): Boolean {
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            if (characteristics.get(CameraCharacteristics.LENS_FACING) == lensFacing) {
                return true
            }
        }
        return false
    }

    private fun maxJpegStillSize(characteristics: CameraCharacteristics?): Size? {
        val sizes = characteristics
            ?.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?.getOutputSizes(ImageFormat.JPEG)
            ?: return null
        return sizes.maxByOrNull { size -> size.width.toLong() * size.height.toLong() }
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun openReceiptCamera(
        result: MethodChannel.Result,
        arguments: Map<*, *>?,
    ) {
        if (pendingReceiptCameraResult != null) {
            result.error(
                "native_camera_busy",
                "Maintainiac receipt camera is already open.",
                null,
            )
            return
        }
        if (!hasCameraPermission()) {
            result.error(
                "native_camera_permission",
                "Camera permission is needed to photograph receipts.",
                null,
            )
            return
        }
        pendingReceiptCameraResult = result
        val intent = Intent(this, ReceiptCameraActivity::class.java).apply {
            putExtras(receiptCameraArguments(arguments))
        }
        startActivityForResult(intent, receiptCameraRequestCode)
    }

    private fun receiptCameraArguments(arguments: Map<*, *>?): Bundle {
        val bundle = Bundle()
        if (arguments == null) return bundle
        for ((key, value) in arguments) {
            if (key !is String) continue
            when (value) {
                is Boolean -> bundle.putBoolean(key, value)
                is Int -> bundle.putInt(key, value)
                is Long -> bundle.putLong(key, value)
                is Double -> bundle.putDouble(key, value)
                is Float -> bundle.putFloat(key, value)
                is String -> bundle.putString(key, value)
                is Iterable<*> -> {
                    val strings = ArrayList<String>()
                    value.forEach { entry ->
                        val text = entry?.toString()?.trim()
                        if (!text.isNullOrEmpty()) strings.add(text)
                    }
                    if (strings.isNotEmpty()) bundle.putStringArrayList(key, strings)
                }
            }
        }
        return bundle
    }

    private fun unavailableCapabilities(): Map<String, Any> {
        return mapOf(
            "engine" to "cameraX",
            "available" to false,
            "cameraPermissionGranted" to hasCameraPermission(),
            "cameraCount" to 0,
            "hasRearCamera" to false,
            "hasFrontCamera" to false,
        )
    }
}
