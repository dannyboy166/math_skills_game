// lib/models/difficulty_level.dart
import 'dart:math';

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy: return 'Easy';
      case DifficultyLevel.medium: return 'Medium';
      case DifficultyLevel.hard: return 'Hard';
      case DifficultyLevel.expert: return 'Expert';
    }
  }
  
  // Center number range
  int get minCenterNumber {
    switch (this) {
      case DifficultyLevel.easy: return 1;
      case DifficultyLevel.medium: return 6;
      case DifficultyLevel.hard: return 11;
      case DifficultyLevel.expert: return 21;
    }
  }
  
  int get maxCenterNumber {
    switch (this) {
      case DifficultyLevel.easy: return 5;
      case DifficultyLevel.medium: return 10;
      case DifficultyLevel.hard: return 20;
      case DifficultyLevel.expert: return 50;
    }
  }
  
  // Outer ring number range
  int get maxOuterNumber {
    switch (this) {
      case DifficultyLevel.easy: return 18;
      case DifficultyLevel.medium: return 24;
      case DifficultyLevel.hard: return 36;
      case DifficultyLevel.expert: return 100;
    }
  }
  
  // Inner ring numbers
  List<int> get innerRingNumbers {
    switch (this) {
      case DifficultyLevel.easy:
      case DifficultyLevel.medium:
      case DifficultyLevel.hard:
        return List.generate(12, (index) => index + 1); // 1-12
      case DifficultyLevel.expert:
        return List.generate(12, (index) => index + 13); // 13-24
    }
  }
  
  // Get a random center number for this difficulty level
  int getRandomCenterNumber(Random random) {
    return minCenterNumber + random.nextInt(maxCenterNumber - minCenterNumber + 1);
  }
}