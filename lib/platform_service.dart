import 'dart:async';
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('track_connect_channel');

  // Method to get battery level
  static Future<String?> getBatteryLevel() async {
    try {
      final String result = await _channel.invokeMethod('getBatteryLevel');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
      return null;
    }
  }

  // Method to get device info
  static Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final Map<String, dynamic> result = 
          await _channel.invokeMethod('getDeviceInfo');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get device info: '${e.message}'.");
      return null;
    }
  }

  // Method to check if location is enabled
  static Future<bool> isLocationEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isLocationEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check location: '${e.message}'.");
      return false;
    }
  }

  // Method to request location services
  static Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      print("Failed to open location settings: '${e.message}'.");
    }
  }

  // Method to get app info
  static Future<Map<String, dynamic>?> getAppInfo() async {
    try {
      final Map<String, dynamic> result = 
          await _channel.invokeMethod('getAppInfo');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get app info: '${e.message}'.");
      return null;
    }
  }
}