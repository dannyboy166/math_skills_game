// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/level_completion_model.dart';
import '../models/daily_streak.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile(User user, {String? displayName, int age = 8}) async {
    // Check if profile already exists
    final docSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (docSnapshot.exists) {
      return; // Profile already exists
    }

    // Determine initial unlocks based on age
    List<int> initialUnlocks = _getInitialUnlocksForAge(age);
    
    // Create new profile
    return _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName ?? user.displayName ?? 'Player',
      'email': user.email,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
      'totalGames': 0,
      'totalStars': 0,
      'level': 'Novice',
      'completedGames': {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0,
      },
      'streakData': {
        'lastPlayedDate': Timestamp.fromDate(DateTime.now()),
        'currentStreak': 0,
        'longestStreak': 0,
      },
      'unlockedTimeTables': initialUnlocks,
      'mistakeTracker': {
        'hasAllTablesUnlocked': age >= 11,
        'perfectCompletions': {},
      }
    });
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Get user profile data with age defaulting to 11+
  Future<Map<String, dynamic>?> getUserProfileData(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (!docSnapshot.exists) return null;
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // If age is missing or null, default to 11
      if (data['age'] == null) {
        data['age'] = 11;
      }
      
      return data;
    } catch (e) {
      print('Error getting user profile data: $e');
      return null;
    }
  }

  // Add age parameter to users who don't have it
  Future<void> addAgeParameterToUser(String userId, {int defaultAge = 11}) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userData = await userRef.get();
      
      if (!userData.exists) return;
      
      final data = userData.data() as Map<String, dynamic>;
      
      // Only update if age is missing
      if (data['age'] == null) {
        await userRef.update({'age': defaultAge});
        print('Added age parameter ($defaultAge) to user: $userId');
      }
    } catch (e) {
      print('Error adding age parameter to user $userId: $e');
      throw e;
    }
  }

  // Add age parameter to all users without it
  Future<void> addAgeParameterToAllUsers({int defaultAge = 11}) async {
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
          batch.update(doc.reference, {'age': defaultAge});
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('Added age parameter to $updateCount users');
      } else {
        print('No users need age parameter update');
      }
    } catch (e) {
      print('Error adding age parameters to all users: $e');
      throw e;
    }
  }

