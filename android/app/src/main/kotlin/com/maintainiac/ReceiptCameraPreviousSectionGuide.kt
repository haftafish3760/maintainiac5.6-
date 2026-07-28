package com.maintainiac

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.exifinterface.media.ExifInterface
import java.io.File
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

internal fun ReceiptCameraActivity.buildPreviousSectionGuide(): View {
    previousSectionGuidePanel = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        // Keep continuation help visible without turning it into a second
        // toolbar that hides the receipt. The guide is optional assistance,
        // never a control that traps or obstructs the capture view.
        setPadding(dp(10), dp(4), dp(10), dp(4))
        setBackgroundColor(Color.argb(100, 5, 6, 7))
        visibility = View.GONE
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(84),
            Gravity.TOP,
        ).apply {
            topMargin = dp(130)
            leftMargin = dp(18)
            rightMargin = dp(18)
        }
    }
    previousSectionGuidePanel.addView(LinearLayout(this).apply {
        gravity = Gravity.CENTER_VERTICAL
        addView(TextView(this@buildPreviousSectionGuide).apply {
            text = previousSectionGhostGuideTitle()
            setTextColor(Color.WHITE)
            textSize = 12f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f,
            )
        })
        addView(TextView(this@buildPreviousSectionGuide).apply {
            text = "Hide"
            contentDescription = "Hide receipt overlap guide"
            setTextColor(Color.rgb(255, 209, 102))
            textSize = 12f
            setPadding(dp(8), 0, 0, 0)
            isClickable = true
            isFocusable = true
            setOnClickListener { previousSectionGuidePanel.visibility = View.GONE }
        })
    })
    previousSectionGuideImage = ImageView(this).apply {
        contentDescription = "Previous receipt section overlap guide"
        scaleType = ImageView.ScaleType.CENTER_CROP
        alpha = previousSectionGhostOpacity.coerceIn(0.0, 1.0).toFloat()
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(22),
        )
    }
    previousSectionGuidePanel.addView(previousSectionGuideImage)
    nextSectionGuideImage = ImageView(this).apply {
        contentDescription = "Next receipt section overlap guide"
        scaleType = ImageView.ScaleType.CENTER_CROP
        alpha = nextSectionGhostOpacity()
        visibility = View.GONE
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(18),
        )
    }
    previousSectionGuidePanel.addView(nextSectionGuideImage)
    previousSectionGuidePanel.addView(TextView(this).apply {
        // The detailed reason stays in accessibility text and review. During
        // capture, one complete instruction is faster to understand and does
        // not cover the receipt with a paragraph.
        text = "Repeat 3–5 readable lines in this guide."
        setTextColor(Color.rgb(255, 209, 102))
        textSize = 10f
        gravity = Gravity.CENTER
    })
    updatePreviousSectionGuide(previousSectionGuidePhotoPath)
    updateNextSectionGuide(nextSectionGuidePhotoPath)
    return previousSectionGuidePanel
}

