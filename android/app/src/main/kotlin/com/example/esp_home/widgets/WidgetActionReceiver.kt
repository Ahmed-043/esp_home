package com.example.esp_home.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlin.concurrent.thread

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val relayKey = intent.getStringExtra(WidgetIntentActions.EXTRA_RELAY_KEY)
        val action = intent.action ?: return

        thread {
            when (action) {
                WidgetIntentActions.ACTION_TOGGLE_RELAY -> relayKey?.let { WidgetRemoteApi.toggleRelay(it) }
                WidgetIntentActions.ACTION_TOGGLE_SENSOR -> relayKey?.let { WidgetRemoteApi.toggleSensor(it) }
                WidgetIntentActions.ACTION_ALL_ON -> WidgetRemoteApi.toggleAll(true)
                WidgetIntentActions.ACTION_ALL_OFF -> WidgetRemoteApi.toggleAll(false)
            }
            WidgetUiUpdater.updateAllWidgets(context)
        }
    }
}
