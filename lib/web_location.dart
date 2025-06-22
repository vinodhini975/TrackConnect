import 'dart:html' as html;

class WebLocation {
  static Future<bool> requestLocationPermission() async {
    try {
      // Request location access
      final permission = await html.window.navigator.geolocation.getCurrentPosition();
      return true; // Permission granted
    } catch (e) {
      return false; // Permission denied
    }
  }
}
