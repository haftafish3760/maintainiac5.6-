package com.maintainiac

import kotlin.math.roundToInt

internal fun ReceiptCameraActivity.nextReceiptSectionNumber(): Int {
    return (capturedPhotoPaths.size + 1).coerceAtMost(maxSectionCount)
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideVisible(): Boolean {
    return longReceiptMode &&
        capturedPhotoPaths.isNotEmpty() &&
        capturedPhotoPaths.size < maxSectionCount
}

internal fun ReceiptCameraActivity.longReceiptSectionDiagnostics(): Map<String, Any> {
    return mapOf(
        "photoCount" to capturedPhotoPaths.size,
        "receiptSectionCount" to capturedPhotoPaths.size,
        "nextReceiptSectionNumber" to nextReceiptSectionNumber(),
        "maxSectionCount" to maxSectionCount,
        "receiptSectionOrderPolicy" to "top_to_bottom_numbered_sections",
        "longReceiptSectionGuidance" to "top_to_bottom_with_readable_overlap",
        "previousSectionGhostGuidePolicy" to previousSectionGhostGuidePolicy(),
        "previousSectionGhostGuideUsesNextContext" to previousSectionGuideUsesNextContext(),
        "previousSectionGhostGuideMatchTarget" to previousSectionGhostGuideMatchTarget(),
        "previousSectionGhostGuideVisible" to previousSectionGhostGuideVisible(),
        "previousSectionGhostSourceStartFraction" to previousSectionGhostSourceStartFraction,
        "previousSectionGhostSourceHeightFraction" to previousSectionGhostSourceHeightFraction,
        "previousSectionGhostOverlayTopFraction" to previousSectionGhostOverlayTopFraction,
        "previousSectionGhostOverlayHeightFraction" to previousSectionGhostOverlayHeightFraction,
        "previousSectionGhostOpacity" to previousSectionGhostOpacity,
        "previousSectionGhostSlicePercent" to (previousSectionGhostSourceHeightFraction * 100.0).roundToInt(),
    )
}

internal fun ReceiptCameraActivity.previousSectionCaptureDiagnostics(): Map<String, Any> {
    return mapOf(
        "hasPreviousSectionGuide" to (previousSectionGuidePhotoPath != null),
        "previousSectionReasonCode" to previousSectionReasonCode,
        "previousSectionMissingBottomAndTotals" to (previousSectionReasonCode == "missing_bottom_edge_and_totals"),
        "previousSectionGhostGuideUsesNextContext" to previousSectionGuideUsesNextContext(),
        "previousSectionGhostGuidePolicy" to previousSectionGhostGuidePolicy(),
        "previousSectionGhostGuideMatchTarget" to previousSectionGhostGuideMatchTarget(),
        "previousSectionGuidanceAvailable" to previousSectionGuidance.isNotEmpty(),
        "previousSectionGhostGuideTitle" to previousSectionGhostGuideTitle(),
        "previousSectionGhostGuideInstruction" to previousSectionGhostGuideInstruction(),
        "previousSectionGhostSourceStartFraction" to previousSectionGhostSourceStartFraction,
        "previousSectionGhostSourceHeightFraction" to previousSectionGhostSourceHeightFraction,
        "previousSectionGhostOverlayTopFraction" to previousSectionGhostOverlayTopFraction,
        "previousSectionGhostOverlayHeightFraction" to previousSectionGhostOverlayHeightFraction,
        "previousSectionGhostOpacity" to previousSectionGhostOpacity,
        "previousSectionGhostSlicePercent" to (previousSectionGhostSourceHeightFraction * 100.0).roundToInt(),
    )
}
