import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

extension ReceiptCameraViewController {
  func recordCapturedPhotoQuality(data: Data) {
    latestCapturedByteBucket = byteSizeBucket(data.count)
    guard let image = UIImage(data: data) else {
      latestCapturedPhotoWidth = 0
      latestCapturedPhotoHeight = 0
      latestCapturedAverageLuma = -1
      latestCapturedEdgeScore = -1
      latestCapturedTopLuma = -1
      latestCapturedMiddleLuma = -1
      latestCapturedBottomLuma = -1
      latestCapturedBottomEdgeScore = -1
      latestCapturedBottomTopLumaDelta = -10000
      latestCapturedBottomTopLumaDeltaBucket = "unknown"
      latestCapturedVerticalQualitySignal = "unknown"
      latestCapturedMegapixelBucket = "unknown"
      latestCapturedBrightnessBucket = "unknown"
      latestCapturedSharpnessBucket = "unknown"
      latestCapturedQualitySignal = "unknown"
      latestCapturedLiveToSavedLumaDelta = -10000
      latestCapturedLiveToSavedLumaDeltaBucket = "unknown"
      latestCapturedPreviewParitySignal = "unknown"
      latestCapturedExposureMismatch = "unknown"
      capturedLightingEvidence = "unknown"
      return
    }
    latestCapturedPhotoWidth = Int(image.size.width * image.scale)
    latestCapturedPhotoHeight = Int(image.size.height * image.scale)
    latestCapturedMegapixelBucket = megapixelBucket(
      width: latestCapturedPhotoWidth,
      height: latestCapturedPhotoHeight
    )
    let sample = sampleCapturedImageQuality(image)
    latestCapturedAverageLuma = roundedDiagnostic(sample.averageLuma)
    latestCapturedEdgeScore = roundedDiagnostic(sample.edgeScore)
    latestCapturedTopLuma = roundedDiagnostic(sample.topLuma)
    latestCapturedMiddleLuma = roundedDiagnostic(sample.middleLuma)
    latestCapturedBottomLuma = roundedDiagnostic(sample.bottomLuma)
    latestCapturedBottomEdgeScore = roundedDiagnostic(sample.bottomEdgeScore)
    latestCapturedBottomTopLumaDelta = capturedBottomTopLumaDelta(sample)
    latestCapturedBottomTopLumaDeltaBucket =
      capturedBottomTopLumaDeltaBucket(latestCapturedBottomTopLumaDelta)
    latestCapturedVerticalQualitySignal = capturedVerticalQualitySignal(sample)
    latestCapturedBrightnessBucket = capturedBrightnessBucket(sample.averageLuma)
    latestCapturedSharpnessBucket = capturedSharpnessBucket(sample.edgeScore)
    latestCapturedQualitySignal = capturedQualitySignal(
      brightnessBucket: latestCapturedBrightnessBucket,
      sharpnessBucket: latestCapturedSharpnessBucket
    )
    latestCapturedLiveToSavedLumaDelta = capturedLiveToSavedLumaDelta(
      liveBrightnessAtShutter: latestCaptureLiveBrightnessAtShutter,
      capturedAverageLuma: sample.averageLuma
    )
    latestCapturedLiveToSavedLumaDeltaBucket =
      capturedLiveToSavedLumaDeltaBucket(latestCapturedLiveToSavedLumaDelta)
    latestCapturedPreviewParitySignal = capturedPreviewParitySignal(
      deltaBucket: latestCapturedLiveToSavedLumaDeltaBucket,
      capturedBrightnessBucket: latestCapturedBrightnessBucket
    )
    latestCapturedExposureMismatch = capturedExposureMismatch(
      liveBrightness: latestCaptureLiveBrightnessAtShutter,
      capturedBrightnessBucket: latestCapturedBrightnessBucket,
      preCaptureDecision: lastPreCaptureExposureDecision
    )
    capturedLightingEvidence = capturedLightingEvidence(
      brightnessBucket: latestCapturedBrightnessBucket,
      verticalQualitySignal: latestCapturedVerticalQualitySignal,
      bottomTopDeltaBucket: latestCapturedBottomTopLumaDeltaBucket,
      exposureMismatch: latestCapturedExposureMismatch
    )
  }

}
