import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  String? _userType;
  String? _phoneNumber;
  bool _isLoading = false;
  String? _error;

  String? get userType => _userType;
  String? get phoneNumber => _phoneNumber;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> sendOTP(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        _phoneNumber = phone;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to send OTP. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _phoneNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userType = data['userType'];
        await storage.write(key: 'userType', value: _userType);
        await storage.write(key: 'phoneNumber', value: _phoneNumber);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to verify OTP. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String phone, String userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'userType': userType,
        }),
      );

      if (response.statusCode == 201) {
        _phoneNumber = phone;
        _userType = userType;
        await storage.write(key: 'userType', value: userType);
        await storage.write(key: 'phoneNumber', value: phone);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to register. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
    _userType = null;
    _phoneNumber = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _userType = await storage.read(key: 'userType');
    _phoneNumber = await storage.read(key: 'phoneNumber');
    notifyListeners();
  }
} 