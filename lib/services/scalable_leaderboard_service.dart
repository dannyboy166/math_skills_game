// lib/services/scalable_leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_skills_game/models/leaderboard_entry.dart';

class ScalableLeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const int TOP_ENTRIES_LIMIT = 100; // Number of top entries to maintain

  // Leaderboard types
  static const String STREAK_LEADERBOARD = 'streaks';
  static const String GAMES_LEADERBOARD = 'gamesPlayed';
  static const String STARS_LEADERBOARD = 'stars';

  // Time-based leaderboards
  static const String ADDITION_TIME = 'additionTime';
  static const String SUBTRACTION_TIME = 'subtractionTime';
  static const String MULTIPLICATION_TIME = 'multiplicationTime';
  static const String DIVISION_TIME = 'divisionTime';

// Add this method to your ScalableLeaderboardService class
  Future<List<LeaderboardEntry>> getTopEntriesForDifficulty(
      String leaderboardType, String difficulty, int limit) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .collection('difficulties')
          .doc(difficulty)
          .collection('entries')
          .orderBy('rank')
          .limit(limit)
          .get();

      // Convert to LeaderboardEntry objects
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        final bestTime = data['bestTime'] as int? ?? 0;
        final difficultyKey =
            '${_getOperationFromLeaderboardType(leaderboardType)}-$difficulty';

        // Create best times map with both operation and difficulty times
        final bestTimes = <String, int>{};
        // Add the operation-specific time
        bestTimes[_getOperationFromLeaderboardType(leaderboardType)] = bestTime;
        // Add the difficulty-specific time
        bestTimes[difficultyKey] = bestTime;

        // Handle lastUpdated with proper null checking
        DateTime lastUpdated;
        if (data['updatedAt'] != null) {
          try {
            lastUpdated = (data['updatedAt'] as Timestamp).toDate();
          } catch (e) {
            print('Error converting updatedAt timestamp: $e');
            lastUpdated = DateTime.now();
          }
        } else {
          lastUpdated = DateTime.now();
        }

        return LeaderboardEntry(
          userId: doc.id,
          displayName: data['displayName'] ?? 'Unknown',
          totalStars: data['totalStars'] ?? 0,
          totalGames: data['totalGames'] ?? 0,
          longestStreak: data['longestStreak'] ?? 0,
          operationCounts: Map<String, int>.from(data['operationCounts'] ?? {}),
          operationStars: Map<String, int>.from(data['operationStars'] ?? {}),
          bestTimes: bestTimes,
          level: data['level'] ?? 'Novice',
          lastUpdated: lastUpdated,
        );
      }).toList();

      return entries;
    } catch (e) {
      print('Error fetching difficulty-specific leaderboard entries: $e');
      return [];
    }
  }

