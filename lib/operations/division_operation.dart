import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_operation.dart';
import '../models/ring_model.dart';

/// Implementation of division operation for the math game.
class DivisionOperation implements GameOperation {
  @override
  String get name => 'division';

  @override
  String get displayName => 'Division';

  @override
  String get symbol => '÷';

  @override
  String get emoji => '➗';

  @override
  Color get color => Colors.orange;

  @override
  void generateGameNumbers(
      {required RingModel outerRingModel,
      required RingModel innerRingModel,
      required int targetNumber}) {
    final random = Random();

    // For division, we have two cases:
    // 1. inner ÷ target = outer (inner must be divisible by target)
    // 2. target ÷ inner = outer (target must be divisible by inner)

    // For inner ring, use numbers 1-12
    final innerNumbers = List.generate(12, (index) => index + 1);

    // Generate products for case 1 (inner = product, outer = quotient)
    List<Map<String, dynamic>> validEquations = [];

    // Case 1: inner ÷ target = outer
    // For this case, inner must be a multiple of target
    for (int factor = 1; factor <= 12; factor++) {
      final product = factor * targetNumber; // This will be our inner number
      if (product <= 144) {
        // Keep within reasonable range
        validEquations.add(
            {'inner': product, 'outer': factor, 'type': 'inner_div_target'});
      }
    }

    // Case 2: target ÷ inner = outer
    // For this case, target must be divisible by inner
    for (int innerNum in innerNumbers) {
      if (targetNumber % innerNum == 0) {
        validEquations.add({
          'inner': innerNum,
          'outer': targetNumber ~/ innerNum,
          'type': 'target_div_inner'
        });
      }
    }

    // Shuffle and select up to 4 valid equations
    validEquations.shuffle(random);
    final equationCount = min(4, validEquations.length);
    final selectedEquations = validEquations.take(equationCount).toList();

    // Create a modified inner ring with the needed values
    List<int> customInnerNumbers = List.from(innerNumbers);

    // Replace some numbers in the inner ring with our specific multiples
    for (int i = 0; i < selectedEquations.length; i++) {
      if (selectedEquations[i]['type'] == 'inner_div_target') {
        // For case 1, we need specific multiples in the inner ring
        final requiredInner = selectedEquations[i]['inner'] as int;
        if (!customInnerNumbers.contains(requiredInner) &&
            requiredInner <= 12) {
          // Only replace if it fits in our 1-12 range
          customInnerNumbers[random.nextInt(12)] = requiredInner;
        }
      }
    }

    // Generate random outer ring numbers (avoiding our valid quotients)
    final validQuotients =
        selectedEquations.map((e) => e['outer'] as int).toList();
    final outerNumbers = List.generate(16, (index) {
      int randomNum;
      do {
        randomNum = random.nextInt(12) + 1; // Reasonable range for quotients
      } while (validQuotients.contains(randomNum));

      return randomNum;
    });

    // Place the valid quotients at random positions
    List<int> possiblePositions = List.generate(16, (index) => index);
    possiblePositions.shuffle(random);

    for (int i = 0; i < equationCount; i++) {
      outerNumbers[possiblePositions[i]] = selectedEquations[i]['outer'] as int;
    }

    // Update the models with the generated numbers
    innerRingModel.numbers.clear();
    innerRingModel.numbers.addAll(customInnerNumbers);

    outerRingModel.numbers.clear();
    outerRingModel.numbers.addAll(outerNumbers);
  }

  @override
  bool checkEquation(
      {required int innerNumber,
      required int outerNumber,
      required int targetNumber}) {
    // For division, either:
    // 1. inner ÷ target = outer (if inner is divisible by target)
    // 2. target ÷ inner = outer (if target is divisible by inner)
    return (innerNumber % targetNumber == 0 &&
            innerNumber ~/ targetNumber == outerNumber) ||
        (targetNumber % innerNumber == 0 &&
            targetNumber ~/ innerNumber == outerNumber);
  }

  @override
  String getEquationString(
      {required int innerNumber,
      required int targetNumber,
      required int outerNumber}) {
    // Determine which equation format is correct
    if (innerNumber % targetNumber == 0 &&
        innerNumber ~/ targetNumber == outerNumber) {
      return '$innerNumber $symbol $targetNumber = $outerNumber';
    } else {
      return '$targetNumber $symbol $innerNumber = $outerNumber';
    }
  }
}
