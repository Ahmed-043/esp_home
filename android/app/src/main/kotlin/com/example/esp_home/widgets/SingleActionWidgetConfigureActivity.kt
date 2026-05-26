package com.example.esp_home.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import com.example.esp_home.R

class SingleActionWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.single_action_widget_configure)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val relayInput = findViewById<EditText>(R.id.config_relay_key)
        val labelInput = findViewById<EditText>(R.id.config_label)
        val save = findViewById<Button>(R.id.config_save)

        save.setOnClickListener {
            val relayKey = relayInput.text.toString().trim()
            val label = labelInput.text.toString().trim().ifEmpty { relayKey }

            if (relayKey.isEmpty()) {
                Toast.makeText(this, "Relay key is required", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            SingleActionWidgetPrefs.save(this, appWidgetId, relayKey, label)

            val manager = AppWidgetManager.getInstance(this)
            WidgetUiUpdater.updateSingleActionWidgets(this, manager, intArrayOf(appWidgetId))

            val resultValue = android.content.Intent().putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                appWidgetId,
            )
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}
