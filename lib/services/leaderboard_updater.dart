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
        // Update the user in all leaderboards using our consolidated service
        await _leaderboardService.updateUserInAllLeaderboards(user.uid);
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
  
  // Update a time high score (optimized path for game completions)
  Future<bool> updateTimeHighScore(String userId, String operation, String difficulty, int newTime) async {
    try {
      if (_isUpdating) {
        // If already updating, wait for completion
        int attempts = 0;
        while (_isUpdating && attempts < 10) {
          await Future.delayed(Duration(milliseconds: 100));
          attempts++;
        }
        if (_isUpdating) {
          print('Warning: Update is taking too long, proceeding with high score update anyway');
        }
      }
      
      _isUpdating = true;
      
      // Use the optimized high score update method
      final result = await _leaderboardService.updateTimeHighScore(
          userId, operation, difficulty, newTime);
          
      return result;
    } catch (e) {
      print('Error updating time high score: $e');
      return false;
    } finally {
      _isUpdating = false;
    }
  }
  
  // Refresh all leaderboards (for admin use or background task)
  Future<void> refreshAllLeaderboards() async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      await _leaderboardService.refreshAllLeaderboards();
    } catch (e) {
      print('Error refreshing all leaderboards: $e');
    } finally {
      _isUpdating = false;
    }
  }
  
  // Clear leaderboard cache
  Future<void> clearLeaderboardCache() async {
    try {
      await _leaderboardService.clearCache();
    } catch (e) {
      print('Error clearing leaderboard cache: $e');
    }
  }
}