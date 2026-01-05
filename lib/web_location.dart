import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';

class WebLocation {
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever
          ? false
          : true;
    } catch (e) {
      return false; // Permission denied
    }
  }
  
  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
