package com.maintainiac

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class DeviceCapabilityEvents(
    private val context: Context,
) : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var receiverRegistered = false
    private var thermalListener: PowerManager.OnThermalStatusChangedListener? = null

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, channelName).setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        if (!receiverRegistered) {
            ContextCompat.registerReceiver(
                context,
                receiver,
                IntentFilter().apply {
                    addAction(Intent.ACTION_BATTERY_CHANGED)
                    addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
                    @Suppress("DEPRECATION")
                    addAction(ConnectivityManager.CONNECTIVITY_ACTION)
                },
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            receiverRegistered = true
        }
        if (Build.VERSION.SDK_INT >= 29 && thermalListener == null) {
            val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            thermalListener = PowerManager.OnThermalStatusChangedListener { emit("thermal") }
                .also { power.addThermalStatusListener(ContextCompat.getMainExecutor(context), it) }
        }
        emit("subscribed")
    }

    override fun onCancel(arguments: Any?) {
        sink = null
        if (receiverRegistered) {
            runCatching { context.unregisterReceiver(receiver) }
            receiverRegistered = false
        }
        if (Build.VERSION.SDK_INT >= 29) {
            thermalListener?.let {
                val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                power.removeThermalStatusListener(it)
            }
        }
        thermalListener = null
    }

    private fun emit(reason: String) {
        sink?.success(mapOf("reason" to reason, "atMs" to System.currentTimeMillis()))
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val reason = when (intent?.action) {
                Intent.ACTION_BATTERY_CHANGED -> "battery"
                PowerManager.ACTION_POWER_SAVE_MODE_CHANGED -> "power"
                else -> "network"
            }
            emit(reason)
        }
    }

    companion object {
        private const val channelName = "maintainiac/device_capability_events"
    }
}
