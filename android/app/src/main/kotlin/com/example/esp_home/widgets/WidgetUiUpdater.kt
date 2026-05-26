package com.example.esp_home.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.esp_home.MainActivity
import com.example.esp_home.R
import kotlin.concurrent.thread

object WidgetUiUpdater {
    fun updateAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)

        val single1x1Ids = manager.getAppWidgetIds(
            ComponentName(context, SingleActionWidget1x1Provider::class.java),
        )
        val single1x2Ids = manager.getAppWidgetIds(
            ComponentName(context, SingleActionWidget1x2Provider::class.java),
        )
        val allButtonsIds = manager.getAppWidgetIds(
            ComponentName(context, AllButtonsWidgetProvider::class.java),
        )
        val setTimeIds = manager.getAppWidgetIds(
            ComponentName(context, SetTimeWidgetProvider::class.java),
        )

        updateSingleActionWidgets(context, manager, single1x1Ids + single1x2Ids)
        updateAllButtonsWidgets(context, manager, allButtonsIds)
        updateSetTimeWidgets(context, manager, setTimeIds)
    }

    fun updateSingleActionWidgets(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        for (widgetId in widgetIds) {
            val config = SingleActionWidgetPrefs.load(context, widgetId)
            val options = manager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val isWide = minWidth >= 160
            val layoutId = if (isWide) {
                R.layout.widget_single_action_wide
            } else {
                R.layout.widget_single_action_compact
            }

            val views = RemoteViews(context.packageName, layoutId)
            views.setTextViewText(R.id.widget_title, config.label)
            views.setOnClickPendingIntent(
                R.id.widget_primary_action,
                actionPendingIntent(
                    context,
                    WidgetIntentActions.ACTION_TOGGLE_RELAY,
                    config.relayKey,
                    widgetId * 31 + 1,
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_alt_action,
                actionPendingIntent(
                    context,
                    WidgetIntentActions.ACTION_TOGGLE_SENSOR,
                    config.relayKey,
                    widgetId * 31 + 2,
                ),
            )

            manager.updateAppWidget(widgetId, views)
        }
    }

    fun updateAllButtonsWidgets(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        if (widgetIds.isEmpty()) return

        thread {
            val root = WidgetRemoteApi.readRoot()
            val relays = mutableListOf<String>()
            val keys = root?.keys()
            while (keys?.hasNext() == true) {
                val key = keys.next()
                if (root.opt(key) is Boolean) {
                    relays.add(key)
                }
            }
            relays.sort()

            widgetIds.forEach { widgetId ->
                val views = RemoteViews(context.packageName, R.layout.widget_all_buttons)

                bindRelaySlot(context, views, 1, relays.getOrNull(0), widgetId)
                bindRelaySlot(context, views, 2, relays.getOrNull(1), widgetId)
                bindRelaySlot(context, views, 3, relays.getOrNull(2), widgetId)
                bindRelaySlot(context, views, 4, relays.getOrNull(3), widgetId)

                views.setOnClickPendingIntent(
                    R.id.widget_all_on,
                    actionPendingIntent(
                        context,
                        WidgetIntentActions.ACTION_ALL_ON,
                        null,
                        widgetId * 31 + 20,
                    ),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_all_off,
                    actionPendingIntent(
                        context,
                        WidgetIntentActions.ACTION_ALL_OFF,
                        null,
                        widgetId * 31 + 21,
                    ),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_open_app,
                    openAppPendingIntent(context, openTimeout = false, requestCode = widgetId * 31 + 22),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_set_time,
                    openAppPendingIntent(context, openTimeout = true, requestCode = widgetId * 31 + 23),
                )

                manager.updateAppWidget(widgetId, views)
            }
        }
    }

    fun updateSetTimeWidgets(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        for (widgetId in widgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_set_time)
            views.setOnClickPendingIntent(
                R.id.set_time_button,
                openAppPendingIntent(context, openTimeout = true, requestCode = widgetId * 31 + 30),
            )
            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindRelaySlot(
        context: Context,
        views: RemoteViews,
        slot: Int,
        relayKey: String?,
        widgetId: Int,
    ) {
        val buttonId = when (slot) {
            1 -> R.id.widget_relay_1
            2 -> R.id.widget_relay_2
            3 -> R.id.widget_relay_3
            else -> R.id.widget_relay_4
        }
        val altId = when (slot) {
            1 -> R.id.widget_relay_alt_1
            2 -> R.id.widget_relay_alt_2
            3 -> R.id.widget_relay_alt_3
            else -> R.id.widget_relay_alt_4
        }

        if (relayKey.isNullOrBlank()) {
            views.setViewVisibility(buttonId, android.view.View.GONE)
            views.setViewVisibility(altId, android.view.View.GONE)
            return
        }

        views.setViewVisibility(buttonId, android.view.View.VISIBLE)
        views.setViewVisibility(altId, android.view.View.VISIBLE)
        views.setTextViewText(buttonId, relayKey.uppercase())
        views.setTextViewText(altId, "ALT")

        views.setOnClickPendingIntent(
            buttonId,
            actionPendingIntent(
                context,
                WidgetIntentActions.ACTION_TOGGLE_RELAY,
                relayKey,
                widgetId * 101 + slot,
            ),
        )
        views.setOnClickPendingIntent(
            altId,
            actionPendingIntent(
                context,
                WidgetIntentActions.ACTION_TOGGLE_SENSOR,
                relayKey,
                widgetId * 101 + slot + 10,
            ),
        )
    }

    private fun actionPendingIntent(
        context: Context,
        action: String,
        relayKey: String?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            this.action = action
            relayKey?.let { putExtra(WidgetIntentActions.EXTRA_RELAY_KEY, it) }
        }

        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppPendingIntent(
        context: Context,
        openTimeout: Boolean,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (openTimeout) {
                putExtra(MainActivity.EXTRA_OPEN_ACTION, "open_timeout")
            }
        }

        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