internal fun ReceiptCameraActivity.updatePreviousSectionGuide(path: String?) {
    if (!hasInitializedReceiptCameraField { previousSectionGuidePanel }) return
    val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideFile = File(guidePath)
    if (
        !guideFile.isAbsolute ||
        !guideFile.isFile ||
        !isPreviousSectionGuideImagePath(guidePath)
    ) {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideSlice = previousSectionGhostSliceBitmap(guideFile)
    if (guideSlice == null) {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    previousSectionGuideImage.setImageBitmap(guideSlice)
    previousSectionGuideImage.alpha = previousSectionGhostOpacity.toFloat()
    previousSectionGuideImage.contentDescription =
        "${previousSectionGhostGuideTitle()}. ${previousSectionGhostGuideInstruction()}"
    previousSectionGuidePanel.visibility = View.VISIBLE
}

internal fun ReceiptCameraActivity.updateNextSectionGuide(path: String?) {
    if (!hasInitializedReceiptCameraField { nextSectionGuideImage }) return
    val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
        nextSectionGuideImage.visibility = View.GONE
        if (previousSectionGuidePhotoPath.isNullOrBlank()) {
            previousSectionGuidePanel.visibility = View.GONE
        }
        return
    }
    val guideFile = File(guidePath)
    if (
        !guideFile.isAbsolute ||
        !guideFile.isFile ||
        !isPreviousSectionGuideImagePath(guidePath)
    ) {
        nextSectionGuideImage.visibility = View.GONE
        return
    }
    val guideSlice = nextSectionGhostSliceBitmap(guideFile)
    if (guideSlice == null) {
        nextSectionGuideImage.visibility = View.GONE
        return
    }
    nextSectionGuideImage.setImageBitmap(guideSlice)
    nextSectionGuideImage.alpha = nextSectionGhostOpacity()
    nextSectionGuideImage.contentDescription =
        "Next receipt section context guide. Repeat the top readable lines."
    nextSectionGuideImage.visibility = View.VISIBLE
    previousSectionGuidePanel.visibility = View.VISIBLE
}

internal fun ReceiptCameraActivity.previousSectionGhostSliceBitmap(file: File): Bitmap? {
    val source = receiptGhostBitmapWithVisualOrientation(file) ?: return null
    if (source.width <= 0 || source.height <= 0) return source
    val sourceStartFraction = boundedFraction(previousSectionGhostSourceStartFraction, 0.80)
    val sourceHeightFraction = boundedFraction(previousSectionGhostSourceHeightFraction, 0.20)
    val startY = floor(source.height * sourceStartFraction)
        .roundToInt()
        .coerceIn(0, source.height - 1)
    val requestedHeight = ceil(source.height * sourceHeightFraction)
        .roundToInt()
        .coerceAtLeast(1)
    val sliceHeight = min(requestedHeight, source.height - startY).coerceAtLeast(1)
    return try {
        Bitmap.createBitmap(source, 0, startY, source.width, sliceHeight)
    } catch (_: IllegalArgumentException) {
        source
    }
}

internal fun ReceiptCameraActivity.nextSectionGhostSliceBitmap(file: File): Bitmap? {
    val source = receiptGhostBitmapWithVisualOrientation(file) ?: return null
    if (source.width <= 0 || source.height <= 0) return source
    val requestedHeight = ceil(source.height * 0.20).roundToInt().coerceAtLeast(1)
    val sliceHeight = min(requestedHeight, source.height).coerceAtLeast(1)
    return try {
        Bitmap.createBitmap(source, 0, 0, source.width, sliceHeight)
    } catch (_: IllegalArgumentException) {
        source
    }
}

private fun receiptGhostBitmapWithVisualOrientation(file: File): Bitmap? {
    val source = BitmapFactory.decodeFile(file.absolutePath) ?: return null
    val orientation = try {
        ExifInterface(file.absolutePath).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL,
        )
    } catch (_: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }
    val matrix = Matrix()
    when (orientation) {
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
        ExifInterface.ORIENTATION_TRANSPOSE -> {
            matrix.setRotate(90f)
            matrix.postScale(-1f, 1f)
        }
        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
        ExifInterface.ORIENTATION_TRANSVERSE -> {
            matrix.setRotate(-90f)
            matrix.postScale(-1f, 1f)
        }
        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
        else -> return source
    }
    return try {
        Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    } catch (_: IllegalArgumentException) {
        source
    }
}

internal fun ReceiptCameraActivity.nextSectionGhostOpacity(): Float = 0.28f

internal fun ReceiptCameraActivity.isPreviousSectionGuideImagePath(path: String): Boolean {
    val lowerPath = path.lowercase()
    return lowerPath.endsWith(".jpg") ||
        lowerPath.endsWith(".jpeg") ||
        lowerPath.endsWith(".png") ||
        lowerPath.endsWith(".heic") ||
        lowerPath.endsWith(".webp")
}

internal fun ReceiptCameraActivity.boundedFraction(value: Double, fallback: Double): Double {
    if (value.isNaN() || value.isInfinite()) return fallback
    return value.coerceIn(0.0, 1.0)
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideTitle(): String {
    return when {
        previousSectionGuideUsesNextContext() -> "Match the next section"
        previousSectionReasonCode == "missing_bottom_edge_and_totals" -> "Match the bottom section"
        else -> "Match receipt sections"
    }
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideInstruction(): String {
    return previousSectionGuidance
        .trim()
        .takeIf { it.isNotEmpty() }
        ?: when {
            previousSectionGuideUsesNextContext() ->
                "Use the top of the next receipt section as context, then confirm the retake still joins cleanly in photo review."
            previousSectionReasonCode == "missing_bottom_edge_and_totals" ->
                "Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines so subtotal, total, and final lines can be matched."
            else -> "Repeat 3-5 readable lines near the top ghost slice of this photo."
        }
}

internal fun ReceiptCameraActivity.previousSectionGuideUsesNextContext(): Boolean {
    return previousSectionReasonCode == "retake_top_with_next_context"
}

internal fun ReceiptCameraActivity.previousSectionGhostGuidePolicy(): String {
    return when {
        previousSectionGuideUsesNextContext() ->
            "next_section_top_context_ghost_at_top_repeat_3_to_5_lines"
        previousSectionReasonCode == "missing_bottom_edge_and_totals" ->
            "bottom_overlap_ghost_at_top_repeat_3_to_5_lines"
        else -> "section_overlap_ghost_at_top_repeat_3_to_5_lines"
    }
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideMatchTarget(): String {
    return when {
        previousSectionGuideUsesNextContext() -> "next_section_top_lines"
        previousSectionReasonCode == "missing_bottom_edge_and_totals" ->
            "subtotal_total_and_final_lines"
        else -> "repeated_receipt_lines"
    }
}

internal fun ReceiptCameraActivity.addSectionButtonTitle(): String {
    return if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
        "Add Bottom"
    } else {
        "Add Photo"
    }
}

internal fun ReceiptCameraActivity.addSectionButtonAccessibilityLabel(): String {
    return if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
        "Add bottom receipt section with overlap from this photo"
    } else {
        "Add another receipt photo if this receipt continues"
    }
}
