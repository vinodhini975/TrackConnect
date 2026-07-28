import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/truck_location.dart';
import '../data/repositories/truck_repository.dart';

class TruckProvider extends ChangeNotifier {
  final TruckRepository _repo;
  TruckLocation? _truckLocation;
  bool _isLoading = true;
  StreamSubscription? _subscription;

  TruckLocation? get truckLocation => _truckLocation;
  bool get isLoading => _isLoading;

  TruckProvider(this._repo);

  void startTracking(String wardNumber) {
    _subscription?.cancel();
    _subscription = _repo.getTruckStream(wardNumber).listen((truck) {
      _truckLocation = truck;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> reportMissedCollection(String wardNumber, String userId) async {
    await _repo.reportMissedCollection(wardNumber, userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
