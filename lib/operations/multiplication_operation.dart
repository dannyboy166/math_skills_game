import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_operation.dart';
import '../models/ring_model.dart';

/// Implementation of multiplication operation for the math game.
class MultiplicationOperation implements GameOperation {
  @override
  String get name => 'multiplication';
  
  @override
  String get displayName => 'Multiplication';
  
  @override
  String get symbol => '×';
  
  @override
  String get emoji => '✖️';
  
  @override
  Color get color => Colors.blue;
  
  @override
  void generateGameNumbers({
    required RingModel outerRingModel,
    required RingModel innerRingModel,
    required int targetNumber
  }) {
    final random = Random();
    
    // For inner ring, use fixed numbers 1-12 in order
    final innerNumbers = List.generate(12, (index) => index + 1);

    // Generate 4 distinct valid multiples for the outer ring
    // Maximum multiple is 12 (e.g., for target 3, max would be 36)
    final maxMultiple = 12;

    // Create a list of all possible multiples (1× to 12×)
    List<int> allMultiples = List.generate(
      maxMultiple, 
      (i) => (i + 1) * targetNumber
    );

    // Shuffle the list of multiples
    allMultiples.shuffle(random);

    // Take the first 4 multiples
    List<int> validAnswers = allMultiples.take(4).toList();

    // Generate outer ring numbers (all random up to 12× the target number)
    final maxOuterValue = targetNumber * 12;
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers between 1 and 12× target
      // Make sure these random numbers are NOT multiples of the target
      int randomNum;
      do {
        randomNum = random.nextInt(maxOuterValue) + 1;
      } while (randomNum % targetNumber == 0); // Avoid multiples of target

      return randomNum;
    });

    // Now shuffle the positions where we'll place these valid answers
    List<int> possiblePositions = List.generate(16, (index) => index);
    possiblePositions.shuffle(random);
    List<int> selectedPositions = possiblePositions.sublist(0, 4);

    // Place the valid answers at the selected positions
    for (int i = 0; i < 4; i++) {
      outerNumbers[selectedPositions[i]] = validAnswers[i];
    }

    // Update the models with the generated numbers
    innerRingModel.numbers.clear();
    innerRingModel.numbers.addAll(innerNumbers);
    
    outerRingModel.numbers.clear();
    outerRingModel.numbers.addAll(outerNumbers);
  }
  
  @override
  bool checkEquation({
    required int innerNumber, 
    required int outerNumber, 
    required int targetNumber
  }) {
    // For multiplication: inner × target = outer
    return innerNumber * targetNumber == outerNumber;
  }
  
  @override
  String getEquationString({
    required int innerNumber, 
    required int targetNumber, 
    required int outerNumber
  }) {
    return '$innerNumber $symbol $targetNumber = $outerNumber';
  }
}