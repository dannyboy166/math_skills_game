// lib/services/leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch top users by longest streak
  Future<List<LeaderboardEntry>> getTopUsersByStreak({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakData.longestStreak', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by streak: $e');
      rethrow;
    }
  }

  // Fetch top users by total games played
  Future<List<LeaderboardEntry>> getTopUsersByGamesPlayed(
      {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalGames', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by games played: $e');
      rethrow;
    }
  }

  // Get top users for a specific operation
  Future<List<LeaderboardEntry>> getTopUsersByOperation(String operation,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('completedGames.$operation', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by operation: $e');
      rethrow;
    }
  }

  // Get top users by best completion time for an operation
  Future<List<LeaderboardEntry>> getTopUsersByBestTime(String operation,
      {int limit = 20}) async {
    try {
      // Find all users with completion times for this operation
      final usersWithTimes = await _firestore
          .collection('users')
          .where('bestTimes.$operation', isGreaterThan: 0)
          .orderBy('bestTimes.$operation',
              descending: false) // Ascending by time (faster is better)
          .limit(limit)
          .get();

      if (usersWithTimes.docs.isEmpty) {
        // If no users have recorded best times yet, fall back to users who have played this operation
        final usersByOperation =
            await getTopUsersByOperation(operation, limit: limit);
        return usersByOperation;
      }

      return usersWithTimes.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by best time: $e');
      // Fall back to operation count if there's an error
      return getTopUsersByOperation(operation, limit: limit);
    }
  }

  // Get current user's rank by streak
  Future<int> getCurrentUserRankByStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      // Get current user's data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final streakData = userData['streakData'] as Map<String, dynamic>? ?? {};
      final userStreak = streakData['longestStreak'] ?? 0;

      // Count users with longer streaks
      final count = await _firestore
          .collection('users')
          .where('streakData.longestStreak', isGreaterThan: userStreak)
          .count()
          .get();

      // Rank is count of users with longer streaks + 1
      return count.count! + 1;
    } catch (e) {
      print('Error getting user rank by streak: $e');
      return 0;
    }
  }

  // Get user's rank by completion time for a specific operation
  Future<int> getUserRankByTime(String operation, String userId) async {
    try {
      // Get the user's best time
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};
      final userTime = bestTimes[operation] ?? 0;

      // If user has no recorded time, return 0 rank
      if (userTime == 0) return 0;

      // Count users with better (smaller) times
      final count = await _firestore
          .collection('users')
          .where('bestTimes.$operation', isLessThan: userTime)
          .count()
          .get();

      // Rank is count of users with better times + 1
      return count.count! + 1;
    } catch (e) {
      print('Error getting user rank by time: $e');
      return 0;
    }
  }

  Future<void> updateUserRankingData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      // Update last ranking update timestamp
      await _firestore.collection('users').doc(userId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update best completion times
      await _updateBestCompletionTimes(userId);
    } catch (e) {
      print('Error updating user ranking data: $e');
    }
  }

  // Get top users by best time and difficulty
  Future<List<LeaderboardEntry>> getTopUsersByBestTimeAndDifficulty(
      String operation, String difficulty,
      {int limit = 20}) async {
    try {
      // Generate the key for the specific operation and difficulty
      final timeKey = '$operation-${difficulty.toLowerCase()}';

      // Find users with completion times for this specific difficulty
      final usersWithTimes = await _firestore
          .collection('users')
          .where('bestTimes.$timeKey', isGreaterThan: 0)
          .orderBy('bestTimes.$timeKey',
              descending: false) // Ascending by time (faster is better)
          .limit(limit)
          .get();

      // If no users have recorded best times for this difficulty yet, return an empty list
      if (usersWithTimes.docs.isEmpty) {
        return [];
      }

      return usersWithTimes.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by best time and difficulty: $e');
      return []; // Return empty list on error
    }
  }

  // Update best completion times
  Future<void> _updateBestCompletionTimes(String userId) async {
    try {
      // Get all level completions
      final completions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levelCompletions')
          .get();

      // Track best times for each operation (overall)
      final bestTimes = {
        'addition': 999999,
        'subtraction': 999999,
        'multiplication': 999999,
        'division': 999999
      };

      // Track best times for each operation and difficulty combination
      final difficultyBestTimes = <String, int>{};

      // Find best (lowest) completion time for each operation and each difficulty
      for (final doc in completions.docs) {
        final data = doc.data();
        final operation = data['operationName'] as String?;
        final difficulty = data['difficultyName'] as String?;
        final completionTime = data['completionTimeMs'] as int?;

        if (operation != null && completionTime != null && completionTime > 0) {
          // Update overall best time for the operation
          if (bestTimes.containsKey(operation) &&
              completionTime < bestTimes[operation]!) {
            bestTimes[operation] = completionTime;
          }

          // Update difficulty-specific best time
          if (difficulty != null) {
            final difficultyKey = '$operation-${difficulty.toLowerCase()}';
            final currentBest = difficultyBestTimes[difficultyKey] ?? 999999;
            if (completionTime < currentBest) {
              difficultyBestTimes[difficultyKey] = completionTime;
            }
          }
        }
      }

      // Filter out any operations with no recorded times
      final filteredBestTimes = <String, int>{};
      bestTimes.forEach((op, time) {
        if (time < 999999) {
          filteredBestTimes[op] = time;
        }
      });

      // Merge the overall and difficulty-specific best times
      filteredBestTimes.addAll(difficultyBestTimes);

      // Only update if we have any valid times
      if (filteredBestTimes.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'bestTimes': filteredBestTimes,
        });
      }
    } catch (e) {
      print('Error updating best completion times: $e');
    }
  }

  // Get user's rank by completion time for a specific operation and difficulty
  Future<int> getUserRankByTimeAndDifficulty(
      String operation, String difficulty, String userId) async {
    try {
      final timeKey = '$operation-${difficulty.toLowerCase()}';

      // Get the user's best time
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};
      final userTime = bestTimes[timeKey] ?? bestTimes[operation] ?? 0;

      // If user has no recorded time, return 0 rank
      if (userTime == 0) return 0;

      // Count users with better (smaller) times
      final count = await _firestore
          .collection('users')
          .where('bestTimes.$timeKey', isLessThan: userTime)
          .count()
          .get();

      // Rank is count of users with better times + 1
      return count.count! + 1;
    } catch (e) {
      print('Error getting user rank by time and difficulty: $e');
      return 0;
    }
  }
}