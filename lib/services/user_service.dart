// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> createUserProfile(User user, {String? displayName}) async {
    // Check if profile already exists
    final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
    
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
  
  Future<void> updateGameStats(
    String userId, 
    String operation, 
    String difficulty, 
    int targetNumber, 
    int stars
  ) async {
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
          'completedAt': FieldValue.serverTimestamp(),
          'stars': stars,
        }
      ]),
    });
    
    // Check and update level
    final userData = await userRef.get();
    final totalGames = userData.data()?['totalGames'] ?? 0;
    
    String newLevel = 'Novice';
    if (totalGames >= 50) newLevel = 'Master';
    else if (totalGames >= 25) newLevel = 'Expert';
    else if (totalGames >= 10) newLevel = 'Apprentice';
    
    if (newLevel != userData.data()?['level']) {
      await userRef.update({'level': newLevel});
    }
  }
}