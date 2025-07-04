// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:number_ninja/services/leaderboard_service.dart';

class AdminService {
  static const String ADMIN_USER_ID = '3s5SMJQy7LPfv6dygWYsPqKr0662';
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

  // Add age parameters to all users who don't have them
  Future<void> addAllAgeParameters({int defaultAge = 11}) async {
    try {
      print('Starting to add age parameters to all users...');
      
      // Get all users
      final querySnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if age is missing
        if (data['age'] == null) {
          // Get the appropriate unlocked time tables for this age
          final unlockedTables = _getInitialUnlocksForAge(defaultAge);
          
          batch.update(doc.reference, {
            'age': defaultAge,
            'unlockedTimeTables': unlockedTables,
            'mistakeTracker': {
              'hasAllTablesUnlocked': defaultAge >= 11,
              'perfectCompletions': data['mistakeTracker']?['perfectCompletions'] ?? {},
            }
          });
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('Added age parameter and unlocked time tables to $updateCount users');
      } else {
        print('No users need age parameter update');
      }
      
      return;
    } catch (e) {
      print('Error adding age parameters to all users: $e');
      throw e;
    }
  }

  // Fix unlocked time tables for all users based on their age
  Future<void> fixUnlockedTimeTablesForAllUsers() async {
    try {
      print('Starting to fix unlocked time tables for all users...');
      
      // Get all users
      final querySnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final userAge = data['age'] ?? 11; // Default to 11 if age is missing
        final currentUnlocked = List<int>.from(data['unlockedTimeTables'] ?? []);
        
        // Get what should be unlocked for this age
        final expectedUnlocked = _getInitialUnlocksForAge(userAge);
        
        // Check if the user needs an update
        if (currentUnlocked.length != expectedUnlocked.length || 
            !_listsAreEqual(currentUnlocked, expectedUnlocked)) {
          
          batch.update(doc.reference, {
            'unlockedTimeTables': expectedUnlocked,
            'mistakeTracker': {
              'hasAllTablesUnlocked': userAge >= 11,
              'perfectCompletions': data['mistakeTracker']?['perfectCompletions'] ?? {},
            }
          });
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('Fixed unlocked time tables for $updateCount users');
      } else {
        print('No users need time table updates');
      }
      
      return;
    } catch (e) {
      print('Error fixing unlocked time tables: $e');
      throw e;
    }
  }

