// lib/screens/game_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:math_skills_game/animations/celebration_animation.dart';
import 'package:math_skills_game/animations/star_animation.dart';
import 'package:math_skills_game/models/difficulty_level.dart';
import 'package:math_skills_game/models/level_completion_model.dart';
import 'package:math_skills_game/services/haptic_service.dart';
import 'package:math_skills_game/services/leaderboard_service.dart';
import 'package:math_skills_game/services/sound_service.dart';
import 'package:math_skills_game/services/user_service.dart';
import 'package:math_skills_game/services/user_stats_service.dart';
import 'package:math_skills_game/utils/tutorial_helper.dart';
import 'package:math_skills_game/widgets/game_screen_ui.dart';
import 'package:math_skills_game/widgets/time_penalty_animation.dart';
import 'package:math_skills_game/widgets/tutorial_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async'; // Add Timer import
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../utils/game_utils.dart';

class GameScreen extends StatefulWidget {
  final String operationName;
  final DifficultyLevel difficultyLevel;
  final int? targetNumber;

  const GameScreen({
    Key? key,
    required this.operationName,
    required this.difficultyLevel,
    this.targetNumber,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RingModel outerRingModel;
  late RingModel innerRingModel;
  late OperationConfig operation;
  late int targetNumber;

  // Track locked equations
  List<LockedEquation> lockedEquations = [];

  // List to keep track of active star animations
  List<Widget> starAnimations = [];

  // Track if the game is complete
  bool isGameComplete = false;

  // Background gradient colors based on operation
  late List<Color> backgroundGradient;

  // Game timer variables
  DateTime? _startTime;
  DateTime? _endTime;
  Timer? _gameTimer;
  int _elapsedTimeMs = 0;
  bool _isTimerRunning = false;

  int _totalPenaltyTimeMs = 0;
  Map<String, Widget> _activePenaltyAnimations = {}; // Track by unique ID
  static const int PENALTY_SECONDS = 3;
  int _penaltyCounter = 0; // Counter for unique IDs

  int get _displayedElapsedTimeMs => _elapsedTimeMs + _totalPenaltyTimeMs;

  final HapticService _hapticService = HapticService();
  final SoundService _soundService = SoundService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDragMode = false; // Default to swipe mode

  @override
  void initState() {
    super.initState();

    print(
        "GameScreen initialized with: operation=${widget.operationName}, difficulty=${widget.difficultyLevel.displayName}, targetNumber=${widget.targetNumber}");

    // Initialize the operation configuration
    operation = OperationConfig.forOperation(widget.operationName);

    // Set the background gradient based on operation
    _setBackgroundGradient();

    // Set target number based on difficulty level
    if (widget.targetNumber != null) {
      targetNumber = widget.targetNumber!;
    } else {
      final random = Random();
      targetNumber = widget.difficultyLevel.getRandomCenterNumber(random);
    }

    // Generate game numbers
    _generateGameNumbers();

    // Start game timer
    _startGameTimer();

    _checkAndShowTutorial();

    _loadControlModePreference();
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _gameTimer?.cancel();
    // Clean up animations
    starAnimations.clear();
    super.dispose();
  }

  void _toggleControlMode() {
    setState(() {
      _isDragMode = !_isDragMode;
    });

    // Optional: Save preference to SharedPreferences
    _saveControlModePreference();

    // Optional: Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isDragMode ? 'Switched to Drag Mode' : 'Switched to Swipe Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: operation.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Optional: Save/load preference
  void _saveControlModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drag_mode', _isDragMode);
  }

  void _loadControlModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDragMode = prefs.getBool('drag_mode') ?? false; // Default to swipe
    });
  }

  void _startGameTimer() {
    _startTime = DateTime.now();
    _isTimerRunning = true;

    // Update timer every 100ms
    _gameTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_isTimerRunning) {
        setState(() {
          _elapsedTimeMs =
              DateTime.now().difference(_startTime!).inMilliseconds;
        });
      }
    });
  }

  void _stopGameTimer() {
    _isTimerRunning = false;
    _endTime = DateTime.now();
    _gameTimer?.cancel();
  }

  void _setBackgroundGradient() {
    switch (widget.operationName) {
      case 'addition':
        backgroundGradient = [
          Colors.green.shade100,
          Colors.green.shade50,
        ];
        break;
      case 'subtraction':
        backgroundGradient = [
          Colors.purple.shade100,
          Colors.purple.shade50,
        ];
        break;
      case 'multiplication':
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade50,
        ];
        break;
      case 'division':
        backgroundGradient = [
          Colors.orange.shade100,
          Colors.orange.shade50,
        ];
        break;
      default:
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade50,
        ];
    }
  }

  // Generate numbers for game
  void _generateGameNumbers() {
    final random = Random();

    List<int> innerNumbers;
    List<int> outerNumbers;

    if (widget.operationName == 'multiplication') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = GameGenerator.generateMultiplicationNumbers(
          targetNumber, random); // ✅ removed maxOuterNumber
    } else if (widget.operationName == 'division') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = GameGenerator.generateDivisionNumbers(
          targetNumber, random); // ✅ removed maxOuterNumber
    } else {
      // Original logic for other operations
      innerNumbers = widget.difficultyLevel.innerRingNumbers;

      switch (widget.operationName) {
        case 'addition':
          outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
        case 'subtraction':
          outerNumbers = GameGenerator.generateSubtractionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
        default:
          outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
      }
    }

    // Initialize ring models
    innerRingModel = RingModel(
      numbers: innerNumbers,
      color: _getInnerRingColor(),
      cornerIndices: [0, 3, 6, 9], // Inner ring corners
    );

    outerRingModel = RingModel(
      numbers: outerNumbers,
      color: _getOuterRingColor(),
      cornerIndices: [0, 4, 8, 12], // Outer ring corners
    );
  }

  // Get more vibrant inner ring color
  Color _getInnerRingColor() {
    switch (widget.operationName) {
      case 'addition':
        return Colors.green.shade400;
      case 'subtraction':
        return Colors.purple.shade400;
      case 'multiplication':
        return Colors.blue.shade400;
      case 'division':
        return Colors.orange.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  // Get more vibrant outer ring color
  Color _getOuterRingColor() {
    switch (widget.operationName) {
      case 'addition':
        return Colors.teal.shade400;
      case 'subtraction':
        return Colors.deepPurple.shade400;
      case 'multiplication':
        return Colors.cyan.shade400;
      case 'division':
        return Colors.amber.shade400;
      default:
        return Colors.teal.shade400;
    }
  }

  bool _checkEquation(int cornerIndex) {
    print("DEBUG: Checking equation at cornerIndex: $cornerIndex");

    // If this corner is already locked, don't check it again
    if (lockedEquations.any((eq) => eq.cornerIndex == cornerIndex)) {
      print("DEBUG: This corner is already locked");
      return true;
    }

    // Get numbers at corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

    print(
        "DEBUG: Equation values - innerNumber: $innerNumber, outerNumber: $outerNumber, target: $targetNumber");

    final result =
        operation.checkEquation(innerNumber, outerNumber, targetNumber);
    print("DEBUG: Equation check result: $result");

    return result;
  }

  void _updateOuterRing(int steps) {
    // Light haptic feedback when rotating
    _hapticService.lightImpact();

    setState(() {
      // Create a new model with the rotation applied
      outerRingModel = outerRingModel.copyWithRotation(steps);
    });
    _checkAllEquations();
  }

  void _updateInnerRing(int steps) {
    // Light haptic feedback when rotating
    _hapticService.lightImpact();

    setState(() {
      // Create a new model with the rotation applied
      innerRingModel = innerRingModel.copyWithRotation(steps);
    });
    _checkAllEquations();
  }

// Lock an equation when it's correct
  void _lockEquation(int cornerIndex) {
    // If already locked, do nothing
    if (lockedEquations.any((eq) => eq.cornerIndex == cornerIndex)) {
      return;
    }

    // Get corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    // Get current numbers at these positions
    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

    // Create a locked equation object
    final lockedEquation = LockedEquation(
      cornerIndex: cornerIndex,
      innerNumber: innerNumber,
      targetNumber: targetNumber,
      outerNumber: outerNumber,
      innerPosition: innerCornerPos,
      outerPosition: outerCornerPos,
      operation: widget.operationName,
      equationString:
          operation.getEquationString(innerNumber, targetNumber, outerNumber),
    );

    // Provide haptic feedback for success
    _hapticService.success();

    // Update state with locked positions
    setState(() {
      // Add to locked equations list
      lockedEquations.add(lockedEquation);

      // Create new models with the positions locked
      innerRingModel =
          innerRingModel.copyWithLockedPosition(innerCornerPos, innerNumber);
      outerRingModel =
          outerRingModel.copyWithLockedPosition(outerCornerPos, outerNumber);

      // Add star animation
      _showStarAnimation(cornerIndex);

      // Check if all four corners are locked (win condition)
      if (lockedEquations.length == 4) {
        isGameComplete = true;
        _stopGameTimer(); // Stop timer when game is complete
        Future.delayed(Duration(milliseconds: 1000), () {
          _showWinDialog();
        });
      }
    });

    // Provide visual feedback with a colorful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'Great job! ${lockedEquations.length}/4 equations complete!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: operation.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show star animation when an equation is locked
  void _showStarAnimation(int cornerIndex) {
    // Calculate the start position (from the corner)
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.9;

    Offset startPosition;
    switch (cornerIndex) {
      case 0: // Top
        startPosition = Offset(boardSize / 2, 0);
        break;
      case 1: // Right
        startPosition = Offset(boardSize, boardSize / 2);
        break;
      case 2: // Bottom
        startPosition = Offset(boardSize / 2, boardSize);
        break;
      case 3: // Left
        startPosition = Offset(0, boardSize / 2);
        break;
      default:
        startPosition = Offset(boardSize / 2, boardSize / 2);
    }

    // End position should be at the top progress bar
    // We'll position it based on the locked equation count
    final endPosition = Offset(
      (screenWidth / 5) * lockedEquations.length,
      60, // Approximate y-position of the progress stars
    );

    // Add the star animation to the list
    setState(() {
      starAnimations.add(
        StarAnimation(
          startPosition: startPosition,
          endPosition: endPosition,
          onComplete: () {
            // Remove this animation when it's complete
            setState(() {
              starAnimations.removeWhere((element) {
                if (element is StarAnimation) {
                  return element.startPosition == startPosition &&
                      element.endPosition == endPosition;
                }
                return false;
              });
            });
          },
        ),
      );
    });
  }

  void _handleEquationTap(int cornerIndex) {
    print("DEBUG: _handleEquationTap called for cornerIndex: $cornerIndex");

    // Check if this equation is correct
    final isCorrect = _checkEquation(cornerIndex);
    print("DEBUG: Equation is correct? $isCorrect");

    if (isCorrect) {
      // Play correct sound and vibration
      _soundService.playCorrect();

      // If it's correct, lock it
      _lockEquation(cornerIndex);
    } else {
      // WRONG ANSWER - Add penalty time and show animation
      _addTimePenalty(cornerIndex);

      // Play incorrect sound and vibration
      _soundService.playIncorrect();

      // Hide any current snackbar before showing a new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show updated snackbar with penalty info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Wrong! +${PENALTY_SECONDS}s penalty. Rotate the rings to make a correct equation.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _addTimePenalty(int cornerIndex) {
    print("🔴 DEBUG: _addTimePenalty called for cornerIndex: $cornerIndex");

    // Add penalty to total
    setState(() {
      _totalPenaltyTimeMs += PENALTY_SECONDS * 1000;
    });
    print("🔴 DEBUG: Total penalty time now: ${_totalPenaltyTimeMs}ms");

    // Calculate animation position (at the corner that was tapped)
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.9;

    Offset penaltyPosition;
    switch (cornerIndex) {
      case 0: // Top
        penaltyPosition = Offset(boardSize / 2, boardSize * 0.2);
        break;
      case 1: // Right
        penaltyPosition = Offset(boardSize * 0.8, boardSize / 2);
        break;
      case 2: // Bottom
        penaltyPosition = Offset(boardSize / 2, boardSize * 0.8);
        break;
      case 3: // Left
        penaltyPosition = Offset(boardSize * 0.2, boardSize / 2);
        break;
      default:
        penaltyPosition = Offset(boardSize / 2, boardSize / 2);
    }

    // Create unique ID for this animation
    final animationId =
        'penalty_${_penaltyCounter++}_${DateTime.now().millisecondsSinceEpoch}';
    print("🔴 DEBUG: Creating penalty animation with ID: $animationId");
    print(
        "🔴 DEBUG: Current active animations before add: ${_activePenaltyAnimations.keys.toList()}");

    // Add penalty animation with unique tracking and KEY
    final penaltyAnimation = TimePenaltyAnimation(
      key: ValueKey(animationId), // 🔥 THIS IS THE FIX - Add unique key!
      animationId: animationId,
      startPosition: penaltyPosition,
      penaltySeconds: PENALTY_SECONDS,
      onComplete: () {
        print("🔴 DEBUG: Animation $animationId completed, calling onComplete");
        print(
            "🔴 DEBUG: Active animations before removal: ${_activePenaltyAnimations.keys.toList()}");

        // Use a post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print("🔴 DEBUG: Post-frame callback executing for $animationId");
          if (mounted) {
            print(
                "🔴 DEBUG: Widget is mounted, proceeding with setState for $animationId");
            setState(() {
              final removed = _activePenaltyAnimations.remove(animationId);
              print(
                  "🔴 DEBUG: Removed animation $animationId: ${removed != null}");
              print(
                  "🔴 DEBUG: Active animations after removal: ${_activePenaltyAnimations.keys.toList()}");
            });
          } else {
            print(
                "🔴 DEBUG: Widget not mounted, skipping setState for $animationId");
          }
        });
      },
    );

    setState(() {
      // Add to our tracking map
      _activePenaltyAnimations[animationId] = penaltyAnimation;
      print("🔴 DEBUG: Added animation $animationId to tracking map");
      print(
          "🔴 DEBUG: Active animations after add: ${_activePenaltyAnimations.keys.toList()}");
    });

    // Also trigger stronger haptic feedback for wrong answer
    _hapticService.error();
    print("🔴 DEBUG: _addTimePenalty completed for $animationId");
  }

  void _handleTileTap(int cornerIndex, int position) {
    print(
        "DEBUG: _handleTileTap called with cornerIndex: $cornerIndex, position: $position");

    // Light haptic feedback when tapping
    _hapticService.lightImpact();

    // Same behavior as tapping on an equation element
    print("DEBUG: About to call _handleEquationTap($cornerIndex)");
    _handleEquationTap(cornerIndex);
  }

  // Check all equations and show debug information
  void _checkAllEquations() {
    for (int i = 0; i < 4; i++) {
      _checkEquation(i);
      lockedEquations.any((eq) => eq.cornerIndex == i);

      // Print the equation details
      final outerCornerPos = outerRingModel.cornerIndices[i];
      final innerCornerPos = innerRingModel.cornerIndices[i];
      outerRingModel.getNumberAtPosition(outerCornerPos);
      innerRingModel.getNumberAtPosition(innerCornerPos);
    }
  }

// Show hint button functionality
  void _showHint() {
    // Light haptic feedback when showing hint
    _hapticService.lightImpact();

    // Find an unlocked corner that could be locked with the current position
    bool foundHint = false;
    for (int i = 0; i < 4; i++) {
      if (!lockedEquations.any((eq) => eq.cornerIndex == i) &&
          _checkEquation(i)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'There\'s a correct equation in one of the corners. Tap to lock it in!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: operation.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        foundHint = true;
        break;
      }
    }

    if (!foundHint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align items to the top
            children: [
              Icon(Icons.touch_app, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                // Add Expanded to allow the text to take available width
                child: Text(
                  'Keep rotating the rings until the equations match!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  softWrap: true, // Allow text to wrap to multiple lines
                  maxLines: 2, // Limit to 2 lines (increase if needed)
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScreenUI(
      operationName: widget.operationName,
      difficultyLevel: widget.difficultyLevel,
      targetNumber: targetNumber,
      operation: operation,
      backgroundGradient: backgroundGradient,
      innerRingModel: innerRingModel,
      outerRingModel: outerRingModel,
      lockedEquations: lockedEquations,
      starAnimations: [
        ...starAnimations,
        ..._activePenaltyAnimations
            .values // 🔥 Use values directly, no separate list!
      ],
      isGameComplete: isGameComplete,
      elapsedTimeMs: _displayedElapsedTimeMs,
      onUpdateInnerRing: _updateInnerRing,
      onUpdateOuterRing: _updateOuterRing,
      onTileTap: _handleTileTap,
      onEquationTap: _handleEquationTap,
      onShowHint: _showHint,
      onShowHelp: _showHelpDialog,
      isDragMode: _isDragMode,
      onToggleMode: _toggleControlMode,
    );
  }

  Future<void> _showWinDialog() async {
    try {
      print("Starting _showWinDialog");

      if (_startTime == null || _endTime == null) {
        print("Start or End time is null");
        return;
      }

      // Use the total time including penalties for final calculation
      final completionTimeMs =
          _endTime!.difference(_startTime!).inMilliseconds +
              _totalPenaltyTimeMs;
      print(
          "Completion time calculated: $completionTimeMs ms (including ${_totalPenaltyTimeMs}ms penalties)");

      final starRating = StarRatingCalculator.calculateStars(
        widget.operationName,
        widget.difficultyLevel.displayName,
        completionTimeMs,
      );
      print("Star rating calculated: $starRating");

      // Play celebration sound based on star rating
      _soundService.playCelebrationByStar(starRating);

      // Initialize high score tracking variables
      bool isNewHighScore = false;
      int? previousRank;
      int? newRank;

      // 🔥 DETECT HIGH SCORE BEFORE SHOWING DIALOG
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          // Get current user data to check for high scores
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final bestTimes =
                userData['bestTimes'] as Map<String, dynamic>? ?? {};
            final currentBestTime =
                bestTimes[widget.operationName] as int? ?? 999999;
            final difficultyKey =
                '${widget.operationName}-${widget.difficultyLevel.displayName.toLowerCase()}';
            final currentDifficultyBestTime =
                bestTimes[difficultyKey] as int? ?? 999999;

            // Determine if this is a high score
            if (!(bestTimes.containsKey(difficultyKey) &&
                bestTimes[difficultyKey] != null)) {
              print(
                  "🏆 This is the first time for $difficultyKey - NEW HIGH SCORE!");
              isNewHighScore = true;
            } else if (completionTimeMs < currentDifficultyBestTime) {
              print(
                  "🏆 New best time for $difficultyKey: $completionTimeMs ms (previous: $currentDifficultyBestTime ms) - NEW HIGH SCORE!");
              isNewHighScore = true;
            } else if (completionTimeMs < currentBestTime) {
              print(
                  "🏆 New overall best time for ${widget.operationName}: $completionTimeMs ms (previous: $currentBestTime ms) - NEW HIGH SCORE!");
              isNewHighScore = true;
            }

            if (isNewHighScore) {
              try {
                print("🏆 HIGH SCORE DETECTED! Personal best achieved!");
              } catch (e) {
                print("Error logging high score: $e");
              }
            }

            print("High score detection: isNewHighScore=$isNewHighScore, " +
                "completionTimeMs=$completionTimeMs, " +
                "currentBestTime=$currentBestTime, " +
                "difficultyKey=$difficultyKey, " +
                "currentDifficultyBestTime=$currentDifficultyBestTime");
          }
        } catch (e) {
          print("Error in high score detection: $e");
        }
      }

      // Show celebration animation with high score info
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: CelebrationAnimation(
                starRating: starRating,
                onComplete: () {
                  Navigator.of(dialogContext).pop();
                  _showCompletionStatsDialog(
                    completionTimeMs,
                    starRating,
                    isNewHighScore: isNewHighScore,
                    // Remove rank parameters
                  );
                },
              ),
            );
          },
        );
      }

      // ✅ Firebase save in the background (doesn't block UI)
      if (userId != null) {
        final userService = UserService();
        final leaderboardService = LeaderboardService();

        final levelCompletion = LevelCompletionModel(
          operationName: widget.operationName,
          difficultyName: widget.difficultyLevel.displayName,
          targetNumber: targetNumber,
          stars: starRating,
          completionTimeMs: completionTimeMs,
          completedAt: DateTime.now(),
        );

        // Save level completion
        await userService.saveLevelCompletion(userId, levelCompletion);
        print("Level completion saved successfully");

        // Update both leaderboards
        await leaderboardService.updateUserInAllLeaderboards(userId,
            isHighScore: isNewHighScore);
        print("Leaderboard data updated successfully");

        // If it was a high score, get the new rank after updating leaderboards
        if (isNewHighScore) {
          try {
            await Future.delayed(
                Duration(milliseconds: 500)); // Wait for leaderboard update
            final leaderboardType = leaderboardService
                .getLeaderboardTypeFromOperation(widget.operationName);
            final rankData = await leaderboardService.getUserLeaderboardData(
                userId, leaderboardType);
            newRank = rankData['rank'] as int?;

            final prefs = await SharedPreferences.getInstance();
            if (newRank != null) {
              await prefs.setInt(
                  'lastRank_${widget.operationName}_${widget.difficultyLevel.displayName}',
                  newRank);
              print(
                  "🏆 New rank after high score: #$newRank (previous: ${previousRank ?? 'none'})");
            }
          } catch (e) {
            print("Error getting new rank: $e");
          }
        }

        // Explicitly handle games update to ensure cache is cleared
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final totalGames = userDoc.data()?['totalGames'] ?? 0;
          await leaderboardService.updateGamesHighScore(userId, totalGames);
          print("Games leaderboard specifically updated");
        }

        // ADDED: Clear leaderboard cache to ensure fresh data on next view
        await leaderboardService.clearCache();
        print("Leaderboard cache cleared to show updated data");

        try {
          final statsService = UserStatsService();
          await statsService.calculateStarsPerOperation(userId);
          print("Operation stars updated successfully");
        } catch (e) {
          print("Error updating operation stars: $e");
        }

        // IMPROVED: Direct leaderboard update for current user
        try {
          // ADDED: Specifically clear games leaderboard cache to ensure it shows updated count
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(
              '${LeaderboardService.CACHED_LEADERBOARD_KEY}.${LeaderboardService.GAMES_LEADERBOARD}_20');
          print(
              "Games leaderboard cache specifically cleared to show updated count");

          print("Leaderboard data updated successfully");
        } catch (e) {
          print("Error updating leaderboard data: $e");
        }
      } else {
        print("User not signed in");
      }
    } catch (e, stack) {
      print("🔥 Crash caught in _showWinDialog");
      print("Error: $e");
      print("Stack trace:\n$stack");
    }
  }

  String getAchievementMessage(int? newRank) {
    if (newRank == null) return "🎉 Great job improving your time! 🎉";

    if (newRank == 1) {
      return "🏆 YOU'RE THE FASTEST! Amazing! 🏆";
    } else if (newRank <= 3) {
      return "🥇 You made the TOP 3! Incredible! 🥇";
    } else if (newRank <= 10) {
      return "⭐ You're in the TOP 10! Well done! ⭐";
    } else if (newRank <= 25) {
      return "🌟 You're in the TOP 25! Keep going! 🌟";
    } else {
      return "📈 You're getting faster! Nice improvement! 📈";
    }
  }

  void _showCompletionStatsDialog(
    int completionTimeMs,
    int starRating, {
    bool isNewHighScore = false,
    // Remove rank parameters entirely
  }) {
    if (context.mounted) {
      // Get appropriate message based on star rating and high score status
      String message;

      if (isNewHighScore) {
        message = "🏆 NEW PERSONAL BEST! 🏆";
      } else {
        // Your existing star-based messages
        switch (starRating) {
          case 0:
            message = "Try a little faster to earn stars!";
            break;
          case 1:
            message = "Good speed! Can you go faster?";
            break;
          case 2:
            message = "Great time! Almost perfect!";
            break;
          case 3:
            message = "Amazing speed! Perfect score!";
            break;
          default:
            message =
                "You completed in ${(completionTimeMs / 1000).toStringAsFixed(2)} seconds";
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              isNewHighScore ? '🎉 SUCCESS! 🎉' : 'Success!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isNewHighScore ? Colors.amber.shade700 : operation.color,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stars display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star,
                        size: 30,
                        color: index < starRating
                            ? Colors.amber
                            : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }),
                ),

                SizedBox(height: 16),

                // High score indicator (if applicable)
                if (isNewHighScore) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FontAwesomeIcons.trophy,
                            color: Colors.amber.shade700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PERSONAL BEST',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // Time information
                Text(
                  'Total time: ${(completionTimeMs / 1000).toStringAsFixed(2)}s',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                if (_totalPenaltyTimeMs > 0) ...[
                  SizedBox(height: 8),
                  Text(
                    'Base time: ${((_elapsedTimeMs) / 1000).toStringAsFixed(2)}s',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Penalties: +${(_totalPenaltyTimeMs / 1000).toStringAsFixed(1)}s',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ],

                SizedBox(height: 12),

                // Main message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isNewHighScore ? 16 : 14,
                    color: isNewHighScore
                        ? Colors.amber.shade700
                        : (starRating == 3 ? Colors.green : operation.color),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true);
                },
                child: Text('Return to Menu'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Your existing play again logic...
                  setState(() {
                    lockedEquations = [];
                    isGameComplete = false;
                    starAnimations = [];
                    _activePenaltyAnimations.clear();
                    _totalPenaltyTimeMs = 0;
                    _penaltyCounter = 0;

                    if (widget.operationName == 'multiplication' ||
                        widget.operationName == 'division') {
                      targetNumber = widget.targetNumber ?? targetNumber;
                    } else {
                      final random = Random();
                      targetNumber =
                          widget.difficultyLevel.getRandomCenterNumber(random);
                    }

                    _generateGameNumbers();
                    _elapsedTimeMs = 0;
                    _startGameTimer();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isNewHighScore ? Colors.amber.shade600 : operation.color,
                ),
                child: Text(
                  'Play Again!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showHelpDialog() {
    // Light haptic feedback when showing help
    _hapticService.lightImpact();

    String equationFormat;
    String additionalInfo = '';

    switch (widget.operationName) {
      case 'addition':
        equationFormat = 'inner + $targetNumber = outer';
        break;
      case 'subtraction':
        equationFormat = 'outer - inner = $targetNumber';
        break;
      case 'multiplication':
        equationFormat = 'inner × $targetNumber = outer';
        additionalInfo =
            'For multiplication, find numbers from the inner ring (1-12) that, when multiplied by $targetNumber, match values in the outer ring. There are at least 4 valid solutions to find!';
        break;
      case 'division':
        equationFormat = 'outer ÷ inner = $targetNumber';
        additionalInfo =
            'For division, find pairs of numbers where an outer ring number divided by an inner ring number (1-12) equals $targetNumber exactly (no remainder). There are at least 4 valid solutions to find!';
        break;
      default:
        equationFormat = 'inner × $targetNumber = outer';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min, // Prevent title overflow
          children: [
            Icon(Icons.info_outline, color: operation.color),
            SizedBox(width: 10),
            Flexible(child: Text('How to Play')),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // Make the content area scrollable with SingleChildScrollView
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.6, // Limit height to 60% of screen height
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem('1',
                    'Rotate the rings to form correct equations at the four corners.'),
                _buildHelpItem(
                    '2', 'Each corner should satisfy: $equationFormat'),
                _buildHelpItem('3',
                    'When a corner has a correct equation, tap any part of it to lock it.'),
                _buildHelpItem('4',
                    'Locked equations stay in place while you continue rotating to solve the remaining corners.'),
                _buildHelpItem('5', 'Complete all four corners to win!'),
                _buildHelpItem(
                    '6', 'Complete levels faster to earn more stars!'),
                if (additionalInfo.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: operation.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(additionalInfo),
                  ),
                ],
                SizedBox(height: 16),
                Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• For addition and multiplication: inner → outer'),
                      Text('• For subtraction and division: outer → inner'),
                      Text('• Faster completion times earn more stars!'),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                (widget.operationName == 'multiplication' ||
                            widget.operationName == 'division') &&
                        widget.targetNumber != null
                    ? Text(
                        '${widget.operationName.capitalize()} Number: ${widget.targetNumber}',
                        style: TextStyle(fontWeight: FontWeight.bold))
                    : Text('Difficulty: ${widget.difficultyLevel.displayName}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close help dialog
              _showTutorial(); // Show the tutorial again
            },
            child: Text('Show Tutorial'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: operation.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: operation.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  void _checkAndShowTutorial() async {
    if (await TutorialHelper.shouldShowTutorial()) {
      // Give a slight delay to ensure the UI is fully rendered
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          _showTutorial();
        }
      });
    }
  }

  void _showTutorial() {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final boardSize = screenWidth * 1.0;
    final innerRingSize = boardSize * 0.62;

    // Center position adjusted for your specific layout
    final centerYPosition = screenHeight * 0.6;

    overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        gameSize: Size(boardSize, boardSize),
        innerRingRadius: innerRingSize / 2,
        outerRingRadius: boardSize / 2,
        centerX: boardSize / 2,
        centerY: centerYPosition,
        onComplete: () {
          overlayEntry?.remove();
          TutorialHelper.markTutorialAsShown();
        },
        // Add the rotation callback
        onRotateRing: () {
          // Rotate clockwise (negative step)
          _updateOuterRing(-1);
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

// Add this extension method
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
