import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _canVibrate = false;

  // Factory constructor
  factory AudioManager() {
    return _instance;
  }

  // Private constructor
  AudioManager._internal() {
    _initVibration();
  }

  // Initialize vibration capabilities
  Future<void> _initVibration() async {
    _canVibrate = await Vibrate.canVibrate;
  }

  // Play a sound effect
  Future<void> playSound(String soundName) async {
    if (!_soundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // Vibrate with a specific pattern
  Future<void> vibrate({FeedbackType type = FeedbackType.success}) async {
    if (!_vibrationEnabled || !_canVibrate) return;

    try {
      Vibrate.feedback(type);
    } catch (e) {
      print('Error during vibration: $e');
    }
  }

  // Play correct answer feedback
  Future<void> playCorrectFeedback() async {
    playSound('correct');
    vibrate(type: FeedbackType.success);
  }

  // Play wrong answer feedback
  Future<void> playWrongFeedback() async {
    playSound('wrong');
    vibrate(type: FeedbackType.error);
  }

  // Play completion celebration
  Future<void> playCompletionFeedback() async {
    playSound('level_complete');
    vibrate(type: FeedbackType.heavy);
  }

  // Getters and setters for settings
  bool get isSoundEnabled => _soundEnabled;
  set isSoundEnabled(bool value) => _soundEnabled = value;

  bool get isVibrationEnabled => _vibrationEnabled;
  set isVibrationEnabled(bool value) => _vibrationEnabled = value;
}
