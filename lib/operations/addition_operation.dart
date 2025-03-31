import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_operation.dart';
import '../models/ring_model.dart';

/// Implementation of addition operation for the math game.
class AdditionOperation implements GameOperation {
  @override
  String get name => 'addition';
  
  @override
  String get displayName => 'Addition';
  
  @override
  String get symbol => '+';
  
  @override
  String get emoji => '➕';
  
  @override
  Color get color => Colors.green;
  
  @override
  void generateGameNumbers({
    required RingModel outerRingModel,
    required RingModel innerRingModel,
    required int targetNumber
  }) {
    final random = Random();
    
    // For inner ring, use numbers 1-12
    final innerNumbers = List.generate(12, (index) => index + 1);
    innerNumbers.shuffle(random);
    
    // Maximum sum value (inner + target)
    final maxSum = 24; // Keeping sums reasonable
    
    // Generate 4 distinct valid sums for the outer ring
    // For addition, we'll select 4 random inner numbers and calculate their sums with target
    List<int> selectedInnerNumbers = [];
    List<int> validSums = [];
    
    // Shuffle the inner numbers to pick random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);
    
    // Select 4 random inner numbers and calculate their sums
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      selectedInnerNumbers.add(innerNum);
      validSums.add(innerNum + targetNumber);
    }
    
    // Generate outer ring numbers (random numbers that aren't valid sums)
    final outerNumbers = List.generate(16, (index) {
      // Generate a random number between 1 and maxSum
      // Ensure it's not one of our valid sums
      int randomNum;
      do {
        randomNum = random.nextInt(maxSum) + 1;
      } while (validSums.contains(randomNum));
      
      return randomNum;
    });
    
    // Now place the valid sums at random positions in the outer ring
    List<int> possiblePositions = List.generate(16, (index) => index);
    possiblePositions.shuffle(random);
    List<int> selectedPositions = possiblePositions.sublist(0, 4);
    
    // Place the valid sums at the selected positions
    for (int i = 0; i < 4; i++) {
      outerNumbers[selectedPositions[i]] = validSums[i];
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
    // For addition: inner + target = outer
    return innerNumber + targetNumber == outerNumber;
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