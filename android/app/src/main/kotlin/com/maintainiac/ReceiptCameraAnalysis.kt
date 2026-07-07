package com.maintainiac

import android.hardware.camera2.CaptureRequest
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import android.view.Surface
import android.widget.Toast
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import kotlin.math.min


internal fun ReceiptCameraActivity.startCamera() {
    val providerFuture = ProcessCameraProvider.getInstance(this)
    providerFuture.addListener(
        {
            if (!isCameraSurfaceActive()) return@addListener
            val provider = providerFuture.get()
            if (!isCameraSurfaceActive()) {
                runCatching { provider.unbindAll() }
                return@addListener
            }
            val targetRotation = previewView.display?.rotation ?: Surface.ROTATION_0
            val preview = Preview.Builder()
                .setTargetRotation(targetRotation)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build().apply {
                setSurfaceProvider(previewView.surfaceProvider)
            }
            val captureMode = receiptStillCaptureMode()
            stillCaptureJpegQuality = receiptStillJpegQuality()
            imageCapture = ImageCapture.Builder()
                .setTargetRotation(targetRotation)
                .setCaptureMode(captureMode)
                .setJpegQuality(stillCaptureJpegQuality)
                .applyReceiptContinuousFocusIfEnabled(this)
                .build()
            val imageAnalysis = buildImageAnalysis(targetRotation)
            try {
                provider.unbindAll()
                if (!isCameraSurfaceActive()) return@addListener
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
            } catch (error: Throwable) {
                guidance.text = "The receipt camera could not open."
                Toast.makeText(this, "Receipt camera could not open.", Toast.LENGTH_LONG).show()
            }
        },
        mainExecutor(),
    )
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
    if (
        !liveAnalysisEnabled ||
        (
                !experimentalQualityWarningsEnabled &&
                !edgeDetectionEnabled &&
                !tooFarTooCloseWarningEnabled &&
                !receiptFullyVisibleWarningEnabled &&
                !textTooSmallWarningEnabled &&
                !autoExposureAssistEnabled
            )
    ) {
        return null
    }
    return ImageAnalysis.Builder()
        .setTargetRotation(targetRotation)
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        .build()
        .apply {
            setAnalyzer(mainExecutor()) { image -> analyzeLiveFrame(image) }
        }
}

internal fun ReceiptCameraActivity.analyzeLiveFrame(image: ImageProxy) {
    try {
        if (!isCameraSurfaceActive() || closeResultDelivered) return
        val now = System.currentTimeMillis()
        if (now - lastLiveAnalysisAt < analysisGapMs) return
        lastLiveAnalysisAt = now
        val lumaSamples = sampleLiveLumaGrid(image)
        val motionScore = evaluateLiveMotion(lumaSamples)
        val shadowScore = estimateShadowScore(lumaSamples)
        val brightness = averageLuma(image)
        latestFrameBrightness = brightness
        latestShadowScore = shadowScore
        var framing = LiveReceiptFraming()
        var hasReceiptTarget = !edgeDetectionEnabled
        if (edgeDetectionEnabled) {
            framing = estimateReceiptFraming(image)
            applyLiveFraming(framing)
            hasReceiptTarget = hasUsableLiveFramingBounds(framing)
            maybeAutoCapture(framing, brightness, motionScore, now)
            autoAdjustExposureForLiveFrame(brightness, now, framing)
        } else {
            latestFramingSignal = "edge_detection_off"
            latestFramingConfidence = "off"
            latestEdgeCoverage = -1.0
            latestPerspectiveReadiness = "perspective_skipped_edge_detection_off"
            autoCaptureStableFrameCount = 0
            latestAutoCaptureStatus = if (autoCaptureEnabled) {
                "waiting_for_edges"
            } else {
                "off"
            }
            lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
            lastAutoExposureDecision = "waiting_for_receipt_target"
        }
        if (!hasReceiptTarget) {
            latestMotionSignal = "waiting_for_receipt_target"
            latestReadabilitySignal = "waiting_for_receipt_target"
            resetExperimentalReceiptQualityCandidate()
            resetExperimentalReceiptQualityGuidanceIfNeeded()
            return
        }
        if (!hasReliableLiveReceiptTargetForQualityWarnings(framing)) {
            latestMotionSignal = "waiting_for_receipt_target"
            latestReadabilitySignal = "waiting_for_receipt_target"
            resetExperimentalReceiptQualityCandidate()
            resetExperimentalReceiptQualityGuidanceIfNeeded()
            return
        }
        if (!hasExperimentalReceiptQualityWarningsEnabled()) {
            latestMotionSignal = "neutral_workflow_guidance_only"
            latestReadabilitySignal = "neutral_workflow_guidance_only"
            resetExperimentalReceiptQualityCandidate()
            resetExperimentalReceiptQualityGuidanceIfNeeded()
            return
        }
        if (!brightness.isFinite() || !motionScore.isFinite() || !shadowScore.isFinite()) {
            latestMotionSignal = "unknown"
            latestReadabilitySignal = "readability_unknown"
            updateExperimentalReceiptQualityGuidance(
                "readability_unknown",
                "Receipt quality needs another look. Keep it flat and readable.",
            )
        } else if (motionBlurWarningEnabled && motionScore > 22.0) {
            latestMotionSignal = "moving_too_much"
            updateExperimentalReceiptQualityGuidance(
                "moving_too_much",
                "Hold steady so the receipt text stays sharp.",
            )
        } else if (lowLightWarningEnabled && brightness in 0.0..58.0) {
            latestReadabilitySignal = "low_light"
            updateExperimentalReceiptQualityGuidance(
                "low_light",
                "Receipt looks dark. Add light or raise Brightness.",
            )
        } else if (glareWarningEnabled && brightness >= 246.0) {
            latestReadabilitySignal = "glare_or_overbright"
            updateExperimentalReceiptQualityGuidance(
                "glare_or_overbright",
                "Receipt is very bright. Tilt it or lower Brightness.",
            )
        } else if (shadowWarningEnabled && shadowScore >= 150.0) {
            latestReadabilitySignal = "shadow_risk"
            updateExperimentalReceiptQualityGuidance(
                "shadow_risk",
                "Receipt has heavy shadows. Move it into even light.",
            )
        } else if (dirtyLensWarningEnabled && brightness in 120.0..235.0 &&
            shadowScore in 0.0..24.0 && motionScore in 0.0..7.0
        ) {
            latestReadabilitySignal = "dirty_lens_or_haze"
            updateExperimentalReceiptQualityGuidance(
                "dirty_lens_or_haze",
                "Lens may be smudged. Wipe it if the receipt looks hazy.",
            )
        } else {
            latestMotionSignal = if (motionScore >= 0) "steady" else "unknown"
            latestReadabilitySignal = "lighting_ok"
            resetExperimentalReceiptQualityCandidate()
            resetExperimentalReceiptQualityGuidanceIfNeeded()
        }
    } finally {
        image.close()
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
    return experimentalReceiptQualityCandidateCount >= 2
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
