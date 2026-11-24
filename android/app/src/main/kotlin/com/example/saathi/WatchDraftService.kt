package com.example.saathi

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.WearableListenerService
import java.nio.charset.StandardCharsets
import org.json.JSONObject

class WatchDraftService : WearableListenerService() {
    override fun onRequest(nodeId: String, path: String, request: ByteArray): Task<ByteArray>? {
        if (path != "/saathi/draft/v1") return null
        val reply = synchronized(WatchDraftService::class.java) {
            try {
                require(request.size <= 8192)
                val payload = JSONObject(String(request, StandardCharsets.UTF_8))
                val id = payload.getString("id")
                val text = payload.getString("text").trim()
                val timestamp = payload.getLong("timestamp")
                require(id.matches(Regex("[a-f0-9-]{36}")))
                require(text.isNotEmpty() && text.length <= 2000)
                require(kotlin.math.abs(System.currentTimeMillis() - timestamp) < 10 * 60 * 1000L)
                val store = getSharedPreferences("watch_drafts", MODE_PRIVATE)
                when {
                    store.getString("last_id", null) == id -> "accepted"
                    store.contains("pending_text") -> "busy"
                    else -> {
                        if (!store.edit().putString("last_id", id)
                                .putString("pending_text", text).commit()) {
                            "error"
                        } else {
                            notifyDraft()
                            "accepted"
                        }
                    }
                }
            } catch (_: Exception) {
                "invalid"
            }
        }
        return Tasks.forResult(reply.toByteArray(StandardCharsets.UTF_8))
    }

    private fun notifyDraft() {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            "watch_drafts", "Watch drafts", NotificationManager.IMPORTANCE_DEFAULT
        ))
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val intent = Intent(this, MainActivity::class.java)
            .setAction("com.example.saathi.OPEN_WATCH_DRAFT")
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pending = PendingIntent.getActivity(this, 431, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager.notify(431, Notification.Builder(this, "watch_drafts")
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle("Saathi watch draft")
            .setContentText("Open Saathi to review your message")
            .setContentIntent(pending)
            .setAutoCancel(true)
            .build())
    }
}
