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
            text = receiptCameraText("Receipt Camera Settings", "Configuración de la cámara de recibos")
            setTextColor(Color.WHITE)
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        })
        addView(android.widget.Button(this@showReceiptCameraSettings).apply {
            text = receiptCameraText("Done", "Listo")
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
        receiptCameraText("Camera only", "Solo cámara"),
        receiptCameraText(
            "These controls apply while this camera is open. Set your usual receipt defaults in Receipt Settings.",
            "Estos controles se aplican mientras esta cámara está abierta. Configure sus valores predeterminados de recibos en Configuración de recibos.",
        ),
    ))
    content.addView(settingSectionHeader(receiptCameraText("CAPTURE FLOW", "FLUJO DE CAPTURA")))
    content.addView(settingSwitch(
        receiptCameraText("Long receipt mode", "Modo de recibo largo"),
        receiptCameraText(
            "Start at the top, add sections in order, and repeat a few readable lines so each section is ready for later receipt reconstruction.",
            "Comience arriba, agregue secciones en orden y repita algunas líneas legibles para que cada sección esté lista para la reconstrucción posterior del recibo.",
        ),
        longReceiptMode,
    ) {
        if (it && !canUseLongReceiptMode()) {
            longReceiptMode = false
            guidance.text = receiptCameraText(
                "Long receipt mode is unavailable for this device or storage setting.",
                "El modo de recibo largo no está disponible para este dispositivo o ajuste de almacenamiento.",
            )
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
        receiptCameraText("Automatic capture", "Captura automática"),
        autoCaptureDetail(),
        autoCaptureEnabled,
    ) {
        if (it && !isAutoCaptureCurrentlyAllowed()) {
            autoCaptureEnabled = false
            guidance.text = autoCaptureBlockedMessage()
            return@settingSwitch
        }
        autoCaptureEnabled = it
        if (!it) {
            autoCaptureStableFrameCount = 0
            latestAutoCaptureStatus = "off"
        }
        guidance.text = if (it) {
            receiptCameraText(
                "Automatic capture is on. Hold steady, or capture anytime.",
                "La captura automática está activada. Mantenga firme el teléfono o capture en cualquier momento.",
            )
        } else {
            guidanceText()
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        receiptCameraText("Receipt framing checks", "Revisiones de encuadre del recibo"),
        receiptCameraText(
            "Warn when paper edges may be cut off or the receipt may be too far away. These checks never block the shutter button.",
            "Advierte cuando los bordes del papel pueden estar cortados o el recibo está demasiado lejos. Estas revisiones nunca bloquean el disparador.",
        ),
        receiptGuidanceWarningsEnabled(),
    ) {
        setReceiptGuidanceWarningsEnabled(it)
        guidance.text = if (it) {
            receiptCameraText("Receipt framing checks are on.", "Las revisiones de encuadre están activadas.")
        } else {
            receiptCameraText("Receipt framing checks are off. Manual shutter still works.", "Las revisiones de encuadre están desactivadas. El disparador manual sigue funcionando.")
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSwitch(
        receiptCameraText("Find receipt edges", "Detectar bordes del recibo"),
        receiptCameraText(
            "Show edge guidance for cropping and straightening. Manual shutter still works.",
            "Muestra guía de bordes para recortar y enderezar. El disparador manual sigue funcionando.",
        ),
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
            receiptCameraText("Receipt edge guidance is on.", "La guía de bordes del recibo está activada.")
        } else {
            receiptCameraText("Receipt edge guidance is off. Take the clearest photo you can.", "La guía de bordes del recibo está desactivada. Tome la foto más clara que pueda.")
        }
        updateSettingsStatusStrip()
    })
    content.addView(settingSummary(
        receiptCameraText("Long receipts", "Recibos largos"),
        receiptCameraText(
            "Capture sections from top to bottom and repeat a few readable lines between photos so the next receipt step can keep them in order.",
            "Capture secciones de arriba a abajo y repita algunas líneas legibles entre fotos para que el siguiente paso del recibo pueda mantenerlas en orden.",
        ),
    ))
    content.addView(settingSectionHeader(receiptCameraText("CAMERA CONTROLS", "CONTROLES DE CÁMARA")))
    content.addView(settingSummary(
        receiptCameraText("Brightness and light", "Brillo y luz"),
        receiptCameraText(
            "Brightness and the receipt light stay on the live camera screen so you can see the receipt while adjusting them.",
            "El brillo y la luz del recibo permanecen en la cámara en vivo para que pueda ver el recibo mientras los ajusta.",
        ),
    ))
    content.addView(settingSummary(
        receiptCameraText("Focus", "Enfoque"),
        receiptCameraText(
            "The phone camera owns autofocus. Maintainiac does not use tap-to-focus on the preview.",
            "La cámara del teléfono controla el enfoque automático. Maintainiac no usa tocar para enfocar en la vista previa.",
        ),
    ))
    content.addView(settingSummary(
        receiptCameraText("Receipt reading source", "Fuente de lectura del recibo"),
        receiptCameraText(
            "Maintainiac reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt is read.",
            "Maintainiac lee primero la foto temporal de calidad completa. Las copias de prueba más pequeñas se crean después de leer el recibo.",
        ),
    ))
    content.addView(settingSummary(
        receiptCameraText("Manual capture", "Captura manual"),
        receiptCameraText(
            "The shutter button always works immediately. Guidance can help, but it never blocks a manual receipt photo.",
            "El disparador siempre funciona de inmediato. La guía ayuda, pero nunca bloquea una foto manual del recibo.",
        ),
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
        text = receiptCameraText("Reset Receipt Camera Defaults", "Restablecer ajustes de cámara de recibos")
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
        "light" -> 1350L * 1024L
        "strong" -> 550L * 1024L
        "maximum" -> 275L * 1024L
        else -> 900L * 1024L
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
    // Expense and account preferences are deliberately not reset here.
    longReceiptMode = false
    autoCaptureEnabled = false
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
    return readabilityGuidancePolicy == "native_camera_receipt_quality_guidance_v1" ||
        readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"
}

internal fun ReceiptCameraActivity.setReceiptGuidanceWarningsEnabled(enabled: Boolean) {
    tooFarTooCloseWarningEnabled = enabled
    receiptFullyVisibleWarningEnabled = enabled
    textTooSmallWarningEnabled = enabled
}
