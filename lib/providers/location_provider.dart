import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _permissionDenied = false;

  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  bool get permissionDenied => _permissionDenied;
  bool get hasLocation => _currentLatitude != null && _currentLongitude != null;

  Future<bool> requestLocationPermission() async {
    _locationError = null;
    _permissionDenied = false;

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _permissionDenied = true;
        _locationError = 'Location permission denied permanently';
        notifyListeners();
        return false;
      }

      if (permission == LocationPermission.denied) {
        _permissionDenied = true;
        _locationError = 'Location permission denied';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _locationError = 'Failed to request location permission: $e';
      debugPrint(_locationError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _isLoadingLocation = false;
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      _locationError = null;
      debugPrint(
        'Location obtained: $_currentLatitude, $_currentLongitude',
      );
      notifyListeners();
      return true;
    } on LocationServiceDisabledException {
      _locationError = 'Location services are disabled';
      debugPrint(_locationError);
      notifyListeners();
      return false;
    } catch (e) {
      _locationError = 'Failed to get location: $e';
      debugPrint(_locationError);
      notifyListeners();
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void clearLocation() {
    _currentLatitude = null;
    _currentLongitude = null;
    _locationError = null;
    _permissionDenied = false;
    notifyListeners();
  }
}
