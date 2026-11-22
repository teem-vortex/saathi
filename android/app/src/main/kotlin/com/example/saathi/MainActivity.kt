package com.example.saathi

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val alertAction = "com.example.saathi.OPEN_DEMO_ALERTS"

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel("demo_alerts", "Demo alerts", NotificationManager.IMPORTANCE_HIGH)
        )
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "saathi/android").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeAlert" -> {
                        val open = intent.action == alertAction
                        if (open) intent.action = null
                        result.success(open)
                    }
                    "requestNotifications" -> {
                        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
                        }
                        result.success(null)
                    }
                    "notificationSettings", "batterySettings" -> {
                        val settingsIntent = if (call.method == "notificationSettings") {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        }
                        startActivity(settingsIntent)
                        result.success(null)
                    }
                    "notify" -> {
                        val enabled = manager.areNotificationsEnabled() &&
                            manager.getNotificationChannel("demo_alerts").importance != NotificationManager.IMPORTANCE_NONE
                        if (enabled) {
                            val openAlerts = Intent(this@MainActivity, MainActivity::class.java).apply {
                                action = alertAction
                                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            }
                            val pending = PendingIntent.getActivity(
                                this@MainActivity, 0, openAlerts, PendingIntent.FLAG_IMMUTABLE
                            )
                            manager.notify(
                                1, Notification.Builder(this@MainActivity, "demo_alerts")
                                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                                    .setContentTitle("Saathi demo alert")
                                    .setContentText("Open Saathi to review the simulated reading.")
                                    .setContentIntent(pending)
                                    .setAutoCancel(true)
                                    .build()
                            )
                        }
                        result.success(enabled)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        if (intent.action == alertAction && channel != null) {
            intent.action = null
            channel?.invokeMethod("openAlerts", null)
        }
        super.onNewIntent(intent)
    }
}
