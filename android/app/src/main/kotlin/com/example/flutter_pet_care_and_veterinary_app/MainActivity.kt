package com.example.flutter_pet_care_and_veterinary_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.provider.AlarmClock
import java.util.ArrayList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flutter.petcare/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationIgnored" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent().apply {
                            action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                            data = Uri.parse("package:$packageName")
                        }
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback to general settings list if package URI fails
                            val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(fallbackIntent)
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openBatterySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "setSystemAlarm" -> {
                    val hour = call.argument<Int>("hour")
                    val minutes = call.argument<Int>("minutes")
                    val message = call.argument<String>("message")
                    val skipUi = call.argument<Boolean>("skipUi") ?: true
                    val days = call.argument<List<Int>>("days")

                    if (hour != null && minutes != null) {
                        try {
                            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                                putExtra(AlarmClock.EXTRA_HOUR, hour)
                                putExtra(AlarmClock.EXTRA_MINUTES, minutes)
                                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                                putExtra(AlarmClock.EXTRA_SKIP_UI, skipUi)
                                if (days != null && days.isNotEmpty()) {
                                    val daysList = ArrayList<Int>()
                                    for (day in days) {
                                        daysList.add(day)
                                    }
                                    putExtra(AlarmClock.EXTRA_DAYS, daysList)
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALARM_SET_FAILED", e.message, null)
                        }
                    } else {
                        result.error("BAD_ARGUMENTS", "Hour and minutes must be provided", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
