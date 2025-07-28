// lib/services/high_score_service.dart
import '../models/level_completion_model.dart';
import '../models/difficulty_level.dart';

/// Service to handle high score retrieval and level range logic
/// This centralizes the logic that was duplicated between levels_screen and game_screen
class HighScoreService {
  
  /// Get the best time for a specific level configuration
  static String getBestTimeForLevel({
    required List<LevelCompletionModel> completions,
    required String operationName,
    required DifficultyLevel difficultyLevel,
    required int targetNumber,
  }) {
    // Get the level range for this specific configuration
    final levelRange = _getLevelRange(
      operationName: operationName,
      difficultyLevel: difficultyLevel,
      targetNumber: targetNumber,
    );

    // Filter completions that fall within this level's range
    final matchingCompletions = completions
        .where((completion) =>
            levelRange.contains(completion.targetNumber) &&
            completion.completionTimeMs > 0)
        .toList();

    if (matchingCompletions.isEmpty) {
      return '--:--';
    }

    // Find the minimum time (best time) achieved in this level range
    final bestCompletion = matchingCompletions
        .reduce((a, b) => a.completionTimeMs < b.completionTimeMs ? a : b);

    return StarRatingCalculator.formatTime(bestCompletion.completionTimeMs);
  }

  /// Get the best time for a level range (used by levels_screen)
  static String getBestTimeForLevelRange({
    required List<LevelCompletionModel> completions,
    required int rangeStart,
    required int rangeEnd,
  }) {
    // Filter completions that fall within this range and have a valid time
    final matchingCompletions = completions
        .where((completion) =>
            completion.targetNumber >= rangeStart &&
            completion.targetNumber <= rangeEnd &&
            completion.completionTimeMs > 0)
        .toList();

    if (matchingCompletions.isEmpty) {
      return '--:--';
    }

    // Find the minimum time (best time) achieved
    final bestCompletion = matchingCompletions
        .reduce((a, b) => a.completionTimeMs < b.completionTimeMs ? a : b);

    return StarRatingCalculator.formatTime(bestCompletion.completionTimeMs);
  }

  /// Parse high score string to milliseconds for race character
  static int parseHighScoreToMs(String highScore) {
    if (highScore == '--:--' || highScore.isEmpty) {
      return 0; // No high score available
    }
    
    try {
      // Handle format like "59.8s" (seconds with decimal)
      if (highScore.endsWith('s')) {
        final secondsStr = highScore.substring(0, highScore.length - 1);
        final seconds = double.parse(secondsStr);
        return (seconds * 1000).round(); // Convert to milliseconds
      }
      
      // Handle format like "1:23" or "0:45" (minutes:seconds)
      final parts = highScore.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds) * 1000; // Convert to milliseconds
      }
    } catch (e) {
      print('Error parsing high score: $highScore');
    }
    
    return 0;
  }

  /// Determine the level range for a given configuration
  static List<int> _getLevelRange({
    required String operationName,
    required DifficultyLevel difficultyLevel,
    required int targetNumber,
  }) {
    if (operationName == 'multiplication' || operationName == 'division') {
      // For multiplication/division, it's just the single target number
      return [targetNumber];
    }

    // For addition/subtraction, determine the range based on difficulty and target number
    if (difficultyLevel == DifficultyLevel.standard ||
        difficultyLevel == DifficultyLevel.challenging) {
      // Individual levels (1-10)
      return [targetNumber];
    }

    // Expert and Impossible have ranges
    if (difficultyLevel == DifficultyLevel.expert) {
      // Expert ranges: 11-12, 13-14, 15-16, 17-18, 19-20
      if (targetNumber >= 11 && targetNumber <= 12) return [11, 12];
      if (targetNumber >= 13 && targetNumber <= 14) return [13, 14];
      if (targetNumber >= 15 && targetNumber <= 16) return [15, 16];
      if (targetNumber >= 17 && targetNumber <= 18) return [17, 18];
      if (targetNumber >= 19 && targetNumber <= 20) return [19, 20];
    }

    if (difficultyLevel == DifficultyLevel.impossible) {
      // Impossible ranges: 21-26, 27-32, 33-38, 39-44, 45-50
      if (targetNumber >= 21 && targetNumber <= 26)
        return List.generate(6, (i) => 21 + i);
      if (targetNumber >= 27 && targetNumber <= 32)
        return List.generate(6, (i) => 27 + i);
      if (targetNumber >= 33 && targetNumber <= 38)
        return List.generate(6, (i) => 33 + i);
      if (targetNumber >= 39 && targetNumber <= 44)
        return List.generate(6, (i) => 39 + i);
      if (targetNumber >= 45 && targetNumber <= 50)
        return List.generate(6, (i) => 45 + i);
    }

    // Fallback to single number
    return [targetNumber];
  }
}