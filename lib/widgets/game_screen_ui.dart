// lib/widgets/game_screen_ui.dart - Enhanced with swipe/drag toggle
import 'package:flutter/material.dart';
import 'package:math_skills_game/models/level_completion_model.dart';
import 'package:math_skills_game/widgets/progress_stars.dart';
import '../models/difficulty_level.dart';
import '../models/operation_config.dart';
import '../models/ring_model.dart';
import '../models/locked_equation.dart';
import '../models/game_mode.dart';
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
  final Set<String> greyedOutNumbers;
  final GameMode gameMode;
  final List<Widget> starAnimations;
  final bool isGameComplete;
  final int elapsedTimeMs;
  
  // NEW: Control mode toggle
  final bool isDragMode;
  final VoidCallback onToggleMode;

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
    required this.greyedOutNumbers,
    required this.gameMode,
    required this.starAnimations,
    required this.isGameComplete,
    required this.elapsedTimeMs,
    required this.isDragMode, // NEW
    required this.onToggleMode, // NEW
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
    final boardSize = screenWidth * 0.95;
    final margin = boardSize * 0.02;
    final innerRingSize = boardSize * 0.62;

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

    // Format time display
    final formattedTime = StarRatingCalculator.formatTime(elapsedTimeMs);

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
          // Timer display in app bar
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  // Top section: title, timer and instructions
                  Column(
                    children: [
                      SizedBox(height: 20),
                      Text(
                        '${difficultyLevel.displayName} Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: operation.color,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Control mode toggle - NEW!
                      _buildControlModeToggle(),

                      SizedBox(height: 8),

                      // Star rating guide
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer,
                              size: 16, color: Colors.amber.shade800),
                          SizedBox(width: 4),
                          Text(
                            'Complete faster to earn more stars!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      // Progress stars at the top
                      ProgressStars(
                        total: gameMode == GameMode.timesTableRing ? 12 : 4,
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
                            // Outer ring - UPDATED to use mode toggle
                            SimpleRing(
                              key: ValueKey('outer_${isDragMode ? 'drag' : 'swipe'}'), // Force rebuild when mode changes
                              ringModel: outerRingModel,
                              size: boardSize,
                              tileSize: outerTileSize,
                              isInner: false,
                              onRotateSteps: onUpdateOuterRing,
                              lockedEquations: lockedEquations,
                              greyedOutNumbers: greyedOutNumbers,
                              onTileTap: onTileTap,
                              transitionRate: 1.0,
                              margin: margin,
                              isDragMode: isDragMode, // NEW parameter
                              gameMode: gameMode, // NEW parameter
                            ),

                            // Inner ring - UPDATED to use mode toggle
                            SimpleRing(
                              key: ValueKey('inner_${isDragMode ? 'drag' : 'swipe'}'), // Force rebuild when mode changes
                              ringModel: innerRingModel,
                              size: innerRingSize,
                              tileSize: innerTileSize,
                              isInner: true,
                              onRotateSteps: onUpdateInnerRing,
                              lockedEquations: lockedEquations,
                              greyedOutNumbers: greyedOutNumbers,
                              onTileTap: onTileTap,
                              transitionRate: 1.0,
                              margin: margin,
                              isDragMode: isDragMode, // NEW parameter
                              gameMode: gameMode, // NEW parameter
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

                            // Equation symbols - using improved layout
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
                        ? _buildCompletionMessage()
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

  // NEW: Build the control mode toggle widget
  Widget _buildControlModeToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: operation.color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDragMode ? Icons.drag_indicator : Icons.swipe,
            size: 18,
            color: operation.color,
          ),
          SizedBox(width: 8),
          Text(
            isDragMode ? 'Drag Mode' : 'Swipe Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: operation.color,
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleMode,
            child: Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDragMode ? operation.color : Colors.grey.shade300,
              ),
              child: AnimatedAlign(
                duration: Duration(milliseconds: 200),
                alignment: isDragMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the hint button
  Widget _buildHintButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      child: ElevatedButton.icon(
        onPressed: onShowHint,
        icon: Icon(
          Icons.lightbulb_outline,
          color: Colors.white, // Make the icon light colored
        ),
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

  Widget _buildCompletionMessage() {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'All Equations Completed!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: operation.color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${lockedEquations.length}/4 equations solved in ${StarRatingCalculator.formatTime(elapsedTimeMs)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}