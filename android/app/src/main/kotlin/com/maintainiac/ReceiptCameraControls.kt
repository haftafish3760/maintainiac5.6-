package com.maintainiac

import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import androidx.camera.core.FocusMeteringAction
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt


internal fun ReceiptCameraActivity.configureTouchControls() {
    scaleGestureDetector = ScaleGestureDetector(
        this,
        object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScaleBegin(detector: ScaleGestureDetector): Boolean {
                if (!pinchZoomEnabled) return false
                zoomGestureStartCount += 1
                lastZoomStatus = if (camera == null) {
                    zoomUnavailableCount += 1
                    "camera_unavailable"
                } else {
                    "gesture_started"
                }
                return camera != null
            }

            override fun onScale(detector: ScaleGestureDetector): Boolean {
                if (!pinchZoomEnabled) {
                    lastZoomStatus = "disabled"
                    return false
                }
                val activeCamera = camera
                if (activeCamera == null) {
                    zoomUnavailableCount += 1
                    lastZoomStatus = "camera_unavailable"
                    return false
                }
                val zoomState = activeCamera.cameraInfo.zoomState.value
                if (zoomState == null) {
                    zoomUnavailableCount += 1
                    lastZoomStatus = "zoom_state_unavailable"
                    return false
                }
                val minZoom = effectiveMinZoom(zoomState.minZoomRatio)
                val maxZoom = effectiveMaxZoom(zoomState.minZoomRatio, zoomState.maxZoomRatio)
                val nextZoom = (
                    zoomState.zoomRatio * detector.scaleFactor
                ).coerceIn(minZoom, maxZoom)
                if (nextZoom == zoomState.zoomRatio && minZoom == maxZoom) {
                    lastZoomStatus = "zoom_range_locked"
                    zoomUnavailableCount += 1
                    return false
                }
                activeCamera.cameraControl.setZoomRatio(nextZoom)
                zoomChangeCount += 1
                lastZoomRatio = roundedDiagnostic(nextZoom.toDouble())
                lastZoomStatus = "zoom_changed"
                suppressTapFocusUntilMs = System.currentTimeMillis() + 350L
                guidance.text = "Zoom ${(nextZoom * 10).roundToInt() / 10.0}x"
                return true
            }
        },
    )
    val previewTouchListener = View.OnTouchListener { view, event ->
        if (!tapFocusEnabled && !pinchZoomEnabled) {
            return@OnTouchListener false
        }
        if (pinchZoomEnabled) {
            scaleGestureDetector?.onTouchEvent(event)
        }
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                view.parent?.requestDisallowInterceptTouchEvent(true)
                return@OnTouchListener true
            }
            MotionEvent.ACTION_POINTER_DOWN,
            MotionEvent.ACTION_MOVE -> {
                return@OnTouchListener true
            }
            MotionEvent.ACTION_UP -> {
                view.parent?.requestDisallowInterceptTouchEvent(false)
                view.performClick()
                if (tapFocusEnabled && event.pointerCount == 1) {
                    val nowMs = System.currentTimeMillis()
                    if (nowMs < suppressTapFocusUntilMs) {
                        tapFocusSuppressedAfterZoomCount += 1
                        lastFocusStatus = "tap_focus_suppressed_after_zoom"
                        return@OnTouchListener true
                    }
                    if (nowMs - lastSinglePointerUpAt <= 250) {
                        return@OnTouchListener true
                    }
                    lastSinglePointerUpAt = nowMs
                    focusAt(event.x, event.y)
                }
                return@OnTouchListener true
            }
            MotionEvent.ACTION_CANCEL -> {
                view.parent?.requestDisallowInterceptTouchEvent(false)
                return@OnTouchListener true
            }
            else -> return@OnTouchListener true
        }
    }
    previewView.setOnTouchListener(previewTouchListener)
    if (hasInitializedReceiptCameraField { receiptFrameGuide }) {
        receiptFrameGuide.setOnTouchListener(previewTouchListener)
    }
}

