package com.maintainiac

import android.os.SystemClock
import android.widget.Toast
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import java.io.File
import java.time.Instant


internal fun ReceiptCameraActivity.capturePhoto(trigger: String = "manual_shutter") {
    lastCaptureTrigger = trigger
    lastCaptureBlockReason = "none"
    if (trigger == "manual_shutter" || trigger == "manual_add_photo") {
        manualShutterTapCount += 1
    } else if (trigger == "auto_capture") {
        autoCaptureAttemptCount += 1
    }
    val capture = imageCapture
    if (capture == null) {
        captureBlockedNoCameraCount += 1
        lastCaptureBlockReason = "no_camera"
        return
    }
    if (captureInFlight) {
        captureBlockedBusyCount += 1
        lastCaptureBlockReason = "capture_in_flight"
        return
    }
    if (closingCamera) {
        captureBlockedClosingCount += 1
        lastCaptureBlockReason = "closing_camera"
        return
    }
    if (!isCameraSurfaceActive()) {
        captureBlockedSurfaceInactiveCount += 1
        lastCaptureBlockReason = "camera_surface_inactive"
        return
    }
    if (trigger == "manual_shutter" || trigger == "manual_add_photo") {
        manualCaptureStartedCount += 1
    } else if (trigger == "auto_capture") {
        autoCaptureStartedCount += 1
    }
    captureInFlight = true
    latestCaptureStartedElapsedMs = SystemClock.elapsedRealtime()
    latestCaptureToSavedMs = -1L
    latestCaptureToReviewReadyMs = -1L
    latestCaptureLatencyBucket = "capture_started"
    latestCaptureLiveBrightnessAtShutter = latestFrameBrightness
    shutterButton.isEnabled = false
    val outputFile = newReceiptCaptureFile()
    val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
    prepareExposureBeforeCapture {
        performReceiptCapture(capture, outputFile, outputOptions)
    }
}

internal fun ReceiptCameraActivity.performReceiptCapture(
    capture: ImageCapture,
    outputFile: File,
    outputOptions: ImageCapture.OutputFileOptions,
) {
    val activity = this
    if (!isCameraSurfaceActive()) {
        captureInFlight = false
        pendingCloseAfterCapture = false
        if (hasInitializedReceiptCameraField { shutterButton }) shutterButton.isEnabled = true
        return
    }
    capture.takePicture(
        outputOptions,
        mainExecutor(),
        object : ImageCapture.OnImageSavedCallback {
            override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                captureInFlight = false
                if (!isCameraSurfaceActive() || closeResultDelivered) return
                val capturedAt = Instant.now().toString()
                latestCaptureToSavedMs = captureElapsedSinceStart()
                latestCaptureLatencyBucket = captureLatencyBucket(latestCaptureToSavedMs)
                val savedByteSize = outputFile.length()
                if (
                    maxLocalPhotoBytes > 0 &&
                    totalCapturedByteSize + savedByteSize > maxLocalPhotoBytes
                ) {
                    outputFile.delete()
                    latestCaptureLatencyBucket = "capture_rejected_over_byte_budget"
                    lastCaptureBlockReason = "native_capture_over_byte_budget"
                    latestAutoCaptureStatus = "native_capture_over_byte_budget"
                    pendingCloseAfterCapture = false
                    shutterButton.isEnabled = true
                    updateDoneButton()
                    guidance.text =
                        "That receipt photo was too large for this device setting. Try again with the receipt closer and clearer."
                    if (capturedPhotoPaths.isNotEmpty()) {
                        finishWithCapturedPhotos(
                            closeReason = "back_capture_failed_returned_existing_sections",
                        )
                    }
                    return
                }
                if (firstCapturedAt == null) firstCapturedAt = capturedAt
                capturedPhotoPaths.add(outputFile.absolutePath)
                totalCapturedByteSize += savedByteSize
                recordCapturedPhotoQuality(outputFile)
                autoCaptureCooldownUntilMs =
                    System.currentTimeMillis() + autoCaptureCooldownMs
                if (pendingCloseAfterCapture) {
                    pendingCloseAfterCapture = false
                    finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")
                    return
                }
                if (longReceiptMode && capturedPhotoPaths.size < maxSectionCount) {
                    shutterButton.isEnabled = true
                    updateDoneButton()
                    updatePreviousSectionGuide(outputFile.absolutePath)
                    guidance.text =
                        "Section ${capturedPhotoPaths.size} saved. " +
                            "Next photo is section ${capturedPhotoPaths.size + 1}. " +
                            "Line up the ghost guide at the top, repeat 3-5 readable lines, " +
                            "or tap Next: Review Receipt Details."
                } else {
                    finishWithCapturedPhotos()
                }
            }

            override fun onError(exception: ImageCaptureException) {
                captureInFlight = false
                if (!isCameraSurfaceActive() || closeResultDelivered) return
                if (pendingCloseAfterCapture) {
                    finishPendingCloseAfterCaptureFailure()
                    return
                }
                pendingCloseAfterCapture = false
                shutterButton.isEnabled = true
                guidance.text = "That photo did not save. Try again."
                Toast.makeText(
                    activity,
                    "Receipt photo did not save.",
                    Toast.LENGTH_SHORT,
                ).show()
            }
        },
    )
}

internal fun ReceiptCameraActivity.requestCloseCamera(backDispatchPath: String = "unknown") {
    closeRequestCount += 1
    lastBackDispatchPath = backDispatchPath
    if (closeResultDelivered) {
        closeRetryCount += 1
        if (!isFinishing && !isDestroyed) {
            finish()
        }
        return
    }
    if (captureInFlight) {
        closeDuringCaptureCount += 1
        pendingCloseAfterCapture = true
        latestAutoCaptureStatus = "closing_after_capture"
        shutterButton.isEnabled = false
        doneButton.isEnabled = false
        if (hasInitializedReceiptCameraField { addPhotoButton }) addPhotoButton.isEnabled = false
        if (hasInitializedReceiptCameraField { bottomReviewButton }) bottomReviewButton.isEnabled = false
        guidance.text = "Saving this receipt photo before opening review."
        return
    }
    closingCamera = true
    latestAutoCaptureStatus = "closing"
    if (capturedPhotoPaths.isEmpty()) {
        guidance.text = "Closing receipt camera without saving a photo."
        cancelWithoutCapturedPhoto("back_no_photo_cancel")
        return
    }
    guidance.text = "Opening receipt photo review. Captured photos are kept."
    finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")
}