  // Helper method to check if two lists contain the same elements
  bool _listsAreEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    final set1 = Set<int>.from(list1);
    final set2 = Set<int>.from(list2);
    return set1.difference(set2).isEmpty && set2.difference(set1).isEmpty;
  }

  // Debug current user's level completions
  Future<Map<String, dynamic>> debugCurrentUserLevelCompletions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'error': 'No user signed in'};

      final userId = user.uid;
      
      // Get all level completions for this user
      final levelCompletionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levelCompletions')
          .get();
      
      List<Map<String, dynamic>> completions = [];
      
      for (final levelDoc in levelCompletionsSnapshot.docs) {
        final levelData = levelDoc.data();
        final stars = levelData['stars'] ?? 0;
        
        completions.add({
          'id': levelDoc.id,
          'operation': levelData['operationName'] ?? 'unknown',
          'difficulty': levelData['difficultyName'] ?? 'unknown', 
          'targetNumber': levelData['targetNumber'] ?? 0,
          'stars': stars,
          'completionTime': levelData['completionTimeMs'] ?? 0,
        });
      }
      
      // Calculate total stars using the same logic as profile screen (grouped by level ranges)
      int totalStars = _calculateCorrectTotalStars(completions);
      
      // Sort by operation and difficulty for easier reading
      completions.sort((a, b) {
        final opCompare = a['operation'].toString().compareTo(b['operation'].toString());
        if (opCompare != 0) return opCompare;
        return a['targetNumber'].toString().compareTo(b['targetNumber'].toString());
      });
      
      // Generate level groupings for display
      final levelGroupings = _generateLevelGroupings(completions);
      
      return {
        'userId': userId,
        'totalCompletions': completions.length,
        'calculatedTotalStars': totalStars,
        'completions': completions,
        'levelGroupings': levelGroupings,
      };
    } catch (e) {
      return {'error': 'Error getting level completions: $e'};
    }
  }

  // Recalculate total stars for all users based on their level completions
  Future<void> recalculateTotalStarsForAllUsers() async {
    try {
      print('Starting to recalculate total stars for all users...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      int processedCount = 0;
      int errorCount = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          
          // Get all level completions for this user
          final levelCompletionsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('levelCompletions')
              .get();
          
          // Calculate total stars from level completions
          int totalStarsEarned = 0;
          for (final levelDoc in levelCompletionsSnapshot.docs) {
            final levelData = levelDoc.data();
            final stars = levelData['stars'] ?? 0;
            totalStarsEarned += stars as int;
          }
          
          // Update the user's totalStars field
          await _firestore.collection('users').doc(userId).update({
            'totalStars': totalStarsEarned,
          });
          
          processedCount++;
          print('Updated total stars for user $userId: $totalStarsEarned stars');
          
        } catch (e) {
          errorCount++;
          print('Error processing user ${userDoc.id}: $e');
        }
      }
      
      print('Total stars recalculation completed. Processed: $processedCount, Errors: $errorCount');
      return;
    } catch (e) {
      print('Error recalculating total stars: $e');
      throw e;
    }
  }

  // Helper method to determine initial unlocks based on age (copied from UserService)
  List<int> _getInitialUnlocksForAge(int age) {
    if (age >= 11) {
      // 11+ gets all tables unlocked
      return List.generate(15, (index) => index + 1); // 1-15
    } else if (age >= 10) {
      // 10-11: 1×, 2×, 5×, 10× + 3×, 4×, 6× + 7×, 8×, 9× + 11×, 12×
      return [1, 2, 5, 10, 3, 4, 6, 7, 8, 9, 11, 12];
    } else if (age >= 9) {
      // 9-10: 1×, 2×, 5×, 10× + 3×, 4×, 6× + 7×, 8×, 9×
      return [1, 2, 5, 10, 3, 4, 6, 7, 8, 9];
    } else if (age >= 8) {
      // 8-9: 1×, 2×, 5×, 10× + 3×, 4×, 6×
      return [1, 2, 5, 10, 3, 4, 6];
    } else {
      // 3-8: 1×, 2×, 5×, 10×
      return [1, 2, 5, 10];
    }
  }

  // Calculate total stars using the same logic as the profile screen
  int _calculateCorrectTotalStars(List<Map<String, dynamic>> completions) {
    int totalStars = 0;
    
    // Group completions by operation
    final Map<String, List<Map<String, dynamic>>> completionsByOperation = {};
    for (final completion in completions) {
      final operation = completion['operation'] ?? '';
      if (!completionsByOperation.containsKey(operation)) {
        completionsByOperation[operation] = [];
      }
      completionsByOperation[operation]!.add(completion);
    }
    
    // Calculate stars for each operation using the same level ranges
    for (final operation in ['addition', 'subtraction', 'multiplication', 'division']) {
      final operationCompletions = completionsByOperation[operation] ?? [];
      if (operationCompletions.isEmpty) continue;
      
      if (operation == 'multiplication' || operation == 'division') {
        // For multiplication/division, each table is its own level
        totalStars += _calculateMultiplicationDivisionStars(operationCompletions);
      } else {
        // For addition/subtraction, use the range-based levels
        totalStars += _calculateAdditionSubtractionStars(operationCompletions);
      }
    }
    
    return totalStars;
  }
  
  int _calculateMultiplicationDivisionStars(List<Map<String, dynamic>> completions) {
    int stars = 0;
    
    // Group by difficulty and target number
    final Map<String, Map<int, int>> bestStarsByDifficultyAndTable = {};
    
    for (final completion in completions) {
      final difficulty = completion['difficulty'] ?? '';
      final targetNumber = completion['targetNumber'] ?? 0;
      final completionStars = (completion['stars'] ?? 0) as int;
      
      if (!bestStarsByDifficultyAndTable.containsKey(difficulty)) {
        bestStarsByDifficultyAndTable[difficulty] = {};
      }
      
      final currentBest = bestStarsByDifficultyAndTable[difficulty]![targetNumber] ?? 0;
      bestStarsByDifficultyAndTable[difficulty]![targetNumber] = 
          completionStars > currentBest ? completionStars : currentBest;
    }
    
    // Sum up all the best stars for each table
    for (final difficultyMap in bestStarsByDifficultyAndTable.values) {
      for (final tableStars in difficultyMap.values) {
        stars += tableStars;
      }
    }
    
    return stars;
  }
  
  int _calculateAdditionSubtractionStars(List<Map<String, dynamic>> completions) {
    int stars = 0;
    
    // Define the same level ranges as in levels_screen.dart
    final levelRanges = [
      // Standard: 1, 2, 3, 4, 5 (individual)
      {'difficulty': 'Standard', 'ranges': [[1,1], [2,2], [3,3], [4,4], [5,5]]},
      // Challenging: 6, 7, 8, 9, 10 (individual)  
      {'difficulty': 'Challenging', 'ranges': [[6,6], [7,7], [8,8], [9,9], [10,10]]},
      // Expert: 11-12, 13-14, 15-16, 17-18, 19-20
      {'difficulty': 'Expert', 'ranges': [[11,12], [13,14], [15,16], [17,18], [19,20]]},
      // Impossible: 21-26, 27-32, 33-38, 39-44, 45-50
      {'difficulty': 'Impossible', 'ranges': [[21,26], [27,32], [33,38], [39,44], [45,50]]},
    ];
    
    for (final difficultyData in levelRanges) {
      final difficulty = difficultyData['difficulty'] as String;
      final ranges = difficultyData['ranges'] as List<List<int>>;
      
      for (final range in ranges) {
        final rangeStart = range[0];
        final rangeEnd = range[1];
        
        // Find all completions in this range for this difficulty
        final matchingCompletions = completions.where((completion) {
          final completionDifficulty = completion['difficulty'] ?? '';
          final targetNumber = completion['targetNumber'] ?? 0;
          return completionDifficulty.toLowerCase() == difficulty.toLowerCase() &&
                 targetNumber >= rangeStart && 
                 targetNumber <= rangeEnd;
        }).toList();
        
        if (matchingCompletions.isNotEmpty) {
          // Take the maximum stars achieved in this range (same logic as levels screen)
          final maxStars = matchingCompletions
              .map((completion) => (completion['stars'] ?? 0) as int)
              .reduce((a, b) => a > b ? a : b);
          stars += maxStars;
        }
      }
    }
    
    return stars;
  }

  // Generate level groupings to show how individual completions are grouped into actual levels
  List<Map<String, dynamic>> _generateLevelGroupings(List<Map<String, dynamic>> completions) {
    List<Map<String, dynamic>> groupings = [];
    
    // Group completions by operation
    final Map<String, List<Map<String, dynamic>>> completionsByOperation = {};
    for (final completion in completions) {
      final operation = completion['operation'] ?? '';
      if (!completionsByOperation.containsKey(operation)) {
        completionsByOperation[operation] = [];
      }
      completionsByOperation[operation]!.add(completion);
    }
    
    // Process each operation
    for (final operation in ['addition', 'subtraction', 'multiplication', 'division']) {
      final operationCompletions = completionsByOperation[operation] ?? [];
      if (operationCompletions.isEmpty) continue;
      
      if (operation == 'multiplication' || operation == 'division') {
        // For multiplication/division, each table is its own level
        final Map<String, Map<int, Map<String, dynamic>>> grouped = {};
        
        for (final completion in operationCompletions) {
          final difficulty = completion['difficulty'] ?? '';
          final targetNumber = completion['targetNumber'] ?? 0;
          
          if (!grouped.containsKey(difficulty)) {
            grouped[difficulty] = {};
          }
          
          if (!grouped[difficulty]!.containsKey(targetNumber) || 
              (completion['stars'] ?? 0) > (grouped[difficulty]![targetNumber]?['stars'] ?? 0)) {
            grouped[difficulty]![targetNumber] = completion;
          }
        }
        
        // Add to groupings
        for (final difficulty in grouped.keys) {
          for (final targetNumber in grouped[difficulty]!.keys) {
            final best = grouped[difficulty]![targetNumber]!;
            groupings.add({
              'operation': operation,
              'levelTitle': '$operation $difficulty ${targetNumber}× table',
              'bestStars': best['stars'],
              'individualCompletions': [best],
            });
          }
        }
      } else {
        // For addition/subtraction, use range-based levels
        final levelRanges = [
          {'difficulty': 'Standard', 'ranges': [[1,1], [2,2], [3,3], [4,4], [5,5]]},
          {'difficulty': 'Challenging', 'ranges': [[6,6], [7,7], [8,8], [9,9], [10,10]]},
          {'difficulty': 'Expert', 'ranges': [[11,12], [13,14], [15,16], [17,18], [19,20]]},
          {'difficulty': 'Impossible', 'ranges': [[21,26], [27,32], [33,38], [39,44], [45,50]]},
        ];
        
        for (final difficultyData in levelRanges) {
          final difficulty = difficultyData['difficulty'] as String;
          final ranges = difficultyData['ranges'] as List<List<int>>;
          
          for (final range in ranges) {
            final rangeStart = range[0];
            final rangeEnd = range[1];
            
            final matchingCompletions = operationCompletions.where((completion) {
              final completionDifficulty = completion['difficulty'] ?? '';
              final targetNumber = completion['targetNumber'] ?? 0;
              return completionDifficulty.toLowerCase() == difficulty.toLowerCase() &&
                     targetNumber >= rangeStart && 
                     targetNumber <= rangeEnd;
            }).toList();
            
            if (matchingCompletions.isNotEmpty) {
              final maxStars = matchingCompletions
                  .map((completion) => (completion['stars'] ?? 0) as int)
                  .reduce((a, b) => a > b ? a : b);
              
              final levelTitle = rangeStart == rangeEnd 
                  ? '$operation $difficulty Level $rangeStart'
                  : '$operation $difficulty Level $rangeStart-$rangeEnd';
              
              groupings.add({
                'operation': operation,
                'levelTitle': levelTitle,
                'bestStars': maxStars,
                'individualCompletions': matchingCompletions,
              });
            }
          }
        }
      }
    }
    
    return groupings;
  }

  // Reset all game data for all users while preserving user accounts
  Future<void> resetAllGameData() async {
    try {
      print('Starting to reset all game data for all users...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      int processedCount = 0;
      int errorCount = 0;
      
      // Process users in batches to avoid memory issues
      final userBatches = <List<QueryDocumentSnapshot>>[];
      for (int i = 0; i < usersSnapshot.docs.length; i += 20) {
        userBatches.add(usersSnapshot.docs.sublist(
          i, 
          i + 20 > usersSnapshot.docs.length ? usersSnapshot.docs.length : i + 20
        ));
      }
      
      for (final batch in userBatches) {
        final firestoreBatch = _firestore.batch();
        
        for (final userDoc in batch) {
          try {
            final userId = userDoc.id;
            final userData = userDoc.data() as Map<String, dynamic>;
            
            // Reset user game data while preserving essential account info
            final resetData = {
              // Preserve account information
              'uid': userData['uid'],
              'email': userData['email'],
              'displayName': userData['displayName'],
              'photoURL': userData['photoURL'],
              'createdAt': userData['createdAt'],
              'lastLoginAt': userData['lastLoginAt'],
              'age': userData['age'],
              'provider': userData['provider'],
              
              // Reset game data
              'totalStars': 0,
              'level': 'Novice',
              'bestTimes': {},
              'gamesPlayed': 0,
              'averageScore': 0.0,
              'perfectGames': 0,
              'totalGameTime': 0,
              'lastPlayedDate': null,
              'achievements': [],
              'unlockedTimeTables': _getInitialUnlocksForAge(userData['age'] ?? 11),
              'mistakeTracker': {
                'hasAllTablesUnlocked': (userData['age'] ?? 11) >= 11,
                'perfectCompletions': {},
              },
              'settings': userData['settings'] ?? {
                'soundEnabled': true,
                'vibrateEnabled': true,
                'theme': 'system',
              },
            };
            
            // Update user document
            firestoreBatch.update(userDoc.reference, resetData);
            
            // Delete all level completions for this user
            final levelCompletionsSnapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('levelCompletions')
                .get();
            
            for (final completionDoc in levelCompletionsSnapshot.docs) {
              firestoreBatch.delete(completionDoc.reference);
            }
            
            processedCount++;
            
          } catch (e) {
            errorCount++;
            print('Error processing user ${userDoc.id}: $e');
          }
        }
        
        // Commit this batch
        await firestoreBatch.commit();
        print('Processed batch of ${batch.length} users');
      }
      
      // Clear all leaderboards
      await _clearAllLeaderboards();
      
      print('Game data reset completed. Processed: $processedCount, Errors: $errorCount');
      return;
    } catch (e) {
      print('Error resetting game data: $e');
      throw e;
    }
  }

  // Helper method to clear all leaderboards
  Future<void> _clearAllLeaderboards() async {
    try {
      print('Clearing all leaderboards...');
      
      final leaderboardTypes = ['additionTime', 'subtractionTime', 'multiplicationTime', 'divisionTime'];
      final difficulties = ['standard', 'challenging', 'expert', 'impossible'];
      
      for (final type in leaderboardTypes) {
        // Clear main leaderboard
        final mainEntriesSnapshot = await _firestore
            .collection('leaderboards')
            .doc(type)
            .collection('entries')
            .get();
        
        final batch = _firestore.batch();
        for (final doc in mainEntriesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // Clear difficulty-specific leaderboards
        for (final difficulty in difficulties) {
          final diffEntriesSnapshot = await _firestore
              .collection('leaderboards')
              .doc(type)
              .collection('difficulties')
              .doc(difficulty)
              .collection('entries')
              .get();
          
          final diffBatch = _firestore.batch();
          for (final doc in diffEntriesSnapshot.docs) {
            diffBatch.delete(doc.reference);
          }
          await diffBatch.commit();
        }
      }
      
      print('All leaderboards cleared successfully');
    } catch (e) {
      print('Error clearing leaderboards: $e');
      throw e;
    }
  }
}
