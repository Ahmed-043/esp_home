package com.example.esp_home.widgets

import android.content.Context

object SingleActionWidgetPrefs {
    private const val PREFS = "single_action_widget_prefs"

    data class Config(val relayKey: String, val label: String)

    fun save(context: Context, appWidgetId: Int, relayKey: String, label: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString("relay_key_$appWidgetId", relayKey)
            .putString("label_$appWidgetId", label)
            .apply()
    }

    fun load(context: Context, appWidgetId: Int): Config {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val relayKey = prefs.getString("relay_key_$appWidgetId", "relay1") ?: "relay1"
        val label = prefs.getString("label_$appWidgetId", relayKey) ?: relayKey
        return Config(relayKey = relayKey, label = label)
    }

    fun clear(context: Context, appWidgetId: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove("relay_key_$appWidgetId")
            .remove("label_$appWidgetId")
            .apply()
    }
}
