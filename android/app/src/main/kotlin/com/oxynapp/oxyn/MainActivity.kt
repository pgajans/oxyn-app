package com.oxynapp.oxyn

import android.content.Intent
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oxynapp.oxyn/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStorageInfo" -> result.success(getStorageInfo())
                    "getBatteryDetails" -> result.success(getBatteryDetails())
                    "getCpuTemperature" -> result.success(getCpuTemperature())
                    "openBatterySettings" -> {
                        startActivity(Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "openAppSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getStorageInfo(): Map<String, Long> {
        val stat = StatFs(Environment.getDataDirectory().path)
        val totalBytes = stat.blockSizeLong * stat.blockCountLong
        val freeBytes = stat.blockSizeLong * stat.availableBlocksLong
        val usedBytes = totalBytes - freeBytes

        return mapOf(
            "totalBytes" to totalBytes,
            "freeBytes" to freeBytes,
            "usedBytes" to usedBytes
        )
    }

    private fun getBatteryDetails(): Map<String, Any> {
        val bm = getSystemService(BATTERY_SERVICE) as BatteryManager
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = bm.isCharging
        val temperature = try {
            val intent = registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
            temp / 10.0
        } catch (e: Exception) {
            0.0
        }

        return mapOf(
            "level" to level,
            "isCharging" to isCharging,
            "temperature" to temperature,
            "state" to if (isCharging) "charging" else "discharging"
        )
    }

    private fun getCpuTemperature(): Double {
        return try {
            val process = Runtime.getRuntime().exec("cat /sys/class/thermal/thermal_zone0/temp")
            val reader = process.inputStream.bufferedReader()
            val temp = reader.readLine()?.toDoubleOrNull() ?: 0.0
            reader.close()
            if (temp > 1000) temp / 1000.0 else temp
        } catch (e: Exception) {
            0.0
        }
    }
}
