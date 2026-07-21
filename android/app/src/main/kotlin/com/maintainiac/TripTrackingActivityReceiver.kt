package com.maintainiac

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityRecognitionResult
import com.google.android.gms.location.DetectedActivity

/** Converts Android motion classification into non-authoritative Dart evidence. */
class TripTrackingActivityReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityRecognitionResult.hasResult(intent)) return
        val epoch = intent.getStringExtra(TripTrackingForegroundService.activityEpochExtra)
            ?: return
        // Play Services may deliver a queued broadcast after the user stopped
        // tracking or immediately after a new session starts. Accept motion
        // assistance only for the currently live collector epoch.
        val result = ActivityRecognitionResult.extractResult(intent) ?: return
        val activity = result.mostProbableActivity ?: return
        val observedAtMillis = result.time
        val nowMillis = System.currentTimeMillis()
        // A delayed motion batch can describe earlier walking, but it must
        // not masquerade as fresh stop evidence for the currently stationary
        // vehicle. Dart retains its own independent timestamp guard.
        if (observedAtMillis <= 0 ||
            observedAtMillis < nowMillis - 120_000L ||
            observedAtMillis > nowMillis + 120_000L) {
            return
        }
        if (!TripTrackingForegroundService.isActivityEpochActive(epoch, observedAtMillis)) return
        TripTrackingEventEmitter.emit(
            mapOf(
                "type" to "activity",
                "activity" to when (activity.type) {
                    DetectedActivity.IN_VEHICLE -> "automotive"
                    DetectedActivity.WALKING, DetectedActivity.ON_FOOT -> "walking"
                    DetectedActivity.RUNNING -> "running"
                    DetectedActivity.ON_BICYCLE -> "cycling"
                    DetectedActivity.STILL -> "still"
                    else -> "unknown"
                },
                "confidence" to activity.confidence,
                // The broadcast can be delayed. Preserve Play Services'
                // observation time so stale walking evidence cannot be
                // presented to Dart as a fresh delivery or job-site stop.
                "recordedAt" to observedAtMillis,
            ),
        )
    }
}
