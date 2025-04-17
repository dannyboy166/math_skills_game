// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/level_completion_model.dart';
import '../models/daily_streak.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile(User user, {String? displayName}) async {
    // Check if profile already exists
    final docSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (docSnapshot.exists) {
      return; // Profile already exists
    }

    // Create new profile
    return _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName ?? user.displayName ?? 'Player',
      'email': user.email,
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
      }
    });
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Future<void> updateGameStats(String userId, String operation,
      String difficulty, int targetNumber, int stars,
      {int completionTimeMs = 0}) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Add to game history
    await userRef.update({
      'totalGames': FieldValue.increment(1),
      'totalStars': FieldValue.increment(stars),
      'completedGames.$operation': FieldValue.increment(1),
      'gameHistory': FieldValue.arrayUnion([
        {
          'operation': operation,
          'difficulty': difficulty,
          'targetNumber': targetNumber,
          'completedAt': Timestamp.fromDate(DateTime.now()),
          'stars': stars,
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

  // Save level completion data with star rating
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

  // NEW STREAK METHODS

  // Update daily streak when user plays a game
  Future<void> _updateDailyStreak(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userData = await userRef.get();
    final userDataMap = userData.data();

    if (userDataMap == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get last played date
    Timestamp? lastPlayedTimestamp =
        userDataMap['streakData']?['lastPlayedDate'];
    DateTime? lastPlayedDate;

    if (lastPlayedTimestamp != null) {
      final lastPlayed = lastPlayedTimestamp.toDate();
      lastPlayedDate =
          DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    }

    // Get current streak
    int currentStreak = userDataMap['streakData']?['currentStreak'] ?? 0;
    int longestStreak = userDataMap['streakData']?['longestStreak'] ?? 0;

    // Check if this is first time playing today
    // if (lastPlayedDate == null || lastPlayedDate.isBefore(today)) {
    // Check if continuing streak (yesterday) or breaking streak
    if (lastPlayedDate != null &&
        lastPlayedDate.difference(today).inDays == -1) {
      // Continuing streak from yesterday
      currentStreak += 1;
    } else if (lastPlayedDate == null ||
        lastPlayedDate.difference(today).inDays < -1) {
      // New streak (either first time or broke streak)
      currentStreak = 1;
    }

    // Update longest streak if needed
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    // Store new streak data
    await userRef.update({
      'streakData': {
        'lastPlayedDate': Timestamp.fromDate(today),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      }
    });

    // Also update weekly streak collection
    await _updateWeeklyStreak(userId, today);
    //}
  }

  // Update weekly streak data
  Future<void> _updateWeeklyStreak(String userId, DateTime today) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Get the current week dates
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    // Create a document ID for the current week
    final weekId =
        '${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';

    // Reference to the weekly streak document
    final weekRef = userRef.collection('weeklyStreaks').doc(weekId);

    // Check if we already have this week
    final weekDoc = await weekRef.get();

    if (weekDoc.exists) {
      // Update the existing week to mark today complete
      final weekData = weekDoc.data() as Map<String, dynamic>;
      final dayOfWeek = today.weekday % 7; // 0-based day of week

      // If this day is not already completed, mark it
      if (!(weekData['days'][dayOfWeek]?['completed'] ?? false)) {
        await weekRef.update({'days.$dayOfWeek.completed': true});
      }
    } else {
      // Create a new week
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
    }
  }

  // Get the current week's streak data
  Future<WeeklyStreak> getCurrentWeekStreak(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));

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
        final daysData = data['days'] as Map<String, dynamic>;

        // Initialize an empty week
        final weeklyStreak = WeeklyStreak.currentWeek();

        // Populate with data from Firestore
        for (int i = 0; i < 7; i++) {
          final dayData = daysData['$i'];
          if (dayData != null) {
            final completed = dayData['completed'] ?? false;
            if (completed) {
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
          return {
            'currentStreak': streakData['currentStreak'] ?? 0,
            'longestStreak': streakData['longestStreak'] ?? 0,
            'lastPlayedDate': streakData['lastPlayedDate'] != null
                ? (streakData['lastPlayedDate'] as Timestamp).toDate()
                : null,
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

  // Helper function to get week number in the year
  int _getWeekNumber(DateTime date) {
    final dayOfYear =
        int.parse('${date.difference(DateTime(date.year, 1, 1)).inDays + 1}');
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // Add this to UserService class
  Stream<WeeklyStreak> weeklyStreakStream(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));

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
      final daysData = data['days'] as Map<String, dynamic>;

      // Initialize an empty week
      final weeklyStreak = WeeklyStreak.currentWeek();

      // Populate with data from Firestore
      for (int i = 0; i < 7; i++) {
        final dayData = daysData['$i'];
        if (dayData != null) {
          final completed = dayData['completed'] ?? false;
          if (completed) {
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
        return {
          'currentStreak': streakData['currentStreak'] ?? 0,
          'longestStreak': streakData['longestStreak'] ?? 0,
        };
      }

      return {
        'currentStreak': 0,
        'longestStreak': 0,
      };
    });
  }
}
