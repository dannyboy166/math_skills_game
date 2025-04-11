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

    // 2. Place valid outer numbers at corners
    List<int> cornerPositions = [0, 4, 8, 12]; // Corner positions
    cornerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[cornerPositions[i]] = validOuterNumbers[i];
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

  /// Generate numbers for multiplication operation
  static List<int> generateMultiplicationNumbers(
      int targetNumber, int maxOuterNumber, Random random) {
    // Special case for target=1
    if (targetNumber == 1) {
      // For target=1, just create a list of numbers 1-16 and shuffle them
      final outerNumbers = List.generate(16, (index) => index + 1);
      outerNumbers.shuffle(random);
      return outerNumbers;
    }

    // Regular case (existing code for target > 1)
    // Maximum product possible (may be adjusted if it's too large)
    final effectiveMaxOuter = min(targetNumber * 12, maxOuterNumber);

    // Initialize outer numbers list
    final outerNumbers = List.filled(16, 0);

    // 1. Choose 4 random numbers from 1-12 (not visible to player, just for calculation)
    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    // 2. Calculate the 4 products with the center number
    List<int> productNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    // 3. Randomly place the 4 product numbers anywhere in the outer ring
    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = productNumbers[i];
    }

    // 4. Fill remaining positions with numbers that:
    //    - Are not duplicates of our chosen products
    //    - Are not duplicates of any previously generated number
    //    - Are within range 1 to maxOuterNumber
    Set<int> usedOuterNumbers = Set.from(productNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(effectiveMaxOuter) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  static List<int> generateDivisionNumbers(
      int targetNumber, int maxOuterNumber, Random random) {
    // Special case for target=1
    if (targetNumber == 1) {
      // For target=1, just create a list of numbers 1-16 and shuffle them
      final outerNumbers = List.generate(16, (index) => index + 1);
      outerNumbers.shuffle(random);
      return outerNumbers;
    }

    // Regular case (existing code for target > 1)
    // Maximum dividend possible
    final effectiveMaxOuter = min(targetNumber * 12, maxOuterNumber);

    // Initialize outer numbers list
    final outerNumbers = List.filled(16, 0);

    // 1. Choose 4 random numbers from 1-12 as divisors
    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    // 2. Calculate the 4 dividends (outer = inner × target)
    // This ensures outer ÷ inner = target
    List<int> dividendNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    // 3. Randomly place the 4 dividend numbers anywhere in the outer ring
    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = dividendNumbers[i];
    }

    // 4. Fill remaining positions with numbers that:
    //    - Are not duplicates of our chosen dividends
    //    - Are not duplicates of any previously generated number
    //    - Are within range 1 to maxOuterNumber
    Set<int> usedOuterNumbers = Set.from(dividendNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(effectiveMaxOuter) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }
}
