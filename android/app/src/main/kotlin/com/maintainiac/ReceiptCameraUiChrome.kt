package com.maintainiac

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
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
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
import androidx.core.view.updatePadding


internal fun ReceiptCameraActivity.buildContentView(): View {
    cameraRootView = FrameLayout(this).apply {
        setBackgroundColor(Color.BLACK)
    }
    previewView = PreviewView(this).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }
    cameraRootView.addView(previewView)
    cameraRootView.addView(buildReceiptFrameGuide())
    cameraRootView.addView(buildTopBar())
    cameraRootView.addView(buildGuidance())
    cameraRootView.addView(buildPreviousSectionGuide())
    cameraRootView.addView(buildSettingsStatusStrip())
    cameraRootView.addView(buildExposureControls())
    cameraRootView.addView(buildBottomBar())
    return cameraRootView
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
            leftMargin = dp(22)
            rightMargin = dp(22)
            topMargin = dp(86)
            bottomMargin = dp(118)
        }
        alpha = 0.54f
    }
    return receiptFrameGuide
}

internal fun ReceiptCameraActivity.buildTopBar(): View {
    topBar = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(12), dp(8), dp(12), dp(4))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(62),
            Gravity.TOP,
        )
    }
    topBar.addView(iconButton("Back", R.drawable.ic_receipt_camera_back) {
        requestCloseCamera(backDispatchPath = "top_bar_back_button")
    })
    topBar.addView(View(this), LinearLayout.LayoutParams(0, 1, 1f))
    topBar.addView(iconButton("Receipt camera settings", R.drawable.ic_receipt_camera_settings) {
        showReceiptCameraSettings()
    })
    torchButton = iconButton(
        "Turn light on",
        R.drawable.ic_receipt_camera_flash,
    ) {
        toggleTorch()
    }
    topBar.addView(torchButton)
    return topBar
}

internal fun ReceiptCameraActivity.buildGuidance(): View {
    guidance = TextView(this).apply {
        text = guidanceText()
        setTextColor(Color.WHITE)
        textSize = 14f
        gravity = Gravity.CENTER
        setTypeface(typeface, Typeface.BOLD)
        maxLines = 1
        ellipsize = TextUtils.TruncateAt.END
        background = pillDrawable(Color.argb(168, 5, 6, 7))
        setPadding(dp(12), dp(8), dp(12), dp(8))
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL,
        ).apply {
            bottomMargin = dp(104)
            leftMargin = dp(16)
            rightMargin = dp(16)
        }
    }
    return guidance
}

internal fun ReceiptCameraActivity.buildExposureControls(): View {
    exposurePanel = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(10), dp(6), dp(10), dp(6))
        setBackgroundColor(Color.argb(118, 5, 6, 7))
        visibility = View.GONE
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
    exposurePanel.addView(TextView(this).apply {
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
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                restoreWorkflowGuidanceIfNeeded()
            }
        })
    }
    exposurePanel.addView(exposureSlider)
    exposureResetButton = Button(this).apply {
        text = "Reset"
        isEnabled = false
        setOnClickListener { resetExposure() }
    }
    exposurePanel.addView(exposureResetButton)
    return exposurePanel
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
        visibility = View.GONE
    }
    return settingsStatusStrip
}

internal fun ReceiptCameraActivity.updateSettingsStatusStrip() {
    if (!hasInitializedReceiptCameraField { settingsStatusStrip }) return
    settingsStatusStrip.text = settingsStatusText()
    settingsStatusStrip.visibility = if (shouldShowSettingsStatusStrip()) {
        View.VISIBLE
    } else {
        View.GONE
    }
}

internal fun ReceiptCameraActivity.settingsStatusText(): String {
    val assist = if (assistedReceiptFill) "Assist on" else "Manual fill"
    val depth = if (reviewDepth == "detailedLines") "Detailed lines" else "Price-only lines"
    val length = if (longReceiptMode) "Long receipt" else "Single photo"
    val light = if (autoExposureAssistEnabled) "Auto light" else "Manual light"
    return "$assist • $depth • $length • $light"
}

