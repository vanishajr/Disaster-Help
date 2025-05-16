import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DisasterProvider with ChangeNotifier {
  Map<String, dynamic>? _clusters;
  Map<String, dynamic>? _supplies;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get clusters => _clusters;
  Map<String, dynamic>? get supplies => _supplies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getClusters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/get-clusters'),
      );

      if (response.statusCode == 200) {
        _clusters = json.decode(response.body)['clusters'];
        _isLoading = false;
        notifyListeners();
      } else {
        _error = json.decode(response.body)['error'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch clusters. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateSupplies(String clusterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/calculate-supplies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'clusterId': clusterId}),
      );

      if (response.statusCode == 200) {
        _supplies = json.decode(response.body)['supplies'];
        _isLoading = false;
        notifyListeners();
      } else {
        _error = json.decode(response.body)['error'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to calculate supplies. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSupplies() {
    _supplies = null;
    notifyListeners();
  }
} 