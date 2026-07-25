package com.maintainiac

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TripTrackingBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return
        if (!TripTrackingRecoveryState.recordSystemPauseIfActive(context)) return
        // Reboot or application replacement is never authorization to restart
        // precise tracking. Preserve the local trip and invite the driver to
        // resume or review it.
        TripTrackingNotificationFactory.notifyRecovery(context)
    }
}