internal fun ReceiptCameraActivity.shouldShowSettingsStatusStrip(): Boolean {
    // Keep the active preview chrome minimal. The full settings summary stays
    // inside the dedicated receipt camera settings surface instead.
    return false
}

internal fun ReceiptCameraActivity.buildBottomBar(): View {
    bottomBar = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        setPadding(dp(12), dp(6), dp(12), dp(12))
        setBackgroundColor(Color.TRANSPARENT)
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(84),
            Gravity.BOTTOM,
        )
    }
    addPhotoButton = Button(this).apply {
        text = "Add Photo"
        contentDescription = "Add another receipt photo"
        isEnabled = false
        visibility = View.GONE
        setOnClickListener { capturePhoto("manual_add_photo") }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    bottomBar.addView(addPhotoButton)
    val leftSpacer = View(this)
    bottomBar.addView(leftSpacer, LinearLayout.LayoutParams(0, 1, 1f))
    shutterButton = ImageButton(this).apply {
        contentDescription = "Take receipt photo"
        setImageResource(R.drawable.ic_receipt_camera_shutter)
        background = shutterDrawable()
        layoutParams = LinearLayout.LayoutParams(dp(70), dp(70)).apply {
            leftMargin = dp(16)
            rightMargin = dp(16)
        }
        setOnClickListener { capturePhoto("manual_shutter") }
    }
    bottomBar.addView(shutterButton)
    val rightSpacer = View(this)
    bottomBar.addView(rightSpacer, LinearLayout.LayoutParams(0, 1, 1f))
    bottomReviewButton = Button(this).apply {
        text = "Done"
        contentDescription = "Done: review captured receipt photos in Maintainiac"
        isEnabled = false
        visibility = View.GONE
        setOnClickListener { finishWithCapturedPhotos() }
        layoutParams = LinearLayout.LayoutParams(0, dp(54), 1f)
    }
    bottomBar.addView(bottomReviewButton)
    return bottomBar
}

internal fun ReceiptCameraActivity.applyEdgeToEdgeReceiptInsets() {
    ViewCompat.setOnApplyWindowInsetsListener(cameraRootView) { _, windowInsets ->
        val insets = windowInsets.getInsets(
            WindowInsetsCompat.Type.systemBars() or
                WindowInsetsCompat.Type.displayCutout(),
        )
        topBar.updatePadding(
            left = dp(12) + insets.left,
            top = dp(8) + insets.top,
            right = dp(12) + insets.right,
            bottom = dp(4),
        )
        topBar.updateLayoutParams<FrameLayout.LayoutParams> {
            height = dp(62) + insets.top
        }
        guidance.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(16) + insets.left
            rightMargin = dp(16) + insets.right
            bottomMargin = dp(104) + insets.bottom
        }
        settingsStatusStrip.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(18) + insets.left
            rightMargin = dp(18) + insets.right
            bottomMargin = dp(154) + insets.bottom
        }
        previousSectionGuidePanel.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(18) + insets.left
            rightMargin = dp(18) + insets.right
            topMargin = dp(130) + insets.top
        }
        exposurePanel.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(18) + insets.left
            rightMargin = dp(18) + insets.right
            bottomMargin = dp(104) + insets.bottom
        }
        bottomBar.updatePadding(
            left = dp(12) + insets.left,
            top = dp(6),
            right = dp(12) + insets.right,
            bottom = dp(12) + insets.bottom,
        )
        bottomBar.updateLayoutParams<FrameLayout.LayoutParams> {
            height = dp(84) + insets.bottom
        }
        receiptFrameGuide.updateLayoutParams<FrameLayout.LayoutParams> {
            leftMargin = dp(22) + insets.left
            rightMargin = dp(22) + insets.right
            topMargin = dp(86) + insets.top
            bottomMargin = dp(118) + insets.bottom
        }
        windowInsets
    }
    ViewCompat.requestApplyInsets(cameraRootView)
}

internal fun ReceiptCameraActivity.pillDrawable(color: Int): GradientDrawable {
    return GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(999).toFloat()
    }
}

internal fun ReceiptCameraActivity.shutterDrawable(): GradientDrawable {
    return GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(Color.WHITE)
        setStroke(dp(4), Color.argb(210, 5, 6, 7))
    }
}
