// lib/models/leaderboard_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalStars;
  final int totalGames;
  final int longestStreak;
  final Map<String, int> operationCounts;
  final Map<String, int> operationStars;
  final String level;
  final DateTime lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalStars,
    required this.totalGames,
    required this.longestStreak,
    required this.operationCounts,
    this.operationStars = const {},
    required this.level,
    required this.lastUpdated,
  });

  // Create from Firestore document
  factory LeaderboardEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final completedGames = data['completedGames'] as Map<String, dynamic>? ?? {};
    
    // Check if there are operation counts
    final operationCounts = <String, int>{};
    operationCounts['addition'] = completedGames['addition'] ?? 0;
    operationCounts['subtraction'] = completedGames['subtraction'] ?? 0;
    operationCounts['multiplication'] = completedGames['multiplication'] ?? 0;
    operationCounts['division'] = completedGames['division'] ?? 0;

    // Get operation stars (if available)
    final operationStars = <String, int>{};
    
    // If we have operation stars stored directly in the user document
    final gameStats = data['gameStats'] as Map<String, dynamic>? ?? {};
    operationStars['addition'] = gameStats['additionStars'] ?? 0;
    operationStars['subtraction'] = gameStats['subtractionStars'] ?? 0;
    operationStars['multiplication'] = gameStats['multiplicationStars'] ?? 0;
    operationStars['division'] = gameStats['divisionStars'] ?? 0;

    // Get streak data
    final streakData = data['streakData'] as Map<String, dynamic>? ?? {};
    final longestStreak = streakData['longestStreak'] ?? 0;

    // Use the provided or calculate total games
    int totalGames = data['totalGames'] ?? 0;
    if (totalGames == 0) {
      // Calculate total if not available
      totalGames = operationCounts.values.fold(0, (sum, count) => sum + count);
    }

    // Handle lastUpdated
    DateTime lastUpdated;
    if (data['lastUpdated'] != null) {
      lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
    } else if (data['updatedAt'] != null) {
      lastUpdated = (data['updatedAt'] as Timestamp).toDate();
    } else {
      lastUpdated = DateTime.now();
    }

    return LeaderboardEntry(
      userId: doc.id,
      displayName: data['displayName'] ?? 'Unknown Player',
      totalStars: data['totalStars'] ?? 0,
      totalGames: totalGames,
      longestStreak: longestStreak,
      operationCounts: operationCounts,
      operationStars: operationStars,
      level: data['level'] ?? 'Novice',
      lastUpdated: lastUpdated,
    );
  }

  // Helper method to get total operations completed
  int get totalOperations => operationCounts.values.fold(0, (sum, count) => sum + count);
  
  // Get favorite operation (most played)
  String get favoriteOperation {
    if (operationCounts.isEmpty) return 'None';
    
    String favorite = 'None';
    int maxCount = 0;
    
    operationCounts.forEach((operation, count) {
      if (count > maxCount) {
        maxCount = count;
        favorite = operation;
      }
    });
    
    // Capitalize first letter
    if (favorite != 'None') {
      favorite = favorite[0].toUpperCase() + favorite.substring(1);
    }
    
    return favorite;
  }
}