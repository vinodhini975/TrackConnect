import 'dart:async';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  String? _selectedDriverId;
  bool _isManual = false; // Flag to check if user personally picked this driver

  final StreamController<String?> _driverController = StreamController<String?>.broadcast();

  String? get selectedDriverId => _selectedDriverId;
  bool get isManual => _isManual;
  Stream<String?> get selectedDriverStream => _driverController.stream;

  void selectDriver(String? driverId, {bool manual = false}) {
    // If we already have a manual selection and this is an auto-request, ignore it.
    if (_isManual && !manual && driverId != null) return;

    _selectedDriverId = driverId;
    if (manual) _isManual = true;
    _driverController.add(driverId);
  }

  void resetToAuto() {
    _isManual = false;
    _selectedDriverId = null;
    _driverController.add(null);
  }
}