// Helper to extract operation name from leaderboard type
  String _getOperationFromLeaderboardType(String leaderboardType) {
    switch (leaderboardType) {
      case ADDITION_TIME:
        return 'addition';
      case SUBTRACTION_TIME:
        return 'subtraction';
      case MULTIPLICATION_TIME:
        return 'multiplication';
      case DIVISION_TIME:
        return 'division';
      default:
        return 'addition';
    }
  }

  Future<List<LeaderboardEntry>> getTopLeaderboardEntries(
      String leaderboardType,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .collection('entries')
          .orderBy('rank')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Create a map for best times
        final Map<String, int> bestTimes = {};

        // If this is a time-based leaderboard, add the time to bestTimes map
        if (leaderboardType == ADDITION_TIME ||
            leaderboardType == SUBTRACTION_TIME ||
            leaderboardType == MULTIPLICATION_TIME ||
            leaderboardType == DIVISION_TIME) {
          final operation = _getOperationFromLeaderboardType(leaderboardType);
          final bestTime = data['bestTime'] as int? ?? 0;

          // Store the time using the operation as key
          if (bestTime > 0) {
            bestTimes[operation] = bestTime;
          }
        } else if (data['bestTimes'] != null) {
          // For other leaderboards, include any bestTimes from the data
          bestTimes.addAll(Map<String, int>.from(data['bestTimes'] ?? {}));
        }

        // Handle lastUpdated with proper null checking
        DateTime lastUpdated;
        if (data['updatedAt'] != null) {
          try {
            lastUpdated = (data['updatedAt'] as Timestamp).toDate();
          } catch (e) {
            print('Error converting updatedAt timestamp: $e');
            lastUpdated = DateTime.now();
          }
        } else {
          lastUpdated = DateTime.now();
        }

        // Convert to LeaderboardEntry for compatibility with existing UI
        return LeaderboardEntry(
          userId: doc.id,
          displayName: data['displayName'] ?? 'Unknown',
          totalStars: data['totalStars'] ?? 0,
          totalGames: data['totalGames'] ?? 0,
          longestStreak: data['longestStreak'] ?? 0,
          operationCounts: Map<String, int>.from(data['operationCounts'] ?? {}),
          operationStars: Map<String, int>.from(data['operationStars'] ?? {}),
          bestTimes: bestTimes,
          level: data['level'] ?? 'Novice',
          lastUpdated: lastUpdated,
        );
      }).toList();
    } catch (e) {
      print('Error fetching leaderboard entries: $e');
      return [];
    }
  }

  // Get user's rank and data from a leaderboard
  Future<Map<String, dynamic>> getUserLeaderboardData(
      String userId, String leaderboardType) async {
    try {
      final docSnapshot = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .collection('entries')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        return {'rank': 0, 'data': null};
      }

      return {
        'rank': docSnapshot.data()?['rank'] ?? 0,
        'data': docSnapshot.data(),
      };
    } catch (e) {
      print('Error fetching user leaderboard data: $e');
      return {'rank': 0, 'data': null};
    }
  }

  // Update all leaderboards for a single user
  Future<void> updateUserInAllLeaderboards(String userId) async {
    try {
      // Get user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;

      // Update user in streak leaderboard
      await _updateUserInStreakLeaderboard(userId, userData);

      // Update user in games played leaderboard
      await _updateUserInGamesLeaderboard(userId, userData);

      // Update user in stars leaderboard
      await _updateUserInStarsLeaderboard(userId, userData);

      // Update user in time-based leaderboards
      await _updateUserInTimeLeaderboards(userId, userData);
    } catch (e) {
      print('Error updating user in leaderboards: $e');
    }
  }

  // Helper method to update streak leaderboard
  Future<void> _updateUserInStreakLeaderboard(
      String userId, Map<String, dynamic> userData) async {
    try {
      final streakData = userData['streakData'] as Map<String, dynamic>? ?? {};
      final longestStreak = streakData['longestStreak'] ?? 0;

      // Only update if the user has a streak
      if (longestStreak > 0) {
        // Get current top entries to determine rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .where('longestStreak', isGreaterThan: longestStreak)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Update or add user to leaderboard
        await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'longestStreak': longestStreak,
          'currentStreak': streakData['currentStreak'] ?? 0,
          'level': userData['level'] ?? 'Novice',
          'rank': newRank,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating streak leaderboard: $e');
    }
  }

  // Helper method to update games played leaderboard
  Future<void> _updateUserInGamesLeaderboard(
      String userId, Map<String, dynamic> userData) async {
    try {
      final totalGames = userData['totalGames'] ?? 0;

      // Only update if the user has played games
      if (totalGames > 0) {
        // Get current top entries to determine rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(GAMES_LEADERBOARD)
            .collection('entries')
            .where('totalGames', isGreaterThan: totalGames)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Update or add user to leaderboard
        await _firestore
            .collection('leaderboards')
            .doc(GAMES_LEADERBOARD)
            .collection('entries')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'totalGames': totalGames,
          'level': userData['level'] ?? 'Novice',
          'operationCounts': userData['completedGames'] ?? {},
          'rank': newRank,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating games leaderboard: $e');
    }
  }

  // Helper method to update stars leaderboard
  Future<void> _updateUserInStarsLeaderboard(
      String userId, Map<String, dynamic> userData) async {
    try {
      final totalStars = userData['totalStars'] ?? 0;

      // Only update if the user has stars
      if (totalStars > 0) {
        // Get current top entries to determine rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(STARS_LEADERBOARD)
            .collection('entries')
            .where('totalStars', isGreaterThan: totalStars)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Extract operation stars
        final gameStats = userData['gameStats'] as Map<String, dynamic>? ?? {};

        // Update or add user to leaderboard
        await _firestore
            .collection('leaderboards')
            .doc(STARS_LEADERBOARD)
            .collection('entries')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'totalStars': totalStars,
          'level': userData['level'] ?? 'Novice',
          'operationStars': {
            'addition': gameStats['additionStars'] ?? 0,
            'subtraction': gameStats['subtractionStars'] ?? 0,
            'multiplication': gameStats['multiplicationStars'] ?? 0,
            'division': gameStats['divisionStars'] ?? 0,
          },
          'rank': newRank,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating stars leaderboard: $e');
    }
  }

  // Helper method to update time-based leaderboards
  Future<void> _updateUserInTimeLeaderboards(
      String userId, Map<String, dynamic> userData) async {
    try {
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // Only proceed if user has time records
      if (bestTimes.isNotEmpty) {
        // Update each operation leaderboard
        final operations = [
          'addition',
          'subtraction',
          'multiplication',
          'division'
        ];

        for (final operation in operations) {
          final bestTime = bestTimes[operation] as int? ?? 0;

          // Skip if no best time
          if (bestTime <= 0) continue;

          // Determine leaderboard type
          String leaderboardType;
          switch (operation) {
            case 'addition':
              leaderboardType = ADDITION_TIME;
              break;
            case 'subtraction':
              leaderboardType = SUBTRACTION_TIME;
              break;
            case 'multiplication':
              leaderboardType = MULTIPLICATION_TIME;
              break;
            case 'division':
              leaderboardType = DIVISION_TIME;
              break;
            default:
              continue;
          }

          // Get current rank
          final rankSnapshot = await _firestore
              .collection('leaderboards')
              .doc(leaderboardType)
              .collection('entries')
              .where('bestTime',
                  isLessThan: bestTime) // Lower is better for time
              .count()
              .get();

          final newRank = (rankSnapshot.count ?? 0) + 1;

          // Update or add user to leaderboard
          await _firestore
              .collection('leaderboards')
              .doc(leaderboardType)
              .collection('entries')
              .doc(userId)
              .set({
            'userId': userId,
            'displayName': userData['displayName'] ?? 'Unknown',
            'bestTime': bestTime,
            'level': userData['level'] ?? 'Novice',
            'rank': newRank,
            'difficulty': 'All', // Default for overall time
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Also update difficulty-specific times
          await _updateUserDifficultyTimeLeaderboards(
              userId, userData, operation, leaderboardType);
        }
      }
    } catch (e) {
      print('Error updating time leaderboards: $e');
    }
  }

  // Helper for difficulty-specific time leaderboards
  Future<void> _updateUserDifficultyTimeLeaderboards(
      String userId,
      Map<String, dynamic> userData,
      String operation,
      String leaderboardType) async {
    try {
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // Check for difficulty-specific times
      final difficulties = ['standard', 'challenging', 'expert', 'impossible'];

      for (final difficulty in difficulties) {
        final difficultyKey = '$operation-$difficulty';
        final bestTime = bestTimes[difficultyKey] as int? ?? 0;

        // Skip if no time for this difficulty
        if (bestTime <= 0) continue;

        // Get current rank for this difficulty
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .collection('difficulties')
            .doc(difficulty)
            .collection('entries')
            .where('bestTime', isLessThan: bestTime)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Update or add user to difficulty leaderboard
        await _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .collection('difficulties')
            .doc(difficulty)
            .collection('entries')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'bestTime': bestTime,
          'level': userData['level'] ?? 'Novice',
          'rank': newRank,
          'difficulty': difficulty.substring(0, 1).toUpperCase() +
              difficulty.substring(1), // Capitalize
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating difficulty time leaderboards: $e');
    }
  }

  // Method to refresh all leaderboards
  Future<void> refreshAllLeaderboards() async {
    await _refreshLeaderboard(
        STREAK_LEADERBOARD, 'streakData.longestStreak', true);
    await _refreshLeaderboard(GAMES_LEADERBOARD, 'totalGames', true);
    await _refreshLeaderboard(STARS_LEADERBOARD, 'totalStars', true);

    // Time leaderboards (lower is better)
    await _refreshTimeLeaderboard(ADDITION_TIME, 'addition');
    await _refreshTimeLeaderboard(SUBTRACTION_TIME, 'subtraction');
    await _refreshTimeLeaderboard(MULTIPLICATION_TIME, 'multiplication');
    await _refreshTimeLeaderboard(DIVISION_TIME, 'division');
  }

  // Add this method to your ScalableLeaderboardService class

// Directly update streak leaderboard for a specific user
  Future<void> updateUserInStreakLeaderboard(String userId) async {
    try {
      // Get user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final streakData = userData['streakData'] as Map<String, dynamic>? ?? {};
      final longestStreak = streakData['longestStreak'] ?? 0;
      final currentStreak = streakData['currentStreak'] ?? 0;

      // Only update if the user has a streak
      if (longestStreak > 0 || currentStreak > 0) {
        // Get current top entries to determine rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .where('longestStreak', isGreaterThan: longestStreak)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Update or add user to leaderboard
        await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .doc(userId)
            .set({
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'longestStreak': longestStreak,
          'currentStreak': currentStreak,
          'level': userData['level'] ?? 'Novice',
          'rank': newRank,
          'updatedAt': FieldValue.serverTimestamp(),
          'operationCounts': userData['completedGames'] ?? {},
        });

        print('Streak leaderboard updated for user: $userId');
      }
    } catch (e) {
      print('Error updating streak leaderboard: $e');
    }
  }

  // Helper to refresh a standard leaderboard
  Future<void> _refreshLeaderboard(
      String leaderboardType, String sortField, bool descendingOrder) async {
    try {
      // Get top users
      final usersQuery = _firestore
          .collection('users')
          .orderBy(sortField, descending: descendingOrder)
          .limit(TOP_ENTRIES_LIMIT);

      final usersSnapshot = await usersQuery.get();

      // Create a batch for efficient writing
      var batch = _firestore.batch();
      int batchCount = 0;
      int rank = 1;

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();

        // Prepare entry data based on leaderboard type
        Map<String, dynamic> entryData = {
          'userId': userDoc.id,
          'displayName': userData['displayName'] ?? 'Unknown',
          'level': userData['level'] ?? 'Novice',
          'rank': rank,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add specific fields based on leaderboard type
        if (leaderboardType == STREAK_LEADERBOARD) {
          final streakData =
              userData['streakData'] as Map<String, dynamic>? ?? {};
          entryData['longestStreak'] = streakData['longestStreak'] ?? 0;
          entryData['currentStreak'] = streakData['currentStreak'] ?? 0;
        } else if (leaderboardType == GAMES_LEADERBOARD) {
          entryData['totalGames'] = userData['totalGames'] ?? 0;
          entryData['operationCounts'] = userData['completedGames'] ?? {};
        } else if (leaderboardType == STARS_LEADERBOARD) {
          entryData['totalStars'] = userData['totalStars'] ?? 0;

          final gameStats =
              userData['gameStats'] as Map<String, dynamic>? ?? {};
          entryData['operationStars'] = {
            'addition': gameStats['additionStars'] ?? 0,
            'subtraction': gameStats['subtractionStars'] ?? 0,
            'multiplication': gameStats['multiplicationStars'] ?? 0,
            'division': gameStats['divisionStars'] ?? 0,
          };
        }

        // Add to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(leaderboardType)
                .collection('entries')
                .doc(userDoc.id),
            entryData);

        batchCount++;
        rank++;

        // Commit batch when it reaches 500 operations (Firestore limit)
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error refreshing $leaderboardType leaderboard: $e');
    }
  }

  // Helper to refresh time-based leaderboards
  Future<void> _refreshTimeLeaderboard(
      String leaderboardType, String operation) async {
    try {
      // Get users with best times for this operation
      final usersQuery = _firestore
          .collection('users')
          .where('bestTimes.$operation', isGreaterThan: 0)
          .orderBy(
              'bestTimes.$operation') // Ascending for time (lower is better)
          .limit(TOP_ENTRIES_LIMIT);

      final usersSnapshot = await usersQuery.get();

      var batch = _firestore.batch();
      int batchCount = 0;
      int rank = 1;

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};
        final bestTime = bestTimes[operation] as int? ?? 0;

        if (bestTime > 0) {
          // Add to main time leaderboard
          batch.set(
              _firestore
                  .collection('leaderboards')
                  .doc(leaderboardType)
                  .collection('entries')
                  .doc(userDoc.id),
              {
                'userId': userDoc.id,
                'displayName': userData['displayName'] ?? 'Unknown',
                'bestTime': bestTime,
                'level': userData['level'] ?? 'Novice',
                'rank': rank,
                'difficulty': 'All',
                'updatedAt': FieldValue.serverTimestamp(),
              });

          batchCount++;
          rank++;

          // Commit batch if needed
          if (batchCount >= 500) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }

          // Also update difficulty-specific leaderboards
          await _refreshDifficultyTimeLeaderboard(
              leaderboardType, operation, userDoc.id, userData);
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error refreshing $leaderboardType leaderboard: $e');
    }
  }

  // Helper for difficulty-specific time leaderboards
  Future<void> _refreshDifficultyTimeLeaderboard(String leaderboardType,
      String operation, String userId, Map<String, dynamic> userData) async {
    try {
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // Handle each difficulty
      final difficulties = ['standard', 'challenging', 'expert', 'impossible'];

      for (final difficulty in difficulties) {
        final difficultyKey = '$operation-$difficulty';
        final bestTime = bestTimes[difficultyKey] as int? ?? 0;

        if (bestTime > 0) {
          // Get current rank
          final rankSnapshot = await _firestore
              .collection('leaderboards')
              .doc(leaderboardType)
              .collection('difficulties')
              .doc(difficulty)
              .collection('entries')
              .where('bestTime', isLessThan: bestTime)
              .count()
              .get();

          final rank = (rankSnapshot.count ?? 0) + 1;

          // Add to difficulty leaderboard
          await _firestore
              .collection('leaderboards')
              .doc(leaderboardType)
              .collection('difficulties')
              .doc(difficulty)
              .collection('entries')
              .doc(userId)
              .set({
            'userId': userId,
            'displayName': userData['displayName'] ?? 'Unknown',
            'bestTime': bestTime,
            'level': userData['level'] ?? 'Novice',
            'rank': rank,
            'difficulty': difficulty.substring(0, 1).toUpperCase() +
                difficulty.substring(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error refreshing difficulty time leaderboard: $e');
    }
  }
}
