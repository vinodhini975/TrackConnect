import 'dart:async';
import 'package:flutter/services.dart';

class AndroidService {
  static const MethodChannel _channel = MethodChannel('android_service_channel');

  // Start background location service
  static Future<void> startBackgroundLocationService() async {
    try {
      await _channel.invokeMethod('startBackgroundLocationService');
    } on PlatformException catch (e) {
      print("Failed to start background location service: '${e.message}'.");
    }
  }

  // Stop background location service
  static Future<void> stopBackgroundLocationService() async {
    try {
      await _channel.invokeMethod('stopBackgroundLocationService');
    } on PlatformException catch (e) {
      print("Failed to stop background location service: '${e.message}'.");
    }
  }

  // Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final bool result = await _channel.invokeMethod('isServiceRunning');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check service status: '${e.message}'.");
      return false;
    }
  }

  // Request background location permission
  static Future<bool> requestBackgroundLocationPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestBackgroundLocationPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to request background location permission: '${e.message}'.");
      return false;
    }
  }

  // Optimize battery usage
  static Future<void> optimizeBatteryUsage() async {
    try {
      await _channel.invokeMethod('optimizeBatteryUsage');
    } on PlatformException catch (e) {
      print("Failed to optimize battery usage: '${e.message}'.");
    }
  }
}