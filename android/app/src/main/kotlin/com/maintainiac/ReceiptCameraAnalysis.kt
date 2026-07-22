package com.maintainiac

import android.hardware.camera2.CaptureRequest
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import android.view.Surface
import android.widget.Toast
import androidx.camera.core.AspectRatio
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import kotlin.math.min


internal fun ReceiptCameraActivity.startCamera() {
    if (cameraStartInProgress || closingCamera || closeResultDelivered) return
    cameraStartInProgress = true
    cameraStartAttemptCount += 1
    lastCameraStartStatus = "provider_requested"
    val providerFuture = ProcessCameraProvider.getInstance(this)
    providerFuture.addListener(
        {
            if (!isCameraSurfaceActive()) {
                cameraStartInProgress = false
                lastCameraStartStatus = "surface_inactive"
                return@addListener
            }
            val provider = runCatching { providerFuture.get() }.getOrElse { error ->
                handleCameraStartFailure(error)
                return@addListener
            }
            cameraProvider = provider
            if (!isCameraSurfaceActive()) {
                runCatching { provider.unbindAll() }
                cameraStartInProgress = false
                lastCameraStartStatus = "surface_inactive"
                return@addListener
            }
            val targetRotation = previewView.display?.rotation ?: Surface.ROTATION_0
            val preview = Preview.Builder()
                .setTargetRotation(targetRotation)
                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build().apply {
                setSurfaceProvider(previewView.surfaceProvider)
            }
            val captureMode = receiptStillCaptureMode()
            stillCaptureJpegQuality = receiptStillJpegQuality()
            imageCapture = ImageCapture.Builder()
                .setTargetRotation(targetRotation)
                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
                .setCaptureMode(captureMode)
                .setJpegQuality(stillCaptureJpegQuality)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build()
            val imageAnalysis = buildImageAnalysis(targetRotation)
            try {
                provider.unbindAll()
                if (!isCameraSurfaceActive()) {
                    cameraStartInProgress = false
                    lastCameraStartStatus = "surface_inactive"
                    return@addListener
                }
                camera = if (imageAnalysis == null) {
                    provider.bindToLifecycle(
                        this,
                        CameraSelector.DEFAULT_BACK_CAMERA,
                        preview,
                        imageCapture,
                    )
                } else {
                    provider.bindToLifecycle(
                        this,
                        CameraSelector.DEFAULT_BACK_CAMERA,
                        preview,
                        imageCapture,
                        imageAnalysis,
                    )
                }
                torchButton.isEnabled = camera?.cameraInfo?.hasFlashUnit() == true
                lastFocusStatus = receiptContinuousFocusStatus()
                configureTouchControls()
                configureExposureControls()
                guidance.text = guidanceText()
                cameraStartInProgress = false
                lastCameraStartStatus = "ready"
            } catch (error: Throwable) {
                runCatching { provider.unbindAll() }
                handleCameraStartFailure(error)
            }
        },
        mainExecutor(),
    )
}

internal fun ReceiptCameraActivity.handleCameraStartFailure(error: Throwable) {
    cameraStartInProgress = false
    cameraStartFailureCount += 1
    camera = null
    imageCapture = null
    if (hasInitializedReceiptCameraField { torchButton }) torchButton.isEnabled = false
    if (hasInitializedReceiptCameraField { shutterButton }) shutterButton.isEnabled = false
    val reason = if (error is SecurityException) "permission_denied" else "provider_unavailable"
    lastCameraStartStatus = reason
    if (cameraStartAttemptCount < 2 && isCameraSurfaceActive()) {
        lastCameraStartStatus = "retry_scheduled_$reason"
        guidance.text = "Restarting the receipt camera."
        previewView.postDelayed(
            {
                if (isCameraSurfaceActive() && !closingCamera && camera == null) startCamera()
            },
            350L,
        )
        return
    }
    guidance.text = "The receipt camera could not open. Returning to backup choices."
    Toast.makeText(this, "Receipt camera could not open.", Toast.LENGTH_LONG).show()
    cancelForCameraStartupFailure(reason)
}

internal fun ReceiptCameraActivity.receiptContinuousFocusStatus(): String {
    return when {
        continuousFocusEnabled && focusMode == "continuous" -> "continuous_autofocus_configured"
        focusMode == "continuous" -> "continuous_autofocus_unavailable"
        else -> "continuous_focus_not_requested"
    }
}

@OptIn(ExperimentalCamera2Interop::class)
internal fun Preview.Builder.applyReceiptContinuousFocusIfEnabled(
    activity: ReceiptCameraActivity,
): Preview.Builder {
    if (!activity.continuousFocusEnabled || activity.focusMode != "continuous") return this
    Camera2Interop.Extender(this)
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AF_MODE,
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
        )
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AE_MODE,
            CaptureRequest.CONTROL_AE_MODE_ON,
        )
    return this
}

