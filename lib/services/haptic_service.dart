// lib/services/haptic_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _vibrationEnabled = true;

  // Initialize and load preferences
  Future<void> initialize() async {
    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
  }

  // Toggle vibration and save preference
  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  // Getter for current state
  bool get isVibrationEnabled => _vibrationEnabled;

  // Basic vibration feedback
  void lightImpact() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void mediumImpact() {
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void heavyImpact() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void vibrate() {
    if (_vibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }

  // Feedback patterns
  void success() {
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
      Future.delayed(Duration(milliseconds: 150), () => HapticFeedback.mediumImpact());
      Future.delayed(Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
    }
  }

  void error() {
    if (_vibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }

  void celebration() {
    if (_vibrationEnabled) {
      // Create a celebratory pattern
      HapticFeedback.mediumImpact();
      Future.delayed(Duration(milliseconds: 150), () => HapticFeedback.mediumImpact());
      Future.delayed(Duration(milliseconds: 300), () => HapticFeedback.mediumImpact());
      Future.delayed(Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());
    }
  }
}