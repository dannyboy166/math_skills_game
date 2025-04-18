// lib/services/leaderboard_initializer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_stats_service.dart';
import 'dart:async';

class LeaderboardInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserStatsService _userStatsService = UserStatsService();
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