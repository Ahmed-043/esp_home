package com.example.esp_home.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

open class BaseSingleActionWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        WidgetUiUpdater.updateSingleActionWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        WidgetUiUpdater.updateSingleActionWidgets(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { SingleActionWidgetPrefs.clear(context, it) }
    }
}

class SingleActionWidget1x1Provider : BaseSingleActionWidgetProvider()

class SingleActionWidget1x2Provider : BaseSingleActionWidgetProvider()
