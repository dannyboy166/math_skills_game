// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Updated for AudioPlayers v3.0.0+
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _audioPlayers = {};
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Initialize and preload sound effects
  Future<void> initialize() async {
    // Create a list of sounds to preload
    final sounds = [
      'sounds/Correct.mp3',
      'sounds/Incorrect.mp3',
      'sounds/0starWin.mp3',
      'sounds/1starWin.mp3',
      'sounds/2starWin.mp3',
      'sounds/3starWin.mp3',
    ];
    
    // Pre-create an AudioPlayer for each sound
    for (var sound in sounds) {
      _audioPlayers[sound] = AudioPlayer();
    }
  }

  // Play sound for correct equation
  void playCorrect() {
    if (_soundEnabled) {
      _playSound('sounds/Correct.mp3');
    }
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  // Play sound for incorrect equation
  void playIncorrect() {
    if (_soundEnabled) {
      _playSound('sounds/Incorrect.mp3');
    }
    if (_vibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }

  // Play celebration sound based on star rating
  void playCelebrationByStar(int stars) {
    if (!_soundEnabled) return;
    
    String soundFile = 'sounds/${stars}starWin.mp3';
    _playSound(soundFile);
    
    if (_vibrationEnabled) {
      _playSuccessVibrationPattern();
    }
  }

  // Helper method to play sounds
  Future<void> _playSound(String soundFile) async {
    try {
      // Get or create an AudioPlayer for this sound
      final player = _audioPlayers[soundFile] ?? AudioPlayer();
      
      // Stop any currently playing sound on this player
      await player.stop();
      
      // Play the sound from assets
      await player.setSource(AssetSource(soundFile));
      await player.resume();
      
      // Save the player if it's new
      if (_audioPlayers[soundFile] == null) {
        _audioPlayers[soundFile] = player;
      }
    } catch (e) {
      print('Error playing sound $soundFile: $e');
    }
  }

  // Enable/disable sound
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  // Enable/disable vibration
  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
  }

  // Getters for current state
  bool get isSoundEnabled => _soundEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;

  // Custom vibration patterns
  void _playSuccessVibrationPattern() {
    HapticFeedback.mediumImpact();
    Future.delayed(Duration(milliseconds: 200), () => HapticFeedback.mediumImpact());
    Future.delayed(Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
  }

  // Clean up resources
  void dispose() {
    _audioPlayer.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
  }
}