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
        val activity = ActivityRecognitionResult.extractResult(intent)
            ?.mostProbableActivity
            ?: return
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
                "recordedAt" to System.currentTimeMillis(),
            ),
        )
    }
}
