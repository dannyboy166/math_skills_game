import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_skills_game/services/haptic_service.dart'; // Add this import

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _audioPlayers = {};
  bool _soundEnabled = true;

  // Reference to haptic service
  final HapticService _hapticService = HapticService();

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

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
  }

  // Play sound for correct equation
  void playCorrect() {
    if (_soundEnabled) {
      _playSound('sounds/Correct.mp3');
    }
    if (_hapticService.isVibrationEnabled) {
      _hapticService.mediumImpact();
    }
  }

  // Play sound for incorrect equation
  void playIncorrect() {
    if (_soundEnabled) {
      _playSound('sounds/Incorrect.mp3');
    }
    if (_hapticService.isVibrationEnabled) {
      _hapticService.vibrate();
    }
  }

  // Play celebration sound based on star rating
  void playCelebrationByStar(int stars) {
    if (!_soundEnabled) return;

    String soundFile = 'sounds/${stars}starWin.mp3';
    _playSound(soundFile);

    if (_hapticService.isVibrationEnabled) {
      _hapticService.celebration();
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

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;

    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  // Getter for current state
  bool get isSoundEnabled => _soundEnabled;

  // Clean up resources
  void dispose() {
    _audioPlayer.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
  }
}
