import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

final class ReceiptCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
  var onCapture: (([String], String, [String: Any]) -> Void)?
  var onCancel: ((String) -> Void)?

  let arguments: [String: Any]
  let session = AVCaptureSession()
  let photoOutput = AVCapturePhotoOutput()
  let videoOutput = AVCaptureVideoDataOutput()
  let sessionQueue = DispatchQueue(label: "maintainiac.receipt.camera.session")
  var previewLayer: AVCaptureVideoPreviewLayer?
  var cameraDevice: AVCaptureDevice?
  var torchOn = false
  var captureInFlight = false
  var closingCamera = false
  var cameraViewClosing = false
  var pendingCloseAfterCapture = false
  var closeResultDelivered = false
  let shutterButton = UIButton(type: .system)
  let torchButton = UIButton(type: .system)
  let brightnessButton = UIButton(type: .system)
  let addPhotoButton = UIButton(type: .system)
  let bottomReviewButton = UIButton(type: .system)
  let guidanceLabel = UILabel()
  let viewerInfoStack = UIStackView()
  let settingsStatusStrip = UILabel()
  let receiptFrameGuide = UIView()
  let exposureSlider = UISlider()
  let exposureResetButton = UIButton(type: .system)
  var exposurePanel: UIView?
  let previousSectionGuidePanel = UIStackView()
  let previousSectionGuideImageView = UIImageView()
  let nextSectionGuideImageView = UIImageView()
  var lastZoomFactor: CGFloat = 1
  var assistedReceiptFill = true
  var longReceiptMode = false
  var autoCaptureEnabled = false
  var autoCaptureAllowed = false
  var deviceTier = "medium"
  var uiLocale = "en-US"
  var settingsContractVersion = "receipt_native_camera_settings_v1"
  var devicePolicyLabel = "balanced_receipt_camera"
  var reviewDepth = "pricesOnly"
  var focusMode = "continuous"
  var exposureMode = "auto"
  var whiteBalanceMode = "auto"
  var whiteBalanceLockEnabled = false
  var dataSaverLevel = "balanced"
  var receiptPhotoBackupEnabled = false
  var askSavedProofSizeEachReceipt = false
  var storageSafetyLevel = "balanced"
  var storageConstrained = false
  var storageSafetyReason = "normal"
  var workloadProtectionPolicy = "balanced_workload"
  var maxLocalPhotoBytes = 12 * 1024 * 1024
  var nativeCaptureMemoryPolicy = "bounded_temporary_source_for_ocr_then_cleanup"
  var previousSectionGuidePhotoPath: String?
  var nextSectionGuidePhotoPath: String?
  var previousSectionReasonCode = "none"
  var previousSectionGuidance = ""
  var previousSectionGhostSourceStartFraction: CGFloat = 0.80
  var previousSectionGhostSourceHeightFraction: CGFloat = 0.20
  var previousSectionGhostOverlayTopFraction: CGFloat = 0.0
  var previousSectionGhostOverlayHeightFraction: CGFloat = 0.20
  var previousSectionGhostOpacity: CGFloat = 0.36
  var liveAnalysisEnabled = true
  var edgeDetectionEnabled = true
  var edgeOverlayEnabled = true
  var lowLightWarningEnabled = false
  var glareWarningEnabled = false
  var dirtyLensWarningEnabled = false
  var motionBlurWarningEnabled = false
  var shadowWarningEnabled = false
  var tooFarTooCloseWarningEnabled = true
  var receiptFullyVisibleWarningEnabled = true
  var textTooSmallWarningEnabled = true
  var tapFocusEnabled = false
  var pinchZoomEnabled = true
  var exposureSliderEnabled = true
  var exposureResetEnabled = true
  var autoExposureAssistEnabled = true
  var perspectiveCorrectionEnabled = true
  var manualCropAfterCapture = true
  var autoCropSuggestionEnabled = true
  var grayscalePreviewEnabled = true
  var contrastBoostEnabled = true
  var sharpeningEnabled = true
  var shadowReductionEnabled = true
  var adaptiveThresholdEnabled = true
  var orientationCorrectionEnabled = true
  var saveOriginalTemporarily = true
  var queueAcceptedCaptureLocally = true
  var ocrUsesOriginalFirst = true
  var analysisGapMs = 720.0
  var readyHoldMs = 700.0
  var assistedShotCount = 4
  var bestShotCandidateCount = 3
  var cameraResolutionTier = "high"
  var cameraWorkloadTier = "balanced"
  let nativePreviewScaleMode = "resize_aspect_capture_parity"
  let nativeControlDensity = "compact_receipt_controls"
  var previewExposurePolicy = "receipt_paper_metering_safe_auto_lift_manual_slider"
  var previewBrightnessGuardPolicy = "avoid_dark_preview_full_receipt_sampling"
  var shutterSpeedPolicy = "prefer_fast_document_shutter_manual_capture_anytime"
  var tapToFocusPolicy = "continuous_focus_primary_no_tap_focus"
  var focusStrategyPolicy = "continuous_focus_primary_no_tap_assist"
  var continuousFocusEnabled = true
  var readabilityGuidancePolicy = "native_camera_baseline_neutral_receipt_guidance"
  var receiptCameraQualityBaseline = true
  var zoomGesturePolicy = "avfoundation_video_zoom_factor_clamped_to_capability"
  var autoCapturePolicy = "off_by_default_manual_shutter_primary"
  var preCaptureExposurePolicy = "receipt_paper_metering_dim_rescue_v2_manual_slider"
  var stillCaptureModeLabel = "receipt_fast_document_shutter"
  var nativeControlContractTags: [String] = []
  var maxLiveAnalysisPixels = 0
  var maxCleanupPixels = 10000000
  var maxStitchOutputPixels = 14000000
  var maxStitchOutputHeight = 18000
  var sessionMinZoom = 1.0
  var sessionMaxZoom = 1.0
  var sessionMinExposureOffset = 0.0
  var sessionMaxExposureOffset = 0.0
  var lastLiveAnalysisAt = 0.0
  var latestFrameBrightness = -1.0
  var latestShadowScore = -1.0
  var latestReadabilitySignal = "unknown"
  let experimentalReceiptQualityRequiredFrames = 3
  var experimentalReceiptQualityCandidateSignal = "none"
  var experimentalReceiptQualityCandidateCount = 0
  var latestFramingSignal = "unknown"
  var latestFramingConfidence = "unknown"
  var latestEdgeCoverage = -1.0
  var latestFramingWidthRatio = -1.0
  var latestFramingHeightRatio = -1.0
  var framingGuidanceCandidateSignal = "none"
  var framingGuidanceCandidateCount = 0
  var latestPerspectiveReadiness = "unknown"
  var latestMotionSignal = "unknown"
  var latestMotionScore = -1.0
  var previousLiveLumaSamples: [Int] = []
  var userExposureOverride = false
  var autoExposureAdjustmentCount = 0
  var preCaptureExposureAdjustmentCount = 0
  var preCaptureExposureAdjustmentConfirmedCount = 0
  var preCaptureExposureAbortCount = 0
  var lastAutoExposureAdjustmentAt = 0.0
  var lastAutoExposureDecision = "not_evaluated"
  var lastPreCaptureExposureDecision = "not_evaluated"
  var lastPreCaptureExposureSkipReason = "none"
  var lastPreCaptureExposureAbortReason = "none"
  var lastAutoExposureBrightnessBucket = "unknown"
  var lastAutoExposureCandidate = "none"
  var autoExposureCandidateFrameCount = 0
  var lastAutoExposureBias: Float = 0
  var lastPreCaptureExposureTargetBias: Float = 0
  var tapFocusCount = 0
  var tapFocusSuppressedAfterZoomCount = 0
  var zoomChangeCount = 0
  var zoomGestureStartCount = 0
  var zoomUnavailableCount = 0
  var lastZoomStatus = "not_used"
  var lastZoomRatio = 1.0
  var manualExposureChangeCount = 0
  var settingsOpenCount = 0
  var settingsResetCount = 0
  var lastFocusStatus = "not_used"
  var suppressTapFocusUntil = Date.distantPast
  var focusLockAttemptCount = 0
  var focusLockSuccessCount = 0
  var exposureLockSuccessCount = 0
  var whiteBalanceLockAttemptCount = 0
  var whiteBalanceLockSuccessCount = 0
  var whiteBalanceLockStatus = "not_requested"
  var autoCaptureStableFrameCount = 0
  var autoCaptureStableFrameTarget = 3
  var autoCaptureMaxMotionScore = 7.5
  var autoCaptureMinBrightness = 112.0
  var autoCaptureMaxBrightness = 238.0
  var autoCaptureCooldownMs = 2600.0
  var autoCaptureTriggerCount = 0
  var autoCaptureCooldownUntilMs = 0.0
  var latestAutoCaptureStatus = "off"
  var manualShutterTapCount = 0
  var manualCaptureStartedCount = 0
  var autoCaptureAttemptCount = 0
  var autoCaptureStartedCount = 0
  var captureBlockedNoCameraCount = 0
  var captureBlockedBusyCount = 0
  var captureBlockedClosingCount = 0
  var captureBlockedSurfaceInactiveCount = 0
  var lastCaptureTrigger = "none"
  var lastCaptureBlockReason = "none"
  var closeAction = "open"
  var closeRetryCount = 0
  var closeRequestCount = 0
  var closeDuringCaptureCount = 0
  var closeNoPhotoCancelCount = 0
  var closeReturnedSectionsCount = 0
  var lastBackDispatchPath = "not_requested"
  var maxSectionCount = 8
  var capturedPhotoPaths: [String] = []
  var firstCapturedAt: String?
  var totalCapturedByteSize = 0
  var latestCapturedPhotoWidth = 0
  var latestCapturedPhotoHeight = 0
  var latestCapturedAverageLuma = -1.0
  var latestCapturedEdgeScore = -1.0
  var latestCapturedTopLuma = -1.0
  var latestCapturedMiddleLuma = -1.0
  var latestCapturedBottomLuma = -1.0
  var latestCapturedBottomEdgeScore = -1.0
  var latestCapturedBottomTopLumaDelta = -10000.0
  var latestCapturedBottomTopLumaDeltaBucket = "unknown"
  var latestCapturedVerticalQualitySignal = "unknown"
  var latestCapturedMegapixelBucket = "unknown"
  var latestCapturedByteBucket = "unknown"
  var latestCapturedBrightnessBucket = "unknown"
  var latestCapturedSharpnessBucket = "unknown"
  var latestCapturedQualitySignal = "unknown"
  var latestCaptureLiveBrightnessAtShutter = -1.0
  var latestCapturedLiveToSavedLumaDelta = -10000.0
  var latestCapturedLiveToSavedLumaDeltaBucket = "unknown"
  var latestCapturedPreviewParitySignal = "unknown"
  var latestCapturedExposureMismatch = "unknown"
  var capturedLightingEvidence = "unknown"
  var latestCaptureStartedAt = 0.0
  var latestCaptureToSavedMs = -1
  var latestCaptureToReviewReadyMs = -1
  var latestCaptureLatencyBucket = "unknown"

  init(arguments: [String: Any]) {
    self.arguments = arguments
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    videoOutput.setSampleBufferDelegate(nil, queue: nil)
  }
}
