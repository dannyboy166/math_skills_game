// lib/services/leaderboard_updater.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import './leaderboard_service.dart';

class LeaderboardUpdater {
  static final LeaderboardUpdater _instance = LeaderboardUpdater._internal();
  factory LeaderboardUpdater() => _instance;
  LeaderboardUpdater._internal();

  final LeaderboardService _leaderboardService = LeaderboardService();
  Timer? _updateTimer;
  bool _isUpdating = false;

  void startUpdates({Duration updateInterval = const Duration(minutes: 5)}) {
    // Cancel any existing timers
    _updateTimer?.cancel();

    // Run an immediate update first
    _updateCurrentUserRankings();

    // Then set up the timer for periodic updates
    _updateTimer = Timer.periodic(updateInterval, (_) {
      _updateCurrentUserRankings();
    });
  }

  void stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _updateCurrentUserRankings() async {
    if (_isUpdating) return; // Prevent multiple concurrent updates
    _isUpdating = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update the user's data in the leaderboard
        await _leaderboardService.updateUserRankingData(user.uid);
      }
    } catch (e) {
      print('Error updating leaderboard rankings: $e');
    } finally {
      _isUpdating = false;
    }
  }

  // Manually trigger an update, useful after completing a level
  Future<void> triggerUpdate() async {
    return _updateCurrentUserRankings();
  }
}