package com.maintainiac

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.Switch
import android.widget.TextView

internal fun ReceiptCameraActivity.settingSwitch(
    title: String,
    detail: String,
    checked: Boolean,
    onChanged: (Boolean) -> Unit,
): View {
    val activity = this
    val row = settingCard().apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }
    row.addView(LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.DKGRAY)
            textSize = 12f
        })
    })
    row.addView(Switch(this).apply {
        isChecked = checked
        setOnCheckedChangeListener { _, isChecked -> onChanged(isChecked) }
    })
    return row
}

internal fun ReceiptCameraActivity.settingSummary(title: String, detail: String): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.DKGRAY)
            textSize = 12f
        })
    }
}

internal fun ReceiptCameraActivity.settingChoiceGroup(
    title: String,
    detail: String,
    selectedValue: String,
    options: List<Pair<String, String>>,
    onChanged: (String) -> Unit,
): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.DKGRAY)
            textSize = 12f
        })
        addView(LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(6), 0, 0)
            options.forEach { (value, label) ->
                addView(Button(activity).apply {
                    text = label
                    isAllCaps = false
                    isSelected = value == selectedValue
                    setTextColor(if (isSelected) Color.BLACK else Color.WHITE)
                    setBackgroundColor(
                        if (isSelected) {
                            Color.rgb(255, 209, 102)
                        } else {
                            Color.rgb(17, 24, 27)
                        },
                    )
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ).apply {
                        topMargin = dp(3)
                        bottomMargin = dp(3)
                    }
                    setOnClickListener {
                        onChanged(value)
                    }
                })
            }
        })
    }
}

internal fun ReceiptCameraActivity.settingSectionHeader(title: String): View {
    return TextView(this).apply {
        text = title
        setTextColor(Color.rgb(65, 78, 84))
        textSize = 12f
        setTypeface(typeface, Typeface.BOLD)
        setPadding(dp(2), dp(13), dp(2), dp(5))
    }
}

internal fun ReceiptCameraActivity.settingMetricRow(
    label: String,
    value: String,
    detail: String,
): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = label
            setTextColor(Color.rgb(83, 97, 103))
            textSize = 11f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = value
            setTextColor(Color.rgb(23, 33, 38))
            textSize = 19f
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, dp(2), 0, dp(2))
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(78, 91, 97))
            textSize = 12f
        })
    }
}

private fun ReceiptCameraActivity.settingCard(): LinearLayout {
    return LinearLayout(this).apply {
        setPadding(dp(12), dp(10), dp(12), dp(10))
        background = GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = dp(6).toFloat()
            setStroke(dp(1), Color.rgb(212, 220, 224))
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            bottomMargin = dp(8)
        }
    }
}
