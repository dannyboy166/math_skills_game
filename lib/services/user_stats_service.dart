// lib/services/user_stats_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/level_completion_model.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate and store stars per operation for the current user
  Future<Map<String, int>> calculateStarsPerOperation(String userId) async {
    try {
      // Get all level completions for this user
      final completions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levelCompletions')
          .get();

      // Initialize operation stars map
      final operationStars = {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0,
      };

      // Process each completion
      for (final doc in completions.docs) {
        final completion = LevelCompletionModel.fromDocument(doc);
        final operation = completion.operationName;
        
        // Add stars to the appropriate operation
        if (operationStars.containsKey(operation)) {
          operationStars[operation] = (operationStars[operation] ?? 0) + completion.stars;
        }
      }

      // Store this data in the user document for future reference
      await _firestore.collection('users').doc(userId).update({
        'gameStats': {
          'additionStars': operationStars['addition'],
          'subtractionStars': operationStars['subtraction'],
          'multiplicationStars': operationStars['multiplication'],
          'divisionStars': operationStars['division'],
          'lastCalculated': FieldValue.serverTimestamp(),
        }
      });

      return operationStars;
    } catch (e) {
      print('Error calculating stars per operation: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        fatal: false,
        information: ['Stars calculation failed for user: $userId'],
      );
      return {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0,
      };
    }
  }

  // Get maximum possible stars for each operation
  Map<String, int> getMaxStarsPerOperation() {
    return {
      'addition': 60,
      'subtraction': 60,
      'multiplication': 45,
      'division': 45,
    };
  }

  // Calculate stars per operation for the current user
  Future<Map<String, int>> getCurrentUserStarsPerOperation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0,
      };
    }

    try {
      // First check if we have this data cached
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData != null) {
        final gameStats = userData['gameStats'] as Map<String, dynamic>?;
        if (gameStats != null) {
          // Check if the data is recent (less than 1 hour old)
          final lastCalculated = gameStats['lastCalculated'] as Timestamp?;
          final now = DateTime.now();
          if (lastCalculated != null && 
              now.difference(lastCalculated.toDate()).inHours < 1) {
            return {
              'addition': gameStats['additionStars'] ?? 0,
              'subtraction': gameStats['subtractionStars'] ?? 0,
              'multiplication': gameStats['multiplicationStars'] ?? 0,
              'division': gameStats['divisionStars'] ?? 0,
            };
          }
        }
      }

      // If we don't have cached data or it's old, calculate it
      return await calculateStarsPerOperation(user.uid);
    } catch (e) {
      print('Error getting current user stars per operation: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        fatal: false,
        information: ['Failed to get user stars for: ${user.uid}'],
      );
      return {
        'addition': 0,
        'subtraction': 0,
        'multiplication': 0,
        'division': 0,
      };
    }
  }

  // Update the user's operation stars after completing a level
  Future<void> updateOperationStarsAfterCompletion(
      String userId, String operation, int starsEarned) async {
    try {
      // Get the current stats
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final gameStats = userData['gameStats'] as Map<String, dynamic>? ?? {};
      final operationField = '${operation}Stars';
      final currentStars = gameStats[operationField] ?? 0;

      // Update with the new stars
      await _firestore.collection('users').doc(userId).update({
        'gameStats.$operationField': currentStars + starsEarned,
        'gameStats.lastCalculated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating operation stars: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        fatal: false,
        information: ['Failed to update operation stars for user: $userId, operation: $operation'],
      );
    }
  }
}