// lib/services/leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch top users by total stars
  Future<List<LeaderboardEntry>> getTopUsersByStars({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('totalStars', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => LeaderboardEntry.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard by stars: $e');
      rethrow;
    }
  }

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

  // NEW METHOD: Get top users by best completion time for an operation
  Future<List<LeaderboardEntry>> getTopUsersByBestTime(String operation,
      {int limit = 20}) async {
    try {
      // First, find all users with completion times for this operation
      final usersWithTimes = await _firestore
          .collection('users')
          .where('bestTimes.$operation', isGreaterThan: 0)
          .orderBy('bestTimes.$operation', descending: false) // Ascending by time (faster is better)
          .limit(limit)
          .get();

      if (usersWithTimes.docs.isEmpty) {
        // If no users have recorded best times yet, fall back to users who have played this operation
        final usersByOperation = await getTopUsersByOperation(operation, limit: limit);
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

  // Get current user's rank by stars
  Future<int> getCurrentUserRankByStars() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      // Get current user's data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userStars = userData['totalStars'] ?? 0;

      // Count users with more stars
      final count = await _firestore
          .collection('users')
          .where('totalStars', isGreaterThan: userStars)
          .count()
          .get();

      // Rank is count of users with more stars + 1
      return count.count! + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // NEW METHOD: Get user's rank by completion time for a specific operation
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

      // Calculate and update operation stars
      await _updateOperationStars(userId);
      
      // Update best completion times
      await _updateBestCompletionTimes(userId);
    } catch (e) {
      print('Error updating user ranking data: $e');
    }
  }

  Future<void> _updateOperationStars(String userId) async {
    try {
      // Get all level completions
      final completions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levelCompletions')
          .get();

      // Operation stars map
      final operationStars = {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0
      };

      // Count stars for each operation
      for (final doc in completions.docs) {
        final data = doc.data();
        final operation = data['operationName'] as String?;
        final stars = data['stars'] as int?;

        if (operation != null &&
            stars != null &&
            operationStars.containsKey(operation)) {
          operationStars[operation] = (operationStars[operation] ?? 0) + stars;
        }
      }

      // Update the user's document
      await _firestore.collection('users').doc(userId).update({
        'gameStats': {
          'additionStars': operationStars['addition'],
          'subtractionStars': operationStars['subtraction'],
          'multiplicationStars': operationStars['multiplication'],
          'divisionStars': operationStars['division'],
          'lastCalculated': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('Error updating operation stars: $e');
    }
  }

  // NEW METHOD: Update the user's best completion times for each operation
  Future<void> _updateBestCompletionTimes(String userId) async {
    try {
      // Get all level completions
      final completions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levelCompletions')
          .get();

      // Track best times for each operation
      final bestTimes = {
        'addition': 999999,
        'subtraction': 999999,
        'multiplication': 999999,
        'division': 999999
      };

      // Find best (lowest) completion time for each operation
      for (final doc in completions.docs) {
        final data = doc.data();
        final operation = data['operationName'] as String?;
        final completionTime = data['completionTimeMs'] as int?;

        if (operation != null && 
            completionTime != null && 
            bestTimes.containsKey(operation)) {
          if (completionTime < bestTimes[operation]!) {
            bestTimes[operation] = completionTime;
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
}