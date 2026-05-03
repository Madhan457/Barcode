import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider with ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _requireSecurityOnEntry = false;
  bool _isAuthenticated = false;
  String? _pin;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get requireSecurityOnEntry => _requireSecurityOnEntry;
  bool get isAuthenticated => _isAuthenticated;
  bool get isPinSet => _pin != null && _pin!.length == 4;

  SecurityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _requireSecurityOnEntry = prefs.getBool('require_security') ?? false;
    _pin = prefs.getString('user_pin');
    notifyListeners();
  }

  Future<void> setPin(String newPin) async {
    if (newPin.length != 4) return;
    _pin = newPin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', newPin);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    if (value && !isPinSet) {
      // Cannot enable biometrics without a PIN
      return;
    }
    _isBiometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setRequireSecurity(bool value) async {
    _requireSecurityOnEntry = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('require_security', value);
    notifyListeners();
  }

  bool verifyPin(String enteredPin) {
    return enteredPin == _pin;
  }

  Future<bool> authenticateBiometrics() async {
    if (!_isBiometricEnabled) return false;

    try {
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      
      // Check for fingerprint specifically
      if (!availableBiometrics.contains(BiometricType.fingerprint) && 
          !availableBiometrics.contains(BiometricType.strong)) {
        return false; 
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate with Fingerprint',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Force biometric only (usually fingerprint/face)
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void resetAuthentication() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
