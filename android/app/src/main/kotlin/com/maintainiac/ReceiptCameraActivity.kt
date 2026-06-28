package com.maintainiac

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.Surface
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import java.io.File
import java.time.Instant
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class ReceiptCameraActivity : Activity(), LifecycleOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)
    private var systemBackCallback: OnBackInvokedCallback? = null
    private lateinit var previewView: PreviewView
    private lateinit var shutterButton: ImageButton
    private lateinit var torchButton: ImageButton
    private lateinit var doneButton: Button
    private lateinit var guidance: TextView
    private lateinit var receiptFrameGuide: View
    private lateinit var exposureSlider: SeekBar
    private lateinit var exposureResetButton: Button
    private lateinit var settingsStatusStrip: TextView
    private lateinit var previousSectionGuidePanel: LinearLayout
    private lateinit var previousSectionGuideImage: ImageView
    private var imageCapture: ImageCapture? = null
    private var camera: Camera? = null
    private var scaleGestureDetector: ScaleGestureDetector? = null
    private var lastSinglePointerUpAt = 0L
    private var assistedReceiptFill = true
    private var longReceiptMode = true
    private var autoCaptureEnabled = false
    private var autoCaptureAllowed = false
    private var reviewDepth = "pricesOnly"
    private var focusMode = "continuous"
    private var exposureMode = "auto"
    private var whiteBalanceMode = "auto"
    private var dataSaverLevel = "balanced"
    private var storageSafetyLevel = "balanced"
    private var storageConstrained = false
    private var storageSafetyReason = "normal"
    private var previousSectionGuidePhotoPath: String? = null
    private var liveAnalysisEnabled = true
    private var edgeDetectionEnabled = true
    private var edgeOverlayEnabled = true
    private var lowLightWarningEnabled = true
    private var glareWarningEnabled = true
    private var motionBlurWarningEnabled = true
    private var shadowWarningEnabled = true
    private var tooFarTooCloseWarningEnabled = true
    private var receiptFullyVisibleWarningEnabled = true
    private var textTooSmallWarningEnabled = true
    private var tapFocusEnabled = true
    private var pinchZoomEnabled = true
    private var exposureSliderEnabled = true
    private var exposureResetEnabled = true
    private var autoExposureAssistEnabled = true
    private var perspectiveCorrectionEnabled = true
    private var manualCropAfterCapture = true
    private var autoCropSuggestionEnabled = true
    private var grayscalePreviewEnabled = true
    private var contrastBoostEnabled = true
    private var sharpeningEnabled = true
    private var shadowReductionEnabled = true
    private var adaptiveThresholdEnabled = true
    private var orientationCorrectionEnabled = true
    private var analysisGapMs = 720L
    private var lastLiveAnalysisAt = 0L
    private var latestFrameBrightness = -1.0
    private var latestShadowScore = -1.0
    private var latestReadabilitySignal = "unknown"
    private var latestFramingSignal = "unknown"
    private var latestFramingConfidence = "unknown"
    private var latestEdgeCoverage = -1.0
    private var latestPerspectiveReadiness = "unknown"
    private var latestMotionSignal = "unknown"
    private var latestMotionScore = -1.0
    private var previousLiveLumaSamples: IntArray? = null
    private var userExposureOverride = false
    private var autoExposureAdjustmentCount = 0
    private var lastAutoExposureAdjustmentAt = 0L
    private var lastAutoExposureDecision = "not_evaluated"
    private var lastAutoExposureBrightnessBucket = "unknown"
    private var lastAutoExposureCandidate = "none"
    private var autoExposureCandidateFrameCount = 0
    private var lastAutoExposureIndex = 0
    private var tapFocusCount = 0
    private var tapFocusSuppressedAfterZoomCount = 0
    private var zoomChangeCount = 0
    private var manualExposureChangeCount = 0
    private var lastFocusStatus = "not_used"
    private var suppressTapFocusUntilMs = 0L
    private var focusLockAttemptCount = 0
    private var focusLockSuccessCount = 0
    private var exposureLockSuccessCount = 0
    private var whiteBalanceLockStatus = "not_requested"
    private var autoCaptureStableFrameCount = 0
    private var autoCaptureTriggerCount = 0
    private var autoCaptureCooldownUntilMs = 0L
    private var latestAutoCaptureStatus = "off"
    private var closeAction = "open"
    private var closeRetryCount = 0
    private var maxSectionCount = 8
    private var torchOn = false
    private var captureInFlight = false
    private var closingCamera = false
    private var pendingCloseAfterCapture = false
    private var closeResultDelivered = false
    private val capturedPhotoPaths = arrayListOf<String>()
    private var firstCapturedAt: String? = null
    private var totalCapturedByteSize = 0L
    private var latestCapturedPhotoWidth = 0
    private var latestCapturedPhotoHeight = 0
    private var latestCapturedMegapixelBucket = "unknown"
    private var latestCapturedByteBucket = "unknown"
    private var latestCapturedBrightnessBucket = "unknown"
    private var latestCapturedSharpnessBucket = "unknown"
    private var latestCapturedQualitySignal = "unknown"
    private var latestCapturedExposureMismatch = "unknown"

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

    private fun readSessionArguments() {
        assistedReceiptFill = intent.getBooleanExtra("assistedReceiptFill", true)
        longReceiptMode = intent.getBooleanExtra("longReceiptMode", true)
        autoCaptureEnabled = intent.getBooleanExtra("autoCaptureEnabled", false)
        autoCaptureAllowed = intent.getBooleanExtra("autoCaptureAllowed", autoCaptureEnabled)
        if (!autoCaptureAllowed) autoCaptureEnabled = false
        reviewDepth = intent.getStringExtra("reviewDepth") ?: "pricesOnly"
        focusMode = intent.getStringExtra("focusMode") ?: "continuous"
        exposureMode = intent.getStringExtra("exposureMode") ?: "auto"
        whiteBalanceMode = intent.getStringExtra("whiteBalanceMode") ?: "auto"
        dataSaverLevel = intent.getStringExtra("dataSaverLevel") ?: "balanced"
        storageSafetyLevel = intent.getStringExtra("storageSafetyLevel") ?: dataSaverLevel
        storageConstrained = intent.getBooleanExtra("storageConstrained", false)
        storageSafetyReason = intent.getStringExtra("storageSafetyReason") ?: "normal"
        liveAnalysisEnabled = intent.getBooleanExtra("liveAnalysisEnabled", true)
        edgeDetectionEnabled = intent.getBooleanExtra("edgeDetectionEnabled", true)
        edgeOverlayEnabled = intent.getBooleanExtra("edgeOverlayEnabled", true)
        tapFocusEnabled = intent.getBooleanExtra("tapFocusEnabled", true)
        pinchZoomEnabled = intent.getBooleanExtra("pinchZoomEnabled", true)
        exposureSliderEnabled = intent.getBooleanExtra("exposureSliderEnabled", true)
        exposureResetEnabled = intent.getBooleanExtra("exposureResetEnabled", true)
        lowLightWarningEnabled = intent.getBooleanExtra("lowLightWarningEnabled", true)
        glareWarningEnabled = intent.getBooleanExtra("glareWarningEnabled", true)
        motionBlurWarningEnabled = intent.getBooleanExtra("motionBlurWarningEnabled", true)
        shadowWarningEnabled = intent.getBooleanExtra("shadowWarningEnabled", true)
        tooFarTooCloseWarningEnabled = intent.getBooleanExtra("tooFarTooCloseWarningEnabled", true)
        receiptFullyVisibleWarningEnabled = intent.getBooleanExtra("receiptFullyVisibleWarningEnabled", true)
        textTooSmallWarningEnabled = intent.getBooleanExtra("textTooSmallWarningEnabled", true)
        autoExposureAssistEnabled = intent.getBooleanExtra("autoExposureAssistEnabled", true)
        perspectiveCorrectionEnabled = intent.getBooleanExtra("perspectiveCorrectionEnabled", true)
        manualCropAfterCapture = intent.getBooleanExtra("manualCropAfterCapture", true)
        autoCropSuggestionEnabled = intent.getBooleanExtra("autoCropSuggestionEnabled", true)
        grayscalePreviewEnabled = intent.getBooleanExtra("grayscalePreviewEnabled", true)
        contrastBoostEnabled = intent.getBooleanExtra("contrastBoostEnabled", true)
        sharpeningEnabled = intent.getBooleanExtra("sharpeningEnabled", true)
        shadowReductionEnabled = intent.getBooleanExtra("shadowReductionEnabled", true)
        adaptiveThresholdEnabled = intent.getBooleanExtra("adaptiveThresholdEnabled", true)
        orientationCorrectionEnabled = intent.getBooleanExtra("orientationCorrectionEnabled", true)
        analysisGapMs = intent.getIntExtra("analysisGapMs", 720).coerceIn(250, 2500).toLong()
        maxSectionCount = intent.getIntExtra("maxSectionCount", 8).coerceIn(1, 24)
        previousSectionGuidePhotoPath = intent
            .getStringExtra("previousSectionGuidePhotoPath")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
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
        unregisterSystemBackHandler()
        runCatching {
            ProcessCameraProvider.getInstance(this).get().unbindAll()
        }
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        requestCloseCamera()
    }

    private fun registerSystemBackHandler() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val callback = OnBackInvokedCallback { requestCloseCamera() }
        onBackInvokedDispatcher.registerOnBackInvokedCallback(
            OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            callback,
        )
        systemBackCallback = callback
    }

    private fun unregisterSystemBackHandler() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val callback = systemBackCallback ?: return
        runCatching {
            onBackInvokedDispatcher.unregisterOnBackInvokedCallback(callback)
        }
        systemBackCallback = null
    }

    private fun buildContentView(): View {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.BLACK)
        }
        previewView = PreviewView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            scaleType = PreviewView.ScaleType.FILL_CENTER
        }
        root.addView(previewView)
        root.addView(buildReceiptFrameGuide())
        root.addView(buildTopBar())
        root.addView(buildGuidance())
        root.addView(buildPreviousSectionGuide())
        root.addView(buildSettingsStatusStrip())
        root.addView(buildExposureControls())
        root.addView(buildBottomBar())
        return root
    }

    private fun buildReceiptFrameGuide(): View {
        receiptFrameGuide = View(this).apply {
            background = frameGuideDrawable(Color.argb(185, 255, 209, 102))
            visibility = if (edgeDetectionEnabled && edgeOverlayEnabled) View.VISIBLE else View.GONE
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            ).apply {
                leftMargin = dp(26)
                rightMargin = dp(26)
                topMargin = dp(146)
                bottomMargin = dp(214)
            }
            alpha = 0.9f
        }
        return receiptFrameGuide
    }

    private fun buildTopBar(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(12), dp(12), 0)
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(72),
                Gravity.TOP,
            )
        }
        row.addView(iconButton("Back", android.R.drawable.ic_menu_revert) {
            requestCloseCamera()
        })
        row.addView(View(this), LinearLayout.LayoutParams(0, 1, 1f))
        doneButton = Button(this).apply {
            text = "Use Photo"
            contentDescription = "Use captured receipt photos"
            isEnabled = false
            visibility = if (longReceiptMode) View.VISIBLE else View.GONE
            setOnClickListener { finishWithCapturedPhotos() }
        }
        row.addView(doneButton)
        row.addView(iconButton("Receipt camera settings", android.R.drawable.ic_menu_manage) {
            showReceiptCameraSettings()
        })
        torchButton = iconButton(
            "Turn light on",
            android.R.drawable.ic_menu_upload,
        ) {
            toggleTorch()
        }
        row.addView(torchButton)
        return row
    }

    private fun buildGuidance(): View {
        guidance = TextView(this).apply {
            text = guidanceText()
            setTextColor(Color.WHITE)
            textSize = 15f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setBackgroundColor(Color.argb(210, 5, 6, 7))
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.TOP,
            ).apply {
                topMargin = dp(86)
                leftMargin = dp(12)
                rightMargin = dp(12)
            }
        }
        return guidance
    }

    private fun buildPreviousSectionGuide(): View {
        previousSectionGuidePanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(10), dp(8), dp(10), dp(8))
            setBackgroundColor(Color.argb(188, 5, 6, 7))
            visibility = View.GONE
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(116),
                Gravity.TOP,
            ).apply {
                topMargin = dp(154)
                leftMargin = dp(12)
                rightMargin = dp(12)
            }
        }
        previousSectionGuidePanel.addView(TextView(this).apply {
            text = "Line up the next section"
            setTextColor(Color.WHITE)
            textSize = 12f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })
        previousSectionGuideImage = ImageView(this).apply {
            contentDescription = "Previous receipt section overlap guide"
            scaleType = ImageView.ScaleType.CENTER_CROP
            alpha = 0.58f
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f,
            )
        }
        previousSectionGuidePanel.addView(previousSectionGuideImage)
        previousSectionGuidePanel.addView(TextView(this).apply {
            text = "Repeat 3-5 readable lines near the top of this photo."
            setTextColor(Color.rgb(255, 209, 102))
            textSize = 11f
            gravity = Gravity.CENTER
        })
        updatePreviousSectionGuide(previousSectionGuidePhotoPath)
        return previousSectionGuidePanel
    }

    private fun updatePreviousSectionGuide(path: String?) {
        if (!this::previousSectionGuidePanel.isInitialized) return
        val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
            previousSectionGuidePanel.visibility = View.GONE
            return
        }
        val guideFile = File(guidePath)
        if (!guideFile.exists()) {
            previousSectionGuidePanel.visibility = View.GONE
            return
        }
        previousSectionGuideImage.setImageURI(Uri.fromFile(guideFile))
        previousSectionGuidePanel.visibility = View.VISIBLE
    }

    private fun buildExposureControls(): View {
        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), dp(8), dp(10), dp(8))
            setBackgroundColor(Color.argb(190, 5, 6, 7))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(58),
                Gravity.BOTTOM,
            ).apply {
                bottomMargin = dp(132)
                leftMargin = dp(12)
                rightMargin = dp(12)
            }
        }
        panel.addView(TextView(this).apply {
            text = "Brightness"
            setTextColor(Color.WHITE)
            textSize = 12f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })
        exposureSlider = SeekBar(this).apply {
            isEnabled = false
            max = 0
            progress = 0
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) setExposureFromSlider(progress)
                }

                override fun onStartTrackingTouch(seekBar: SeekBar?) = Unit
                override fun onStopTrackingTouch(seekBar: SeekBar?) = Unit
            })
        }
        panel.addView(exposureSlider)
        exposureResetButton = Button(this).apply {
            text = "Reset"
            isEnabled = false
            setOnClickListener { resetExposure() }
        }
        panel.addView(exposureResetButton)
        return panel
    }

    private fun buildSettingsStatusStrip(): View {
        settingsStatusStrip = TextView(this).apply {
            text = settingsStatusText()
            setTextColor(Color.rgb(228, 235, 238))
            textSize = 11.5f
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(10), dp(7), dp(10), dp(7))
            setBackgroundColor(Color.argb(184, 5, 6, 7))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM,
            ).apply {
                bottomMargin = dp(194)
                leftMargin = dp(12)
                rightMargin = dp(12)
            }
        }
        return settingsStatusStrip
    }

    private fun updateSettingsStatusStrip() {
        if (!this::settingsStatusStrip.isInitialized) return
        settingsStatusStrip.text = settingsStatusText()
    }

    private fun settingsStatusText(): String {
        val assist = if (assistedReceiptFill) "Assist on" else "Manual fill"
        val depth = if (reviewDepth == "detailedLines") "Detailed lines" else "Price review"
        val length = if (longReceiptMode) "Long receipt on" else "Single photo"
        val storage = "${dataSaverLabel()} backup"
        return "$assist • $depth • $length • $storage • OCR reads original first"
    }

    private fun buildBottomBar(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(14), dp(12), dp(18))
            setBackgroundColor(Color.argb(210, 5, 6, 7))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(132),
                Gravity.BOTTOM,
            )
        }
        row.addView(modeLabel("Assisted receipt", "Review before saving"))
        shutterButton = ImageButton(this).apply {
            contentDescription = "Take receipt photo"
            setImageResource(android.R.drawable.ic_menu_camera)
            setColorFilter(Color.BLACK)
            setBackgroundColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(dp(82), dp(82)).apply {
                leftMargin = dp(16)
                rightMargin = dp(16)
            }
            setOnClickListener { capturePhoto() }
        }
        row.addView(shutterButton)
        row.addView(modeLabel(dataSaverLabel(), storageSafetyDetail()))
        return row
    }

    private fun startCamera() {
        val providerFuture = ProcessCameraProvider.getInstance(this)
        providerFuture.addListener(
            {
                val provider = providerFuture.get()
                val targetRotation = previewView.display?.rotation ?: Surface.ROTATION_0
                val preview = Preview.Builder()
                    .setTargetRotation(targetRotation)
                    .build().apply {
                    setSurfaceProvider(previewView.surfaceProvider)
                }
                imageCapture = ImageCapture.Builder()
                    .setTargetRotation(targetRotation)
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                    .setJpegQuality(98)
                    .build()
                val imageAnalysis = buildImageAnalysis(targetRotation)
                try {
                    provider.unbindAll()
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

    private fun buildImageAnalysis(targetRotation: Int): ImageAnalysis? {
        if (
            !liveAnalysisEnabled ||
            (
                    !lowLightWarningEnabled &&
                    !glareWarningEnabled &&
                    !motionBlurWarningEnabled &&
                    !shadowWarningEnabled &&
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

    private fun analyzeLiveFrame(image: ImageProxy) {
        try {
            val now = System.currentTimeMillis()
            if (now - lastLiveAnalysisAt < analysisGapMs) return
            lastLiveAnalysisAt = now
            val lumaSamples = sampleLiveLumaGrid(image)
            val motionScore = evaluateLiveMotion(lumaSamples)
            val shadowScore = estimateShadowScore(lumaSamples)
            val brightness = averageLuma(image)
            latestFrameBrightness = brightness
            latestShadowScore = shadowScore
            if (edgeDetectionEnabled) {
                val framing = estimateReceiptFraming(image)
                applyLiveFraming(framing)
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
            val currentGuidance = guidance.text.toString()
            if (motionBlurWarningEnabled && motionScore > 22.0) {
                latestMotionSignal = "moving_too_much"
                guidance.text = "Hold steady so the receipt text stays sharp."
            } else if (lowLightWarningEnabled && brightness in 0.0..58.0) {
                latestReadabilitySignal = "low_light"
                guidance.text = "Receipt looks dark. Add light or raise Brightness."
            } else if (glareWarningEnabled && brightness >= 246.0) {
                latestReadabilitySignal = "glare_or_overbright"
                guidance.text = "Receipt is very bright. Tilt it or lower Brightness."
            } else if (shadowWarningEnabled && shadowScore >= 150.0) {
                latestReadabilitySignal = "shadow_risk"
                guidance.text = "Receipt has heavy shadows. Move it into even light."
            } else {
                latestMotionSignal = if (motionScore >= 0) "steady" else "unknown"
                latestReadabilitySignal = "lighting_ok"
                if (
                    currentGuidance.startsWith("Receipt looks dark") ||
                    currentGuidance.startsWith("Receipt is very bright") ||
                    currentGuidance.startsWith("Hold steady")
                ) {
                    guidance.text = guidanceText()
                }
            }
        } finally {
            image.close()
        }
    }

    private fun sampleLiveLumaGrid(image: ImageProxy): IntArray {
        val plane = image.planes.firstOrNull() ?: return IntArray(0)
        val buffer = plane.buffer.duplicate()
        val width = image.width
        val height = image.height
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride.coerceAtLeast(1)
        if (width <= 0 || height <= 0 || buffer.limit() <= 0) return IntArray(0)
        val samples = ArrayList<Int>(144)
        val rowStep = maxOf(1, height / 12)
        val colStep = maxOf(1, width / 12)
        var y = rowStep / 2
        while (y < height) {
            var x = colStep / 2
            while (x < width) {
                val index = y * rowStride + x * pixelStride
                if (index >= 0 && index < buffer.limit()) {
                    samples.add(buffer.get(index).toInt() and 0xFF)
                }
                x += colStep
            }
            y += rowStep
        }
        return samples.toIntArray()
    }

    private fun evaluateLiveMotion(samples: IntArray): Double {
        if (samples.isEmpty()) return -1.0
        val previous = previousLiveLumaSamples
        previousLiveLumaSamples = samples
        if (previous == null || previous.size != samples.size) {
            latestMotionScore = -1.0
            latestMotionSignal = "unknown"
            return -1.0
        }
        var totalDelta = 0.0
        for (index in samples.indices) {
            totalDelta += kotlin.math.abs(samples[index] - previous[index]).toDouble()
        }
        val score = totalDelta / samples.size.toDouble()
        latestMotionScore = score
        return score
    }

    private fun estimateShadowScore(samples: IntArray): Double {
        if (samples.isEmpty()) return -1.0
        var minSample = 255
        var maxSample = 0
        for (sample in samples) {
            if (sample < minSample) minSample = sample
            if (sample > maxSample) maxSample = sample
        }
        return (maxSample - minSample).toDouble()
    }

    private fun applyLiveFraming(framing: LiveReceiptFraming) {
        latestFramingConfidence = framing.confidenceBucket
        latestEdgeCoverage = framing.edgeCoverage
        latestPerspectiveReadiness = perspectiveReadinessFor(framing)
        if (!framing.found) {
            latestFramingSignal = "receipt_not_found"
            resetFrameGuideBounds()
            setFrameGuideColor(Color.argb(185, 255, 209, 102))
            if (receiptFullyVisibleWarningEnabled) {
                guidance.text = "Place the receipt inside the frame. Manual capture still works."
            }
            return
        }
        updateFrameGuideBounds(framing)
        if (framing.widthRatio < 0.42 || framing.heightRatio < 0.36) {
            latestFramingSignal = "move_closer"
            setFrameGuideColor(Color.argb(210, 255, 209, 102))
            if (textTooSmallWarningEnabled || tooFarTooCloseWarningEnabled) {
                guidance.text = "Move closer until receipt text fills the guide."
            }
            return
        }
        if (framing.touchesEdge) {
            latestFramingSignal = "possibly_cut_off"
            setFrameGuideColor(Color.argb(220, 255, 176, 32))
            if (receiptFullyVisibleWarningEnabled) {
                guidance.text = "Full receipt may be cut off. Leave a little paper edge visible."
            }
            return
        }
        latestFramingSignal = "framing_ok"
        setFrameGuideColor(Color.argb(205, 142, 246, 164))
        if (receiptFullyVisibleWarningEnabled) {
            guidance.text = framingGuidanceCopy(framing.confidenceBucket)
        }
    }

    private fun perspectiveReadinessFor(framing: LiveReceiptFraming): String {
        if (!perspectiveCorrectionEnabled) return "perspective_skipped_setting_off"
        if (!edgeDetectionEnabled) return "perspective_skipped_edge_detection_off"
        if (!framing.found) return "perspective_skipped_no_receipt_bounds"
        if (framing.widthRatio < 0.34 || framing.heightRatio < 0.34) {
            return "perspective_skipped_bounds_too_small"
        }
        if (framing.touchesEdge) return "perspective_skipped_cut_off_risk"
        if (
            framing.confidenceBucket != "strong_edges" &&
            framing.confidenceBucket != "usable_edges"
        ) {
            return "perspective_skipped_weak_edges"
        }
        return "perspective_ready_safe_bounds"
    }

    private fun framingGuidanceCopy(confidenceBucket: String): String {
        return when (confidenceBucket) {
            "strong_edges" -> "Receipt edges found. Hold steady and tap the shutter."
            "usable_edges" -> "Receipt edges look usable. Tap the shutter if the text is clear."
            "weak_edges" -> "Receipt edges are weak. Leave paper edges visible if you can."
            else -> "Receipt edge hint found. Make sure all text is readable."
        }
    }

    private fun estimateReceiptFraming(image: ImageProxy): LiveReceiptFraming {
        val plane = image.planes.firstOrNull() ?: return LiveReceiptFraming()
        val buffer = plane.buffer.duplicate()
        val width = image.width
        val height = image.height
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride.coerceAtLeast(1)
        var left = width
        var top = height
        var right = 0
        var bottom = 0
        var hits = 0
        var totalSamples = 0
        val rowStep = maxOf(2, height / 72)
        val colStep = maxOf(2, width / 72)
        var y = 0
        while (y < height) {
            var x = 0
            while (x < width) {
                totalSamples += 1
                val index = y * rowStride + x * pixelStride
                if (index >= 0 && index < buffer.limit()) {
                    val luma = buffer.get(index).toInt() and 0xFF
                    if (luma > 188 || luma < 82) {
                        hits += 1
                        if (x < left) left = x
                        if (x > right) right = x
                        if (y < top) top = y
                        if (y > bottom) bottom = y
                    }
                }
                x += colStep
            }
            y += rowStep
        }
        if (hits < 40 || right <= left || bottom <= top) return LiveReceiptFraming()
        val widthRatio = (right - left).toDouble() / width.toDouble()
        val heightRatio = (bottom - top).toDouble() / height.toDouble()
        val edgeCoverage = (widthRatio * heightRatio).coerceIn(0.0, 1.0)
        val hitDensity = if (totalSamples <= 0) 0.0 else hits.toDouble() / totalSamples.toDouble()
        val confidenceScore = ((edgeCoverage * 0.72) + (hitDensity * 0.28)).coerceIn(0.0, 1.0)
        val touchesEdge = left < width * .035 ||
            top < height * .035 ||
            right > width * .965 ||
            bottom > height * .965
        return LiveReceiptFraming(
            found = true,
            widthRatio = widthRatio,
            heightRatio = heightRatio,
            edgeCoverage = edgeCoverage,
            confidenceBucket = framingConfidenceBucket(confidenceScore),
            touchesEdge = touchesEdge,
            leftRatio = left.toDouble() / width.toDouble(),
            topRatio = top.toDouble() / height.toDouble(),
            rightRatio = right.toDouble() / width.toDouble(),
            bottomRatio = bottom.toDouble() / height.toDouble(),
        )
    }

    private fun framingConfidenceBucket(score: Double): String {
        return when {
            score >= 0.72 -> "strong_edges"
            score >= 0.48 -> "usable_edges"
            score >= 0.28 -> "weak_edges"
            else -> "edge_hint_only"
        }
    }

    private fun setFrameGuideColor(color: Int) {
        if (!this::receiptFrameGuide.isInitialized) return
        receiptFrameGuide.background = frameGuideDrawable(color)
    }

    private fun resetFrameGuideBounds() {
        if (!this::receiptFrameGuide.isInitialized) return
        receiptFrameGuide.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            Gravity.CENTER,
        ).apply {
            leftMargin = dp(26)
            rightMargin = dp(26)
            topMargin = dp(146)
            bottomMargin = dp(214)
        }
    }

    private fun updateFrameGuideBounds(framing: LiveReceiptFraming) {
        if (!this::receiptFrameGuide.isInitialized) return
        val previewWidth = previewView.width
        val previewHeight = previewView.height
        if (previewWidth <= 0 || previewHeight <= 0) return
        val minLeft = dp(10)
        val minTop = dp(84)
        val maxRight = previewWidth - dp(10)
        val maxBottom = previewHeight - dp(142)
        val left = (framing.leftRatio * previewWidth).roundToInt()
            .coerceIn(minLeft, maxRight)
        val top = (framing.topRatio * previewHeight).roundToInt()
            .coerceIn(minTop, maxBottom)
        val right = (framing.rightRatio * previewWidth).roundToInt()
            .coerceIn(left + dp(42), maxRight)
        val bottom = (framing.bottomRatio * previewHeight).roundToInt()
            .coerceIn(top + dp(72), maxBottom)
        receiptFrameGuide.layoutParams = FrameLayout.LayoutParams(
            right - left,
            bottom - top,
            Gravity.TOP or Gravity.START,
        ).apply {
            leftMargin = left
            topMargin = top
        }
    }

    private fun frameGuideDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.TRANSPARENT)
            setStroke(dp(2), color)
            cornerRadius = dp(14).toFloat()
        }
    }

    private fun averageLuma(image: ImageProxy): Double {
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

    private fun configureTouchControls() {
        val activeCamera = camera ?: return
        scaleGestureDetector = ScaleGestureDetector(
            this,
            object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
                override fun onScale(detector: ScaleGestureDetector): Boolean {
                    if (!pinchZoomEnabled) return false
                    val zoomState = activeCamera.cameraInfo.zoomState.value ?: return false
                    val nextZoom = (
                        zoomState.zoomRatio * detector.scaleFactor
                    ).coerceIn(zoomState.minZoomRatio, zoomState.maxZoomRatio)
                    activeCamera.cameraControl.setZoomRatio(nextZoom)
                    zoomChangeCount += 1
                    suppressTapFocusUntilMs = System.currentTimeMillis() + 350L
                    guidance.text = "Zoom ${(nextZoom * 10).roundToInt() / 10.0}x"
                    return true
                }
            },
        )
        previewView.setOnTouchListener { _, event ->
            if (pinchZoomEnabled) {
                scaleGestureDetector?.onTouchEvent(event)
            }
            if (
                tapFocusEnabled &&
                event.actionMasked == MotionEvent.ACTION_UP &&
                event.pointerCount == 1
            ) {
                val nowMs = System.currentTimeMillis()
                if (nowMs < suppressTapFocusUntilMs) {
                    tapFocusSuppressedAfterZoomCount += 1
                    lastFocusStatus = "tap_focus_suppressed_after_zoom"
                    return@setOnTouchListener true
                }
                if (nowMs - lastSinglePointerUpAt <= 250) {
                    return@setOnTouchListener true
                }
                lastSinglePointerUpAt = nowMs
                focusAt(event.x, event.y)
                true
            } else {
                event.pointerCount > 1
            }
        }
    }

    private fun focusAt(x: Float, y: Float) {
        val activeCamera = camera ?: return
        val point = previewView.meteringPointFactory.createPoint(x, y)
        val shouldLockFocus = focusMode == "locked"
        val shouldLockExposure = exposureMode == "locked"
        val shouldLockWhiteBalance = whiteBalanceMode == "locked"
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

    private fun configureExposureControls() {
        val activeCamera = camera ?: return
        val exposureState = activeCamera.cameraInfo.exposureState
        val range = exposureState.exposureCompensationRange
        if (!exposureSliderEnabled || range.lower == range.upper) {
            exposureSlider.isEnabled = false
            exposureSlider.alpha = 0.45f
        } else {
            exposureSlider.max = range.upper - range.lower
            exposureSlider.progress = exposureState.exposureCompensationIndex - range.lower
            exposureSlider.isEnabled = true
            exposureSlider.alpha = 1f
        }
        if (!exposureResetEnabled || range.lower == range.upper) {
            exposureResetButton.isEnabled = false
            exposureResetButton.alpha = 0.45f
            return
        }
        exposureResetButton.isEnabled = true
        exposureResetButton.alpha = 1f
    }

    private fun setExposureFromSlider(progress: Int) {
        val activeCamera = camera ?: return
        if (!exposureSliderEnabled) return
        val range = activeCamera.cameraInfo.exposureState.exposureCompensationRange
        val index = range.lower + progress
        userExposureOverride = true
        manualExposureChangeCount += 1
        activeCamera.cameraControl.setExposureCompensationIndex(index)
        guidance.text = if (index == 0) {
            "Brightness reset."
        } else {
            "Brightness ${if (index > 0) "+" else ""}$index"
        }
    }

    private fun resetExposure() {
        val activeCamera = camera ?: return
        if (!exposureResetEnabled) return
        val range = activeCamera.cameraInfo.exposureState.exposureCompensationRange
        if (0 in range.lower..range.upper) {
            exposureSlider.progress = -range.lower
            activeCamera.cameraControl.setExposureCompensationIndex(0)
            userExposureOverride = false
            manualExposureChangeCount += 1
            guidance.text = "Brightness reset."
        }
    }

    private fun autoAdjustExposureForLiveFrame(
        brightness: Double,
        nowMs: Long,
        framing: LiveReceiptFraming?,
    ) {
        lastAutoExposureBrightnessBucket = brightnessBucket(brightness)
        if (brightness < 0.0) {
            lastAutoExposureDecision = "brightness_unknown"
            resetAutoExposureCandidate()
            return
        }
        if (framing == null || !framing.found) {
            when {
                brightness <= 58.0 -> {
                    if (!stableAutoExposureCandidate("fallback_brighten", requiredFrames = 4)) return
                    autoAdjustExposureForLiveFrame(
                        brighten = true,
                        strongCorrection = true,
                        nowMs = nowMs,
                    )
                }
                brightness >= 246.0 -> {
                    if (!stableAutoExposureCandidate("fallback_dim", requiredFrames = 4)) return
                    autoAdjustExposureForLiveFrame(
                        brighten = false,
                        strongCorrection = true,
                        nowMs = nowMs,
                    )
                }
                else -> {
                    lastAutoExposureDecision = "waiting_for_receipt_target"
                    resetAutoExposureCandidate()
                }
            }
            return
        }
        when {
            brightness <= 96.0 -> {
                if (!stableAutoExposureCandidate("brighten")) return
                autoAdjustExposureForLiveFrame(
                    brighten = true,
                    strongCorrection = brightness <= 58.0,
                    nowMs = nowMs,
                )
            }
            brightness >= 246.0 -> {
                if (!stableAutoExposureCandidate("dim")) return
                autoAdjustExposureForLiveFrame(
                    brighten = false,
                    strongCorrection = brightness >= 252.0,
                    nowMs = nowMs,
                )
            }
            else -> {
                lastAutoExposureDecision = "lighting_ok"
                resetAutoExposureCandidate()
            }
        }
    }

    private fun stableAutoExposureCandidate(
        candidate: String,
        requiredFrames: Int = 2,
    ): Boolean {
        if (lastAutoExposureCandidate == candidate) {
            autoExposureCandidateFrameCount += 1
        } else {
            lastAutoExposureCandidate = candidate
            autoExposureCandidateFrameCount = 1
        }
        if (autoExposureCandidateFrameCount < requiredFrames) {
            lastAutoExposureDecision = "stabilizing_$candidate"
            return false
        }
        return true
    }

    private fun resetAutoExposureCandidate() {
        lastAutoExposureCandidate = "none"
        autoExposureCandidateFrameCount = 0
    }

    private fun maybeAutoCapture(
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
        val steady = motionScore in 0.0..7.5
        val lightReady = brightness in 68.0..245.0
        if (!edgesReady || !steady || !lightReady) {
            autoCaptureStableFrameCount = 0
            latestAutoCaptureStatus = when {
                !edgesReady -> "waiting_for_edges"
                !steady -> "waiting_for_steady"
                !lightReady -> "waiting_for_light"
                else -> "waiting"
            }
            return
        }
        autoCaptureStableFrameCount += 1
        latestAutoCaptureStatus = "ready_${autoCaptureStableFrameCount}_of_3"
        if (autoCaptureStableFrameCount < 3) return
        autoCaptureStableFrameCount = 0
        autoCaptureTriggerCount += 1
        autoCaptureCooldownUntilMs = nowMs + 2600L
        latestAutoCaptureStatus = "capturing"
        guidance.text = "Receipt looks steady. Taking photo."
        capturePhoto()
    }

    private fun autoAdjustExposureForLiveFrame(
        brighten: Boolean,
        strongCorrection: Boolean,
        nowMs: Long,
    ) {
        if (!autoExposureAssistEnabled) {
            lastAutoExposureDecision = "off"
            return
        }
        if (userExposureOverride) {
            lastAutoExposureDecision = "manual_override"
            return
        }
        if (nowMs - lastAutoExposureAdjustmentAt < 900L) {
            lastAutoExposureDecision = "cooling_down"
            return
        }
        val activeCamera = camera ?: return
        val exposureState = activeCamera.cameraInfo.exposureState
        val range = exposureState.exposureCompensationRange
        if (range.lower == range.upper) {
            lastAutoExposureDecision = "not_supported"
            return
        }
        val current = exposureState.exposureCompensationIndex
        lastAutoExposureIndex = current
        val step = if (strongCorrection) 2 else 1
        val target = if (brighten) {
            (current + step).coerceAtMost(range.upper)
        } else {
            (current - step).coerceAtLeast(range.lower)
        }
        if (target == current) {
            lastAutoExposureDecision = if (brighten) {
                "already_at_brightest"
            } else {
                "already_at_dimmest"
            }
            return
        }
        activeCamera.cameraControl.setExposureCompensationIndex(target)
        exposureSlider.progress = target - range.lower
        autoExposureAdjustmentCount += 1
        lastAutoExposureAdjustmentAt = nowMs
        lastAutoExposureIndex = target
        resetAutoExposureCandidate()
        lastAutoExposureDecision = if (brighten) {
            if (strongCorrection) "brightened_strong" else "brightened"
        } else {
            if (strongCorrection) "dimmed_strong" else "dimmed"
        }
    }

    private fun brightnessBucket(brightness: Double): String {
        return when {
            brightness < 0.0 -> "unknown"
            brightness <= 58.0 -> "too_dark_warning"
            brightness <= 96.0 -> "dark_assisted"
            brightness >= 246.0 -> "glare_warning"
            brightness >= 232.0 -> "bright_receipt_ok"
            else -> "lighting_ok"
        }
    }

    private fun exposureAssistStatus(): String {
        val activeCamera = camera ?: return "camera_unavailable"
        val exposureState = activeCamera.cameraInfo.exposureState
        val range = exposureState.exposureCompensationRange
        return when {
            range.lower == range.upper -> "not_supported"
            userExposureOverride -> "manual_override"
            !autoExposureAssistEnabled -> "off"
            autoExposureAdjustmentCount > 0 -> "auto_adjusted"
            else -> "ready"
        }
    }

    private fun capturePhoto() {
        val capture = imageCapture ?: return
        if (captureInFlight || closingCamera || isFinishing || isDestroyed) return
        captureInFlight = true
        shutterButton.isEnabled = false
        val outputFile = newReceiptCaptureFile()
        val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
        capture.takePicture(
            outputOptions,
            mainExecutor(),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    captureInFlight = false
                    val capturedAt = Instant.now().toString()
                    if (firstCapturedAt == null) firstCapturedAt = capturedAt
                    capturedPhotoPaths.add(outputFile.absolutePath)
                    totalCapturedByteSize += outputFile.length()
                    recordCapturedPhotoQuality(outputFile)
                    autoCaptureCooldownUntilMs = System.currentTimeMillis() + 2600L
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
                            "Section ${capturedPhotoPaths.size} saved. Add the next section, or tap Done."
                    } else {
                        finishWithCapturedPhotos()
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    captureInFlight = false
                    pendingCloseAfterCapture = false
                    shutterButton.isEnabled = true
                    guidance.text = "That photo did not save. Try again."
                    Toast.makeText(
                        this@ReceiptCameraActivity,
                        "Receipt photo did not save.",
                        Toast.LENGTH_SHORT,
                    ).show()
                }
            },
        )
    }

    private fun requestCloseCamera() {
        if (closeResultDelivered) {
            closeRetryCount += 1
            if (!isFinishing && !isDestroyed) {
                finish()
            }
            return
        }
        closingCamera = true
        latestAutoCaptureStatus = "closing"
        if (captureInFlight) {
            pendingCloseAfterCapture = true
            shutterButton.isEnabled = false
            doneButton.isEnabled = false
            guidance.text = "Finishing this receipt photo before closing."
            return
        }
        if (capturedPhotoPaths.isEmpty()) {
            closeAction = "back_no_photo_cancel"
            closeResultDelivered = true
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        finishWithCapturedPhotos(closeReason = "back_returned_captured_sections")
    }

    private fun recordCapturedPhotoQuality(file: File) {
        latestCapturedByteBucket = byteSizeBucket(file.length())
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(file.absolutePath, options)
        latestCapturedPhotoWidth = options.outWidth.coerceAtLeast(0)
        latestCapturedPhotoHeight = options.outHeight.coerceAtLeast(0)
        latestCapturedMegapixelBucket = megapixelBucket(
            latestCapturedPhotoWidth,
            latestCapturedPhotoHeight,
        )
        val sampleOptions = BitmapFactory.Options().apply {
            inSampleSize = capturedPhotoSampleSize(
                latestCapturedPhotoWidth,
                latestCapturedPhotoHeight,
            )
        }
        val bitmap = BitmapFactory.decodeFile(file.absolutePath, sampleOptions)
        if (bitmap == null) {
            latestCapturedBrightnessBucket = "unknown"
            latestCapturedSharpnessBucket = "unknown"
            latestCapturedQualitySignal = "unknown"
            latestCapturedExposureMismatch = "unknown"
            return
        }
        try {
            val sample = sampleCapturedBitmapQuality(bitmap)
            latestCapturedBrightnessBucket = capturedBrightnessBucket(sample.averageLuma)
            latestCapturedSharpnessBucket = capturedSharpnessBucket(sample.edgeScore)
            latestCapturedQualitySignal = capturedQualitySignal(
                latestCapturedBrightnessBucket,
                latestCapturedSharpnessBucket,
            )
            latestCapturedExposureMismatch = capturedExposureMismatch(
                latestFrameBrightness,
                latestCapturedBrightnessBucket,
            )
        } finally {
            bitmap.recycle()
        }
    }

    private fun capturedPhotoSampleSize(width: Int, height: Int): Int {
        val maxSide = max(width, height)
        if (maxSide <= 640) return 1
        var sample = 1
        while (maxSide / sample > 640) sample *= 2
        return sample
    }

    private data class CapturedPhotoQualitySample(
        val averageLuma: Double,
        val edgeScore: Double,
    )

    private fun sampleCapturedBitmapQuality(bitmap: android.graphics.Bitmap): CapturedPhotoQualitySample {
        val width = bitmap.width
        val height = bitmap.height
        if (width <= 1 || height <= 1) {
            return CapturedPhotoQualitySample(-1.0, -1.0)
        }
        val strideX = max(1, width / 96)
        val strideY = max(1, height / 128)
        var count = 0
        var lumaTotal = 0.0
        var edgeTotal = 0.0
        var edgeCount = 0
        var previousRowLuma = DoubleArray(width / strideX + 2)
        var rowIndex = 0
        var y = 0
        while (y < height) {
            var x = 0
            var previousLuma = -1.0
            var columnIndex = 0
            while (x < width) {
                val luma = pixelLuma(bitmap.getPixel(x, y))
                lumaTotal += luma
                count += 1
                if (previousLuma >= 0.0) {
                    edgeTotal += abs(luma - previousLuma)
                    edgeCount += 1
                }
                if (rowIndex > 0 && columnIndex < previousRowLuma.size) {
                    edgeTotal += abs(luma - previousRowLuma[columnIndex])
                    edgeCount += 1
                }
                previousRowLuma[columnIndex] = luma
                previousLuma = luma
                columnIndex += 1
                x += strideX
            }
            rowIndex += 1
            y += strideY
        }
        return CapturedPhotoQualitySample(
            averageLuma = if (count == 0) -1.0 else lumaTotal / count,
            edgeScore = if (edgeCount == 0) -1.0 else edgeTotal / edgeCount,
        )
    }

    private fun pixelLuma(pixel: Int): Double {
        return (Color.red(pixel) * 0.299) +
            (Color.green(pixel) * 0.587) +
            (Color.blue(pixel) * 0.114)
    }

    private fun capturedBrightnessBucket(luma: Double): String {
        return when {
            luma < 0.0 -> "unknown"
            luma < 70.0 -> "captured_too_dark"
            luma < 105.0 -> "captured_dim"
            luma < 205.0 -> "captured_readable"
            luma < 246.0 -> "captured_bright"
            else -> "captured_glare_risk"
        }
    }

    private fun capturedSharpnessBucket(edgeScore: Double): String {
        return when {
            edgeScore < 0.0 -> "unknown"
            edgeScore < 5.5 -> "captured_soft_blur_risk"
            edgeScore < 10.0 -> "captured_usable_soft"
            edgeScore < 24.0 -> "captured_sharp"
            else -> "captured_high_contrast_edges"
        }
    }

    private fun capturedQualitySignal(
        brightnessBucket: String,
        sharpnessBucket: String,
    ): String {
        if (brightnessBucket == "unknown" || sharpnessBucket == "unknown") return "unknown"
        if (brightnessBucket == "captured_too_dark" || brightnessBucket == "captured_glare_risk") {
            return "retake_brightness_risk"
        }
        if (sharpnessBucket == "captured_soft_blur_risk") return "retake_blur_risk"
        if (brightnessBucket == "captured_dim" || sharpnessBucket == "captured_usable_soft") {
            return "review_before_saving"
        }
        return "captured_readable"
    }

    private fun capturedExposureMismatch(
        liveBrightness: Double,
        capturedBrightnessBucket: String,
    ): String {
        if (liveBrightness < 0.0 || capturedBrightnessBucket == "unknown") return "unknown"
        val liveBucket = brightnessBucket(liveBrightness)
        return when {
            liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_too_dark" ->
                "live_ok_capture_too_dark"
            liveBucket == "lighting_ok" && capturedBrightnessBucket == "captured_dim" ->
                "live_ok_capture_dim"
            liveBucket == "too_dark_warning" && capturedBrightnessBucket == "captured_readable" ->
                "live_dark_capture_readable"
            liveBucket == "dark_assisted" && capturedBrightnessBucket == "captured_readable" ->
                "live_dark_capture_readable"
            liveBucket == "glare_warning" && capturedBrightnessBucket == "captured_readable" ->
                "live_bright_capture_readable"
            liveBucket == "bright_receipt_ok" && capturedBrightnessBucket == "captured_readable" ->
                "live_bright_capture_readable"
            else -> "live_capture_aligned"
        }
    }

    private fun byteSizeBucket(bytes: Long): String {
        return when {
            bytes <= 0L -> "unknown"
            bytes < 350_000L -> "tiny_under_350kb"
            bytes < 1_000_000L -> "small_under_1mb"
            bytes < 3_000_000L -> "normal_1mb_to_3mb"
            bytes < 8_000_000L -> "large_3mb_to_8mb"
            else -> "very_large_over_8mb"
        }
    }

    private fun megapixelBucket(width: Int, height: Int): String {
        if (width <= 0 || height <= 0) return "unknown"
        val megapixels = (width.toDouble() * height.toDouble()) / 1_000_000.0
        return when {
            megapixels < 4.0 -> "low_under_4mp"
            megapixels < 9.0 -> "medium_4mp_to_9mp"
            megapixels < 18.0 -> "high_9mp_to_18mp"
            megapixels < 40.0 -> "very_high_18mp_to_40mp"
            else -> "extreme_over_40mp"
        }
    }

    private fun finishWithCapturedPhotos(closeReason: String = "done_returned_captured_sections") {
        if (closeResultDelivered) return
        closingCamera = true
        latestAutoCaptureStatus = "closing"
        if (capturedPhotoPaths.isEmpty()) {
            closeAction = "done_no_photo_cancel"
            closeResultDelivered = true
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        closeAction = closeReason
        closeResultDelivered = true
        val capturedAt = firstCapturedAt ?: Instant.now().toString()
        val data = Intent().apply {
            putStringArrayListExtra(extraOriginalPhotoPaths, capturedPhotoPaths)
            putExtra(extraCapturedAt, capturedAt)
            putExtra(
                extraCaptureDiagnostics,
                nativeCaptureDiagnostics(totalCapturedByteSize, capturedAt),
            )
        }
        setResult(RESULT_OK, data)
        finish()
    }

    private fun updateDoneButton() {
        doneButton.visibility = if (longReceiptMode) View.VISIBLE else View.GONE
        doneButton.isEnabled = capturedPhotoPaths.isNotEmpty()
        val count = capturedPhotoPaths.size
        doneButton.text = when (count) {
            0 -> "Use Photo"
            1 -> "Use Photo (1)"
            else -> "Use Photos ($count)"
        }
        doneButton.contentDescription = doneButton.text.toString()
        updateSettingsStatusStrip()
    }

    private fun toggleTorch() {
        val cameraControl = camera?.cameraControl ?: return
        torchOn = !torchOn
        cameraControl.enableTorch(torchOn)
        torchButton.contentDescription = if (torchOn) "Turn light off" else "Turn light on"
    }

    private fun showReceiptCameraSettings() {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(10), dp(18), dp(4))
        }
        content.addView(settingSwitch(
            "Let Maintainiac help fill this receipt",
            "After photos are accepted, open receipt review instead of dropping back to the form.",
            assistedReceiptFill,
        ) {
            assistedReceiptFill = it
            updateSettingsStatusStrip()
        })
        content.addView(settingSwitch(
            "Long receipt mode",
            "Use more than one readable photo instead of squeezing tiny text into one image.",
            longReceiptMode,
        ) {
            longReceiptMode = it
            updateDoneButton()
            guidance.text = guidanceText()
            updateSettingsStatusStrip()
        })
        content.addView(settingSwitch(
            "Automatic capture",
            autoCaptureDetail(),
            autoCaptureEnabled,
        ) {
            if (it && !isAutoCaptureCurrentlyAllowed()) {
                autoCaptureEnabled = false
                guidance.text = autoCaptureBlockedMessage()
                return@settingSwitch
            }
            autoCaptureEnabled = it
            guidance.text = if (it) {
                "Automatic capture is on. Hold steady, or tap the shutter anytime."
            } else {
                guidanceText()
            }
            updateSettingsStatusStrip()
        })
        content.addView(settingSwitch(
            "Auto brightness assist",
            "Make small brightness corrections for dark receipts or glare. Manual Brightness still wins.",
            autoExposureAssistEnabled,
        ) {
            autoExposureAssistEnabled = it
            guidance.text = if (it) {
                "Auto brightness assist is on."
            } else {
                "Auto brightness assist is off. Use Brightness manually."
            }
            updateSettingsStatusStrip()
        })
        content.addView(settingSwitch(
            "Find receipt edges",
            "Show edge guidance for cropping and straightening. Manual shutter still works.",
            edgeDetectionEnabled,
        ) {
            edgeDetectionEnabled = it
            if (!it && autoCaptureEnabled) {
                autoCaptureEnabled = false
                autoCaptureStableFrameCount = 0
                latestAutoCaptureStatus = "edge_detection_off"
            }
            receiptFrameGuide.visibility = if (it && edgeOverlayEnabled) View.VISIBLE else View.GONE
            guidance.text = if (it) {
                "Receipt edge guidance is on."
            } else {
                "Receipt edge guidance is off. Take the clearest photo you can."
            }
            updateSettingsStatusStrip()
        })
        content.addView(settingSwitch(
            "Receipt guidance warnings",
            "Warn about shake, glare, low light, tiny text, or cut-off receipt edges.",
            receiptGuidanceWarningsEnabled(),
        ) {
            setReceiptGuidanceWarningsEnabled(it)
            guidance.text = if (it) {
                "Receipt guidance warnings are on."
            } else {
                "Receipt guidance warnings are off. Manual shutter still works."
            }
            updateSettingsStatusStrip()
        })
        content.addView(settingSummary(
            "Image cleanup",
            "Crop, straighten, grayscale, contrast, and shadow cleanup are prepared after capture.",
        ))
        content.addView(settingSummary(
            "Receipt reader",
            "OCR reads the original photo first. Smaller backup copies are made after the receipt has been read.",
        ))
        content.addView(settingSummary(
            "Review style",
            if (reviewDepth == "detailedLines") {
                "Detailed receipt lines"
            } else {
                "Price-only receipt lines"
            },
        ))
        content.addView(settingSummary("Save-space backup", dataSaverLabel()))
        content.addView(settingSummary(
            "Manual shutter",
            "The shutter button always works. Automatic capture is optional and never blocks a clear manual photo.",
        ))
        content.addView(settingSummary(
            "Camera controls",
            "Tap receipt text to focus. Pinch to zoom. Use Brightness anytime.",
        ))
        AlertDialog.Builder(this)
            .setTitle("Receipt Camera Settings")
            .setView(content)
            .setNegativeButton("Reset brightness") { _, _ -> resetExposure() }
            .setPositiveButton("Done", null)
            .show()
    }

    private fun settingSwitch(
        title: String,
        detail: String,
        checked: Boolean,
        onChanged: (Boolean) -> Unit,
    ): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(8), 0, dp(8))
        }
        row.addView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            addView(TextView(this@ReceiptCameraActivity).apply {
                text = title
                setTextColor(Color.BLACK)
                textSize = 15f
                setTypeface(typeface, android.graphics.Typeface.BOLD)
            })
            addView(TextView(this@ReceiptCameraActivity).apply {
                text = detail
                setTextColor(Color.DKGRAY)
                textSize = 12f
            })
        })
        row.addView(Switch(this).apply {
            isChecked = checked
            setOnCheckedChangeListener { _, isChecked -> onChanged(isChecked) }
        })
        return row
    }

    private fun settingSummary(title: String, detail: String): View {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(8), 0, dp(8))
            addView(TextView(this@ReceiptCameraActivity).apply {
                text = title
                setTextColor(Color.BLACK)
                textSize = 15f
                setTypeface(typeface, android.graphics.Typeface.BOLD)
            })
            addView(TextView(this@ReceiptCameraActivity).apply {
                text = detail
                setTextColor(Color.DKGRAY)
                textSize = 12f
            })
        }
    }

    private fun receiptGuidanceWarningsEnabled(): Boolean {
        return lowLightWarningEnabled ||
            glareWarningEnabled ||
            motionBlurWarningEnabled ||
            tooFarTooCloseWarningEnabled ||
            receiptFullyVisibleWarningEnabled
    }

    private fun setReceiptGuidanceWarningsEnabled(enabled: Boolean) {
        lowLightWarningEnabled = enabled
        glareWarningEnabled = enabled
        motionBlurWarningEnabled = enabled
        tooFarTooCloseWarningEnabled = enabled
        receiptFullyVisibleWarningEnabled = enabled
    }

    private fun newReceiptCaptureFile(): File {
        val directory = File(cacheDir, "receipt_camera").apply {
            if (!exists()) mkdirs()
        }
        return File(directory, "receipt_${System.currentTimeMillis()}.jpg")
    }

    private fun iconButton(
        label: String,
        icon: Int,
        onClick: () -> Unit,
    ): ImageButton {
        return ImageButton(this).apply {
            contentDescription = label
            setImageResource(icon)
            setColorFilter(Color.WHITE)
            setBackgroundColor(Color.argb(220, 17, 24, 27))
            layoutParams = LinearLayout.LayoutParams(dp(52), dp(52)).apply {
                leftMargin = dp(4)
                rightMargin = dp(4)
            }
            setOnClickListener { onClick() }
        }
    }

    private fun modeLabel(title: String, detail: String): TextView {
        return TextView(this).apply {
            text = "$title\n$detail"
            setTextColor(Color.WHITE)
            textSize = 12f
            gravity = Gravity.CENTER
            setPadding(dp(8), dp(8), dp(8), dp(8))
            setBackgroundColor(Color.argb(220, 17, 24, 27))
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
    }

    private fun guidanceText(): String {
        return if (longReceiptMode) {
            "Fill the screen with readable receipt text. Use more photos for long receipts."
        } else if (autoCaptureEnabled) {
            "Hold steady. Manual capture is always available."
        } else {
            "Fill the screen with readable receipt text, then tap the shutter."
        }
    }

    private fun dataSaverLabel(): String {
        return when (storageSafetyLevel) {
            "original" -> "Local original"
            "light" -> "High quality"
            "strong" -> "Low storage"
            "maximum" -> "Tiny backup"
            else -> "Normal backup"
        }
    }

    private fun autoCaptureDetail(): String {
        return if (isAutoCaptureCurrentlyAllowed()) {
            "Off by default. Waits for 3 steady readable frames. Manual shutter always works."
        } else if (!edgeDetectionEnabled) {
            "Turn receipt edge guidance on before using automatic capture."
        } else {
            "Manual capture is safest for this device or storage mode."
        }
    }

    private fun autoCaptureBlockedMessage(): String {
        if (!edgeDetectionEnabled) {
            return "Receipt edge guidance is off, so automatic capture is held back. Tap the shutter when ready."
        }
        return if (storageConstrained) {
            "Storage is tight, so automatic capture is held back. Tap the shutter when ready."
        } else {
            "Automatic capture is held back on this device. Tap the shutter when ready."
        }
    }

    private fun isAutoCaptureCurrentlyAllowed(): Boolean {
        return autoCaptureAllowed && edgeDetectionEnabled
    }

    private fun storageSafetyDetail(): String {
        return if (storageConstrained) {
            "Keeps long receipts lighter"
        } else {
            "OCR uses clear source first"
        }
    }

    private fun nativeCaptureDiagnostics(
        photoByteSize: Long,
        capturedAt: String,
    ): HashMap<String, Any> {
        val activeCamera = camera
        val exposureState = activeCamera?.cameraInfo?.exposureState
        val exposureRange = exposureState?.exposureCompensationRange
        val zoomState = activeCamera?.cameraInfo?.zoomState?.value
        return hashMapOf(
            "engine" to "cameraX",
            "captureSurface" to "maintainiac_native_android",
            "captureMode" to "manual",
            "captureQualityMode" to "maximizeQuality",
            "capturedAt" to capturedAt,
            "photoByteSize" to photoByteSize,
            "photoByteSizeBucket" to byteSizeBucket(photoByteSize),
            "latestCapturedPhotoWidth" to latestCapturedPhotoWidth,
            "latestCapturedPhotoHeight" to latestCapturedPhotoHeight,
            "latestCapturedMegapixelBucket" to latestCapturedMegapixelBucket,
            "latestCapturedByteBucket" to latestCapturedByteBucket,
            "latestCapturedBrightnessBucket" to latestCapturedBrightnessBucket,
            "latestCapturedSharpnessBucket" to latestCapturedSharpnessBucket,
            "latestCapturedQualitySignal" to latestCapturedQualitySignal,
            "latestCapturedExposureMismatch" to latestCapturedExposureMismatch,
            "photoCount" to capturedPhotoPaths.size,
            "maxSectionCount" to maxSectionCount,
            "liveAnalysisEnabled" to liveAnalysisEnabled,
            "autoExposureAssistEnabled" to autoExposureAssistEnabled,
            "edgeDetectionEnabled" to edgeDetectionEnabled,
            "edgeOverlayEnabled" to edgeOverlayEnabled,
            "shadowWarningEnabled" to shadowWarningEnabled,
            "textTooSmallWarningEnabled" to textTooSmallWarningEnabled,
            "perspectiveCorrectionEnabled" to perspectiveCorrectionEnabled,
            "manualCropAfterCapture" to manualCropAfterCapture,
            "autoCropSuggestionEnabled" to autoCropSuggestionEnabled,
            "grayscalePreviewEnabled" to grayscalePreviewEnabled,
            "contrastBoostEnabled" to contrastBoostEnabled,
            "sharpeningEnabled" to sharpeningEnabled,
            "shadowReductionEnabled" to shadowReductionEnabled,
            "adaptiveThresholdEnabled" to adaptiveThresholdEnabled,
            "orientationCorrectionEnabled" to orientationCorrectionEnabled,
            "receiptGuidanceWarningsEnabled" to receiptGuidanceWarningsEnabled(),
            "autoExposureAdjustmentCount" to autoExposureAdjustmentCount,
            "lastAutoExposureDecision" to lastAutoExposureDecision,
            "lastAutoExposureBrightnessBucket" to lastAutoExposureBrightnessBucket,
            "lastAutoExposureCandidate" to lastAutoExposureCandidate,
            "autoExposureCandidateFrameCount" to autoExposureCandidateFrameCount,
            "lastAutoExposureIndex" to lastAutoExposureIndex,
            "tapFocusCount" to tapFocusCount,
            "tapFocusSuppressedAfterZoomCount" to tapFocusSuppressedAfterZoomCount,
            "zoomChangeCount" to zoomChangeCount,
            "manualExposureChangeCount" to manualExposureChangeCount,
            "lastFocusStatus" to lastFocusStatus,
            "focusMode" to focusMode,
            "exposureMode" to exposureMode,
            "whiteBalanceMode" to whiteBalanceMode,
            "focusLockAttemptCount" to focusLockAttemptCount,
            "focusLockSuccessCount" to focusLockSuccessCount,
            "exposureLockSuccessCount" to exposureLockSuccessCount,
            "whiteBalanceLockStatus" to whiteBalanceLockStatus,
            "autoCaptureStableFrameCount" to autoCaptureStableFrameCount,
            "autoCaptureTriggerCount" to autoCaptureTriggerCount,
            "latestAutoCaptureStatus" to latestAutoCaptureStatus,
            "closeAction" to closeAction,
            "closeRetryCount" to closeRetryCount,
            "closingCamera" to closingCamera,
            "pendingCloseAfterCapture" to pendingCloseAfterCapture,
            "closeResultDelivered" to closeResultDelivered,
            "exposureAssistStatus" to exposureAssistStatus(),
            "userExposureOverride" to userExposureOverride,
            "analysisGapMs" to analysisGapMs,
            "latestFrameBrightness" to latestFrameBrightness,
            "latestShadowScore" to latestShadowScore,
            "latestBrightnessBucket" to brightnessBucket(latestFrameBrightness),
            "latestReadabilitySignal" to latestReadabilitySignal,
            "latestFramingSignal" to latestFramingSignal,
            "latestFramingConfidence" to latestFramingConfidence,
            "latestEdgeCoverage" to latestEdgeCoverage,
            "latestPerspectiveReadiness" to latestPerspectiveReadiness,
            "latestMotionSignal" to latestMotionSignal,
            "latestMotionScore" to latestMotionScore,
            "assistedReceiptFill" to assistedReceiptFill,
            "longReceiptMode" to longReceiptMode,
            "autoCaptureEnabled" to autoCaptureEnabled,
            "autoCaptureAllowed" to autoCaptureAllowed,
            "autoCaptureCurrentlyAllowed" to isAutoCaptureCurrentlyAllowed(),
            "reviewDepth" to reviewDepth,
            "dataSaverLevel" to dataSaverLevel,
            "storageSafetyLevel" to storageSafetyLevel,
            "storageConstrained" to storageConstrained,
            "storageSafetyReason" to storageSafetyReason,
            "hasPreviousSectionGuide" to (previousSectionGuidePhotoPath != null),
            "torchOn" to torchOn,
            "hasFlashUnit" to (activeCamera?.cameraInfo?.hasFlashUnit() == true),
            "exposureCompensationIndex" to (exposureState?.exposureCompensationIndex ?: 0),
            "exposureCompensationRangeLower" to (exposureRange?.lower ?: 0),
            "exposureCompensationRangeUpper" to (exposureRange?.upper ?: 0),
            "zoomRatio" to ((zoomState?.zoomRatio ?: 1f).toDouble()),
            "minZoomRatio" to ((zoomState?.minZoomRatio ?: 1f).toDouble()),
            "maxZoomRatio" to ((zoomState?.maxZoomRatio ?: 1f).toDouble()),
            "tapFocusEnabled" to tapFocusEnabled,
            "pinchZoomEnabled" to pinchZoomEnabled,
            "exposureSliderEnabled" to exposureSliderEnabled,
            "exposureResetEnabled" to exposureResetEnabled,
            "manualShutterAlwaysAvailable" to intent.getBooleanExtra("manualShutterAlwaysAvailable", true),
            "ocrUsesOriginalFirst" to true,
        )
    }

    private fun mainExecutor(): Executor = ContextCompat.getMainExecutor(this)

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    companion object {
        const val extraOriginalPhotoPaths = "originalPhotoPaths"
        const val extraCapturedAt = "capturedAt"
        const val extraCaptureDiagnostics = "captureDiagnostics"
    }

    private data class LiveReceiptFraming(
        val found: Boolean = false,
        val widthRatio: Double = 0.0,
        val heightRatio: Double = 0.0,
        val edgeCoverage: Double = 0.0,
        val confidenceBucket: String = "unknown",
        val touchesEdge: Boolean = false,
        val leftRatio: Double = 0.0,
        val topRatio: Double = 0.0,
        val rightRatio: Double = 1.0,
        val bottomRatio: Double = 1.0,
    )
}