// This is the corrected version of updateGameStats in user_service.dart
  Future<void> updateGameStats(String userId, String operation,
      String difficulty, int targetNumber, int newStars,
      {int completionTimeMs = 0}) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Check if this level has been completed before and with what stars
    final levelId = '${operation}_${difficulty}_${targetNumber}';
    final levelRef = userRef.collection('levelCompletions').doc(levelId);
    final levelDoc = await levelRef.get();

    // Calculate star difference for accurate total stars update
    int starDifference = newStars;
    if (levelDoc.exists) {
      final existingData = levelDoc.data() as Map<String, dynamic>;
      final existingStars = (existingData['stars'] ?? 0) as int;

      // Only count the improvement
      if (existingStars >= newStars) {
        starDifference = 0; // No improvement in stars
      } else {
        starDifference = newStars - existingStars;
      }
    }

    // Add to game history
    await userRef.update({
      'totalGames': FieldValue.increment(1),
      'totalStars':
          FieldValue.increment(starDifference), // Only add the difference
      'completedGames.$operation': FieldValue.increment(1),
      'gameHistory': FieldValue.arrayUnion([
        {
          'operation': operation,
          'difficulty': difficulty,
          'targetNumber': targetNumber,
          'completedAt': Timestamp.fromDate(DateTime.now()),
          'stars': newStars,
          'completionTimeMs': completionTimeMs,
        }
      ]),
    });

    // Update daily streak
    await _updateDailyStreak(userId);

    // Check and update level
    final userData = await userRef.get();
    final totalGames = userData.data()?['totalGames'] ?? 0;

    String newLevel = 'Novice';
    if (totalGames >= 50)
      newLevel = 'Master';
    else if (totalGames >= 25)
      newLevel = 'Expert';
    else if (totalGames >= 10) newLevel = 'Apprentice';

    if (newLevel != userData.data()?['level']) {
      await userRef.update({'level': newLevel});
    }
  }

  Future<void> saveLevelCompletion(
      String userId, LevelCompletionModel completion) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Create a level ID for tracking best scores
    final levelId =
        '${completion.operationName}_${completion.difficultyName}_${completion.targetNumber}';

    // First check if this level has been completed before and with what score
    final levelRef = userRef.collection('levelCompletions').doc(levelId);
    final levelDoc = await levelRef.get();

    if (levelDoc.exists) {
      final existingData = levelDoc.data() as Map<String, dynamic>;
      final existingStars = existingData['stars'] ?? 0;
      final existingTime = existingData['completionTimeMs'] ?? 0;

      // Only update if the new star rating is higher OR
      // if the star rating is the same but completion time is faster
      if (completion.stars > existingStars ||
          (completion.stars == existingStars &&
              completion.completionTimeMs < existingTime)) {
        await levelRef.set(completion.toMap());
      }
    } else {
      // First time completing this level
      await levelRef.set(completion.toMap());
    }

    // Also update the total stars
    await updateGameStats(userId, completion.operationName,
        completion.difficultyName, completion.targetNumber, completion.stars,
        completionTimeMs: completion.completionTimeMs);

    // Also update the user's best time for this operation, including difficulty-specific time
    await updateBestTime(userId, completion.operationName,
        completion.difficultyName, completion.completionTimeMs);
  }

  // Get all level completions for a user
  Future<List<LevelCompletionModel>> getLevelCompletions(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('levelCompletions')
        .get();

    return querySnapshot.docs
        .map((doc) => LevelCompletionModel.fromDocument(doc))
        .toList();
  }

  // Get best completion for a specific level
  Future<LevelCompletionModel?> getBestLevelCompletion(String userId,
      String operation, String difficulty, int targetNumber) async {
    final levelId = '${operation}_${difficulty}_${targetNumber}';

    final docSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('levelCompletions')
        .doc(levelId)
        .get();

    if (docSnapshot.exists) {
      return LevelCompletionModel.fromDocument(docSnapshot);
    }

    return null;
  }

  Future<void> _updateDailyStreak(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userData = await userRef.get();
    final userDataMap = userData.data();

    if (userDataMap == null) return;

    // Use consistent date normalization
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get last played date from Firestore
    Timestamp? lastPlayedTimestamp =
        userDataMap['streakData']?['lastPlayedDate'];
    DateTime? lastPlayedDate;

    if (lastPlayedTimestamp != null) {
      final lastPlayed = lastPlayedTimestamp.toDate();
      lastPlayedDate =
          DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    }

    // Get current streak values
    int currentStreak = userDataMap['streakData']?['currentStreak'] ?? 0;
    int longestStreak = userDataMap['streakData']?['longestStreak'] ?? 0;

    print('STREAK DEBUG: Current date: $today');
    print('STREAK DEBUG: Last played date: $lastPlayedDate');
    print('STREAK DEBUG: Current streak before update: $currentStreak');

    bool streakUpdated = false;

    if (lastPlayedDate == null) {
      // First time playing
      print('STREAK DEBUG: First time playing - setting streak to 1');
      currentStreak = 1;
      streakUpdated = true;
    } else if (lastPlayedDate.isBefore(today)) {
      // Calculate days difference
      final daysDifference = today.difference(lastPlayedDate).inDays;
      print('STREAK DEBUG: Days since last play: $daysDifference');

      if (daysDifference == 1) {
        // Played yesterday, continue streak
        print('STREAK DEBUG: Continuing streak from yesterday');
        currentStreak += 1;
        streakUpdated = true;
      } else {
        // Missed more than one day, start new streak
        print('STREAK DEBUG: Missed days, starting new streak at 1');
        currentStreak = 1;
        streakUpdated = true;
      }
    } else if (lastPlayedDate.isAtSameMomentAs(today)) {
      // Already played today
      print(
          'STREAK DEBUG: Already played today, keeping streak at $currentStreak');
      // Fix zero streak for existing users who played today
      if (currentStreak == 0) {
        currentStreak = 1;
        streakUpdated = true;
      }
    }

    // Update longest streak if needed
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      print('STREAK DEBUG: New longest streak: $longestStreak');
    }

    // Save updated streak data
    if (streakUpdated || currentStreak == 0) {
      print(
          'STREAK DEBUG: Saving streak data - current: $currentStreak, longest: $longestStreak');

      await userRef.update({
        'streakData': {
          'lastPlayedDate': Timestamp.fromDate(today),
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
        }
      });

      // Update weekly streak with consistent date
      await _updateWeeklyStreak(userId, today);
    }
  }

