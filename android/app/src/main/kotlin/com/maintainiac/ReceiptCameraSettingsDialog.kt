package com.maintainiac

import android.app.Dialog
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

internal fun ReceiptCameraActivity.showReceiptCameraSettings() {
    settingsOpenCount += 1
    val dialog = Dialog(this).apply {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
    }
    val root = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setBackgroundColor(Color.rgb(22, 29, 32))
    }
    root.addView(LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        setPadding(dp(12), dp(12), dp(12), dp(8))
        setBackgroundColor(Color.rgb(17, 24, 27))
        addView(TextView(this@showReceiptCameraSettings).apply {
            text = "Receipt Camera Settings"
            setTextColor(Color.WHITE)
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        })
        addView(android.widget.Button(this@showReceiptCameraSettings).apply {
            text = "Done"
            isAllCaps = false
            setTextColor(Color.rgb(16, 20, 22))
            setBackgroundColor(Color.rgb(255, 209, 102))
            setOnClickListener { dialog.dismiss() }
        })
    })
    val content = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(18), dp(12), dp(18), dp(18))
    }
    content.addView(settingSummary(
        "Current receipt flow",
        "Capture or upload, review photos, use receipt, then review filled details. Brightness and light stay on the camera viewer.",
    ))
    content.addView(settingSectionHeader("ACCOUNT AND STORAGE"))
    content.addView(settingSwitch(
        "Back up receipt photos",
        "When enabled, saved proof copies can use Maintainiac backup. Full-size originals stay temporary unless you choose to keep them.",
        receiptPhotoBackupEnabled,
    ) {
        receiptPhotoBackupEnabled = it
        updateSettingsStatusStrip()
    })
    content.addView(settingMetricRow(
        "Storage remaining",
        receiptBackupRemainingLabel(),
        receiptBackupStorageDetailText(),
    ))
    content.addView(settingMetricRow(
        "Estimated receipt room",
        receiptBackupEstimatedReceiptCountLabel(),
        receiptBackupEstimatedReceiptDetailText(),
    ))
    content.addView(settingChoiceGroup(
        title = "Saved proof size",
        detail = "OCR reads the clearest temporary source first. This controls the smaller proof copy kept for review and backup.",
        selectedValue = dataSaverLevel,
        options = listOf(
            "light" to "High quality",
            "balanced" to "Balanced",
            "strong" to "Save storage",
            "maximum" to "Maximum savings",
            "original" to "Keep original locally",
        ),
    ) { selected ->
        dataSaverLevel = selected
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        "Ask proof size each receipt",
        "Show the proof-size choice during receipt review instead of always using this default.",
        askSavedProofSizeEachReceipt,
    ) {
        askSavedProofSizeEachReceipt = it
        updateSettingsStatusStrip()
    })
    content.addView(settingSectionHeader("RECEIPT ASSIST"))
    content.addView(settingSwitch(
        "Let Maintainiac help fill this receipt",
        "Read the photo and suggest receipt fields. You review everything before saving.",
        assistedReceiptFill,
    ) {
        assistedReceiptFill = it
        updateSettingsStatusStrip()
    })
    content.addView(settingSummary(
        "Manual entry stays available",
        "Turning Receipt Assist off keeps the photo attached and lets you fill the receipt form yourself.",
    ))
    content.addView(settingChoiceGroup(
        title = "Receipt details style",
        detail = "Choose the review screen Maintainiac opens after receipt text is read.",
        selectedValue = reviewDepth,
        options = listOf(
            "pricesOnly" to "Price-only review",
            "detailedLines" to "Detailed line review",
        ),
    ) { selected ->
        reviewDepth = selected
        updateSettingsStatusStrip()
    })
    content.addView(settingSectionHeader("CAPTURE FLOW"))
    content.addView(settingSwitch(
        "Long receipt mode",
        "Start at the top, add sections in order, and repeat a few readable lines so Maintainiac can match the receipt pieces.",
        longReceiptMode,
    ) {
        if (it && !canUseLongReceiptMode()) {
            longReceiptMode = false
            guidance.text = "Long receipt mode is unavailable for this device or storage setting."
            updateDoneButton()
            updateSettingsStatusStrip()
            return@settingSwitch
        }
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
            "Automatic capture is on. Hold steady, or capture anytime."
        } else {
            guidanceText()
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        "Receipt framing checks",
        "Warn when paper edges may be cut off or the receipt may be too far away. These checks never block the shutter button.",
        receiptGuidanceWarningsEnabled(),
    ) {
        setReceiptGuidanceWarningsEnabled(it)
        guidance.text = if (it) {
            "Receipt framing checks are on."
        } else {
            "Receipt framing checks are off. Manual shutter still works."
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
    content.addView(settingSummary(
        "Capture order",
        "Take the first photo, review it, add another section only when the receipt continues, then use the receipt.",
    ))
    content.addView(settingSummary(
        "Photo review decisions",
        "Retake fixes the current photo. Add Another is only for long receipts. Use Receipt starts OCR and opens the details review.",
    ))
    content.addView(settingSectionHeader("IMAGE HANDOFF"))
    content.addView(settingSummary(
        "Text reading source",
        "Maintainiac reads from the clearest temporary photo first. Smaller saved proof copies are made after the receipt has been read.",
    ))
    content.addView(settingSummary(
        "Long receipt stitching",
        "Sections are numbered top to bottom. Overlap is kept so review and stitching can match repeated lines.",
    ))
    content.addView(settingSectionHeader("CAMERA CONTROLS"))
    content.addView(settingSummary(
        "Brightness and light",
        "Brightness and the receipt light stay on the live camera screen so you can see the receipt while adjusting them.",
    ))
    content.addView(settingSummary(
        "Focus",
        "The phone camera owns autofocus. Maintainiac does not use tap-to-focus on the preview.",
    ))
    content.addView(settingSectionHeader("PRIVACY AND DIAGNOSTICS"))
    content.addView(settingSummary(
        "Improve receipt capture",
        "Receipt diagnostics must stay privacy-safe. Receipt images are not shown to the app owner from this screen.",
    ))
    val scroll = ScrollView(this).apply {
        isFillViewport = true
        addView(content)
    }
    root.addView(scroll, LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        0,
        1f,
    ))
    root.addView(android.widget.Button(this).apply {
        text = "Reset Receipt Camera Defaults"
        isAllCaps = false
        setTextColor(Color.rgb(255, 209, 102))
        setBackgroundColor(Color.rgb(31, 37, 40))
        setOnClickListener {
            resetReceiptCameraDefaults()
            dialog.dismiss()
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            leftMargin = dp(18)
            rightMargin = dp(18)
            bottomMargin = dp(14)
        }
    })
    dialog.setContentView(root)
    dialog.setOnShowListener {
        dialog.window?.setBackgroundDrawable(ColorDrawable(Color.rgb(22, 29, 32)))
        dialog.window?.setLayout(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
    }
    dialog.show()
}

internal fun ReceiptCameraActivity.receiptBackupRemainingLabel(): String {
    val quotaBytes = receiptBackupQuotaBytes()
    val usedBytes = receiptBackupUsedBytes()
    val remainingBytes = (quotaBytes - usedBytes).coerceIn(0, quotaBytes)
    return "${formatReceiptBytes(remainingBytes)} of ${formatReceiptBytes(quotaBytes)}"
}

internal fun ReceiptCameraActivity.receiptBackupStorageDetailText(): String {
    val connection = receiptBackupConnectionLabel()
    val usedBytes = receiptBackupUsedBytes()
    return "$connection. ${formatReceiptBytes(usedBytes)} already used for receipt backup."
}

internal fun ReceiptCameraActivity.receiptBackupEstimatedReceiptCountLabel(): String {
    val quotaBytes = receiptBackupQuotaBytes()
    val usedBytes = receiptBackupUsedBytes()
    val remainingBytes = (quotaBytes - usedBytes).coerceIn(0, quotaBytes)
    val proofBytes = receiptProofTargetBytesFor(dataSaverLevel)
    val estimatedReceipts = if (proofBytes > 0) remainingBytes / proofBytes else 0
    return "~$estimatedReceipts receipts"
}

internal fun ReceiptCameraActivity.receiptBackupEstimatedReceiptDetailText(): String {
    return "Based on ${receiptProofSizeLabel(dataSaverLevel)} saved proof copies. Actual count depends on receipt length and image quality."
}

internal fun ReceiptCameraActivity.receiptBackupConnectionLabel(): String {
    return intent.getStringExtra("receiptBackupConnectionLabel")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: "Backup account not connected"
}

internal fun ReceiptCameraActivity.receiptBackupQuotaBytes(): Long {
    return intent.getLongExtra("receiptBackupQuotaBytes", 100L * 1024L * 1024L)
        .coerceAtLeast(0L)
}

internal fun ReceiptCameraActivity.receiptBackupUsedBytes(): Long {
    return intent.getLongExtra("receiptBackupUsedBytes", 0L)
        .coerceAtLeast(0L)
}

internal fun ReceiptCameraActivity.receiptProofTargetBytesFor(level: String): Long {
    return when (level) {
        "original" -> 4L * 1024L * 1024L
        "light" -> 650L * 1024L
        "strong" -> 150L * 1024L
        "maximum" -> 80L * 1024L
        else -> 300L * 1024L
    }
}

internal fun ReceiptCameraActivity.receiptProofSizeLabel(level: String): String {
    return when (level) {
        "original" -> "original local"
        "light" -> "high quality"
        "strong" -> "save storage"
        "maximum" -> "maximum savings"
        else -> "balanced"
    }
}

internal fun ReceiptCameraActivity.formatReceiptBytes(bytes: Long): String {
    val gib = 1024.0 * 1024.0 * 1024.0
    val mib = 1024.0 * 1024.0
    val kib = 1024.0
    return when {
        bytes >= 1024L * 1024L * 1024L -> String.format("%.1f GB", bytes / gib)
        bytes >= 1024L * 1024L -> String.format("%.0f MB", bytes / mib)
        bytes >= 1024L -> String.format("%.0f KB", bytes / kib)
        else -> "$bytes B"
    }
}

internal fun ReceiptCameraActivity.resetReceiptCameraDefaults() {
    settingsResetCount += 1
    // Receipt Assist remains opt-in, even after restoring camera defaults.
    assistedReceiptFill = false
    receiptPhotoBackupEnabled = false
    longReceiptMode = canUseLongReceiptMode()
    autoCaptureEnabled = false
    reviewDepth = "pricesOnly"
    dataSaverLevel = "balanced"
    askSavedProofSizeEachReceipt = false
    autoExposureAssistEnabled = true
    liveAnalysisEnabled = true
    edgeDetectionEnabled = true
    edgeOverlayEnabled = true
    setReceiptGuidanceWarningsEnabled(true)
    perspectiveCorrectionEnabled = true
    manualCropAfterCapture = true
    autoCropSuggestionEnabled = true
    grayscalePreviewEnabled = true
    contrastBoostEnabled = true
    sharpeningEnabled = true
    shadowReductionEnabled = true
    adaptiveThresholdEnabled = true
    orientationCorrectionEnabled = true
    autoCaptureStableFrameCount = 0
    latestAutoCaptureStatus = "reset_to_manual_capture"
    userExposureOverride = false
    resetExposure()
    if (hasInitializedReceiptCameraField { receiptFrameGuide }) {
        receiptFrameGuide.visibility = View.VISIBLE
    }
    updateDoneButton()
    updateSettingsStatusStrip()
    guidance.text = "Receipt camera defaults restored. Manual shutter is ready."
}

internal fun ReceiptCameraActivity.receiptGuidanceWarningsEnabled(): Boolean {
    return tooFarTooCloseWarningEnabled ||
        receiptFullyVisibleWarningEnabled ||
        textTooSmallWarningEnabled
}

internal fun ReceiptCameraActivity.experimentalLiveReceiptQualityPolicyEnabled(): Boolean {
    return readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"
}

internal fun ReceiptCameraActivity.setReceiptGuidanceWarningsEnabled(enabled: Boolean) {
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
    textTooSmallWarningEnabled = enabled
}
