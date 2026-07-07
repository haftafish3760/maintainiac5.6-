package com.maintainiac

import android.app.Activity
import android.content.Intent
import android.os.SystemClock
import android.view.View
import java.io.File
import java.time.Instant
import java.util.UUID


internal fun ReceiptCameraActivity.finishWithCapturedPhotos(closeReason: String = "done_returned_captured_sections") {
    if (closeResultDelivered) return
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if (capturedPhotoPaths.isEmpty()) {
        cancelWithoutCapturedPhoto("done_no_photo_cancel")
        return
    }
    closeAction = closeReason
    if (
        closeReason == "back_returned_captured_sections" ||
        closeReason == "back_capture_failed_returned_existing_sections"
    ) {
        closeReturnedSectionsCount += 1
    }
    latestCaptureToReviewReadyMs = captureElapsedSinceStart()
    latestCaptureLatencyBucket = captureReviewLatencyBucket(latestCaptureToReviewReadyMs)
    closeResultDelivered = true
    val capturedAt = firstCapturedAt ?: Instant.now().toString()
    val data = Intent().apply {
        putStringArrayListExtra(ReceiptCameraActivity.extraOriginalPhotoPaths, capturedPhotoPaths)
        putExtra(ReceiptCameraActivity.extraCapturedAt, capturedAt)
        putExtra(
            ReceiptCameraActivity.extraCaptureDiagnostics,
            nativeCaptureDiagnostics(totalCapturedByteSize, capturedAt),
        )
    }
    setResult(Activity.RESULT_OK, data)
    finish()
}

internal fun ReceiptCameraActivity.updateDoneButton() {
    doneButton.visibility = View.GONE
    doneButton.isEnabled = capturedPhotoPaths.isNotEmpty()
    val count = capturedPhotoPaths.size
    val title = when (count) {
        0 -> "Next"
        1 -> "Next"
        else -> "Next ($count)"
    }
    doneButton.text = title
    doneButton.contentDescription =
        "Next: review captured receipt photos in Maintainiac"
    if (hasInitializedReceiptCameraField { addPhotoButton }) {
        addPhotoButton.visibility = if (
            capturedPhotoPaths.isEmpty() ||
            !longReceiptMode ||
            capturedPhotoPaths.size >= maxSectionCount
        ) {
            View.GONE
        } else {
            View.VISIBLE
        }
        addPhotoButton.isEnabled = addPhotoButton.visibility == View.VISIBLE
        addPhotoButton.text = addSectionButtonTitle()
        addPhotoButton.contentDescription = addSectionButtonAccessibilityLabel()
    }
    if (hasInitializedReceiptCameraField { shutterButton }) {
        shutterButton.contentDescription = "Take receipt photo"
    }
    if (hasInitializedReceiptCameraField { bottomReviewButton }) {
        bottomReviewButton.visibility = if (capturedPhotoPaths.isEmpty()) {
            View.GONE
        } else {
            View.VISIBLE
        }
        bottomReviewButton.isEnabled = capturedPhotoPaths.isNotEmpty()
        bottomReviewButton.text = title
        bottomReviewButton.contentDescription =
            "Next: review captured receipt photos in Maintainiac"
    }
    updateSettingsStatusStrip()
}

internal fun ReceiptCameraActivity.captureElapsedSinceStart(): Long {
    if (latestCaptureStartedElapsedMs <= 0L) return -1L
    return (SystemClock.elapsedRealtime() - latestCaptureStartedElapsedMs).coerceAtLeast(0L)
}

internal fun ReceiptCameraActivity.captureLatencyBucket(milliseconds: Long): String {
    return when {
        milliseconds < 0L -> "unknown"
        milliseconds <= 450L -> "save_fast_under_450ms"
        milliseconds <= 900L -> "save_good_under_900ms"
        milliseconds <= 1600L -> "save_review_under_1600ms"
        milliseconds <= 2800L -> "save_slow_under_2800ms"
        else -> "save_very_slow_over_2800ms"
    }
}

internal fun ReceiptCameraActivity.captureReviewLatencyBucket(milliseconds: Long): String {
    return when {
        milliseconds < 0L -> latestCaptureLatencyBucket
        milliseconds <= 700L -> "review_fast_under_700ms"
        milliseconds <= 1200L -> "review_good_under_1200ms"
        milliseconds <= 2200L -> "review_watch_under_2200ms"
        milliseconds <= 3800L -> "review_slow_under_3800ms"
        else -> "review_very_slow_over_3800ms"
    }
}

internal fun ReceiptCameraActivity.toggleTorch() {
    val cameraControl = camera?.cameraControl ?: return
    torchOn = !torchOn
    cameraControl.enableTorch(torchOn)
    torchButton.contentDescription = if (torchOn) "Turn light off" else "Turn light on"
}

internal fun ReceiptCameraActivity.newReceiptCaptureFile(): File {
    val directory = File(cacheDir, "receipt_camera").apply {
        if (!exists()) mkdirs()
    }
    return File(directory, "receipt_${System.currentTimeMillis()}_${UUID.randomUUID()}.jpg")
}
