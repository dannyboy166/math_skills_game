// lib/services/leaderboard_updater.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Service to keep the leaderboard data updated
class LeaderboardUpdater {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _updateTimer;
  bool _isUpdating = false;

  // Singleton pattern
  static final LeaderboardUpdater _instance = LeaderboardUpdater._internal();
  
  factory LeaderboardUpdater() {
    return _instance;
  }
  
  LeaderboardUpdater._internal();

  /// Start periodic updates of the leaderboard data
  void startUpdates({Duration period = const Duration(minutes: 30)}) {
    stopUpdates(); // Stop any existing updates first
    
    // Run an initial update
    _updateCurrentUserData();
    
    // Start periodic updates
    _updateTimer = Timer.periodic(period, (timer) {
      _updateCurrentUserData();
    });
  }

  /// Stop the periodic updates
  void stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Update data for the current user only
  Future<void> _updateCurrentUserData() async {
    if (_isUpdating) return; // Prevent concurrent updates
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _isUpdating = true;
    
    try {
      // Get current user data
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        await _updateUserStats(user.uid, docSnapshot.data()!);
      }
      
    } catch (e) {
      print('Error updating user data: $e');
    } finally {
      _isUpdating = false;
    }
  }

  /// Update stats for a specific user
  Future<void> _updateUserStats(String userId, Map<String, dynamic> userData) async {
    final completedGames = userData['completedGames'] as Map<String, dynamic>? ?? {};
    
    // Calculate total games
    int additionCount = completedGames['addition'] ?? 0;
    int subtractionCount = completedGames['subtraction'] ?? 0;
    int multiplicationCount = completedGames['multiplication'] ?? 0;
    int divisionCount = completedGames['division'] ?? 0;
    
    int calculatedTotal = additionCount + subtractionCount + 
                          multiplicationCount + divisionCount;
    
    // Update the user document if needed
    final updates = <String, dynamic>{
      'totalGames': calculatedTotal,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    // Also update favorite operation
    String favoriteOperation = 'None';
    int maxCount = 0;
    
    if (additionCount > maxCount) {
      maxCount = additionCount;
      favoriteOperation = 'addition';
    }
    if (subtractionCount > maxCount) {
      maxCount = subtractionCount;
      favoriteOperation = 'subtraction';
    }
    if (multiplicationCount > maxCount) {
      maxCount = multiplicationCount;
      favoriteOperation = 'multiplication';
    }
    if (divisionCount > maxCount) {
      maxCount = divisionCount;
      favoriteOperation = 'division';
    }
    
    if (maxCount > 0) {
      updates['favoriteOperation'] = favoriteOperation;
    }
    
    await _firestore.collection('users').doc(userId).update(updates);
  }

  /// Force an immediate update for the current user
  Future<void> updateCurrentUser() async {
    await _updateCurrentUserData();
  }
}