import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_operation.dart';
import '../models/ring_model.dart';

/// Implementation of subtraction operation for the math game.
class SubtractionOperation implements GameOperation {
  @override
  String get name => 'subtraction';
  
  @override
  String get displayName => 'Subtraction';
  
  @override
  String get symbol => '-';
  
  @override
  String get emoji => '➖';
  
  @override
  Color get color => Colors.purple;
  
  @override
  void generateGameNumbers({
    required RingModel outerRingModel,
    required RingModel innerRingModel,
    required int targetNumber
  }) {
    final random = Random();
    
    // For subtraction, we have two cases:
    // 1. inner - target = outer (inner > target)
    // 2. target - inner = outer (target > inner)
    
    // For this implementation, we'll use both approaches
    
    // For inner ring, use numbers 1-12
    final innerNumbers = List.generate(12, (index) => index + 1);
    
    // Generate valid differences for the outer ring
    List<int> validDifferences = [];
    List<bool> isTargetMinusInner = []; // Track which equation type each one is
    
    // For case 1: inner - target (inner must be > target)
    for (int innerNum in innerNumbers) {
      if (innerNum > targetNumber) {
        validDifferences.add(innerNum - targetNumber);
        isTargetMinusInner.add(false);
      }
    }
    
    // For case 2: target - inner (target must be > inner)
    for (int innerNum in innerNumbers) {
      if (targetNumber > innerNum) {
        validDifferences.add(targetNumber - innerNum);
        isTargetMinusInner.add(true);
      }
    }
    
    // Shuffle the valid differences
    final combinedLists = List.generate(
      validDifferences.length, 
      (i) => {'diff': validDifferences[i], 'isTargetMinus': isTargetMinusInner[i]}
    );
    combinedLists.shuffle(random);
    
    // Take up to 4 valid differences (or fewer if not enough are available)
    final answerCount = min(4, combinedLists.length);
    List<int> selectedDifferences = [];
    List<bool> selectedIsTargetMinus = [];
    
    for (int i = 0; i < answerCount; i++) {
      selectedDifferences.add(combinedLists[i]['diff'] as int);
      selectedIsTargetMinus.add(combinedLists[i]['isTargetMinus'] as bool);
    }
    
    // Generate random outer ring numbers (avoiding our valid differences)
    final outerNumbers = List.generate(16, (index) {
      int randomNum;
      do {
        randomNum = random.nextInt(20) + 1; // Reasonable range for differences
      } while (selectedDifferences.contains(randomNum));
      
      return randomNum;
    });
    
    // Place the valid differences at random positions
    List<int> possiblePositions = List.generate(16, (index) => index);
    possiblePositions.shuffle(random);
    
    for (int i = 0; i < answerCount; i++) {
      outerNumbers[possiblePositions[i]] = selectedDifferences[i];
    }
    
    // Update the models with the generated numbers
    innerRingModel.numbers.clear();
    innerRingModel.numbers.addAll(innerNumbers);
    
    outerRingModel.numbers.clear();
    outerRingModel.numbers.addAll(outerNumbers);
    
    // Store the information about which equation type each answer is
    // This could be stored as metadata on the game board
    // For now, we'll just keep track of it locally for the implementation
  }
  
  @override
  bool checkEquation({
    required int innerNumber, 
    required int outerNumber, 
    required int targetNumber
  }) {
    // For subtraction, either:
    // 1. inner - target = outer
    // 2. target - inner = outer
    return innerNumber - targetNumber == outerNumber || 
           targetNumber - innerNumber == outerNumber;
  }
  
  @override
  String getEquationString({
    required int innerNumber, 
    required int targetNumber, 
    required int outerNumber
  }) {
    // Determine which equation format is correct
    if (innerNumber - targetNumber == outerNumber) {
      return '$innerNumber $symbol $targetNumber = $outerNumber';
    } else {
      return '$targetNumber $symbol $innerNumber = $outerNumber';
    }
  }
}