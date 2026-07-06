package com.maintainiac

import android.app.AlertDialog
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView

internal fun ReceiptCameraActivity.showReceiptCameraSettings() {
    settingsOpenCount += 1
    val content = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(18), dp(10), dp(18), dp(4))
    }
    content.addView(settingSwitch(
        "Let Maintainiac help fill this receipt",
        "After photos are accepted, open receipt details instead of dropping back to the blank form.",
        assistedReceiptFill,
    ) {
        assistedReceiptFill = it
        updateSettingsStatusStrip()
    })
    content.addView(settingSummary(
        "Maintainiac receipt camera",
        "These settings control this receipt scanner, not the phone's regular camera app.",
    ))
    content.addView(settingSummary(
        "Capture quality",
        "Take the clearest receipt photo for OCR first. Save-space proof size is applied only after receipt assistance uses the clearest source.",
    ))
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
        "Receipt framing checks",
        "Warn when the receipt may be too far away, text may be small, or paper edges may be cut off. The phone's native camera still owns focus, blur, glare, and exposure behavior.",
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
    content.addView(settingSummary(
        "Image cleanup",
        "Crop, straighten, grayscale, contrast, and shadow cleanup are prepared after capture.",
    ))
    content.addView(settingSummary(
        "Receipt reader",
        "OCR reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt has been read.",
    ))
    content.addView(settingChoiceGroup(
        title = "Receipt details style",
        detail = "Choose what Maintainiac shows after OCR reads the receipt.",
        selectedValue = reviewDepth,
        options = listOf(
            "pricesOnly" to "Prices only",
            "detailedLines" to "Detailed lines",
        ),
    ) { selected ->
        reviewDepth = selected
        updateSettingsStatusStrip()
    })
    content.addView(settingChoiceGroup(
        title = "Save-space proof size",
        detail = "OCR reads the clear source first. This only changes the smaller saved proof kept for proof and cloud backup.",
        selectedValue = dataSaverLevel,
        options = listOf(
            "original" to "Local original",
            "light" to "High quality",
            "balanced" to "Normal proof",
            "strong" to "Low storage",
            "maximum" to "Tiny proof",
        ),
    ) { selected ->
        dataSaverLevel = selected
        updateSettingsStatusStrip()
    })
    content.addView(settingSummary(
        "Manual shutter",
        "The shutter button always works immediately. Automatic capture is optional and never blocks a clear manual photo.",
    ))
    content.addView(settingSummary(
        "Camera controls",
        "Hold steady for the phone camera's autofocus. Pinch to zoom if the print is small. Use Brightness anytime.",
    ))
    val scroll = ScrollView(this).apply {
        isFillViewport = false
        addView(content)
    }
    AlertDialog.Builder(this)
        .setTitle("Receipt Camera Settings")
        .setView(scroll)
        .setNegativeButton("Reset brightness") { _, _ -> resetExposure() }
        .setNeutralButton("Reset receipt camera defaults") { _, _ ->
            resetReceiptCameraDefaults()
        }
        .setPositiveButton("Done", null)
        .show()
}

internal fun ReceiptCameraActivity.resetReceiptCameraDefaults() {
    settingsResetCount += 1
    assistedReceiptFill = true
    longReceiptMode = canUseLongReceiptMode()
    autoCaptureEnabled = false
    reviewDepth = "pricesOnly"
    dataSaverLevel = "balanced"
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
