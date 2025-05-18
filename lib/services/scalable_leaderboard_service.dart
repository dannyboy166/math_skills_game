// lib/services/scalable_leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_skills_game/models/leaderboard_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScalableLeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const int TOP_ENTRIES_LIMIT = 100; // Number of top entries to maintain
  static const int MIN_UPDATE_INTERVAL_MINUTES =
      15; // Minimum time between leaderboard updates

  // Leaderboard types
  static const String STREAK_LEADERBOARD = 'streaks';
  static const String GAMES_LEADERBOARD = 'gamesPlayed';
  static const String STARS_LEADERBOARD = 'stars';

  // Time-based leaderboards
  static const String ADDITION_TIME = 'additionTime';
  static const String SUBTRACTION_TIME = 'subtractionTime';
  static const String MULTIPLICATION_TIME = 'multiplicationTime';
  static const String DIVISION_TIME = 'divisionTime';

  // Shared preferences keys
  static const String LAST_LEADERBOARD_UPDATE_KEY = 'last_leaderboard_update';
  static const String CACHED_USER_RANKS_KEY = 'cached_user_ranks';

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
      // Try to get cached rank data first
      final prefs = await SharedPreferences.getInstance();
      final cachedRanksJson = prefs.getString(CACHED_USER_RANKS_KEY);

      if (cachedRanksJson != null) {
        try {
          final Map<String, dynamic> cachedRanks = Map<String, dynamic>.from(
              Map<String, dynamic>.from(json.decode(cachedRanksJson)));

          if (cachedRanks.containsKey(leaderboardType)) {
            final leaderboardData = cachedRanks[leaderboardType];
            if (leaderboardData is Map<String, dynamic> &&
                leaderboardData.containsKey('rank')) {
              return leaderboardData;
            }
          }
        } catch (e) {
          print('Error parsing cached ranks: $e');
          // Continue to fetch from Firestore
        }
      }

      final docSnapshot = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .collection('entries')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        return {'rank': 0, 'data': null};
      }

      final result = {
        'rank': docSnapshot.data()?['rank'] ?? 0,
        'data': docSnapshot.data(),
      };

      // Cache this result
      _cacheUserRank(userId, leaderboardType, result);

      return result;
    } catch (e) {
      print('Error fetching user leaderboard data: $e');
      return {'rank': 0, 'data': null};
    }
  }

  Future<void> _cacheUserRank(String userId, String leaderboardType,
      Map<String, dynamic> rankData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRanksJson = prefs.getString(CACHED_USER_RANKS_KEY);

      Map<String, dynamic> cachedRanks = {};
      if (cachedRanksJson != null) {
        try {
          cachedRanks = Map<String, dynamic>.from(json.decode(cachedRanksJson));
        } catch (e) {
          print('Error parsing cached ranks: $e');
          cachedRanks = {};
        }
      }

      if (!cachedRanks.containsKey(userId)) {
        cachedRanks[userId] = {};
      }

      // Create a sanitized copy of rankData that doesn't include Timestamp objects
      Map<String, dynamic> sanitizedRankData = {};
      rankData.forEach((key, value) {
        if (key == 'data' && value != null) {
          // Clone the data but convert Timestamp objects to ISO strings
          Map<String, dynamic> cleanData = {};
          (value as Map<String, dynamic>).forEach((dataKey, dataValue) {
            if (dataValue is Timestamp) {
              cleanData[dataKey] = dataValue.toDate().toIso8601String();
            } else {
              cleanData[dataKey] = dataValue;
            }
          });
          sanitizedRankData[key] = cleanData;
        } else {
          sanitizedRankData[key] = value;
        }
      });

      cachedRanks[userId][leaderboardType] = sanitizedRankData;

      await prefs.setString(CACHED_USER_RANKS_KEY, json.encode(cachedRanks));
    } catch (e) {
      print('Error caching user rank: $e');
    }
  }

  Future<void> updateUserInAllLeaderboards(String userId,
      {bool isHighScore = false}) async {
    try {
      // Check if we need to throttle updates
      print("updateUserInAllLeaderboards called with isHighScore=$isHighScore");

      if (!await _shouldUpdateLeaderboards(userId, isHighScore: isHighScore)) {
        print('Skipping leaderboard update due to throttling');
        return;
      }

      // Get user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;

      // Check for significant changes that warrant an update
      if (!isHighScore &&
          !await _hasSignificantLeaderboardChanges(userId, userData)) {
        print('Skipping leaderboard update - no significant changes');
        return;
      }

      // Create a single batch for all leaderboard updates
      final batch = _firestore.batch();
      int batchCount = 0;

      // Process streak leaderboard
      batchCount = await _prepareStreakLeaderboardBatch(
          userId, userData, batch, batchCount);

      // Process games played leaderboard
      batchCount = await _prepareGamesLeaderboardBatch(
          userId, userData, batch, batchCount);

      // Process stars leaderboard
      batchCount = await _prepareStarsLeaderboardBatch(
          userId, userData, batch, batchCount);

      // Process time-based leaderboards
      batchCount = await _prepareTimeLeaderboardsBatch(
          userId, userData, batch, batchCount,
          isHighScore: isHighScore);

      // Only commit if we have operations to perform
      if (batchCount > 0) {
        await batch.commit();
        print(
            'Updated leaderboards for user $userId with $batchCount operations');

        // Record the update time
        await _recordLeaderboardUpdate(userId);
      }
    } catch (e) {
      print('Error updating user in leaderboards: $e');
    }
  }

  Future<bool> _shouldUpdateLeaderboards(String userId,
      {bool isHighScore = false}) async {
    // Add this debug print
    print("_shouldUpdateLeaderboards called with isHighScore=$isHighScore");

    // Immediately allow updates for high scores
    if (isHighScore) {
      print("Bypassing throttling for high score update");
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr =
          prefs.getString('${LAST_LEADERBOARD_UPDATE_KEY}_$userId');

      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final now = DateTime.now();
        final minutesSinceLastUpdate = now.difference(lastUpdate).inMinutes;

        // Allow immediate updates for players with fewer than 5 games
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        final totalGames = userData?['totalGames'] ?? 0;

        if (totalGames < 5) {
          return true;
        }

        return minutesSinceLastUpdate >= MIN_UPDATE_INTERVAL_MINUTES;
      }

      return true; // No record of previous update
    } catch (e) {
      print('Error checking update throttle: $e');
      return true; // Default to allowing updates if we can't check
    }
  }

  Future<void> _recordLeaderboardUpdate(String userId,
      {bool isHighScore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only record the timestamp if it's not a high score
      if (!isHighScore) {
        await prefs.setString('${LAST_LEADERBOARD_UPDATE_KEY}_$userId',
            DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error recording leaderboard update: $e');
    }
  }

  // Check if there are significant changes that warrant a leaderboard update
  Future<bool> _hasSignificantLeaderboardChanges(
      String userId, Map<String, dynamic> userData) async {
    try {
      // Get user's current entries in leaderboards
      final streakData =
          await getUserLeaderboardData(userId, STREAK_LEADERBOARD);
      final gamesData = await getUserLeaderboardData(userId, GAMES_LEADERBOARD);
      final starsData = await getUserLeaderboardData(userId, STARS_LEADERBOARD);

      // Current values from user data
      final newLongestStreak =
          (userData['streakData'] as Map<String, dynamic>?)?['longestStreak'] ??
              0;
      final newTotalGames = userData['totalGames'] ?? 0;
      final newTotalStars = userData['totalStars'] ?? 0;

      // Previous values from leaderboard
      final oldLongestStreak = streakData['data']?['longestStreak'] ?? 0;
      final oldTotalGames = gamesData['data']?['totalGames'] ?? 0;
      final oldTotalStars = starsData['data']?['totalStars'] ?? 0;

      // Calculate percentage changes
      double streakChange = oldLongestStreak > 0
          ? (newLongestStreak - oldLongestStreak) / oldLongestStreak
          : (newLongestStreak > 0 ? 1.0 : 0.0);

      double gamesChange = oldTotalGames > 0
          ? (newTotalGames - oldTotalGames) / oldTotalGames
          : (newTotalGames > 0 ? 1.0 : 0.0);

      double starsChange = oldTotalStars > 0
          ? (newTotalStars - oldTotalStars) / oldTotalStars
          : (newTotalStars > 0 ? 1.0 : 0.0);

      // Check for time-based leaderboard changes
      bool hasNewBestTime = await _checkForNewBestTimes(userId, userData);

      // Update if any metric has changed by more than 10% or if there's a new best time
      // Also always update if it's a new player (total games <= 10)
      return newTotalGames <= 10 ||
          streakChange >= 0.1 ||
          gamesChange >= 0.1 ||
          starsChange >= 0.1 ||
          hasNewBestTime;
    } catch (e) {
      print('Error checking for significant changes: $e');
      return true; // Default to allowing updates if we can't check
    }
  }

  // Check if user has new best times since last update
  Future<bool> _checkForNewBestTimes(
      String userId, Map<String, dynamic> userData) async {
    try {
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // If no best times, no need to update
      if (bestTimes.isEmpty) return false;

      // Check each operation
      for (final operation in [
        'addition',
        'subtraction',
        'multiplication',
        'division'
      ]) {
        final bestTime = bestTimes[operation] as int? ?? 0;
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

        // Get current time in leaderboard
        final timeData = await getUserLeaderboardData(userId, leaderboardType);
        final oldBestTime = timeData['data']?['bestTime'] ?? 0;

        // If time improved (lower is better), update
        if (oldBestTime == 0 || bestTime < oldBestTime) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking for new best times: $e');
      return false;
    }
  }

  // Prepare streak leaderboard batch operations
  Future<int> _prepareStreakLeaderboardBatch(String userId,
      Map<String, dynamic> userData, WriteBatch batch, int batchCount) async {
    try {
      final streakData = userData['streakData'] as Map<String, dynamic>? ?? {};
      final longestStreak = streakData['longestStreak'] ?? 0;
      final currentStreak = streakData['currentStreak'] ?? 0;

      // Only update if the user has a streak
      if (longestStreak > 0 || currentStreak > 0) {
        // Get current rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .where('longestStreak', isGreaterThan: longestStreak)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Add to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(STREAK_LEADERBOARD)
                .collection('entries')
                .doc(userId),
            {
              'userId': userId,
              'displayName': userData['displayName'] ?? 'Unknown',
              'longestStreak': longestStreak,
              'currentStreak': currentStreak,
              'level': userData['level'] ?? 'Novice',
              'rank': newRank,
              'updatedAt': FieldValue.serverTimestamp(),
              'operationCounts': userData['completedGames'] ?? {},
            });

        return batchCount + 1;
      }

      return batchCount;
    } catch (e) {
      print('Error preparing streak leaderboard batch: $e');
      return batchCount;
    }
  }

  // Prepare games leaderboard batch operations
  Future<int> _prepareGamesLeaderboardBatch(String userId,
      Map<String, dynamic> userData, WriteBatch batch, int batchCount) async {
    try {
      final totalGames = userData['totalGames'] ?? 0;

      // Only update if the user has played games
      if (totalGames > 0) {
        // Get current rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(GAMES_LEADERBOARD)
            .collection('entries')
            .where('totalGames', isGreaterThan: totalGames)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Add to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(GAMES_LEADERBOARD)
                .collection('entries')
                .doc(userId),
            {
              'userId': userId,
              'displayName': userData['displayName'] ?? 'Unknown',
              'totalGames': totalGames,
              'level': userData['level'] ?? 'Novice',
              'operationCounts': userData['completedGames'] ?? {},
              'rank': newRank,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        return batchCount + 1;
      }

      return batchCount;
    } catch (e) {
      print('Error preparing games leaderboard batch: $e');
      return batchCount;
    }
  }

  // Prepare stars leaderboard batch operations
  Future<int> _prepareStarsLeaderboardBatch(String userId,
      Map<String, dynamic> userData, WriteBatch batch, int batchCount) async {
    try {
      final totalStars = userData['totalStars'] ?? 0;

      // Only update if the user has stars
      if (totalStars > 0) {
        // Get current rank
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

        // Add to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(STARS_LEADERBOARD)
                .collection('entries')
                .doc(userId),
            {
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

        return batchCount + 1;
      }

      return batchCount;
    } catch (e) {
      print('Error preparing stars leaderboard batch: $e');
      return batchCount;
    }
  }

// Prepare time leaderboards batch operations
  Future<int> _prepareTimeLeaderboardsBatch(String userId,
      Map<String, dynamic> userData, WriteBatch batch, int batchCount,
      {bool isHighScore = false}) async {
    try {
      // If we already know it's a high score, skip the checking
      if (isHighScore) {
        print("Processing confirmed high score update!");
      }

      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};
      int localBatchCount = batchCount;

      // Skip if no times
      if (bestTimes.isEmpty) return localBatchCount;

      // Process operations
      for (final operation in [
        'addition',
        'subtraction',
        'multiplication',
        'division'
      ]) {
        final bestTime = bestTimes[operation] as int? ?? 0;
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

        bool shouldUpdate =
            isHighScore; // Update if we already know it's a high score

        if (!shouldUpdate) {
          // Check if this is an improvement over previous time
          final existingData =
              await getUserLeaderboardData(userId, leaderboardType);
          final existingTime = existingData['data']?['bestTime'] ?? 0;

          // Only update if it's an improvement (lower is better for time)
          shouldUpdate = existingTime == 0 || bestTime < existingTime;
        }

        // Skip if not needed
        if (!shouldUpdate) continue;

        // Get current rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .collection('entries')
            .where('bestTime', isLessThan: bestTime)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Add to batch
        batch.set(
            _firestore
                .collection('leaderboards')
                .doc(leaderboardType)
                .collection('entries')
                .doc(userId),
            {
              'userId': userId,
              'displayName': userData['displayName'] ?? 'Unknown',
              'bestTime': bestTime,
              'level': userData['level'] ?? 'Novice',
              'rank': newRank,
              'difficulty': 'All',
              'updatedAt': FieldValue.serverTimestamp(),
            });

        localBatchCount++;

        // Only update difficulty leaderboards if we actually updated the main one
        localBatchCount = await _prepareDifficultyTimeLeaderboardsBatch(userId,
            userData, operation, leaderboardType, batch, localBatchCount,
            isHighScore: isHighScore);
      }

      return localBatchCount;
    } catch (e) {
      print('Error preparing time leaderboards batch: $e');
      return batchCount;
    }
  }

// Prepare difficulty-specific time leaderboards batch operations
  Future<int> _prepareDifficultyTimeLeaderboardsBatch(
      String userId,
      Map<String, dynamic> userData,
      String operation,
      String leaderboardType,
      WriteBatch batch,
      int batchCount,
      {bool isHighScore = false}) async {
    try {
      // If we know it's a high score, print a debug message
      if (isHighScore) {
        print(
            "Processing difficulty-specific high score update for $operation");
      }

      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};
      int localBatchCount = batchCount;

      // Process each difficulty
      for (final difficulty in [
        'standard',
        'challenging',
        'expert',
        'impossible'
      ]) {
        final difficultyKey = '$operation-$difficulty';
        final bestTime = bestTimes[difficultyKey] as int? ?? 0;
        if (bestTime <= 0) continue;

        // Define the document reference
        final docRef = _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .collection('difficulties')
            .doc(difficulty)
            .collection('entries')
            .doc(userId);

        bool shouldUpdate =
            isHighScore; // Update if we already know it's a high score

        if (!shouldUpdate) {
          // Check if this is an improvement
          final existingDoc = await docRef.get();
          if (existingDoc.exists) {
            final existingTime = existingDoc.data()?['bestTime'] ?? 0;
            shouldUpdate = existingTime == 0 || bestTime < existingTime;
          } else {
            // No existing entry, so this is a new best time
            shouldUpdate = true;
          }
        }

        // Skip if not needed
        if (!shouldUpdate) continue;

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

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Add to batch
        batch.set(docRef, {
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown',
          'bestTime': bestTime,
          'level': userData['level'] ?? 'Novice',
          'rank': newRank,
          'difficulty': difficulty.substring(0, 1).toUpperCase() +
              difficulty.substring(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
            "Adding difficulty-specific leaderboard update for $operation-$difficulty: $bestTime ms");
        localBatchCount++;
      }

      return localBatchCount;
    } catch (e) {
      print('Error preparing difficulty time leaderboards batch: $e');
      return batchCount;
    }
  }

  Future<void> updateUserInStreakLeaderboard(String userId,
      {bool isHighScore = false}) async {
    try {
      // Check if we need to throttle updates
      if (!await _shouldUpdateLeaderboards(userId, isHighScore: isHighScore)) {
        print('Skipping streak leaderboard update due to throttling');
        return;
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final streakData = userData['streakData'] as Map<String, dynamic>? ?? {};
      final longestStreak = streakData['longestStreak'] ?? 0;
      final currentStreak = streakData['currentStreak'] ?? 0;

      // Get existing leaderboard entry
      final existingData =
          await getUserLeaderboardData(userId, STREAK_LEADERBOARD);
      final existingLongestStreak = existingData['data']?['longestStreak'] ?? 0;
      final existingCurrentStreak = existingData['data']?['currentStreak'] ?? 0;

      // Only update if there's a significant change in streak
      if (longestStreak > existingLongestStreak ||
          (currentStreak > 0 && currentStreak != existingCurrentStreak)) {
        // Get current rank
        final rankSnapshot = await _firestore
            .collection('leaderboards')
            .doc(STREAK_LEADERBOARD)
            .collection('entries')
            .where('longestStreak', isGreaterThan: longestStreak)
            .count()
            .get();

        final newRank = (rankSnapshot.count ?? 0) + 1;

        // Update streak leaderboard
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

        // Record the update
        await _recordLeaderboardUpdate(userId);
      } else {
        print('Skipping streak update - no significant changes');
      }
    } catch (e) {
      print('Error updating streak leaderboard: $e');
    }
  }

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
  } // Method to refresh all leaderboards

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
  Future<DateTime?> getLeaderboardLastUpdateTime(String leaderboardType) async {
    try {
      final docSnap = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .get();

      if (docSnap.exists) {
        // Try both 'lastUpdated' and 'updatedAt' fields
        Timestamp? timestamp;
        if (docSnap.data()!.containsKey('lastUpdated')) {
          timestamp = docSnap.data()?['lastUpdated'] as Timestamp?;
        } else if (docSnap.data()!.containsKey('updatedAt')) {
          timestamp = docSnap.data()?['updatedAt'] as Timestamp?;
        }
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      print('Error getting leaderboard last update time: $e');
      return null;
    }
  }
}
