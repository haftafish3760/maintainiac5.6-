package com.maintainiac

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.util.Base64
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.security.MessageDigest
import java.security.SecureRandom

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
                    if (canReadBluetoothConnections()) {
                        addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
                        addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                        addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                    }
                },
                ContextCompat.RECEIVER_EXPORTED,
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

    private fun emitBluetoothConnection(intent: Intent, connected: Boolean) {
        if (!canReadBluetoothConnections()) return
        val device = bluetoothDevice(intent) ?: return
        val address = runCatching { device.address }.getOrNull() ?: return
        sink?.success(
            mapOf(
                "reason" to "bluetoothConnection",
                "opaqueDeviceId" to opaqueBluetoothDeviceId(address),
                "connected" to connected,
                "atMs" to System.currentTimeMillis(),
            ),
        )
    }

    private fun canReadBluetoothConnections(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT,
            ) == PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun bluetoothDevice(intent: Intent): BluetoothDevice? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(
                BluetoothDevice.EXTRA_DEVICE,
                BluetoothDevice::class.java,
            )
        } else {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

    private fun opaqueBluetoothDeviceId(address: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        digest.update(bluetoothIdSalt)
        val bytes = digest.digest(address.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    private val bluetoothIdSalt: ByteArray by lazy {
        val preferences = context.getSharedPreferences(
            "maintainiac_bluetooth_identity",
            Context.MODE_PRIVATE,
        )
        val saved = preferences.getString("salt", null)
        if (saved != null) {
            return@lazy Base64.decode(saved, Base64.NO_WRAP)
        }
        ByteArray(32).also { salt ->
            SecureRandom().nextBytes(salt)
            preferences.edit()
                .putString("salt", Base64.encodeToString(salt, Base64.NO_WRAP))
                .apply()
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                    emitBluetoothConnection(intent, connected = true)
                    return
                }
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                    emitBluetoothConnection(intent, connected = false)
                    return
                }
            }
            val reason = when (intent?.action) {
                Intent.ACTION_BATTERY_CHANGED -> "battery"
                PowerManager.ACTION_POWER_SAVE_MODE_CHANGED -> "power"
                BluetoothAdapter.ACTION_STATE_CHANGED -> "bluetooth"
                else -> "network"
            }
            emit(reason)
        }
    }

    companion object {
        private const val channelName = "maintainiac/device_capability_events"
    }
}