// Fixed _updateWeeklyStreak method
  Future<void> _updateWeeklyStreak(String userId, DateTime today) async {
    final userRef = _firestore.collection('users').doc(userId);

    // FIXED: Consistent week calculation
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday; // Sunday = 0
    final startOfWeek = today.subtract(Duration(days: todayWeekday));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    // Create a document ID for the current week
    final weekId =
        '${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';

    print('WEEKLY STREAK DEBUG: Week ID: $weekId');
    print('WEEKLY STREAK DEBUG: Start of week: $startOfWeek');
    print('WEEKLY STREAK DEBUG: Today: $today, Day of week: $todayWeekday');

    // Reference to the weekly streak document
    final weekRef = userRef.collection('weeklyStreaks').doc(weekId);

    try {
      // Check if we already have this week
      final weekDoc = await weekRef.get();

      if (weekDoc.exists) {
        // Update the existing week to mark today complete
        final weekData = weekDoc.data() as Map<String, dynamic>;
        final daysData = weekData['days'] as Map<String, dynamic>? ?? {};

        print(
            'WEEKLY STREAK DEBUG: Existing week found, updating day $todayWeekday');

        // Check if today is already marked complete
        final todayData =
            daysData['$todayWeekday'] as Map<String, dynamic>? ?? {};
        final isAlreadyComplete = todayData['completed'] ?? false;

        if (!isAlreadyComplete) {
          await weekRef.update({
            'days.$todayWeekday.completed': true,
            'days.$todayWeekday.date': Timestamp.fromDate(today),
            'days.$todayWeekday.dayOfWeek': todayWeekday,
          });
          print('WEEKLY STREAK DEBUG: Marked day $todayWeekday as complete');
        } else {
          print(
              'WEEKLY STREAK DEBUG: Day $todayWeekday already marked complete');
        }
      } else {
        // Create a new week
        print('WEEKLY STREAK DEBUG: Creating new week');
        final weeklyStreak = WeeklyStreak.currentWeek();
        weeklyStreak.markDayCompleted(today);

        // Convert to a format suitable for Firestore
        final daysMap = <String, dynamic>{};
        for (int i = 0; i < weeklyStreak.days.length; i++) {
          final day = weeklyStreak.days[i];
          daysMap['$i'] = day.toMap();
        }

        await weekRef.set({
          'startDate': Timestamp.fromDate(startOfWeek),
          'endDate': Timestamp.fromDate(endOfWeek),
          'days': daysMap,
          'weekNumber': _getWeekNumber(startOfWeek),
        });

        print(
            'WEEKLY STREAK DEBUG: New week created and today marked complete');
      }
    } catch (e) {
      print('WEEKLY STREAK ERROR: $e');
    }
  }

  Future<WeeklyStreak> getCurrentWeekStreak(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // FIXED: Consistent week calculation
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday;
    final startOfWeek = today.subtract(Duration(days: todayWeekday));

    // Create the week ID
    final weekId =
        '${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';

    try {
      // Try to get the week from Firestore
      final weekDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weeklyStreaks')
          .doc(weekId)
          .get();

      if (weekDoc.exists) {
        final data = weekDoc.data() as Map<String, dynamic>;
        final daysData = data['days'] as Map<String, dynamic>? ?? {};

        // Initialize an empty week with correct dates
        final weeklyStreak = WeeklyStreak.currentWeek();

        // Populate with data from Firestore
        for (int i = 0; i < 7; i++) {
          final dayData = daysData['$i'] as Map<String, dynamic>?;
          if (dayData != null) {
            final completed = dayData['completed'] ?? false;
            if (completed && i < weeklyStreak.days.length) {
              weeklyStreak.days[i] =
                  weeklyStreak.days[i].copyWith(completed: true);
            }
          }
        }

        return weeklyStreak;
      }
    } catch (e) {
      print('Error getting weekly streak: $e');
    }

    // If no data found or error, return an empty week
    return WeeklyStreak.currentWeek();
  }

  // Get streak stats (current streak, longest streak)
  Future<Map<String, dynamic>> getStreakStats(String userId) async {
    try {
      final userData = await _firestore.collection('users').doc(userId).get();

      if (userData.exists) {
        final data = userData.data();
        final streakData = data?['streakData'] as Map<String, dynamic>?;

        if (streakData != null) {
          int currentStreak = streakData['currentStreak'] ?? 0;
          
          // Check if streak should be reset due to missed days (without updating database)
          final lastPlayedTimestamp = streakData['lastPlayedDate'] as Timestamp?;
          if (lastPlayedTimestamp != null && currentStreak > 0) {
            final lastPlayed = lastPlayedTimestamp.toDate();
            final lastPlayedDate = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            
            if (lastPlayedDate.isBefore(todayDate)) {
              final daysDifference = todayDate.difference(lastPlayedDate).inDays;
              if (daysDifference > 1) {
                // Missed more than one day, streak should show as 0 until they play
                currentStreak = 0;
              }
            }
          }
          
          return {
            'currentStreak': currentStreak,
            'longestStreak': streakData['longestStreak'] ?? 0,
            'lastPlayedDate': lastPlayedTimestamp?.toDate(),
          };
        }
      }
    } catch (e) {
      print('Error getting streak stats: $e');
    }

    // Default values if no data found
    return {
      'currentStreak': 0,
      'longestStreak': 0,
      'lastPlayedDate': null,
    };
  }

  Future<void> updateBestTime(String userId, String operation,
      String difficulty, int completionTimeMs) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      // Store best times for both the operation overall and for the specific difficulty
      final userData = userDoc.data() as Map<String, dynamic>;
      final bestTimes = userData['bestTimes'] as Map<String, dynamic>? ?? {};

      // 1. Update the overall best time for this operation
      final currentBestTime = bestTimes[operation] as int? ?? 999999;
      if (completionTimeMs < currentBestTime) {
        await userRef.update({
          'bestTimes.$operation': completionTimeMs,
        });
      }

      // 2. Update the difficulty-specific best time
      final difficultyKey = '$operation-${difficulty.toLowerCase()}';
      final currentDifficultyBestTime =
          bestTimes[difficultyKey] as int? ?? 999999;
      if (completionTimeMs < currentDifficultyBestTime) {
        await userRef.update({
          'bestTimes.$difficultyKey': completionTimeMs,
        });
      }

      print(
          'Updated best times for $operation ($difficulty): ${completionTimeMs}ms');
    } catch (e) {
      print('Error updating best time: $e');
    }
  }

  // Helper function to get week number in the year
  int _getWeekNumber(DateTime date) {
    final dayOfYear =
        int.parse('${date.difference(DateTime(date.year, 1, 1)).inDays + 1}');
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Stream<WeeklyStreak> weeklyStreakStream(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // FIXED: Consistent week calculation
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday;
    final startOfWeek = today.subtract(Duration(days: todayWeekday));

    // Create the week ID
    final weekId =
        '${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyStreaks')
        .doc(weekId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return WeeklyStreak.currentWeek();
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final daysData = data['days'] as Map<String, dynamic>? ?? {};

      // Initialize an empty week with correct dates
      final weeklyStreak = WeeklyStreak.currentWeek();

      // Populate with data from Firestore
      for (int i = 0; i < 7; i++) {
        final dayData = daysData['$i'] as Map<String, dynamic>?;
        if (dayData != null) {
          final completed = dayData['completed'] ?? false;
          if (completed && i < weeklyStreak.days.length) {
            weeklyStreak.days[i] =
                weeklyStreak.days[i].copyWith(completed: true);
          }
        }
      }

      return weeklyStreak;
    });
  }

  // Also add a stream for streak stats
  Stream<Map<String, dynamic>> streakStatsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {
          'currentStreak': 0,
          'longestStreak': 0,
        };
      }

      final data = snapshot.data();
      final streakData = data?['streakData'] as Map<String, dynamic>?;

      if (streakData != null) {
        int currentStreak = streakData['currentStreak'] ?? 0;
        
        // Check if streak should be reset due to missed days (without updating database)
        final lastPlayedTimestamp = streakData['lastPlayedDate'] as Timestamp?;
        if (lastPlayedTimestamp != null && currentStreak > 0) {
          final lastPlayed = lastPlayedTimestamp.toDate();
          final lastPlayedDate = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          
          if (lastPlayedDate.isBefore(todayDate)) {
            final daysDifference = todayDate.difference(lastPlayedDate).inDays;
            if (daysDifference > 1) {
              // Missed more than one day, streak should show as 0 until they play
              currentStreak = 0;
            }
          }
        }
        
        return {
          'currentStreak': currentStreak,
          'longestStreak': streakData['longestStreak'] ?? 0,
        };
      }

      return {
        'currentStreak': 0,
        'longestStreak': 0,
      };
    });
  }

  // Helper method to determine initial unlocks based on age
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

  // Check if a time table is unlocked for a user
  Future<bool> isTimeTableUnlocked(String userId, int table) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final unlockedTables = List<int>.from(userData['unlockedTimeTables'] ?? []);
      
      return unlockedTables.contains(table);
    } catch (e) {
      print('Error checking if time table $table is unlocked: $e');
      return false;
    }
  }

  // Get list of unlocked time tables for a user
  Future<List<int>> getUnlockedTimeTables(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data() as Map<String, dynamic>;
      return List<int>.from(userData['unlockedTimeTables'] ?? []);
    } catch (e) {
      print('Error getting unlocked time tables: $e');
      return [];
    }
  }

  // Track a mistake in a level
  Future<void> trackMistake(String userId, String operation, String difficulty, int targetNumber) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userData = await userRef.get();
      
      if (!userData.exists) return;
      
      final data = userData.data() as Map<String, dynamic>;
      final mistakeTracker = data['mistakeTracker'] as Map<String, dynamic>? ?? {};
      
      // Don't track mistakes if all tables are already unlocked
      if (mistakeTracker['hasAllTablesUnlocked'] == true) return;
      
      final levelId = '${operation}_${difficulty}_$targetNumber';
      final perfectCompletions = Map<String, bool>.from(mistakeTracker['perfectCompletions'] ?? {});
      
      // Mark this level as having a mistake
      perfectCompletions[levelId] = false;
      
      await userRef.update({
        'mistakeTracker.perfectCompletions': perfectCompletions,
      });
    } catch (e) {
      print('Error tracking mistake: $e');
    }
  }

  // Track a perfect completion and check for unlocks
  Future<List<int>> trackPerfectCompletion(String userId, String operation, String difficulty, int targetNumber) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userData = await userRef.get();
      
      if (!userData.exists) return [];
      
      final data = userData.data() as Map<String, dynamic>;
      final mistakeTracker = data['mistakeTracker'] as Map<String, dynamic>? ?? {};
      
      // Don't track if all tables are already unlocked
      if (mistakeTracker['hasAllTablesUnlocked'] == true) return [];
      
      final levelId = '${operation}_${difficulty}_$targetNumber';
      final perfectCompletions = Map<String, bool>.from(mistakeTracker['perfectCompletions'] ?? {});
      
      // Mark this level as perfectly completed
      perfectCompletions[levelId] = true;
      
      // Check if this perfect completion unlocks new tables
      final currentUnlocked = List<int>.from(data['unlockedTimeTables'] ?? []);
      final newUnlocks = _checkForNewUnlocks(currentUnlocked, operation, targetNumber, perfectCompletions);
      
      Map<String, dynamic> updateData = {
        'mistakeTracker.perfectCompletions': perfectCompletions,
      };
      
      if (newUnlocks.isNotEmpty) {
        final allUnlocked = [...currentUnlocked, ...newUnlocks];
        updateData['unlockedTimeTables'] = allUnlocked;
        
        // Check if all tables are now unlocked
        if (allUnlocked.length >= 15) {
          updateData['mistakeTracker.hasAllTablesUnlocked'] = true;
        }
      }
      
      await userRef.update(updateData);
      
      // Return the newly unlocked tables for celebration
      return newUnlocks;
    } catch (e) {
      print('Error tracking perfect completion: $e');
      return [];
    }
  }

  // Check what new tables should be unlocked based on perfect completion
  List<int> _checkForNewUnlocks(List<int> currentUnlocked, String operation, int targetNumber, Map<String, bool> perfectCompletions) {
    // Only unlock for multiplication and division
    if (operation != 'multiplication' && operation != 'division') {
      return [];
    }
    
    List<int> newUnlocks = [];
    
    // Define the progression groups
    List<List<int>> progressionGroups = [
      [1, 2, 5, 10],        // Initial group
      [3, 4, 6],            // Unlocked after completing any from first group
      [7, 8, 9],            // Unlocked after completing any from second group  
      [11, 12],             // Unlocked after completing any from third group
      [13, 14, 15],         // Unlocked after completing any from fourth group
    ];
    
    // Find which group the completed table belongs to
    int completedGroupIndex = -1;
    for (int i = 0; i < progressionGroups.length; i++) {
      if (progressionGroups[i].contains(targetNumber)) {
        completedGroupIndex = i;
        break;
      }
    }
    
    if (completedGroupIndex == -1 || completedGroupIndex >= progressionGroups.length - 1) {
      return []; // No next group to unlock
    }
    
    // Check if the next group should be unlocked
    int nextGroupIndex = completedGroupIndex + 1;
    List<int> nextGroup = progressionGroups[nextGroupIndex];
    
    // Add tables from next group that aren't already unlocked
    for (int table in nextGroup) {
      if (!currentUnlocked.contains(table)) {
        newUnlocks.add(table);
      }
    }
    
    return newUnlocks;
  }

  // Stream to monitor unlocked time tables
  Stream<List<int>> unlockedTimeTablesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <int>[];
      
      final data = snapshot.data() as Map<String, dynamic>;
      return List<int>.from(data['unlockedTimeTables'] ?? []);
    });
  }
}
