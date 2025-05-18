// lib/models/difficulty_level.dart
import 'dart:math';

enum DifficultyLevel {
  standard,
  challenging,
  expert,
  impossible,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.standard: return 'Standard';
      case DifficultyLevel.challenging: return 'Challenging';
      case DifficultyLevel.expert: return 'Expert';
      case DifficultyLevel.impossible: return 'Impossible';
    }
  }
  
  // Center number range
  int get minCenterNumber {
    switch (this) {
      case DifficultyLevel.standard: return 1;
      case DifficultyLevel.challenging: return 6;
      case DifficultyLevel.expert: return 11;
      case DifficultyLevel.impossible: return 21;
    }
  }
  
  int get maxCenterNumber {
    switch (this) {
      case DifficultyLevel.standard: return 5;
      case DifficultyLevel.challenging: return 10;
      case DifficultyLevel.expert: return 20;
      case DifficultyLevel.impossible: return 50;
    }
  }
  
  // Outer ring number range
  int get maxOuterNumber {
    switch (this) {
      case DifficultyLevel.standard: return 18;
      case DifficultyLevel.challenging: return 24;
      case DifficultyLevel.expert: return 36;
      case DifficultyLevel.impossible: return 100;
    }
  }
  
  // Inner ring numbers
  List<int> get innerRingNumbers {
    switch (this) {
      case DifficultyLevel.standard:
      case DifficultyLevel.challenging:
      case DifficultyLevel.expert:
        return List.generate(12, (index) => index + 1); // 1-12
      case DifficultyLevel.impossible:
        return List.generate(12, (index) => index + 13); // 13-24
    }
  }
  
  // Get a random center number for this difficulty level
  int getRandomCenterNumber(Random random) {
    return minCenterNumber + random.nextInt(maxCenterNumber - minCenterNumber + 1);
  }
}