import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _isDisasterMode = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDisasterMode => _isDisasterMode;

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get location. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation(String phone) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
    }

    if (_currentPosition == null) return;

    try {
      final response = await http.post(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'location': {
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
          },
          'disasterMode': _isDisasterMode,
        }),
      );

      if (response.statusCode != 200) {
        _error = json.decode(response.body)['error'];
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update location. Please try again.';
      notifyListeners();
    }
  }

  void toggleDisasterMode() {
    _isDisasterMode = !_isDisasterMode;
    notifyListeners();
  }

  void setDisasterMode(bool value) {
    _isDisasterMode = value;
    notifyListeners();
  }
} 