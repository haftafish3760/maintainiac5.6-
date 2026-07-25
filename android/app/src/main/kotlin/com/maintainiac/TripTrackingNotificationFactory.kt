package com.maintainiac

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

internal object TripTrackingNotificationFactory {
    private const val channelId = "maintainiac_trip_tracking"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "Trip tracking",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
    }

    fun active(context: Context, pauseAction: String): Notification {
        val openAppIntent = PendingIntent.getActivity(
            context,
            7314,
            Intent(context, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val pauseIntent = PendingIntent.getService(
            context,
            7315,
            Intent(context, TripTrackingForegroundService::class.java).setAction(
                pauseAction,
            ),
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Maintainiac trip tracking")
            .setContentText("GPS-assisted trip tracking is active")
            .setContentIntent(openAppIntent)
            .setOngoing(true)
            .addAction(0, "Pause GPS assistance", pauseIntent)
            .build()
    }

    fun notifyRecovery(context: Context) {
        ensureChannel(context)
        val openAppIntent = PendingIntent.getActivity(
            context,
            7316,
            Intent(context, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Trip tracking needs review")
            .setContentText(
                "An unfinished GPS-assisted trip is saved. Open Maintainiac to review or resume.",
            )
            .setContentIntent(openAppIntent)
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(7316, notification)
        } catch (_: SecurityException) {
            // Android notification permission is optional. The durable trip
            // and paused recovery marker remain available inside the app.
        }
    }
}
