// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_skills_game/services/leaderboard_service.dart';

class AdminService {
  static const String ADMIN_USER_ID = '51xmsPQN8eNpiPVueybYjz4sqsp1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

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
          .limit(50) // Adjust this limit for your actual user count
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

  Future<void> forceLeaderboardSync(String userId) async {
    try {
      print("Starting forced leaderboard sync for user $userId");

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print("User document doesn't exist!");
        return;
      }

      final userData = userDoc.data()!;
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      if (bestTimes.isEmpty) {
        print("No best times found for user");
        return;
      }

      // Create a batch for all updates
      final batch = _firestore.batch();
      int operationCount = 0;

      // Process all operation types
      for (final operation in [
        'addition',
        'subtraction',
        'multiplication',
        'division'
      ]) {
        // Get the overall best time
        final overallBestTime = bestTimes[operation] as int? ?? 0;
        if (overallBestTime <= 0) continue;

        // Determine leaderboard type
        String leaderboardType;
        switch (operation) {
          case 'addition':
            leaderboardType = 'additionTime';
            break;
          case 'subtraction':
            leaderboardType = 'subtractionTime';
            break;
          case 'multiplication':
            leaderboardType = 'multiplicationTime';
            break;
          case 'division':
            leaderboardType = 'divisionTime';
            break;
          default:
            continue;
        }

        // Get rank for overall leaderboard
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .collection('entries')
            .where('bestTime', isLessThan: overallBestTime)
            .count()
            .get();

        final rank = (rankSnapshot.count ?? 0) + 1;

        // Add overall time to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(leaderboardType)
                .collection('entries')
                .doc(userId),
            {
              'userId': userId,
              'displayName': userData['displayName'] ?? 'Unknown',
              'bestTime': overallBestTime,
              'level': userData['level'] ?? 'Novice',
              'rank': rank,
              'difficulty': 'All',
              'updatedAt': FieldValue.serverTimestamp(),
            });
        operationCount++;

        // Process difficulty-specific times
        for (final difficulty in [
          'standard',
          'challenging',
          'expert',
          'impossible'
        ]) {
          final difficultyKey = '$operation-$difficulty';
          final difficultyBestTime = bestTimes[difficultyKey] as int? ?? 0;
          if (difficultyBestTime <= 0) continue;

          // Get rank for difficulty leaderboard
          final diffRankSnapshot = await _firestore
              .collection('leaderboards')
              .doc(leaderboardType)
              .collection('difficulties')
              .doc(difficulty)
              .collection('entries')
              .where('bestTime', isLessThan: difficultyBestTime)
              .count()
              .get();

          final diffRank = (diffRankSnapshot.count ?? 0) + 1;

          // Add to batch
          batch.set(
              _firestore
                  .collection('leaderboards')
                  .doc(leaderboardType)
                  .collection('difficulties')
                  .doc(difficulty)
                  .collection('entries')
                  .doc(userId),
              {
                'userId': userId,
                'displayName': userData['displayName'] ?? 'Unknown',
                'bestTime': difficultyBestTime,
                'level': userData['level'] ?? 'Novice',
                'rank': diffRank,
                'difficulty': difficulty.substring(0, 1).toUpperCase() +
                    difficulty.substring(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
          operationCount++;
        }
      }

      // Commit the batch
      if (operationCount > 0) {
        await batch.commit();
        print("Synced $operationCount leaderboard entries for user $userId");
      } else {
        print("No leaderboard entries to sync");
      }
    } catch (e) {
      print("Error during forced leaderboard sync: $e");
    }
  }

  Future<void> forceSyncCurrentUserLeaderboards() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("No user is signed in");
    }

    return forceLeaderboardSync(userId);
  }
}
