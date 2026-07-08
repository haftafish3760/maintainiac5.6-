package com.maintainiac

import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
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
                if (!zoomState.zoomRatio.isFinite() || !detector.scaleFactor.isFinite()) {
                    zoomUnavailableCount += 1
                    lastZoomStatus = "zoom_invalid_scale"
                    return false
                }
                val nextZoom = (
                    zoomState.zoomRatio * detector.scaleFactor
                ).coerceIn(minZoom, maxZoom)
                if (!nextZoom.isFinite()) {
                    zoomUnavailableCount += 1
                    lastZoomStatus = "zoom_invalid_scale"
                    return false
                }
                if (nextZoom == zoomState.zoomRatio && minZoom == maxZoom) {
                    lastZoomStatus = "zoom_range_locked"
                    zoomUnavailableCount += 1
                    return false
                }
                activeCamera.cameraControl.setZoomRatio(nextZoom)
                zoomChangeCount += 1
                lastZoomRatio = roundedDiagnostic(nextZoom.toDouble())
                lastZoomStatus = "zoom_changed"
                guidance.text = "Zoom ${(nextZoom * 10).roundToInt() / 10.0}x"
                return true
            }
        },
    )
    val previewTouchListener = View.OnTouchListener { view, event ->
        if (!pinchZoomEnabled) {
            return@OnTouchListener false
        }
        if (event.pointerCount > 1 || event.actionMasked == MotionEvent.ACTION_POINTER_DOWN) {
            scaleGestureDetector?.onTouchEvent(event)
        }
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                return@OnTouchListener false
            }
            MotionEvent.ACTION_POINTER_DOWN -> {
                view.parent?.requestDisallowInterceptTouchEvent(true)
                return@OnTouchListener true
            }
            MotionEvent.ACTION_POINTER_UP -> {
                view.parent?.requestDisallowInterceptTouchEvent(false)
                restoreWorkflowGuidanceIfNeeded()
                return@OnTouchListener true
            }
            MotionEvent.ACTION_MOVE -> {
                return@OnTouchListener event.pointerCount > 1
            }
            MotionEvent.ACTION_UP -> {
                view.parent?.requestDisallowInterceptTouchEvent(false)
                restoreWorkflowGuidanceIfNeeded()
                return@OnTouchListener false
            }
            MotionEvent.ACTION_CANCEL -> {
                view.parent?.requestDisallowInterceptTouchEvent(false)
                restoreWorkflowGuidanceIfNeeded()
                return@OnTouchListener false
            }
            else -> return@OnTouchListener false
        }
    }
    previewView.setOnTouchListener(previewTouchListener)
    if (hasInitializedReceiptCameraField { receiptFrameGuide }) {
        receiptFrameGuide.setOnTouchListener(previewTouchListener)
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
        hasUsableLiveFramingBounds(framing) &&
        !framing.touchesEdge &&
        (framing.confidenceBucket == "strong_edges" ||
            framing.confidenceBucket == "usable_edges")
    val steady = motionScore in 0.0..autoCaptureMaxMotionScore
    val lightReady = brightness in autoCaptureMinBrightness..autoCaptureMaxBrightness
    val qualityReviewNeeded =
        receiptQualityReviewReadabilitySignals().contains(latestReadabilitySignal)
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

internal fun receiptQualityReviewReadabilitySignals(): Set<String> {
    return setOf("shadow_risk", "dirty_lens_or_haze")
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
