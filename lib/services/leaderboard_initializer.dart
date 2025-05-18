// lib/services/leaderboard_initializer.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_stats_service.dart';
import 'leaderboard_service.dart';
import 'dart:async';

class LeaderboardInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserStatsService _userStatsService = UserStatsService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  static bool _hasInitialized = false;

  // Initialize operation stars for current user
  Future<void> initializeForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if the user document has gameStats with operation stars
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final gameStats = data['gameStats'] as Map<String, dynamic>?;
        
        // If gameStats doesn't exist or is missing operation stars, calculate them
        if (gameStats == null || 
            !gameStats.containsKey('additionStars') || 
            !gameStats.containsKey('subtractionStars') || 
            !gameStats.containsKey('multiplicationStars') || 
            !gameStats.containsKey('divisionStars')) {
          
          print('Calculating operation stars for current user...');
          await _userStatsService.calculateStarsPerOperation(user.uid);
        }
        
        // Ensure the user is registered in the leaderboards
        // This is lightweight and only updates if necessary
        final userId = user.uid;
        final isNewUser = data['totalGames'] == null || (data['totalGames'] as int) < 5;
        
        if (isNewUser) {
          // For new users, always update the leaderboard to get them ranked
          await _leaderboardService.updateUserInAllLeaderboards(userId);
        } else {
          // For existing users, check if we need to update
          final userRankings = await _leaderboardService.getUserRankingsInAllLeaderboards(userId);
          
          // If the user doesn't have any rankings yet, update them
          if (userRankings.isEmpty || userRankings.values.every((rank) => rank == 0)) {
            await _leaderboardService.updateUserInAllLeaderboards(userId);
          }
        }
      }
    } catch (e) {
      print('Error initializing operation stars for current user: $e');
    }
  }

  // Mark that initialization has been done
  static void markInitialized() {
    _hasInitialized = true;
  }

  // Check if initialization has been done
  static bool hasInitialized() {
    return _hasInitialized;
  }
}