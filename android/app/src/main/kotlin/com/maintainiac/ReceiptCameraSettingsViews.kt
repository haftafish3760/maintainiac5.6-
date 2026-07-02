package com.maintainiac

import android.graphics.Color
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
    val row = LinearLayout(activity).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(0, dp(8), 0, dp(8))
    }
    row.addView(LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
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
    return LinearLayout(activity).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(0, dp(8), 0, dp(8))
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
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
    return LinearLayout(activity).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(0, dp(8), 0, dp(8))
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.BLACK)
            textSize = 15f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
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
