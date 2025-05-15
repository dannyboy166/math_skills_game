// lib/services/leaderboard_updater.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import './leaderboard_service.dart';
import './scalable_leaderboard_service.dart'; // Add this import

class LeaderboardUpdater {
  static final LeaderboardUpdater _instance = LeaderboardUpdater._internal();
  factory LeaderboardUpdater() => _instance;
  LeaderboardUpdater._internal();

  final LeaderboardService _leaderboardService = LeaderboardService();
  final ScalableLeaderboardService _scalableLeaderboardService = ScalableLeaderboardService(); // Add this
  
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
        // Update the user's data in the legacy leaderboard
        await _leaderboardService.updateUserRankingData(user.uid);
        
        // ADDED: Also update in the scalable leaderboard system
        await _scalableLeaderboardService.updateUserInAllLeaderboards(user.uid);
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
  
  // ADDED: Method to fully refresh all leaderboards (for admin use or scheduled task)
  Future<void> refreshAllLeaderboards() async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      await _scalableLeaderboardService.refreshAllLeaderboards();
    } catch (e) {
      print('Error refreshing all leaderboards: $e');
    } finally {
      _isUpdating = false;
    }
  }
}