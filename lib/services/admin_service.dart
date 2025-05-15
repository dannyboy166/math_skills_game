// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_skills_game/services/scalable_leaderboard_service.dart';

class AdminService {
  static const String ADMIN_USER_ID = '51xmsPQN8eNpiPVueybYjz4sqsp1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScalableLeaderboardService _leaderboardService = ScalableLeaderboardService();

  // Check if the current user is an admin
  bool isCurrentUserAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == ADMIN_USER_ID;
  }

  // Migrate data for the current user
  Future<void> migrateCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      print('Starting migration for user: ${user.uid}');
      
      // Update user in all leaderboards
      await _leaderboardService.updateUserInAllLeaderboards(user.uid);
      
      print('Migration completed successfully for current user');
      return;
    } catch (e) {
      print('Error during user migration: $e');
      throw e;
    }
  }

  // Migrate all users' data - be careful with this on a large database!
  Future<void> migrateAllUsers() async {
    try {
      // Get all users (limit to a reasonable number for testing)
      final querySnapshot = await _firestore
          .collection('users')
          .limit(50)  // Adjust this limit for your actual user count
          .get();

      print('Starting migration for ${querySnapshot.docs.length} users');
      
      int successCount = 0;
      int errorCount = 0;
      
      // Process each user
      for (final userDoc in querySnapshot.docs) {
        try {
          await _leaderboardService.updateUserInAllLeaderboards(userDoc.id);
          successCount++;
          print('Migrated user: ${userDoc.id}');
        } catch (e) {
          errorCount++;
          print('Error migrating user ${userDoc.id}: $e');
        }
      }

      print('Migration completed. Success: $successCount, Errors: $errorCount');
      return;
    } catch (e) {
      print('Error during migration: $e');
      throw e;
    }
  }

  // Refresh all leaderboards
  Future<void> refreshAllLeaderboards() async {
    try {
      print('Starting leaderboard refresh');
      await _leaderboardService.refreshAllLeaderboards();
      print('Leaderboard refresh completed successfully');
      return;
    } catch (e) {
      print('Error refreshing leaderboards: $e');
      throw e;
    }
  }
}