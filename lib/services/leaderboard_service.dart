// lib/services/leaderboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  // Constants
  static const int TOP_ENTRIES_LIMIT = 100; // Number of top entries to maintain
  static const int MIN_UPDATE_INTERVAL_MINUTES =
      15; // Minimum time between leaderboard updates

  // Leaderboard types - SIMPLIFIED to just the ones we want to keep
  static const String GAMES_LEADERBOARD = 'gamesPlayed';

  // Time-based leaderboards
  static const String ADDITION_TIME = 'additionTime';
  static const String SUBTRACTION_TIME = 'subtractionTime';
  static const String MULTIPLICATION_TIME = 'multiplicationTime';
  static const String DIVISION_TIME = 'divisionTime';

  // Shared preferences keys
  static const String LAST_LEADERBOARD_UPDATE_KEY = 'last_leaderboard_update';
  static const String CACHED_USER_RANKS_KEY = 'cached_user_ranks';
  static const String CACHED_LEADERBOARD_KEY = 'cached_leaderboard';

  // Helper to get operation name from leaderboard type
  String getOperationFromLeaderboardType(String leaderboardType) {
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

  // Helper to get leaderboard type from operation
  String getLeaderboardTypeFromOperation(String operation) {
    switch (operation) {
      case 'addition':
        return ADDITION_TIME;
      case 'subtraction':
        return SUBTRACTION_TIME;
      case 'multiplication':
        return MULTIPLICATION_TIME;
      case 'division':
        return DIVISION_TIME;
      default:
        return ADDITION_TIME;
    }
  }

  // Get top entries for a specific difficulty
  Future<List<LeaderboardEntry>> getTopEntriesForDifficulty(
      String leaderboardType, String difficulty, int limit) async {
    try {
      // Try to get from cache first
      final entries =
          await _getFromCache('${leaderboardType}_${difficulty}_$limit');
      if (entries.isNotEmpty) {
        return entries;
      }

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
      final result = snapshot.docs.map((doc) {
        final data = doc.data();
        final bestTime = data['bestTime'] as int? ?? 0;
        final operationName = getOperationFromLeaderboardType(leaderboardType);
        final difficultyKey = '$operationName-$difficulty';

        // Create best times map with both operation and difficulty times
        final bestTimes = <String, int>{};
        // Add the operation-specific time
        bestTimes[operationName] = bestTime;
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
          operationCounts: Map<String, int>.from(data['operationCounts'] ?? {}),
          operationStars: Map<String, int>.from(data['operationStars'] ?? {}),
          bestTimes: bestTimes,
          level: data['level'] ?? 'Novice',
          lastUpdated: lastUpdated,
        );
      }).toList();

      // Cache the result
      _cacheLeaderboardEntries(
          '${leaderboardType}_${difficulty}_$limit', result);

      return result;
    } catch (e) {
      print('Error fetching difficulty-specific leaderboard entries: $e');
      return [];
    }
  }

  // Get top entries for a standard leaderboard
  Future<List<LeaderboardEntry>> getTopLeaderboardEntries(
      String leaderboardType,
      {int limit = 20}) async {
    try {
      // Try to get from cache first
      final entries = await _getFromCache('${leaderboardType}_$limit');
      if (entries.isNotEmpty) {
        return entries;
      }

      final snapshot = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .collection('entries')
          .orderBy('rank')
          .limit(limit)
          .get();

      final result = snapshot.docs.map((doc) {
        final data = doc.data();

        // Create a map for best times
        final Map<String, int> bestTimes = {};

        // If this is a time-based leaderboard, add the time to bestTimes map
        if (leaderboardType == ADDITION_TIME ||
            leaderboardType == SUBTRACTION_TIME ||
            leaderboardType == MULTIPLICATION_TIME ||
            leaderboardType == DIVISION_TIME) {
          final operation = getOperationFromLeaderboardType(leaderboardType);
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
          operationCounts: Map<String, int>.from(data['operationCounts'] ?? {}),
          operationStars: Map<String, int>.from(data['operationStars'] ?? {}),
          bestTimes: bestTimes,
          level: data['level'] ?? 'Novice',
          lastUpdated: lastUpdated,
        );
      }).toList();

      // Cache the result
      _cacheLeaderboardEntries('${leaderboardType}_$limit', result);

      return result;
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
              // Check if the cached data is still recent (less than 15 minutes old)
              final timestamp = leaderboardData['timestamp'];
              if (timestamp != null) {
                final cacheTime = DateTime.parse(timestamp);
                if (DateTime.now().difference(cacheTime).inMinutes <
                    MIN_UPDATE_INTERVAL_MINUTES) {
                  return leaderboardData;
                }
              }
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
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Cache this result
      _cacheUserRank(userId, leaderboardType, result);

      return result;
    } catch (e) {
      print('Error fetching user leaderboard data: $e');
      return {'rank': 0, 'data': null};
    }
  }

  // Cache user's rank data
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

      // Add timestamp for cache invalidation
      sanitizedRankData['timestamp'] = DateTime.now().toIso8601String();

      cachedRanks[userId][leaderboardType] = sanitizedRankData;

      await prefs.setString(CACHED_USER_RANKS_KEY, json.encode(cachedRanks));
    } catch (e) {
      print('Error caching user rank: $e');
    }
  }

  // Cache leaderboard entries
  Future<void> _cacheLeaderboardEntries(
      String cacheKey, List<LeaderboardEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'entries': entries.map((e) => _leaderboardEntryToJson(e)).toList(),
      };

      await prefs.setString(
          '$CACHED_LEADERBOARD_KEY.$cacheKey', json.encode(cacheData));
    } catch (e) {
      print('Error caching leaderboard entries: $e');
    }
  }

  // Get cached leaderboard entries
  Future<List<LeaderboardEntry>> _getFromCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$CACHED_LEADERBOARD_KEY.$cacheKey');

      if (cachedData != null) {
        final decoded = json.decode(cachedData);
        final timestamp = DateTime.parse(decoded['timestamp']);

        // Check if cache is still valid (less than 5 minutes old)
        if (DateTime.now().difference(timestamp).inMinutes < 5) {
          final entriesList = decoded['entries'] as List;
          return entriesList
              .map((e) =>
                  _leaderboardEntryFromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }

      return []; // Empty list indicates cache miss
    } catch (e) {
      print('Error getting cached leaderboard entries: $e');
      return [];
    }
  }

  // Helper for JSON serialization
  Map<String, dynamic> _leaderboardEntryToJson(LeaderboardEntry entry) {
    return {
      'userId': entry.userId,
      'displayName': entry.displayName,
      'totalStars': entry.totalStars,
      'totalGames': entry.totalGames,
      'operationCounts': entry.operationCounts,
      'operationStars': entry.operationStars,
      'bestTimes': entry.bestTimes,
      'level': entry.level,
      'lastUpdated': entry.lastUpdated.toIso8601String(),
    };
  }

  // Helper for JSON deserialization
  LeaderboardEntry _leaderboardEntryFromJson(Map<String, dynamic> json) {
    final operationCounts = <String, int>{};
    final operationStars = <String, int>{};
    final bestTimes = <String, int>{};

    if (json['operationCounts'] != null) {
      (json['operationCounts'] as Map).forEach((key, value) {
        operationCounts[key.toString()] = (value as num).toInt();
      });
    }

    if (json['operationStars'] != null) {
      (json['operationStars'] as Map).forEach((key, value) {
        operationStars[key.toString()] = (value as num).toInt();
      });
    }

    if (json['bestTimes'] != null) {
      (json['bestTimes'] as Map).forEach((key, value) {
        bestTimes[key.toString()] = (value as num).toInt();
      });
    }

    return LeaderboardEntry(
      userId: json['userId'],
      displayName: json['displayName'],
      totalStars: json['totalStars'],
      totalGames: json['totalGames'],
      operationCounts: operationCounts,
      operationStars: operationStars,
      bestTimes: bestTimes,
      level: json['level'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  // Check if an update should be allowed (throttling logic)
  Future<bool> shouldUpdateLeaderboard(String userId,
      {bool isHighScore = false}) async {
    try {
      // Always allow updates for high scores
      if (isHighScore) {
        print("Bypassing throttling for high score update");
        return true;
      }

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

  // Record a leaderboard update
  Future<void> recordLeaderboardUpdate(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${LAST_LEADERBOARD_UPDATE_KEY}_$userId',
          DateTime.now().toIso8601String());
    } catch (e) {
      print('Error recording leaderboard update: $e');
    }
  }

  // Update user in all leaderboards
  Future<void> updateUserInAllLeaderboards(String userId,
      {bool isHighScore = false}) async {
    try {
      // Check if we need to throttle updates
      if (!await shouldUpdateLeaderboard(userId, isHighScore: isHighScore)) {
        print('Skipping leaderboard update due to throttling');
        return;
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;

      // Create a batch for all updates
      final batch = _firestore.batch();
      int batchCount = 0;

      // Process each leaderboard type - SIMPLIFIED to only use games and time
      batchCount = await _addGamesLeaderboardToBatch(
          userId, userData, batch, batchCount);
      batchCount = await _addTimeLeaderboardsToBatch(
          userId, userData, batch, batchCount,
          isHighScore: isHighScore);

      // Only commit if we have operations to perform
      if (batchCount > 0) {
        await batch.commit();
        print(
            'Updated leaderboards for user $userId with $batchCount operations');

        // Record the update time
        await recordLeaderboardUpdate(userId);
      }
    } catch (e) {
      print('Error updating user in leaderboards: $e');
    }
  }

  // Add games leaderboard updates to batch
  Future<int> _addGamesLeaderboardToBatch(String userId,
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
      print('Error adding games leaderboard to batch: $e');
      return batchCount;
    }
  }

  // Add time leaderboards updates to batch
  Future<int> _addTimeLeaderboardsToBatch(String userId,
      Map<String, dynamic> userData, WriteBatch batch, int batchCount,
      {bool isHighScore = false}) async {
    try {
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
        String leaderboardType = getLeaderboardTypeFromOperation(operation);

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
        localBatchCount = await _addDifficultyTimeLeaderboardsToBatch(userId,
            userData, operation, leaderboardType, batch, localBatchCount,
            isHighScore: isHighScore);
      }

      return localBatchCount;
    } catch (e) {
      print('Error adding time leaderboards to batch: $e');
      return batchCount;
    }
  }

  // Add difficulty-specific time leaderboards to batch
  Future<int> _addDifficultyTimeLeaderboardsToBatch(
      String userId,
      Map<String, dynamic> userData,
      String operation,
      String leaderboardType,
      WriteBatch batch,
      int batchCount,
      {bool isHighScore = false}) async {
    try {
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

        localBatchCount++;
      }

      return localBatchCount;
    } catch (e) {
      print('Error adding difficulty time leaderboards to batch: $e');
      return batchCount;
    }
  }

  Future<bool> updateTimeHighScore(
      String userId, String operation, String difficulty, int newTime) async {
    try {
      print(
          'DEBUG: Attempting to update high score: $operation/$difficulty/$newTime ms');

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('DEBUG: User document not found: $userId');
        return false;
      }

      final userData = userDoc.data()!;
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // Generate the key for this operation and difficulty
      final timeKey = difficulty != 'All'
          ? '$operation-${difficulty.toLowerCase()}'
          : operation;

      // Get current best time
      final currentBestTime = bestTimes[timeKey] ?? 999999;

      print(
          'DEBUG: Current best time: $currentBestTime ms, New time: $newTime ms');

      // Only update if the new time is better (lower is better)
      if (newTime < currentBestTime) {
        print(
            'DEBUG: New best time for $timeKey: $newTime ms (previous: $currentBestTime ms)');

        // Update user document with the new best time
        final updates = <String, dynamic>{
          'bestTimes.$timeKey': newTime,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Also update the general operation time if this is better
        if (difficulty != 'All') {
          final generalOperationTime = bestTimes[operation] ?? 999999;
          if (newTime < generalOperationTime) {
            print(
                'DEBUG: Also updating general operation best time: $operation');
            updates['bestTimes.$operation'] = newTime;
          }
        }

        await _firestore.collection('users').doc(userId).update(updates);
        print('DEBUG: Updated user document with new best time');

        // Update the leaderboard entries with high score flag
        await updateUserInAllLeaderboards(userId, isHighScore: true);
        print('DEBUG: Leaderboard update completed for high score');

        return true;
      } else {
        print(
            'DEBUG: New time is not better than current best time. No update needed.');
        return false;
      }
    } catch (e) {
      print('Error updating time high score: $e');
      return false;
    }
  }

  Future<DateTime?> getLeaderboardLastUpdateTime(String leaderboardType) async {
    try {
      final docSnap = await _firestore
          .collection('leaderboards')
          .doc(leaderboardType)
          .get();

      if (!docSnap.exists) {
        print('DEBUG: Leaderboard document does not exist: $leaderboardType');
        // Create the document with an initial timestamp
        await _firestore.collection('leaderboards').doc(leaderboardType).set({
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return DateTime.now();
      }

      // Check multiple possible timestamp fields with clear logging
      Timestamp? timestamp;
      final data = docSnap.data()!;

      if (data.containsKey('lastUpdated') && data['lastUpdated'] != null) {
        timestamp = data['lastUpdated'] as Timestamp;
        print('DEBUG: Found lastUpdated timestamp: ${timestamp.toDate()}');
      } else if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
        timestamp = data['updatedAt'] as Timestamp;
        print('DEBUG: Found updatedAt timestamp: ${timestamp.toDate()}');
      } else {
        print('DEBUG: No timestamp found in document. Setting current time.');
        // Update the document with a current timestamp
        await _firestore
            .collection('leaderboards')
            .doc(leaderboardType)
            .update({
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return DateTime.now();
      }

      return timestamp.toDate();
    } catch (e) {
      print('Error getting leaderboard last update time: $e');
      return null;
    }
  }

  Future<void> refreshAllLeaderboards() async {
    try {
      print('DEBUG: Beginning refresh of all leaderboards');
      final refreshStartTime = DateTime.now();

      await _refreshLeaderboard(GAMES_LEADERBOARD, 'totalGames', true);
      await _refreshTimeLeaderboard(ADDITION_TIME, 'addition');
      await _refreshTimeLeaderboard(SUBTRACTION_TIME, 'subtraction');
      await _refreshTimeLeaderboard(MULTIPLICATION_TIME, 'multiplication');
      await _refreshTimeLeaderboard(DIVISION_TIME, 'division');

      // Update leaderboard metadata with server timestamp and explicitly check
      final now = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      final leaderboardTypes = [
        GAMES_LEADERBOARD,
        ADDITION_TIME,
        SUBTRACTION_TIME,
        MULTIPLICATION_TIME,
        DIVISION_TIME
      ];

      for (final type in leaderboardTypes) {
        batch.set(
            _firestore.collection('leaderboards').doc(type),
            {
              'lastUpdated': now,
              'refreshedAt': refreshStartTime.toIso8601String()
            },
            SetOptions(merge: true));
      }

      await batch.commit();

      // Verify timestamps were updated
      for (final type in leaderboardTypes) {
        final doc = await _firestore.collection('leaderboards').doc(type).get();
        print(
            'DEBUG: After refresh, $type timestamp: ${doc.data()?["lastUpdated"]}');
      }

      print(
          'All leaderboards refreshed successfully at ${refreshStartTime.toIso8601String()}');
    } catch (e) {
      print('Error refreshing all leaderboards: $e');
    }
  }

  // Refresh a specific leaderboard
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
        if (leaderboardType == GAMES_LEADERBOARD) {
          entryData['totalGames'] = userData['totalGames'] ?? 0;
          entryData['operationCounts'] = userData['completedGames'] ?? {};
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
        if (batchCount >= 450) {
          // Using 450 to be safe
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

  // Refresh time-based leaderboard
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
          if (batchCount >= 450) {
            // Using 450 to be safe
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

  // Refresh difficulty-specific time leaderboard
  Future<void> _refreshDifficultyTimeLeaderboard(String leaderboardType,
      String operation, String userId, Map<String, dynamic> userData) async {
    try {
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // Create a single batch for all difficulty updates
      var batch = _firestore.batch();
      int batchCount = 0;

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
                'bestTime': bestTime,
                'level': userData['level'] ?? 'Novice',
                'rank': rank,
                'difficulty': difficulty.substring(0, 1).toUpperCase() +
                    difficulty.substring(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });

          batchCount++;

          // Commit batch if needed
          if (batchCount >= 450) {
            // Using 450 to be safe
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error refreshing difficulty time leaderboard: $e');
    }
  }

  // Clear the leaderboard cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that match the leaderboard cache pattern
      final allKeys = prefs.getKeys();
      final leaderboardCacheKeys = allKeys
          .where((key) =>
              key.startsWith(CACHED_LEADERBOARD_KEY) ||
              key.startsWith(CACHED_USER_RANKS_KEY) ||
              key.startsWith(LAST_LEADERBOARD_UPDATE_KEY))
          .toList();

      // Remove each key
      for (final key in leaderboardCacheKeys) {
        await prefs.remove(key);
      }

      print('Cleared ${leaderboardCacheKeys.length} leaderboard cache entries');
    } catch (e) {
      print('Error clearing leaderboard cache: $e');
    }
  }

  // Get user's ranking in all leaderboards at once (reduces Firebase reads)
  Future<Map<String, int>> getUserRankingsInAllLeaderboards(
      String userId) async {
    try {
      final result = <String, int>{};

      // Try to get cached rankings first
      final prefs = await SharedPreferences.getInstance();
      final cachedRanksJson =
          prefs.getString('${CACHED_USER_RANKS_KEY}_all_$userId');

      if (cachedRanksJson != null) {
        try {
          final Map<String, dynamic> cachedRanks =
              Map<String, dynamic>.from(json.decode(cachedRanksJson));
          final timestamp =
              DateTime.parse(cachedRanks['timestamp'] ?? '2000-01-01');

          // If cache is recent (less than 10 minutes old), use it
          if (DateTime.now().difference(timestamp).inMinutes < 10) {
            cachedRanks.remove('timestamp');
            cachedRanks.forEach((key, value) {
              result[key] = value as int;
            });
            return result;
          }
        } catch (e) {
          print('Error parsing cached rankings: $e');
        }
      }

      // If no valid cache, get fresh data from Firebase
      final gamesData = await getUserLeaderboardData(userId, GAMES_LEADERBOARD);
      final additionTimeData =
          await getUserLeaderboardData(userId, ADDITION_TIME);
      final subtractionTimeData =
          await getUserLeaderboardData(userId, SUBTRACTION_TIME);
      final multiplicationTimeData =
          await getUserLeaderboardData(userId, MULTIPLICATION_TIME);
      final divisionTimeData =
          await getUserLeaderboardData(userId, DIVISION_TIME);

      // Extract ranks
      result[GAMES_LEADERBOARD] = gamesData['rank'] ?? 0;
      result[ADDITION_TIME] = additionTimeData['rank'] ?? 0;
      result[SUBTRACTION_TIME] = subtractionTimeData['rank'] ?? 0;
      result[MULTIPLICATION_TIME] = multiplicationTimeData['rank'] ?? 0;
      result[DIVISION_TIME] = divisionTimeData['rank'] ?? 0;

      // Cache the result
      final cacheData = Map<String, dynamic>.from(result);
      cacheData['timestamp'] = DateTime.now().toIso8601String();
      await prefs.setString(
          '${CACHED_USER_RANKS_KEY}_all_$userId', json.encode(cacheData));

      return result;
    } catch (e) {
      print('Error getting user rankings: $e');
      return {};
    }
  }

  // Get user's best rank (for display on home screen)
  Future<Map<String, dynamic>> getUserBestRank(String userId) async {
    try {
      final allRankings = await getUserRankingsInAllLeaderboards(userId);

      // Find the best (lowest) non-zero rank
      int bestRank = 999999;
      String bestCategory = '';

      allRankings.forEach((category, rank) {
        if (rank > 0 && rank < bestRank) {
          bestRank = rank;
          bestCategory = category;
        }
      });

      // Translate category to user-friendly name
      String categoryName;
      switch (bestCategory) {
        case GAMES_LEADERBOARD:
          categoryName = 'Games Played';
          break;
        case ADDITION_TIME:
          categoryName = 'Addition Time';
          break;
        case SUBTRACTION_TIME:
          categoryName = 'Subtraction Time';
          break;
        case MULTIPLICATION_TIME:
          categoryName = 'Multiplication Time';
          break;
        case DIVISION_TIME:
          categoryName = 'Division Time';
          break;
        default:
          categoryName = 'Overall';
      }

      return {
        'rank': bestRank < 999999 ? bestRank : 0,
        'category': categoryName,
      };
    } catch (e) {
      print('Error getting user best rank: $e');
      return {'rank': 0, 'category': 'Overall'};
    }
  }
}
