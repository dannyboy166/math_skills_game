// lib/models/level_completion_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LevelCompletionModel {
  final String operationName;
  final String difficultyName;
  final int targetNumber;
  final int stars;
  final int completionTimeMs;
  final DateTime completedAt;

  const LevelCompletionModel({
    required this.operationName,
    required this.difficultyName,
    required this.targetNumber,
    required this.stars,
    required this.completionTimeMs,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'difficultyName': difficultyName,
      'targetNumber': targetNumber,
      'stars': stars,
      'completionTimeMs': completionTimeMs,
      'completedAt': Timestamp.fromDate(completedAt), // ✅ FIXED
    };
  }

  // Create from Firestore document
  factory LevelCompletionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LevelCompletionModel(
      operationName: data['operationName'] ?? '',
      difficultyName: data['difficultyName'] ?? '',
      targetNumber: data['targetNumber'] ?? 0,
      stars: data['stars'] ?? 0,
      completionTimeMs: data['completionTimeMs'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp).toDate(),
    );
  }

  // Create copy with updated fields
  LevelCompletionModel copyWith({
    String? operationName,
    String? difficultyName,
    int? targetNumber,
    int? stars,
    int? completionTimeMs,
    DateTime? completedAt,
  }) {
    return LevelCompletionModel(
      operationName: operationName ?? this.operationName,
      difficultyName: difficultyName ?? this.difficultyName,
      targetNumber: targetNumber ?? this.targetNumber,
      stars: stars ?? this.stars,
      completionTimeMs: completionTimeMs ?? this.completionTimeMs,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Helper class to calculate star ratings based on operation and difficulty
class StarRatingCalculator {
  // Time thresholds in milliseconds for each difficulty level
  // Format: [3-star threshold, 2-star threshold, 1-star threshold]
  // Updated for age group 5-14
  static const Map<String, Map<String, List<int>>> _timeThresholds = {
    'addition': {
      'Standard': [25000, 50000, 120000], // 25s, 50s, 120s
      'Challenging': [35000, 70000, 150000], // 35s, 70s, 150s
      'Expert': [45000, 90000, 180000], // 45s, 90s, 180s
      'Impossible': [60000, 120000, 240000], // 60s, 120s, 240s
    },
    'subtraction': {
      'Standard': [30000, 60000, 120000], // 30s, 60s, 120s
      'Challenging': [40000, 80000, 160000], // 40s, 80s, 160s
      'Expert': [55000, 110000, 220000], // 55s, 110s, 220s
      'Impossible': [75000, 150000, 300000], // 75s, 150s, 300s
    },
    'multiplication': {
      'Standard': [35000, 70000, 140000], // 35s, 70s, 140s
      'Challenging': [45000, 90000, 180000], // 45s, 90s, 180s
      'Expert': [60000, 120000, 240000], // 60s, 120s, 240s
      'Impossible': [75000, 150000, 300000], // 75s, 150s, 300s
    },
    'division': {
      'Standard': [40000, 80000, 160000], // 40s, 80s, 160s
      'Challenging': [50000, 100000, 200000], // 50s, 100s, 200s
      'Expert': [65000, 130000, 260000], // 65s, 130s, 260s
      'Impossible': [85000, 170000, 340000], // 85s, 170s, 340s
    },
  };

  // Calculate stars based on operation, difficulty and completion time
  static int calculateStars(
      String operation, String difficulty, int completionTimeMs) {
    // Default to Standard difficulty if not found
    // Since we only have 12-equation mode now, multiply base thresholds by 3
    final baseThresholds = _timeThresholds[operation]?[difficulty] ??
        _timeThresholds[operation]?['Standard'] ??
        [35000, 70000, 140000];

    // All games are now 12-equation mode, so use 3x the original thresholds
    final thresholds = baseThresholds.map((threshold) => (threshold * 3).toInt()).toList();

    if (completionTimeMs <= thresholds[0]) {
      return 3; // Fast completion - 3 stars
    } else if (completionTimeMs <= thresholds[1]) {
      return 2; // Good completion - 2 stars
    } else if (completionTimeMs <= thresholds[2]) {
      return 1; // Slow completion - 1 star
    } else {
      return 0; // Very slow - 0 stars
    }
  }

  // Get the time threshold for a specific star rating
  static int getTimeThreshold(String operation, String difficulty, int stars) {
    if (stars < 1 || stars > 3) {
      return 0; // Invalid star count
    }

    final thresholds = _timeThresholds[operation]?[difficulty] ??
        _timeThresholds[operation]?['Standard'] ??
        [35000, 70000, 140000];

    return thresholds[
        3 - stars]; // Index 0 for 3 stars, 1 for 2 stars, 2 for 1 star
  }

  // Format milliseconds as a human-readable string
  static String formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$seconds.${(milliseconds % 1000) ~/ 100}s';
    }
  }
}