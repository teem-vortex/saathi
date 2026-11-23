package com.example.saathi

import android.Manifest
import android.app.role.RoleManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.LauncherApps
import android.os.Process
import android.content.ComponentName
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

open class MainActivity : FlutterActivity() {
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
                    "apps" -> {
                        val launcher = getSystemService(LauncherApps::class.java)
                        val apps = launcher.getActivityList(null, Process.myUserHandle())
                            .sortedBy { it.label.toString().lowercase() }
                            .map { mapOf("label" to it.label.toString(), "package" to it.componentName.packageName, "activity" to it.componentName.className) }
                        result.success(apps)
                    }
                    "launchApp" -> {
                        try {
                            val args = call.arguments as Map<*, *>
                            getSystemService(LauncherApps::class.java).startMainActivity(
                                ComponentName(args["package"] as String, args["activity"] as String),
                                Process.myUserHandle(), null, null
                            )
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                    "shortcut" -> {
                        val shortcut = when (call.arguments as String) {
                            "phone" -> Intent(Intent.ACTION_DIAL)
                            "messages" -> Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_MESSAGING)
                            "camera" -> Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA)
                            else -> Intent(Settings.ACTION_SETTINGS)
                        }
                        try {
                            startActivity(shortcut)
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                    "requestHome" -> {
                        val roles = getSystemService(RoleManager::class.java)
                        if (roles.isRoleAvailable(RoleManager.ROLE_HOME) && !roles.isRoleHeld(RoleManager.ROLE_HOME)) {
                            startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_HOME), 2)
                        }
                        result.success(null)
                    }
                    "assistantStatus" -> result.success(getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_ASSISTANT))
                    "assistantSettings" -> {
                        val settings = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                        try {
                            startActivity(settings)
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                    "homeStatus" -> result.success(getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_HOME))
                    "homeSettings" -> {
                        val home = Intent(Settings.ACTION_HOME_SETTINGS)
                        if (home.resolveActivity(packageManager) != null) startActivity(home)
                        else startActivity(Intent(Settings.ACTION_SETTINGS))
                        result.success(null)
                    }
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
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            channel?.invokeMethod("returnHome", null)
        }
        if (intent.action == alertAction && channel != null) {
            intent.action = null
            channel?.invokeMethod("openAlerts", null)
        }
        super.onNewIntent(intent)
    }
}

class HomeActivity : MainActivity() {
    override fun getInitialRoute(): String = "/elderHome"
}

class AssistantActivity : MainActivity() {
    override fun getInitialRoute(): String = "/assistant"
}
