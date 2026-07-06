package com.maintainiac

import android.app.Activity
import android.os.Bundle
import android.view.KeyEvent
import android.view.ScaleGestureDetector
import android.view.View
import android.widget.Button
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import android.window.OnBackInvokedCallback
import androidx.camera.core.Camera
import androidx.camera.core.ImageCapture
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import java.util.concurrent.Executor

class ReceiptCameraActivity : Activity(), LifecycleOwner {
    internal val lifecycleRegistry = LifecycleRegistry(this)
    internal var systemBackCallback: OnBackInvokedCallback? = null
    internal lateinit var previewView: PreviewView
    internal lateinit var shutterButton: ImageButton
    internal lateinit var torchButton: ImageButton
    internal lateinit var doneButton: Button
    internal lateinit var addPhotoButton: Button
    internal lateinit var bottomReviewButton: Button
    internal lateinit var guidance: TextView
    internal lateinit var receiptFrameGuide: View
    internal lateinit var exposureSlider: SeekBar
    internal lateinit var exposureResetButton: Button
    internal lateinit var settingsStatusStrip: TextView
    internal lateinit var previousSectionGuidePanel: LinearLayout
    internal lateinit var previousSectionGuideImage: ImageView
    internal var imageCapture: ImageCapture? = null
    internal var camera: Camera? = null
    internal var scaleGestureDetector: ScaleGestureDetector? = null
    internal var lastSinglePointerUpAt = 0L
    internal var assistedReceiptFill = true
    internal var longReceiptMode = true
    internal var autoCaptureEnabled = false
    internal var autoCaptureAllowed = false
    internal var deviceTier = "medium"
    internal var settingsContractVersion = "receipt_native_camera_settings_v1"
    internal var devicePolicyLabel = "balanced_receipt_camera"
    internal var reviewDepth = "pricesOnly"
    internal var focusMode = "continuous"
    internal var exposureMode = "auto"
    internal var whiteBalanceMode = "auto"
    internal var whiteBalanceLockEnabled = false
    internal var dataSaverLevel = "balanced"
    internal var storageSafetyLevel = "balanced"
    internal var storageConstrained = false
    internal var storageSafetyReason = "normal"
    internal var workloadProtectionPolicy = "balanced_workload"
    internal var maxLocalPhotoBytes = 12 * 1024 * 1024
    internal var nativeCaptureMemoryPolicy = "bounded_temporary_source_for_ocr_then_cleanup"
    internal var previousSectionGuidePhotoPath: String? = null
    internal var previousSectionReasonCode: String = "none"
    internal var previousSectionGuidance: String = ""
    internal var previousSectionGhostSourceStartFraction = 0.80
    internal var previousSectionGhostSourceHeightFraction = 0.20
    internal var previousSectionGhostOverlayTopFraction = 0.0
    internal var previousSectionGhostOverlayHeightFraction = 0.20
    internal var previousSectionGhostOpacity = 0.36
    internal var liveAnalysisEnabled = true
    internal var edgeDetectionEnabled = true
    internal var edgeOverlayEnabled = true
    internal var lowLightWarningEnabled = false
    internal var glareWarningEnabled = false
    internal var dirtyLensWarningEnabled = false
    internal var motionBlurWarningEnabled = false
    internal var shadowWarningEnabled = false
    internal var tooFarTooCloseWarningEnabled = true
    internal var receiptFullyVisibleWarningEnabled = true
    internal var textTooSmallWarningEnabled = true
    internal var tapFocusEnabled = false
    internal var pinchZoomEnabled = true
    internal var exposureSliderEnabled = true
    internal var exposureResetEnabled = true
    internal var autoExposureAssistEnabled = true
    internal var perspectiveCorrectionEnabled = true
    internal var manualCropAfterCapture = true
    internal var autoCropSuggestionEnabled = true
    internal var grayscalePreviewEnabled = true
    internal var contrastBoostEnabled = true
    internal var sharpeningEnabled = true
    internal var shadowReductionEnabled = true
    internal var adaptiveThresholdEnabled = true
    internal var orientationCorrectionEnabled = true
    internal var saveOriginalTemporarily = true
    internal var queueAcceptedCaptureLocally = true
    internal var ocrUsesOriginalFirst = true
    internal var analysisGapMs = 720L
    internal var readyHoldMs = 700L
    internal var assistedShotCount = 4
    internal var bestShotCandidateCount = 3
    internal var cameraResolutionTier = "high"
    internal var cameraWorkloadTier = "balanced"
    internal val nativePreviewScaleMode = "fit_center_full_receipt"
    internal val nativeControlDensity = "compact_receipt_controls"
    internal var previewExposurePolicy = "receipt_paper_metering_safe_auto_lift_manual_slider"
    internal var previewBrightnessGuardPolicy = "avoid_dark_preview_full_receipt_sampling"
    internal var shutterSpeedPolicy = "prefer_fast_document_shutter_manual_capture_anytime"
    internal val closeCapturedPhotoPolicy =
        "back_returns_captured_sections_before_cancel"
    internal val closeDuringCapturePolicy =
        "wait_for_in_flight_capture_then_return_review"
    internal val closeNoPhotoPolicy =
        "back_without_photo_cancels_without_creating_expense"
    internal val capturedPhotoReviewDestination =
        "receipt_photo_review_then_receipt_details"
    internal var tapToFocusPolicy = "continuous_focus_primary_no_tap_focus"
    internal var focusStrategyPolicy = "continuous_focus_primary_no_tap_assist"
    internal var continuousFocusEnabled = true
    internal var readabilityGuidancePolicy =
        "live_receipt_workflow_guidance_only_unproven_quality_claims_off"
    internal var receiptCameraQualityBaseline = true
    internal var zoomGesturePolicy = "cameraX_zoom_ratio_clamped_to_capability"
    internal var autoCapturePolicy = "off_by_default_manual_shutter_primary"
    internal var preCaptureExposurePolicy = "receipt_paper_metering_dim_rescue_v2_manual_slider"
    internal var nativeControlContractTags = arrayListOf<String>()
    internal var maxLiveAnalysisPixels = 0
    internal var maxCleanupPixels = 10000000
    internal var maxStitchOutputPixels = 14000000
    internal var maxStitchOutputHeight = 18000
    internal var sessionMinZoom = 1.0
    internal var sessionMaxZoom = 1.0
    internal var sessionMinExposureOffset = 0.0
    internal var sessionMaxExposureOffset = 0.0
    internal var lastLiveAnalysisAt = 0L
    internal var latestFrameBrightness = -1.0
    internal var latestShadowScore = -1.0
    internal var latestReadabilitySignal = "unknown"
    internal var latestFramingSignal = "unknown"
    internal var latestFramingConfidence = "unknown"
    internal var latestEdgeCoverage = -1.0
    internal var latestFramingWidthRatio = -1.0
    internal var latestFramingHeightRatio = -1.0
    internal var latestPerspectiveReadiness = "unknown"
    internal var latestMotionSignal = "unknown"
    internal var latestMotionScore = -1.0
    internal var previousLiveLumaSamples: IntArray? = null
    internal var userExposureOverride = false
    internal var autoExposureAdjustmentCount = 0
    internal var preCaptureExposureAdjustmentCount = 0
    internal var preCaptureExposureAdjustmentConfirmedCount = 0
    internal var preCaptureExposureAbortCount = 0
    internal var lastAutoExposureAdjustmentAt = 0L
    internal var lastAutoExposureDecision = "not_evaluated"
    internal var lastPreCaptureExposureDecision = "not_evaluated"
    internal var lastPreCaptureExposureSkipReason = "none"
    internal var lastPreCaptureExposureAbortReason = "none"
    internal var lastAutoExposureBrightnessBucket = "unknown"
    internal var lastAutoExposureCandidate = "none"
    internal var autoExposureCandidateFrameCount = 0
    internal var lastAutoExposureIndex = 0
    internal var lastPreCaptureExposureTargetIndex = 0
    internal var tapFocusCount = 0
    internal var tapFocusSuppressedAfterZoomCount = 0
    internal var zoomChangeCount = 0
    internal var zoomGestureStartCount = 0
    internal var zoomUnavailableCount = 0
    internal var lastZoomStatus = "not_used"
    internal var lastZoomRatio = 1.0
    internal var manualExposureChangeCount = 0
    internal var settingsOpenCount = 0
    internal var settingsResetCount = 0
    internal var lastFocusStatus = "not_used"
    internal var suppressTapFocusUntilMs = 0L
    internal var focusLockAttemptCount = 0
    internal var focusLockSuccessCount = 0
    internal var exposureLockSuccessCount = 0
    internal var whiteBalanceLockStatus = "not_requested"
    internal var autoCaptureStableFrameCount = 0
    internal var autoCaptureStableFrameTarget = 3
    internal var autoCaptureMaxMotionScore = 7.5
    internal var autoCaptureMinBrightness = 112.0
    internal var autoCaptureMaxBrightness = 238.0
    internal var autoCaptureCooldownMs = 2600L
    internal var autoCaptureTriggerCount = 0
    internal var autoCaptureCooldownUntilMs = 0L
    internal var latestAutoCaptureStatus = "off"
    internal var manualShutterTapCount = 0
    internal var manualCaptureStartedCount = 0
    internal var autoCaptureAttemptCount = 0
    internal var autoCaptureStartedCount = 0
    internal var captureBlockedNoCameraCount = 0
    internal var captureBlockedBusyCount = 0
    internal var captureBlockedClosingCount = 0
    internal var captureBlockedSurfaceInactiveCount = 0
    internal var lastCaptureTrigger = "none"
    internal var lastCaptureBlockReason = "none"
    internal var closeAction = "open"
    internal var closeRetryCount = 0
    internal var closeRequestCount = 0
    internal var closeDuringCaptureCount = 0
    internal var closeNoPhotoCancelCount = 0
    internal var closeReturnedSectionsCount = 0
    internal var lastBackDispatchPath = "not_requested"
    internal var maxSectionCount = 8
    internal var torchOn = false
    internal var captureInFlight = false
    internal var closingCamera = false
    internal var pendingCloseAfterCapture = false
    internal var closeResultDelivered = false
    internal val capturedPhotoPaths = arrayListOf<String>()
    internal var firstCapturedAt: String? = null
    internal var totalCapturedByteSize = 0L
    internal var latestCapturedPhotoWidth = 0
    internal var latestCapturedPhotoHeight = 0
    internal var latestCapturedAverageLuma = -1.0
    internal var latestCapturedEdgeScore = -1.0
    internal var latestCapturedTopLuma = -1.0
    internal var latestCapturedMiddleLuma = -1.0
    internal var latestCapturedBottomLuma = -1.0
    internal var latestCapturedBottomEdgeScore = -1.0
    internal var latestCapturedBottomTopLumaDelta = -10000.0
    internal var latestCapturedBottomTopLumaDeltaBucket = "unknown"
    internal var latestCapturedVerticalQualitySignal = "unknown"
    internal var latestCapturedMegapixelBucket = "unknown"
    internal var latestCapturedByteBucket = "unknown"
    internal var latestCapturedBrightnessBucket = "unknown"
    internal var latestCapturedSharpnessBucket = "unknown"
    internal var latestCapturedQualitySignal = "unknown"
    internal var latestCaptureLiveBrightnessAtShutter = -1.0
    internal var latestCapturedLiveToSavedLumaDelta = -10000.0
    internal var latestCapturedLiveToSavedLumaDeltaBucket = "unknown"
    internal var latestCapturedPreviewParitySignal = "unknown"
    internal var latestCapturedExposureMismatch = "unknown"
    internal var capturedLightingEvidence = "unknown"
    internal var latestCaptureStartedElapsedMs = 0L
    internal var latestCaptureToSavedMs = -1L
    internal var latestCaptureToReviewReadyMs = -1L
    internal var latestCaptureLatencyBucket = "unknown"
    internal var stillCaptureModeLabel = "receipt_fast_document_shutter"
    internal var stillCaptureJpegQuality = 95

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        readSessionArguments()
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
        registerSystemBackHandler()
        setContentView(buildContentView())
        startCamera()
    }

    override fun onStart() {
        super.onStart()
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
    }

    override fun onResume() {
        super.onResume()
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    override fun onPause() {
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        super.onPause()
    }

    override fun onStop() {
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
        super.onStop()
    }

    override fun onDestroy() {
        closingCamera = true
        unregisterSystemBackHandler()
        runCatching {
            ProcessCameraProvider.getInstance(this).get().unbindAll()
        }
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        requestCloseCamera(backDispatchPath = "legacy_on_back_pressed")
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            requestCloseCamera(backDispatchPath = "hardware_key_up")
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    internal fun mainExecutor(): Executor = ContextCompat.getMainExecutor(this)

    internal fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    companion object {
        const val extraOriginalPhotoPaths = "originalPhotoPaths"
        const val extraCapturedAt = "capturedAt"
        const val extraCaptureDiagnostics = "captureDiagnostics"
        const val extraCloseAction = "closeAction"
    }
}
