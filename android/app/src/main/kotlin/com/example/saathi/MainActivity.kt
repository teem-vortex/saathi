package com.example.saathi

import android.Manifest
import android.app.role.RoleManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.ActivityNotFoundException
import android.content.pm.PackageManager
import android.content.pm.LauncherApps
import android.os.Process
import android.os.Bundle
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import android.view.WindowInsets
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import android.content.ComponentName
import android.provider.MediaStore
import android.provider.Settings
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import java.util.Locale
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

open class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var homeRequestResult: MethodChannel.Result? = null
    private val alertAction = "com.example.saathi.OPEN_DEMO_ALERTS"
    private var speechResult: MethodChannel.Result? = null
    private var textToSpeech: TextToSpeech? = null
    private var ttsReady = false

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
                            .map {
                                val drawable = it.getBadgedIcon(resources.displayMetrics.densityDpi)
                                val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
                                val canvas = Canvas(bitmap)
                                drawable.setBounds(0, 0, 96, 96)
                                drawable.draw(canvas)
                                val output = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                                mapOf("label" to it.label.toString(), "package" to it.componentName.packageName, "activity" to it.componentName.className, "icon" to output.toByteArray())
                            }
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
                        if (roles.isRoleHeld(RoleManager.ROLE_HOME)) {
                            result.success(true)
                        } else if (!roles.isRoleAvailable(RoleManager.ROLE_HOME)) {
                            result.success(false)
                        } else if (homeRequestResult != null) {
                            result.error("BUSY", "Home selection is already open", null)
                        } else {
                            try {
                                homeRequestResult = result
                                startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_HOME), 2)
                            } catch (_: Exception) {
                                homeRequestResult = null
                                result.success(false)
                            }
                        }
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
                    "listen" -> {
                        if (speechResult != null) {
                            result.error("busy", "Speech recognition is already open", null)
                        } else {
                            val listen = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, call.argument<String>("language") ?: "en-IN")
                                putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak your message")
                            }
                            try {
                                speechResult = result
                                @Suppress("DEPRECATION")
                                startActivityForResult(listen, 2201)
                            } catch (_: ActivityNotFoundException) {
                                speechResult = null
                                result.error("unavailable", "Speech recognition is not available on this device", null)
                            }
                        }
                    }
                    "speak" -> {
                        if (!ttsReady) {
                            result.error("unavailable", "Text-to-speech is not ready", null)
                        } else {
                            val locale = Locale.forLanguageTag(call.argument<String>("language") ?: "en-IN")
                            val engine = textToSpeech!!
                            val supported = engine.setLanguage(locale)
                            if (supported == TextToSpeech.LANG_MISSING_DATA || supported == TextToSpeech.LANG_NOT_SUPPORTED) {
                                result.error("language_unavailable", "This voice language is not installed", null)
                            } else {
                                val status = engine.speak(call.argument<String>("text") ?: "", TextToSpeech.QUEUE_FLUSH, null, "saathi")
                                if (status == TextToSpeech.ERROR) result.error("speech_failed", "Could not speak this message", null)
                                else result.success(null)
                            }
                        }
                    }
                    "stopSpeaking" -> { textToSpeech?.stop(); result.success(null) }
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
        textToSpeech = TextToSpeech(this) { status -> ttsReady = status == TextToSpeech.SUCCESS }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 2201) {
            val pending = speechResult
            speechResult = null
            val words = if (resultCode == RESULT_OK) data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull() else null
            pending?.success(words)
        }
    }

    override fun onDestroy() {
        speechResult?.error("cancelled", "Speech recognition was interrupted", null)
        speechResult = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }

    @Deprecated("Android role picker result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 2) {
            homeRequestResult?.success(getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_HOME))
            homeRequestResult = null
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

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setDecorFitsSystemWindows(false)
        window.insetsController?.show(WindowInsets.Type.systemBars())
    }
}

class AssistantActivity : MainActivity() {
    override fun getInitialRoute(): String = "/assistant"
}
