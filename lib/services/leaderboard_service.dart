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
}
