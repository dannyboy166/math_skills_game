// lib/widgets/game_screen_ui.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/widgets/progress_stars.dart';
import '../models/difficulty_level.dart';
import '../models/operation_config.dart';
import '../models/ring_model.dart';
import '../models/locked_equation.dart';
import 'simple_ring.dart';
import 'equation_layout.dart';

/// UI component for the game screen
/// This separates the UI from the logic in the GameScreen widget
class GameScreenUI extends StatelessWidget {
  final String operationName;
  final DifficultyLevel difficultyLevel;
  final int targetNumber;
  final OperationConfig operation;
  final List<Color> backgroundGradient;
  final RingModel innerRingModel;
  final RingModel outerRingModel;
  final List<LockedEquation> lockedEquations;
  final List<Widget> starAnimations;
  final bool isGameComplete;

  // Callback functions for interactions
  final Function(int) onUpdateInnerRing;
  final Function(int) onUpdateOuterRing;
  final Function(int, int) onTileTap;
  final Function(int) onEquationTap;
  final VoidCallback onShowHint;
  final VoidCallback onShowHelp;

  const GameScreenUI({
    Key? key,
    required this.operationName,
    required this.difficultyLevel,
    required this.targetNumber,
    required this.operation,
    required this.backgroundGradient,
    required this.innerRingModel,
    required this.outerRingModel,
    required this.lockedEquations,
    required this.starAnimations,
    required this.isGameComplete,
    required this.onUpdateInnerRing,
    required this.onUpdateOuterRing,
    required this.onTileTap,
    required this.onEquationTap,
    required this.onShowHint,
    required this.onShowHelp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final boardSize = screenWidth * 0.9;
    final innerRingSize = boardSize * 0.6;

    final outerTileSize = boardSize * 0.12;
    final innerTileSize = innerRingSize * 0.16;

    // Determine the appropriate title based on operation
    String title;
    switch (operationName) {
      case 'addition':
        title = 'Addition - Target: $targetNumber';
        break;
      case 'subtraction':
        title = 'Subtraction - Target: $targetNumber';
        break;
      case 'division':
        title = 'Division - Target: $targetNumber';
        break;
      case 'multiplication':
      default:
        title = 'Multiplication - Target: $targetNumber';
        break;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: operation.color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          // Help button
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: onShowHelp,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content column with better space management
              Column(
                children: [
                  // Top section: title and instructions
                  Column(
                    children: [
                      Text(
                        '${difficultyLevel.displayName} Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: operation.color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Rotate the rings to make equations',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      // Progress stars at the top
                      ProgressStars(
                        total: 4,
                        completed: lockedEquations.length,
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Game board section - using Expanded to take available space
                  Expanded(
                    child: Center(
                      child: Container(
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
                              onRotateSteps: onUpdateOuterRing,
                              lockedEquations: lockedEquations,
                              onTileTap: onTileTap,
                            ),

                            // Inner ring
                            SimpleRing(
                              ringModel: innerRingModel,
                              size: innerRingSize,
                              tileSize: innerTileSize,
                              isInner: true,
                              onRotateSteps: onUpdateInnerRing,
                              lockedEquations: lockedEquations,
                              onTileTap: onTileTap,
                            ),

                            // Center target number with enhanced styling
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: operation.color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    operation.color.withOpacity(0.7),
                                    operation.color,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$targetNumber',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Equation symbols
                            EquationLayout(
                              boardSize: boardSize,
                              innerRingSize: innerRingSize,
                              outerRingSize: boardSize,
                              operation: operation,
                              lockedEquations: lockedEquations,
                              onEquationTap: onEquationTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom section: Only show hint button during gameplay
                  // When game is complete, show locked equations
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: isGameComplete
                        ? _buildCompletedEquationsUI()
                        : _buildHintButton(),
                  ),
                ],
              ),

              // Star animations layer
              ...starAnimations,
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the hint button
  Widget _buildHintButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      child: ElevatedButton.icon(
        onPressed: onShowHint,
        icon: Icon(Icons.lightbulb_outline),
        label: Text('Hint', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: operation.color.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  // Helper method to build the completed equations summary
  Widget _buildCompletedEquationsUI() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: operation.color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Completed Equations:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: operation.color,
            ),
          ),
          SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                children: lockedEquations
                    .map((eq) => Container(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, 
                                  size: 20, 
                                  color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                eq.equationString,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}