import 'package:flutter/material.dart';
import 'dart:math';
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../widgets/simple_ring.dart';
import '../widgets/equation_layout.dart';

class GameScreen extends StatefulWidget {
  final int targetNumber;
  final String operationName;

  const GameScreen({
    Key? key,
    required this.targetNumber,
    required this.operationName,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RingModel outerRingModel;
  late RingModel innerRingModel;
  late OperationConfig operation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the operation configuration
    operation = OperationConfig.forOperation(widget.operationName);
    
    // Generate game numbers
    _generateGameNumbers();
  }
  
  void _generateGameNumbers() {
    final random = Random();
    
    // For inner ring: Use fixed numbers 1-12
    final innerNumbers = List.generate(12, (index) => index + 1);
    
    // For outer ring: Generate numbers based on operation
    List<int> outerNumbers;
    List<int> cornerPositions;
    
    // Different number generation based on operation
    switch (widget.operationName) {
      case 'addition':
        outerNumbers = _generateAdditionNumbers(innerNumbers, random);
        break;
      case 'subtraction':
        outerNumbers = _generateSubtractionNumbers(innerNumbers, random);
        break;
      case 'division':
        outerNumbers = _generateDivisionNumbers(innerNumbers, random);
        break;
      case 'multiplication':
      default:
        outerNumbers = _generateMultiplicationNumbers(innerNumbers, random);
        break;
    }
    
    // Initialize ring models
    innerRingModel = RingModel(
      numbers: innerNumbers,
      color: Colors.blue,
      cornerIndices: [0, 3, 6, 9], // Inner ring corners
    );
    
    outerRingModel = RingModel(
      numbers: outerNumbers,
      color: Colors.teal,
      cornerIndices: [0, 4, 8, 12], // Outer ring corners
    );
  }
  
  // Generate numbers for multiplication operation
  List<int> _generateMultiplicationNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random non-product numbers
      return random.nextInt(100) + 1;
    });
    
    // Select 4 inner numbers to create valid products
    List<int> validInnerNumbers = [];
    List<int> validProducts = [];
    
    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);
    
    // Take 4 numbers from the shuffled list
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);
      validProducts.add(innerNum * widget.targetNumber);
    }
    
    // Place valid products at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);
    
    for (int i = 0; i < 4; i++) {
      outerNumbers[possiblePositions[i]] = validProducts[i];
    }
    
    return outerNumbers;
  }
  
  // Generate numbers for addition operation
  List<int> _generateAdditionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers
      return random.nextInt(24) + 1;
    });
    
    // Select 4 inner numbers to create valid sums
    List<int> validInnerNumbers = [];
    List<int> validSums = [];
    
    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);
    
    // Take 4 numbers from the shuffled list
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);
      validSums.add(innerNum + widget.targetNumber);
    }
    
    // Place valid sums at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);
    
    for (int i = 0; i < 4; i++) {
      outerNumbers[possiblePositions[i]] = validSums[i];
    }
    
    return outerNumbers;
  }
  
  // Generate numbers for subtraction operation
  List<int> _generateSubtractionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers
      return random.nextInt(20) + 1;
    });
    
    List<int> validInnerNumbers = [];
    List<int> validResults = [];
    List<bool> isTargetMinusInner = [];
    
    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);
    
    // Take up to 4 numbers that satisfy our criteria
    int count = 0;
    for (int i = 0; i < shuffledInner.length && count < 4; i++) {
      final innerNum = shuffledInner[i];
      
      if (innerNum > widget.targetNumber) {
        // inner - target = result
        validInnerNumbers.add(innerNum);
        validResults.add(innerNum - widget.targetNumber);
        isTargetMinusInner.add(false);
        count++;
      } else if (innerNum < widget.targetNumber) {
        // target - inner = result
        validInnerNumbers.add(innerNum);
        validResults.add(widget.targetNumber - innerNum);
        isTargetMinusInner.add(true);
        count++;
      }
    }
    
    // Place valid results at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);
    
    for (int i = 0; i < count; i++) {
      outerNumbers[possiblePositions[i]] = validResults[i];
    }
    
    return outerNumbers;
  }
  
  // Generate numbers for division operation
  List<int> _generateDivisionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers for non-corner positions
      return random.nextInt(12) + 1;
    });
    
    List<int> validInnerNumbers = [];
    List<int> validResults = [];
    List<bool> isTargetDividedByInner = [];
    
    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);
    
    // Take up to 4 numbers that satisfy our criteria
    int count = 0;
    for (int i = 0; i < shuffledInner.length && count < 4; i++) {
      final innerNum = shuffledInner[i];
      
      if (innerNum % widget.targetNumber == 0) {
        // inner ÷ target = result
        validInnerNumbers.add(innerNum);
        validResults.add(innerNum ~/ widget.targetNumber);
        isTargetDividedByInner.add(false);
        count++;
      } else if (widget.targetNumber % innerNum == 0) {
        // target ÷ inner = result
        validInnerNumbers.add(innerNum);
        validResults.add(widget.targetNumber ~/ innerNum);
        isTargetDividedByInner.add(true);
        count++;
      }
    }
    
    // Place valid results at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);
    
    for (int i = 0; i < count; i++) {
      outerNumbers[possiblePositions[i]] = validResults[i];
    }
    
    return outerNumbers;
  }
  
  // Check if equations are correct
  bool _checkEquation(int cornerIndex) {
    // Get numbers at corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];
    
    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);
    
    return operation.checkEquation(innerNumber, outerNumber, widget.targetNumber);
  }
  
  // Update outer ring rotation
  void _updateOuterRing(int steps) {
    setState(() {
      outerRingModel = outerRingModel.copyWith(rotationSteps: steps);
    });
    _checkAllEquations();
  }
  
  // Update inner ring rotation
  void _updateInnerRing(int steps) {
    setState(() {
      innerRingModel = innerRingModel.copyWith(rotationSteps: steps);
    });
    _checkAllEquations();
  }
  
  // Check all equations and show debug information
  void _checkAllEquations() {
    for (int i = 0; i < 4; i++) {
      final isCorrect = _checkEquation(i);
      print('Corner $i equation: ${isCorrect ? "CORRECT" : "INCORRECT"}');
      
      // Print the equation details
      final outerCornerPos = outerRingModel.cornerIndices[i];
      final innerCornerPos = innerRingModel.cornerIndices[i];
      final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
      final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);
      
      print(operation.getEquationString(innerNumber, widget.targetNumber, outerNumber));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.9;
    final innerRingSize = boardSize * 0.6;
    
    final outerTileSize = boardSize * 0.12;
    final innerTileSize = innerRingSize * 0.16;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Math Game - ${widget.targetNumber} ${operation.symbol}'),
        backgroundColor: operation.color,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rotate the rings to make equations',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            
            // Debug info
            Text(
              'Target Number: ${widget.targetNumber}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Game board
            Container(
              width: boardSize,
              height: boardSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  SimpleRing(
                    ringModel: outerRingModel,
                    size: boardSize,
                    tileSize: outerTileSize,
                    isInner: false,
                    onRotateSteps: _updateOuterRing,
                  ),
                  
                  // Inner ring
                  SimpleRing(
                    ringModel: innerRingModel,
                    size: innerRingSize,
                    tileSize: innerTileSize,
                    isInner: true,
                    onRotateSteps: _updateInnerRing,
                  ),
                  
                  // Center target number
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.targetNumber}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Equation symbols (properly positioned)
                  EquationLayout(
                    boardSize: boardSize,
                    innerRingSize: innerRingSize,
                    outerRingSize: boardSize,
                    operation: operation,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            Text(
              'Check console for debug information',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}