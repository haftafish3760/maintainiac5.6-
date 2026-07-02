package com.maintainiac

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.io.File
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

internal fun ReceiptCameraActivity.buildPreviousSectionGuide(): View {
    previousSectionGuidePanel = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(10), dp(7), dp(10), dp(7))
        setBackgroundColor(Color.argb(132, 5, 6, 7))
        visibility = View.GONE
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(102),
            Gravity.TOP,
        ).apply {
            topMargin = dp(130)
            leftMargin = dp(18)
            rightMargin = dp(18)
        }
    }
    previousSectionGuidePanel.addView(TextView(this).apply {
        text = previousSectionGhostGuideTitle()
        setTextColor(Color.WHITE)
        textSize = 12f
        setTypeface(typeface, android.graphics.Typeface.BOLD)
    })
    previousSectionGuideImage = ImageView(this).apply {
        contentDescription = "Previous receipt section overlap guide"
        scaleType = ImageView.ScaleType.CENTER_CROP
        alpha = previousSectionGhostOpacity.toFloat()
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            0,
            1f,
        )
    }
    previousSectionGuidePanel.addView(previousSectionGuideImage)
    previousSectionGuidePanel.addView(TextView(this).apply {
        text = previousSectionGhostGuideInstruction()
        setTextColor(Color.rgb(255, 209, 102))
        textSize = 11f
        gravity = Gravity.CENTER
    })
    updatePreviousSectionGuide(previousSectionGuidePhotoPath)
    return previousSectionGuidePanel
}

internal fun ReceiptCameraActivity.updatePreviousSectionGuide(path: String?) {
    if (!hasInitializedReceiptCameraField { previousSectionGuidePanel }) return
    val guidePath = path?.trim()?.takeIf { it.isNotEmpty() } ?: run {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideFile = File(guidePath)
    if (!guideFile.exists()) {
        previousSectionGuidePanel.visibility = View.GONE
        return
    }
    val guideSlice = previousSectionGhostSliceBitmap(guideFile)
    if (guideSlice != null) {
        previousSectionGuideImage.setImageBitmap(guideSlice)
    } else {
        previousSectionGuideImage.setImageURI(Uri.fromFile(guideFile))
    }
    previousSectionGuideImage.alpha = previousSectionGhostOpacity.toFloat()
    previousSectionGuideImage.contentDescription =
        "${previousSectionGhostGuideTitle()}. ${previousSectionGhostGuideInstruction()}"
    previousSectionGuidePanel.visibility = View.VISIBLE
}

internal fun ReceiptCameraActivity.previousSectionGhostSliceBitmap(file: File): Bitmap? {
    val source = BitmapFactory.decodeFile(file.absolutePath) ?: return null
    if (source.width <= 0 || source.height <= 0) return source
    val startY = floor(source.height * previousSectionGhostSourceStartFraction)
        .roundToInt()
        .coerceIn(0, source.height - 1)
    val requestedHeight = ceil(source.height * previousSectionGhostSourceHeightFraction)
        .roundToInt()
        .coerceAtLeast(1)
    val sliceHeight = min(requestedHeight, source.height - startY).coerceAtLeast(1)
    return try {
        Bitmap.createBitmap(source, 0, startY, source.width, sliceHeight)
    } catch (_: IllegalArgumentException) {
        source
    }
}

internal fun ReceiptCameraActivity.boundedFraction(value: Double, fallback: Double): Double {
    if (value.isNaN() || value.isInfinite()) return fallback
    return value.coerceIn(0.0, 1.0)
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideTitle(): String {
    return if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
        "Match the bottom section"
    } else {
        "Match receipt sections"
    }
}

internal fun ReceiptCameraActivity.previousSectionGhostGuideInstruction(): String {
    return previousSectionGuidance
        .trim()
        .takeIf { it.isNotEmpty() }
        ?: if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
            "Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines so subtotal, total, and final lines can be matched."
        } else {
            "Repeat 3-5 readable lines near the top ghost slice of this photo."
        }
}

internal fun ReceiptCameraActivity.addSectionButtonTitle(): String {
    return if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
        "Add Bottom"
    } else {
        "Add Section ${nextReceiptSectionNumber()}"
    }
}

internal fun ReceiptCameraActivity.addSectionButtonAccessibilityLabel(): String {
    return if (previousSectionReasonCode == "missing_bottom_edge_and_totals") {
        "Add bottom receipt section with overlap from this photo"
    } else {
        "Add receipt section ${nextReceiptSectionNumber()} if this receipt continues"
    }
}
