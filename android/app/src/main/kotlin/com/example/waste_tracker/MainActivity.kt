package com.example.waste_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterActivity() {
    private val CHANNEL = "track_connect_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Register the main channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success("Battery level: $batteryLevel%")
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available", null)
                    }
                }
                "getDeviceInfo" -> {
                    val deviceInfo = getDeviceInfo()
                    result.success(deviceInfo)
                }
                "isLocationEnabled" -> {
                    val locationEnabled = isLocationEnabled()
                    result.success(locationEnabled)
                }
                "openLocationSettings" -> {
                    openLocationSettings()
                    result.success(null)
                }
                "getAppInfo" -> {
                    val appInfo = getAppInfo()
                    result.success(appInfo)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Register the android service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "android_service_channel").setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startBackgroundLocationService" -> {
                    // Placeholder implementation
                    result.success(null)
                }
                "stopBackgroundLocationService" -> {
                    // Placeholder implementation
                    result.success(null)
                }
                "isServiceRunning" -> {
                    // Placeholder implementation
                    result.success(false)
                }
                "requestBackgroundLocationPermission" -> {
                    // Placeholder implementation
                    result.success(true)
                }
                "optimizeBatteryUsage" -> {
                    // Placeholder implementation
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            -1
        }
    }

    private fun getDeviceInfo(): java.util.HashMap<String, String> {
        val deviceInfo = java.util.HashMap<String, String>()
        deviceInfo["model"] = android.os.Build.MODEL
        deviceInfo["manufacturer"] = android.os.Build.MANUFACTURER
        deviceInfo["version"] = android.os.Build.VERSION.RELEASE
        deviceInfo["sdk"] = android.os.Build.VERSION.SDK_INT.toString()
        return deviceInfo
    }

    private fun isLocationEnabled(): Boolean {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) || 
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun openLocationSettings() {
        val intent = Intent(android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        startActivity(intent)
    }

    private fun getAppInfo(): java.util.HashMap<String, String> {
        val appInfo = java.util.HashMap<String, String>()
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        appInfo["appName"] = "Waste Tracker" // Using hardcoded app name instead of string resource
        appInfo["packageName"] = packageName
        appInfo["versionName"] = packageInfo.versionName ?: "1.0.0" // Provide default if null
        appInfo["versionCode"] = packageInfo.versionCode.toString()
        return appInfo
    }
}
