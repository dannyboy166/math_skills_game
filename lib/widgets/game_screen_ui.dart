// lib/widgets/game_screen_ui.dart - Enhanced with swipe/drag toggle
import 'package:flutter/material.dart';
import 'package:number_ninja/models/level_completion_model.dart';
import 'package:number_ninja/widgets/progress_stars.dart';
import 'package:number_ninja/widgets/race_character.dart';
import 'package:number_ninja/services/high_score_service.dart';
import '../models/difficulty_level.dart';
import '../models/operation_config.dart';
import '../models/ring_model.dart';
import '../models/locked_equation.dart';
import '../models/game_mode.dart';
import '../models/rotation_speed.dart';
import 'simple_ring.dart';
import 'equation_layout.dart';
import 'equation_highlight_overlay.dart';

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
  final String currentHighScore;
  final bool isGameRunning;

  // NEW: Control mode toggle
  final bool isDragMode;
  final VoidCallback onToggleMode;

  // NEW: Rotation speed control
  final RotationSpeed rotationSpeed;

  // NEW: Equation highlight overlay control
  final bool showEquationHighlight;

  // Callback functions for interactions
  final Function(int) onUpdateInnerRing;
  final Function(int) onUpdateOuterRing;
  final Function(int, int) onTileTap;
  final Function(int) onEquationTap;
  final VoidCallback onShowSettings;

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
    required this.currentHighScore,
    required this.isGameRunning,
    required this.isDragMode, // NEW
    required this.onToggleMode, // NEW
    required this.rotationSpeed, // NEW
    this.showEquationHighlight = false, // NEW
    required this.onUpdateInnerRing,
    required this.onUpdateOuterRing,
    required this.onTileTap,
    required this.onEquationTap,
    required this.onShowSettings,
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
        title = 'Addition';
        break;
      case 'subtraction':
        title = 'Subtraction';
        break;
      case 'division':
        title = 'Division';
        break;
      case 'multiplication':
      default:
        title = 'Multiplication';
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
          // Settings button
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: onShowSettings,
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
              // Centered rings and stars
              Align(
                alignment: Alignment(0, 0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Race character above the rings
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: RaceCharacter(
                        highScoreTimeMs: HighScoreService.parseHighScoreToMs(currentHighScore),
                        currentElapsedTimeMs: elapsedTimeMs,
                        completedStars: lockedEquations.length, // Number of completed stars
                        isGameRunning: isGameRunning,
                        isGameComplete: isGameComplete,
                        width: screenWidth * 0.8,
                        characterColor: operation.color,
                        highScoreString: currentHighScore,
                      ),
                    ),
                    
                    // Game board section - centered
                    Container(
                      width: boardSize,
                      height: boardSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring - UPDATED to use mode toggle and rotation speed
                          SimpleRing(
                            key: ValueKey(
                                'outer_${isDragMode ? 'drag' : 'swipe'}_${rotationSpeed.level}'), // Force rebuild when mode or speed changes
                            ringModel: outerRingModel,
                            size: boardSize,
                            tileSize: outerTileSize,
                            isInner: false,
                            onRotateSteps: onUpdateOuterRing,
                            lockedEquations: lockedEquations,
                            greyedOutNumbers: greyedOutNumbers,
                            onTileTap: onTileTap,
                            transitionRate: rotationSpeed
                                .transitionRate, // NEW: Use user's preferred speed
                            margin: margin,
                            isDragMode: isDragMode, // NEW parameter
                            gameMode: gameMode, // NEW parameter
                          ),

                          // Inner ring - UPDATED to use mode toggle and rotation speed
                          SimpleRing(
                            key: ValueKey(
                                'inner_${isDragMode ? 'drag' : 'swipe'}_${rotationSpeed.level}'), // Force rebuild when mode or speed changes
                            ringModel: innerRingModel,
                            size: innerRingSize,
                            tileSize: innerTileSize,
                            isInner: true,
                            onRotateSteps: onUpdateInnerRing,
                            lockedEquations: lockedEquations,
                            greyedOutNumbers: greyedOutNumbers,
                            onTileTap: onTileTap,
                            transitionRate: rotationSpeed
                                .transitionRate, // NEW: Use user's preferred speed
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
                                  operation.color.withValues(alpha: 0.7),
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
                            gameMode: gameMode,
                            isGameComplete: isGameComplete,
                          ),

                          // Equation highlight overlay
                          if (showEquationHighlight)
                            EquationHighlightOverlay(
                              size: boardSize,
                              tileSize: outerTileSize,
                              margin: margin,
                              innerRingModel: innerRingModel,
                              outerRingModel: outerRingModel,
                              targetNumber: targetNumber,
                              isVisible: showEquationHighlight,
                            ),
                        ],
                      ),
                    ),

                    // Progress stars under the rings
                    Container(
                      padding: EdgeInsets.only(top: 20, bottom: 0),
                      child: ProgressStars(
                        total: 12,
                        completed: lockedEquations.length,
                      ),
                    ),
                  ],
                ),
              ),

              // Title at the top
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  '${difficultyLevel.displayName} Mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: operation.color,
                  ),
                ),
              ),

              // Completion message overlay removed - user requested no bottom popups

              // Star animations layer
              ...starAnimations,
            ],
          ),
        ),
      ),
    );
  }


  // _buildCompletionMessage removed - user requested no bottom popups
}