package com.example.esp_home.widgets

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.net.URL

object WidgetRemoteApi {
    private const val DATABASE_URL = "https://esp32-smart-home-5643e-default-rtdb.firebaseio.com"

    fun readRoot(): JSONObject? {
        val body = request("", "GET") ?: return null
        if (body == "null") return null
        return runCatching { JSONObject(body) }.getOrNull()
    }

    fun readRelayValue(relayKey: String): Boolean? {
        val body = request(relayKey, "GET") ?: return null
        return when (body.trim()) {
            "true" -> true
            "false" -> false
            else -> null
        }
    }

    fun toggleRelay(relayKey: String) {
        val current = readRelayValue(relayKey) ?: return
        request(relayKey, "PUT", (!current).toString())
    }

    fun toggleSensor(relayKey: String) {
        val raw = request("sensors", "GET")
            ?.trim()
            ?.removeSurrounding("\"")
            ?: ""

        val current = raw
            .split(',')
            .map { it.trim().lowercase() }
            .filter { it.isNotEmpty() }
            .toMutableSet()

        val normalized = relayKey.lowercase()
        if (current.contains(normalized)) current.remove(normalized) else current.add(normalized)

        val payload = JSONObject.quote(current.joinToString(","))
        request("sensors", "PUT", payload)
    }

    fun toggleAll(value: Boolean) {
        val root = readRoot() ?: return
        val update = JSONObject()
        val keys = root.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            if (root.opt(key) is Boolean) {
                update.put(key, value)
            }
        }
        if (update.length() > 0) {
            request("", "PATCH", update.toString())
        }
    }

    private fun request(path: String, method: String, body: String? = null): String? {
        val normalizedPath = path.trim('/').let {
            if (it.isEmpty()) ".json" else "${URLEncoder.encode(it, "UTF-8")}.json"
        }

        val url = URL("$DATABASE_URL/$normalizedPath")
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 5000
            readTimeout = 5000
            setRequestProperty("Content-Type", "application/json")
            doInput = true
            if (body != null) {
                doOutput = true
            }
        }

        return runCatching {
            body?.let {
                connection.outputStream.use { output ->
                    output.write(it.toByteArray())
                    output.flush()
                }
            }
            val stream = if (connection.responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            stream?.bufferedReader()?.use { it.readText() }
        }.getOrNull().also {
            connection.disconnect()
        }
    }
}
