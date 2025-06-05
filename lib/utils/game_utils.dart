// lib/utils/game_utils.dart
import 'dart:math';

/// Utility class for generating number sets for different operations
class GameGenerator {
  /// Generate numbers for addition operation
  static List<int> generateAdditionNumbers(List<int> innerNumbers,
      int targetNumber, int maxOuterNumber, Random random) {
    // Initialize outer numbers list with placeholders
    final outerNumbers = List.filled(16, 0);

    // 1. First, ensure we have exactly 4 valid equations
    List<int> validInnerNumbers = [];
    List<int> validOuterNumbers = [];
    Set<int> usedOuterNumbers = {};

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take 4 numbers from the shuffled list for our valid equations
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);

      // For addition: inner + target = outer
      final outerNum = innerNum + targetNumber;

      // Make sure we don't exceed max range and don't have duplicates
      if (outerNum <= maxOuterNumber && !usedOuterNumbers.contains(outerNum)) {
        validOuterNumbers.add(outerNum);
        usedOuterNumbers.add(outerNum);
      } else {
        // If we can't use this number, try another until we find a valid one
        int attempts = 0;
        bool found = false;
        while (attempts < 20 && !found) {
          final newInnerNum = innerNumbers[random.nextInt(innerNumbers.length)];
          final newOuterNum = newInnerNum + targetNumber;

          if (newOuterNum <= maxOuterNumber &&
              !usedOuterNumbers.contains(newOuterNum)) {
            validInnerNumbers[i] = newInnerNum;
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            found = true;
          }
          attempts++;
        }

        // If we still couldn't find a valid number, create one by decrementing
        if (!found) {
          int newOuterNum = maxOuterNumber;
          while (usedOuterNumbers.contains(newOuterNum) &&
              newOuterNum > targetNumber) {
            newOuterNum--;
          }

          if (!usedOuterNumbers.contains(newOuterNum)) {
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            // Recalculate corresponding inner number
            validInnerNumbers[i] = newOuterNum - targetNumber;
          } else {
            // Extreme fallback - just use a number and accept the duplicate
            final fallbackOuter = innerNum + targetNumber;
            validOuterNumbers.add(fallbackOuter);
            usedOuterNumbers.add(fallbackOuter);
          }
        }
      }
    }

    // 2. NEW: Place valid outer numbers at RANDOM positions, not just corners
    // Generate all possible positions and shuffle them
    List<int> allPositions = List.generate(16, (index) => index);
    allPositions.shuffle(random);

    // Take the first 4 positions for our valid numbers
    List<int> validPositions = allPositions.sublist(0, 4);

    // Place valid numbers at the random positions
    for (int i = 0; i < 4; i++) {
      outerNumbers[validPositions[i]] = validOuterNumbers[i];
    }

    // 3. Fill remaining positions with random numbers within range
    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(maxOuterNumber) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  /// Generate numbers for subtraction operation
  static List<int> generateSubtractionNumbers(List<int> innerNumbers,
      int targetNumber, int maxOuterNumber, Random random) {
    // For subtraction: outer - inner = target
    // This means: outer = inner + target
    // So we can reuse the addition logic but be clearer about what we're doing

    return generateAdditionNumbers(
        innerNumbers, targetNumber, maxOuterNumber, random);
  }

  static List<int> generateMultiplicationNumbers(
      int targetNumber, Random random) {
    if (targetNumber == 1) {
      final outerNumbers = List.generate(16, (index) => index + 1);
      outerNumbers.shuffle(random);
      return outerNumbers;
    }

    final maxProduct = targetNumber * 12;
    final outerNumbers = List.filled(16, 0);

    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    List<int> productNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = productNumbers[i];
    }

    Set<int> usedOuterNumbers = Set.from(productNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        int randomNum;
        do {
          randomNum = random.nextInt(maxProduct) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  static List<int> generateDivisionNumbers(int targetNumber, Random random) {
    if (targetNumber == 1) {
      final outerNumbers = List.generate(16, (index) => index + 1);
      outerNumbers.shuffle(random);
      return outerNumbers;
    }

    final maxDividend = targetNumber * 12;
    final outerNumbers = List.filled(16, 0);

    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    List<int> dividendNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = dividendNumbers[i];
    }

    Set<int> usedOuterNumbers = Set.from(dividendNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        int randomNum;
        do {
          randomNum = random.nextInt(maxDividend) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  /// Generate numbers for times table ring mode
  static List<int> generateTimesTableRingNumbers(
      int targetNumber, Random random) {
    print(
        "🎯 generateTimesTableRingNumbers called with targetNumber: $targetNumber");

    // SPECIAL CASE: Target number 1
    if (targetNumber == 1) {
      print("   ⚠️ Special case: targetNumber = 1, using custom generation");
      // For target 1, all numbers 1-12 are correct answers
      // Generate distractors from a higher range
      List<int> correctAnswers =
          List.generate(12, (i) => i + 1); // [1,2,3...12]
      List<int> distractors = [
        13,
        14,
        15,
        16
      ]; // Simple distractors outside the range

      List<int> allNumbers = [...correctAnswers, ...distractors];
      allNumbers.shuffle(random);
      print("   ✅ Generated numbers for target 1: $allNumbers");
      return allNumbers;
    }

    // Generate all 12 correct answers: 1×target, 2×target, ..., 12×target
    List<int> correctAnswers = [];
    for (int i = 1; i <= 12; i++) {
      correctAnswers.add(i * targetNumber);
    }
    print("   ✅ Correct answers: $correctAnswers");

    // Generate 4 distractor numbers
    List<int> distractors = [];
    Set<int> usedNumbers = Set.from(correctAnswers);

    int minRange = targetNumber;
    int maxRange = targetNumber * 12;
    int attempts = 0;
    int maxAttempts = 100; // Safety limit

    print("   🎲 Generating distractors in range $minRange to $maxRange");

    while (distractors.length < 4 && attempts < maxAttempts) {
      int candidate = random.nextInt(maxRange - minRange + 1) + minRange;

      // Check if it's not a multiple of targetNumber and not already used
      if (candidate % targetNumber != 0 && !usedNumbers.contains(candidate)) {
        distractors.add(candidate);
        usedNumbers.add(candidate);
        print("   ✅ Added distractor: $candidate");
      }
      attempts++;
    }

    // Safety fallback if we couldn't generate enough distractors
    while (distractors.length < 4) {
      int fallback = maxRange + distractors.length + 1;
      if (!usedNumbers.contains(fallback)) {
        distractors.add(fallback);
        usedNumbers.add(fallback);
        print("   ⚠️ Added fallback distractor: $fallback");
      }
    }

    print("   ✅ Final distractors: $distractors");

    // Combine and shuffle all 16 numbers
    List<int> allNumbers = [...correctAnswers, ...distractors];
    allNumbers.shuffle(random);

    print("   ✅ Final shuffled numbers: $allNumbers");
    return allNumbers;
  }
}
