package com.maintainiac

import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import androidx.camera.view.PreviewView


internal fun ReceiptCameraActivity.buildContentView(): View {
    val root = FrameLayout(this).apply {
        setBackgroundColor(Color.BLACK)
    }
    previewView = PreviewView(this).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
        scaleType = PreviewView.ScaleType.FIT_CENTER
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

internal fun ReceiptCameraActivity.buildReceiptFrameGuide(): View {
    receiptFrameGuide = View(this).apply {
        background = frameGuideDrawable(Color.argb(138, 255, 209, 102))
        visibility = if (edgeDetectionEnabled && edgeOverlayEnabled) View.VISIBLE else View.GONE
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            Gravity.CENTER,
        ).apply {
            leftMargin = dp(26)
            rightMargin = dp(26)
            topMargin = dp(120)
            bottomMargin = dp(156)
        }
        alpha = 0.54f
    }
    return receiptFrameGuide
}

internal fun ReceiptCameraActivity.buildTopBar(): View {
    val row = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(12), dp(8), dp(12), 0)
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(64),
            Gravity.TOP,
        )
    }
    row.addView(iconButton("Back", android.R.drawable.ic_menu_revert) {
        requestCloseCamera(backDispatchPath = "top_bar_back_button")
    })
    row.addView(View(this), LinearLayout.LayoutParams(0, 1, 1f))
    doneButton = Button(this).apply {
        text = "Next"
        contentDescription = "Review captured receipt photos in Maintainiac"
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

internal fun ReceiptCameraActivity.buildGuidance(): View {
    guidance = TextView(this).apply {
        text = guidanceText()
        setTextColor(Color.WHITE)
        textSize = 15f
        setTypeface(typeface, android.graphics.Typeface.BOLD)
        setBackgroundColor(Color.argb(126, 5, 6, 7))
        setPadding(dp(10), dp(8), dp(10), dp(8))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.TOP,
        ).apply {
            topMargin = dp(74)
            leftMargin = dp(18)
            rightMargin = dp(18)
        }
    }
    return guidance
}

internal fun ReceiptCameraActivity.buildExposureControls(): View {
    val panel = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(10), dp(6), dp(10), dp(6))
        setBackgroundColor(Color.argb(118, 5, 6, 7))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(48),
            Gravity.BOTTOM,
        ).apply {
            bottomMargin = dp(104)
            leftMargin = dp(18)
            rightMargin = dp(18)
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

internal fun ReceiptCameraActivity.buildSettingsStatusStrip(): View {
    settingsStatusStrip = TextView(this).apply {
        text = settingsStatusText()
        setTextColor(Color.rgb(228, 235, 238))
        textSize = 11.5f
        gravity = Gravity.CENTER
        setTypeface(typeface, android.graphics.Typeface.BOLD)
        setPadding(dp(10), dp(6), dp(10), dp(6))
        setBackgroundColor(Color.argb(104, 5, 6, 7))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM,
        ).apply {
            bottomMargin = dp(154)
            leftMargin = dp(18)
            rightMargin = dp(18)
        }
    }
    return settingsStatusStrip
}

internal fun ReceiptCameraActivity.updateSettingsStatusStrip() {
    if (!hasInitializedReceiptCameraField { settingsStatusStrip }) return
    settingsStatusStrip.text = settingsStatusText()
}

internal fun ReceiptCameraActivity.settingsStatusText(): String {
    val assist = if (assistedReceiptFill) "Assist on" else "Manual fill"
    val depth = if (reviewDepth == "detailedLines") "Detailed lines" else "Price review"
    val length = if (longReceiptMode) "Long receipt on" else "Single photo"
    val storage = "${dataSaverLabel()} saved proof"
    val brightness = if (autoExposureAssistEnabled) "Brightness assist" else "Manual brightness"
    return "Maintainiac receipt camera • $assist • $depth • $length • $brightness • $storage • OCR reads original first"
}

internal fun ReceiptCameraActivity.buildBottomBar(): View {
    val row = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        setPadding(dp(12), dp(10), dp(12), dp(14))
        setBackgroundColor(Color.argb(134, 5, 6, 7))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(104),
            Gravity.BOTTOM,
        )
    }
    addPhotoButton = Button(this).apply {
        text = "Add Next"
        contentDescription = "Add next receipt section photo"
        isEnabled = false
        visibility = View.GONE
        setOnClickListener { capturePhoto("manual_add_photo") }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    row.addView(addPhotoButton)
    shutterButton = ImageButton(this).apply {
        contentDescription = "Take receipt photo"
        setImageResource(android.R.drawable.ic_menu_camera)
        setColorFilter(Color.BLACK)
        setBackgroundColor(Color.WHITE)
        layoutParams = LinearLayout.LayoutParams(dp(72), dp(72)).apply {
            leftMargin = dp(16)
            rightMargin = dp(16)
        }
        setOnClickListener { capturePhoto("manual_shutter") }
    }
    row.addView(shutterButton)
    bottomReviewButton = Button(this).apply {
        text = "Next"
        contentDescription = "Review captured receipt photos in Maintainiac"
        isEnabled = false
        setOnClickListener { finishWithCapturedPhotos() }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    row.addView(bottomReviewButton)
    return row
}
