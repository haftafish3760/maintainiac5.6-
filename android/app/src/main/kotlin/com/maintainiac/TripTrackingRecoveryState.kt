package com.maintainiac

import android.content.Context

internal object TripTrackingRecoveryState {
    private const val preferencesName = "maintainiac_trip_tracking_recovery"
    private const val statusKey = "nativeRecoveryStatus"
    private const val activeKey = "nativeTrackingWasActive"
    private const val pausedByUser = "paused_by_user"
    private const val pausedBySystem = "paused_by_system"

    fun markTrackingStarted(context: Context) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(activeKey, true)
            .remove(statusKey)
            .commit()
    }

    fun clearForExplicitStop(context: Context) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(activeKey, false)
            .remove(statusKey)
            .commit()
    }

    fun recordUserPause(context: Context) {
        recordPause(context, pausedByUser)
    }

    fun recordSystemPauseIfActive(context: Context): Boolean {
        val preferences =
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        if (!preferences.getBoolean(activeKey, false)) return false
        preferences.edit()
            .putBoolean(activeKey, false)
            .putString(statusKey, pausedBySystem)
            .commit()
        return true
    }

    fun consumeStatus(context: Context): String? {
        val preferences =
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val status = preferences.getString(statusKey, null)
        preferences.edit().remove(statusKey).commit()
        return status?.takeIf { it == pausedByUser || it == pausedBySystem }
    }

    private fun recordPause(context: Context, status: String) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(activeKey, false)
            .putString(statusKey, status)
            .commit()
    }
}