internal fun ReceiptCameraActivity.focusAt(x: Float, y: Float) {
    val activeCamera = camera ?: return
    val point = previewView.meteringPointFactory.createPoint(x, y)
    val shouldLockFocus = focusMode == "locked"
    val shouldLockExposure = exposureMode == "locked"
    val shouldLockWhiteBalance = whiteBalanceLockEnabled && whiteBalanceMode == "locked"
    val builder = FocusMeteringAction.Builder(point, FocusMeteringAction.FLAG_AF)
        .addPoint(point, FocusMeteringAction.FLAG_AE)
    whiteBalanceLockStatus = if (shouldLockWhiteBalance) {
        "not_supported_cameraX"
    } else {
        "not_requested"
    }
    if (shouldLockFocus || shouldLockExposure || shouldLockWhiteBalance) {
        builder.disableAutoCancel()
        focusLockAttemptCount += 1
    } else {
        builder.setAutoCancelDuration(4, TimeUnit.SECONDS)
    }
    val action = builder.build()
    val future = activeCamera.cameraControl.startFocusAndMetering(action)
    tapFocusCount += 1
    lastFocusStatus = "requested"
    guidance.text = "Focus set. Hold steady, then tap the shutter."
    if (shouldLockFocus || shouldLockExposure) {
        future.addListener(
            {
                val result = runCatching { future.get() }.getOrNull()
                if (result?.isFocusSuccessful == true) {
                    if (shouldLockFocus) focusLockSuccessCount += 1
                    if (shouldLockExposure) exposureLockSuccessCount += 1
                    lastFocusStatus = "locked"
                    guidance.text = "Focus locked. Tap the shutter when the receipt is readable."
                } else {
                    lastFocusStatus = "lock_not_confirmed"
                }
            },
            mainExecutor(),
        )
    }
}

internal fun ReceiptCameraActivity.maybeAutoCapture(
    framing: LiveReceiptFraming,
    brightness: Double,
    motionScore: Double,
    nowMs: Long,
) {
    if (!autoCaptureEnabled) {
        autoCaptureStableFrameCount = 0
        latestAutoCaptureStatus = "off"
        return
    }
    if (closingCamera || isFinishing || isDestroyed) {
        autoCaptureStableFrameCount = 0
        latestAutoCaptureStatus = "closing"
        return
    }
    if (captureInFlight || nowMs < autoCaptureCooldownUntilMs) {
        latestAutoCaptureStatus = "cooling_down"
        return
    }
    val edgesReady = framing.found &&
        !framing.touchesEdge &&
        (framing.confidenceBucket == "strong_edges" ||
            framing.confidenceBucket == "usable_edges")
    val steady = motionScore in 0.0..autoCaptureMaxMotionScore
    val lightReady = brightness in autoCaptureMinBrightness..autoCaptureMaxBrightness
    val qualityReviewNeeded = latestReadabilitySignal == "shadow_risk" ||
        latestReadabilitySignal == "dirty_lens_or_haze"
    if (!edgesReady || !steady || !lightReady || qualityReviewNeeded) {
        autoCaptureStableFrameCount = 0
        latestAutoCaptureStatus = when {
            !edgesReady -> "waiting_for_edges"
            !steady -> "waiting_for_steady"
            !lightReady -> "waiting_for_light"
            qualityReviewNeeded -> "waiting_for_quality_review"
            else -> "waiting"
        }
        return
    }
    autoCaptureStableFrameCount += 1
    latestAutoCaptureStatus = "ready_${autoCaptureStableFrameCount}_of_$autoCaptureStableFrameTarget"
    if (autoCaptureStableFrameCount < autoCaptureStableFrameTarget) return
    autoCaptureStableFrameCount = 0
    autoCaptureTriggerCount += 1
    autoCaptureCooldownUntilMs = nowMs + autoCaptureCooldownMs
    latestAutoCaptureStatus = "capturing"
    guidance.text = "Receipt looks steady. Taking photo."
    capturePhoto("auto_capture")
}

internal fun ReceiptCameraActivity.closeCapturedPhotoOutcome(): String {
    return when {
        closeAction == "back_returned_captured_sections" -> "back_returned_captured_sections"
        closeAction == "done_returned_captured_sections" -> "next_returned_captured_sections"
        closeAction == "back_capture_failed_returned_existing_sections" ->
            "capture_failed_returned_existing_sections"
        closeAction.contains("capture_failed") -> "capture_failed_after_close"
        closeAction.endsWith("no_photo_cancel") -> "closed_without_photo"
        pendingCloseAfterCapture -> "waiting_for_in_flight_capture"
        closeRetryCount > 0 -> "close_already_delivered"
        else -> "open_or_not_closed"
    }
}