@OptIn(ExperimentalCamera2Interop::class)
internal fun ImageCapture.Builder.applyReceiptContinuousFocusIfEnabled(
    activity: ReceiptCameraActivity,
): ImageCapture.Builder {
    if (!activity.continuousFocusEnabled || activity.focusMode != "continuous") return this
    Camera2Interop.Extender(this)
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AF_MODE,
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE,
        )
        .setCaptureRequestOption(
            CaptureRequest.CONTROL_AE_MODE,
            CaptureRequest.CONTROL_AE_MODE_ON,
        )
    return this
}

internal fun ReceiptCameraActivity.receiptStillCaptureMode(): Int {
    return when (cameraWorkloadTier) {
        "light" -> {
            stillCaptureModeLabel = "receipt_latency_light_device"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
        "flagship" -> {
            stillCaptureModeLabel = "receipt_fast_document_shutter"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
        else -> {
            stillCaptureModeLabel = "receipt_fast_document_shutter"
            ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY
        }
    }
}

internal fun ReceiptCameraActivity.receiptStillJpegQuality(): Int {
    return when (cameraWorkloadTier) {
        "flagship" -> 96
        "light" -> 94
        else -> 95
    }
}

internal fun ReceiptCameraActivity.buildImageAnalysis(targetRotation: Int): ImageAnalysis? {
    val experimentalQualityWarningsEnabled =
        experimentalLiveReceiptQualityPolicyEnabled() && (
            lowLightWarningEnabled ||
                glareWarningEnabled ||
                motionBlurWarningEnabled ||
                shadowWarningEnabled ||
                dirtyLensWarningEnabled
            )
    // Keep the default manual camera responsive. The phone already handles
    // autofocus and exposure; expensive frame analysis is reserved for the
    // user-enabled automatic capture or experimental warning modes.
    val needsLiveAnalysis = autoCaptureEnabled || experimentalQualityWarningsEnabled
    if (!liveAnalysisEnabled || !needsLiveAnalysis) {
        return null
    }
    return ImageAnalysis.Builder()
        .setTargetRotation(targetRotation)
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        .build()
        .apply {
            setAnalyzer(cameraAnalysisExecutor) { image -> analyzeLiveFrame(image) }
        }
}

internal fun ReceiptCameraActivity.hasExperimentalReceiptQualityWarningsEnabled(): Boolean {
    if (!experimentalLiveReceiptQualityPolicyEnabled()) {
        return false
    }
    return motionBlurWarningEnabled ||
        lowLightWarningEnabled ||
        glareWarningEnabled ||
        shadowWarningEnabled ||
        dirtyLensWarningEnabled
}

internal fun ReceiptCameraActivity.updateExperimentalReceiptQualityGuidance(
    signal: String,
    message: String,
) {
    if (stableExperimentalReceiptQualitySignal(signal)) {
        guidance.text = message
    } else {
        resetExperimentalReceiptQualityGuidanceIfNeeded()
    }
}

internal fun ReceiptCameraActivity.stableExperimentalReceiptQualitySignal(signal: String): Boolean {
    if (experimentalReceiptQualityCandidateSignal == signal) {
        experimentalReceiptQualityCandidateCount += 1
    } else {
        experimentalReceiptQualityCandidateSignal = signal
        experimentalReceiptQualityCandidateCount = 1
    }
    return experimentalReceiptQualityCandidateCount >= experimentalReceiptQualityRequiredFrames
}

internal fun ReceiptCameraActivity.resetExperimentalReceiptQualityCandidate() {
    experimentalReceiptQualityCandidateSignal = "none"
    experimentalReceiptQualityCandidateCount = 0
}

internal fun ReceiptCameraActivity.resetExperimentalReceiptQualityGuidanceIfNeeded() {
    val currentGuidance = guidance.text.toString()
    if (
        currentGuidance.startsWith("Receipt quality needs another look") ||
        currentGuidance.startsWith("Hold steady so the receipt text stays sharp") ||
        currentGuidance.startsWith("Receipt looks dark") ||
        currentGuidance.startsWith("Receipt is very bright") ||
        currentGuidance.startsWith("Receipt has heavy shadows") ||
        currentGuidance.startsWith("Lens may be smudged")
    ) {
        guidance.text = guidanceText()
    }
}

internal fun ReceiptCameraActivity.averageLuma(image: ImageProxy): Double {
    val plane = image.planes.firstOrNull() ?: return -1.0
    val buffer = plane.buffer.duplicate()
    val remaining = buffer.remaining()
    if (remaining <= 0) return -1.0
    val sampleLimit = 2048
    val step = maxOf(1, remaining / sampleLimit)
    var sum = 0L
    var count = 0
    while (buffer.hasRemaining()) {
        sum += (buffer.get().toInt() and 0xFF).toLong()
        count += 1
        if (step > 1 && buffer.hasRemaining()) {
            buffer.position(min(buffer.limit(), buffer.position() + step - 1))
        }
    }
    return if (count == 0) -1.0 else sum.toDouble() / count.toDouble()
}
