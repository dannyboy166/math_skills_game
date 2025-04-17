// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/level_completion_model.dart';

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
}
