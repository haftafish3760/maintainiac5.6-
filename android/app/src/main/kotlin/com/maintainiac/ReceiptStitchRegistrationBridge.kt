package com.maintainiac

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import org.opencv.android.OpenCVLoader
import org.opencv.calib3d.Calib3d
import org.opencv.core.DMatch
import org.opencv.core.Mat
import org.opencv.core.MatOfDMatch
import org.opencv.core.MatOfKeyPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Size
import org.opencv.features2d.DescriptorMatcher
import org.opencv.features2d.ORB
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

class ReceiptStitchRegistrationBridge(private val activity: Activity) {
    private val executor = Executors.newSingleThreadExecutor()
    private val requestGeneration = AtomicLong()
    private var channel: MethodChannel? = null
    @Volatile private var activeTask: Future<*>? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingClientRequestId: Long? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, channelName).also {
            it.setMethodCallHandler(::handle)
        }
    }

    fun close() {
        cancelActiveRequest(replyWithEmptyResult = false)
        channel?.setMethodCallHandler(null)
        channel = null
        executor.shutdownNow()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "cancelProposals") {
            val requestedId = ((call.arguments as? Map<*, *>)?.get("requestId") as? Number)
                ?.toLong()
                ?.takeIf { it > 0 }
            if (requestedId == null) {
                result.error(
                    "invalid_registration_request",
                    "Receipt registration cancellation requires a request ID.",
                    null,
                )
                return
            }
            result.success(
                cancelActiveRequest(
                    replyWithEmptyResult = true,
                    expectedClientRequestId = requestedId,
                ),
            )
            return
        }
        if (call.method != "proposeTransforms") {
            result.notImplemented()
            return
        }
        val arguments = call.arguments as? Map<*, *>
        val clientRequestId = (arguments?.get("requestId") as? Number)
            ?.toLong()
            ?.takeIf { it > 0 }
        if (clientRequestId == null) {
            result.error(
                "invalid_registration_request",
                "Receipt registration requires a request ID.",
                null,
            )
            return
        }
        val paths = (arguments?.get("paths") as? List<*>)
            ?.mapNotNull { it as? String }
            ?.filter { it.isNotBlank() }
            ?: emptyList()
        val comparisonWidth =
            ((arguments?.get("comparisonWidth") as? Number)?.toInt() ?: 320)
                .coerceIn(240, 480)
        val maxFeatures =
            ((arguments?.get("maxFeatures") as? Number)?.toInt() ?: 420)
                .coerceIn(240, 1200)
        if (paths.size < 2) {
            result.success(emptyList<Map<String, Any>>())
            return
        }
        cancelActiveRequest(replyWithEmptyResult = true)
        val requestId = requestGeneration.incrementAndGet()
        pendingResult = result
        pendingClientRequestId = clientRequestId
        activeTask = executor.submit {
            try {
                if (!OpenCVLoader.initLocal()) {
                    throw IllegalStateException("OpenCV initialization failed")
                }
                val proposals = mutableListOf<Map<String, Any>>()
                for ((index, pair) in paths.zipWithNext().withIndex()) {
                    if (
                        requestGeneration.get() != requestId ||
                        Thread.currentThread().isInterrupted
                    ) {
                        return@submit
                    }
                    proposePair(index, pair.first, pair.second, comparisonWidth, maxFeatures)
                        ?.let(proposals::add)
                }
                completeRequest(requestId, result) { result.success(proposals) }
            } catch (error: Throwable) {
                if (requestGeneration.get() == requestId) {
                    completeRequest(requestId, result) {
                        result.error(
                            "native_registration_failed",
                            "Native receipt registration was unavailable.",
                            mapOf("type" to error.javaClass.simpleName),
                        )
                    }
                }
            }
        }
    }

    private fun cancelActiveRequest(
        replyWithEmptyResult: Boolean,
        expectedClientRequestId: Long? = null,
    ): Boolean {
        if (expectedClientRequestId != null && pendingClientRequestId != expectedClientRequestId) {
            return false
        }
        requestGeneration.incrementAndGet()
        activeTask?.cancel(true)
        activeTask = null
        val result = pendingResult
        pendingResult = null
        pendingClientRequestId = null
        if (replyWithEmptyResult && result != null) {
            result.success(emptyList<Map<String, Any>>())
        }
        return result != null
    }

    private fun completeRequest(
        requestId: Long,
        result: MethodChannel.Result,
        completion: () -> Unit,
    ) {
        activity.runOnUiThread {
            if (requestGeneration.get() != requestId || pendingResult !== result) {
                return@runOnUiThread
            }
            activeTask = null
            pendingResult = null
            pendingClientRequestId = null
            completion()
        }
    }

    private fun proposePair(
        pairIndex: Int,
        previousPath: String,
        nextPath: String,
        comparisonWidth: Int,
        maxFeatures: Int,
    ): Map<String, Any>? {
        val previous = readComparisonImage(previousPath, comparisonWidth) ?: return null
        val next = readComparisonImage(nextPath, comparisonWidth) ?: run {
            previous.release()
            return null
        }
        val orb = ORB.create(maxFeatures)
        val previousKeypoints = MatOfKeyPoint()
        val nextKeypoints = MatOfKeyPoint()
        val previousDescriptors = Mat()
        val nextDescriptors = Mat()
        val mask = Mat()
        try {
            orb.detectAndCompute(previous, mask, previousKeypoints, previousDescriptors)
            orb.detectAndCompute(next, mask, nextKeypoints, nextDescriptors)
            if (previousDescriptors.empty() || nextDescriptors.empty()) return null
            val matcher = DescriptorMatcher.create(DescriptorMatcher.BRUTEFORCE_HAMMING)
            val matches = mutableListOf<MatOfDMatch>()
            try {
                matcher.knnMatch(nextDescriptors, previousDescriptors, matches, 2)
            } finally {
                matcher.clear()
            }
            val previousPoints = previousKeypoints.toArray()
            val nextPoints = nextKeypoints.toArray()
            val goodMatches = matches.mapNotNull { neighbors ->
                val values = neighbors.toArray()
                neighbors.release()
                if (values.size < 2 || values[0].distance >= values[1].distance * ratioThreshold) {
                    null
                } else {
                    values[0]
                }
            }.filter { match ->
                val source = nextPoints.getOrNull(match.queryIdx)?.pt ?: return@filter false
                val destination = previousPoints.getOrNull(match.trainIdx)?.pt
                    ?: return@filter false
                val sourceY = source.y / max(1.0, next.rows().toDouble())
                val destinationY = destination.y / max(1.0, previous.rows().toDouble())
                destinationY - sourceY >= minimumContinuationAdvance
            }.sortedBy(DMatch::distance).take(maxMatches)
            if (goodMatches.size < minimumInliers) return null

            val sourcePoints = goodMatches.map { nextPoints[it.queryIdx].pt }
            val destinationPoints = goodMatches.map { previousPoints[it.trainIdx].pt }
            val sourceMat = MatOfPoint2f(*sourcePoints.toTypedArray())
            val destinationMat = MatOfPoint2f(*destinationPoints.toTypedArray())
            val inlierMask = Mat()
            val transform = try {
                Calib3d.estimateAffinePartial2D(
                    sourceMat,
                    destinationMat,
                    inlierMask,
                    Calib3d.RANSAC,
                    ransacThreshold,
                    2000,
                    .995,
                    10,
                )
            } finally {
                sourceMat.release()
                destinationMat.release()
            }
            try {
                if (transform.empty() || transform.rows() != 2 || transform.cols() != 3) {
                    return null
                }
                val inlierFlags = ByteArray(inlierMask.rows().toInt())
                if (inlierFlags.isNotEmpty()) inlierMask.get(0, 0, inlierFlags)
                val inlierIndices = inlierFlags.indices.filter { inlierFlags[it].toInt() != 0 }
                if (inlierIndices.size < minimumInliers) return null
                val a = transform.get(0, 0)[0]
                val c = transform.get(1, 0)[0]
                val scale = hypot(a, c)
                val rotationDegrees = Math.toDegrees(atan2(c, a))
                if (scale !in .75..1.25 || rotationDegrees !in -8.0..8.0) return null
                val anchors = inlierIndices.take(maxAnchors).map { matchIndex ->
                    val previousPoint = destinationPoints[matchIndex]
                    val nextPoint = sourcePoints[matchIndex]
                    mapOf(
                        "previousX" to (previousPoint.x / previous.cols()).coerceIn(0.0, 1.0),
                        "previousY" to (previousPoint.y / previous.rows()).coerceIn(0.0, 1.0),
                        "nextX" to (nextPoint.x / next.cols()).coerceIn(0.0, 1.0),
                        "nextY" to (nextPoint.y / next.rows()).coerceIn(0.0, 1.0),
                    )
                }
                val reprojectionError = medianReprojectionError(
                    transform,
                    inlierIndices,
                    sourcePoints,
                    destinationPoints,
                )
                val inlierRatio = inlierIndices.size.toDouble() / goodMatches.size
                val coverage = verticalCoverage(anchors)
                if (reprojectionError > maximumReprojectionError || coverage < minimumCoverage) {
                    return null
                }
                val confidence = (
                    min(1.0, inlierIndices.size / 14.0) * .45 +
                        inlierRatio * .35 +
                        min(1.0, coverage / .22) * .20 -
                        min(.25, reprojectionError / 20)
                    ).coerceIn(0.0, 1.0)
                if (confidence < minimumConfidence) return null
                return mapOf(
                    "pairIndex" to pairIndex,
                    "scale" to scale,
                    "rotationDegrees" to rotationDegrees,
                    "confidence" to confidence,
                    "inlierCount" to inlierIndices.size,
                    "reprojectionError" to reprojectionError,
                    "anchors" to anchors,
                )
            } finally {
                transform.release()
                inlierMask.release()
            }
        } finally {
            mask.release()
            previousDescriptors.release()
            nextDescriptors.release()
            previousKeypoints.release()
            nextKeypoints.release()
            orb.clear()
            previous.release()
            next.release()
        }
    }

    private fun readComparisonImage(path: String, width: Int): Mat? {
        val source = Imgcodecs.imread(path, Imgcodecs.IMREAD_GRAYSCALE)
        if (source.empty() || source.cols() < 48 || source.rows() < 80) {
            source.release()
            return null
        }
        val resized = Mat()
        val height = max(1, (source.rows().toDouble() * width / source.cols()).toInt())
        Imgproc.resize(source, resized, Size(width.toDouble(), height.toDouble()), 0.0, 0.0, Imgproc.INTER_AREA)
        source.release()
        return resized
    }

    private fun medianReprojectionError(
        transform: Mat,
        inlierIndices: List<Int>,
        source: List<Point>,
        destination: List<Point>,
    ): Double {
        val a = transform.get(0, 0)[0]
        val b = transform.get(0, 1)[0]
        val tx = transform.get(0, 2)[0]
        val c = transform.get(1, 0)[0]
        val d = transform.get(1, 1)[0]
        val ty = transform.get(1, 2)[0]
        val errors = inlierIndices.map { index ->
            val point = source[index]
            val expected = destination[index]
            hypot(a * point.x + b * point.y + tx - expected.x, c * point.x + d * point.y + ty - expected.y)
        }.sorted()
        return errors[errors.size / 2]
    }

    private fun verticalCoverage(anchors: List<Map<String, Double>>): Double {
        if (anchors.isEmpty()) return 0.0
        val previousValues = anchors.mapNotNull { it["previousY"] }
        val nextValues = anchors.mapNotNull { it["nextY"] }
        return min(
            (previousValues.maxOrNull() ?: 0.0) - (previousValues.minOrNull() ?: 0.0),
            (nextValues.maxOrNull() ?: 0.0) - (nextValues.minOrNull() ?: 0.0),
        )
    }

    companion object {
        private const val channelName = "maintainiac/receipt_stitch_registration"
        private const val ratioThreshold = .74
        private const val minimumContinuationAdvance = .04
        private const val ransacThreshold = 3.0
        private const val maximumReprojectionError = 4.5
        private const val minimumConfidence = .45
        private const val minimumCoverage = .08
        private const val minimumInliers = 6
        private const val maxMatches = 96
        private const val maxAnchors = 24
    }
}
