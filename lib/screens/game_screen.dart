// lib/screens/game_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:number_ninja/animations/celebration_animation.dart';
import 'package:number_ninja/animations/star_animation.dart';
import 'package:number_ninja/models/difficulty_level.dart';
import 'package:number_ninja/models/level_completion_model.dart';
import 'package:number_ninja/services/haptic_service.dart';
import 'package:number_ninja/services/leaderboard_service.dart';
import 'package:number_ninja/services/sound_service.dart';
import 'package:number_ninja/services/unlock_celebration_service.dart';
import 'package:number_ninja/services/user_service.dart';
import 'package:number_ninja/services/user_stats_service.dart';
import 'package:number_ninja/services/high_score_service.dart';
import 'package:number_ninja/widgets/game_screen_ui.dart';
import 'package:number_ninja/widgets/time_penalty_animation.dart';
import 'package:number_ninja/screens/game_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async'; // Add Timer import
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../models/game_mode.dart';
import '../models/rotation_speed.dart';
import '../utils/game_utils.dart';

class GameScreen extends StatefulWidget {
  final String operationName;
  final DifficultyLevel difficultyLevel;
  final int? targetNumber;
  final GameMode gameMode;

  const GameScreen({
    Key? key,
    required this.operationName,
    required this.difficultyLevel,
    this.targetNumber,
    this.gameMode = GameMode.timesTableRing,
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

  // High score tracking
  String _currentHighScore = '--:--';

  // Track greyed out number pairs for times table mode
  Set<String> greyedOutPairs = {};

  // Track solved equations by value (not position) for times table mode
  Set<String> solvedEquations = {};

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

  // Track if any mistakes were made during this game session
  bool _hasMadeMistakes = false;

  final HapticService _hapticService = HapticService();
  final SoundService _soundService = SoundService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDragMode = false; // Default to swipe mode
  RotationSpeed _rotationSpeed =
      RotationSpeed.defaultSpeed; // Default rotation speed

  bool _showEquationHighlight = true; // Show equation highlighting overlay (for testing)

// Add more debug logging to GameScreen initState method:

  @override
  void initState() {
    super.initState();

    print("🎮 GameScreen.initState() START");
    print("   - operation: ${widget.operationName}");
    print("   - difficulty: ${widget.difficultyLevel.displayName}");
    print("   - targetNumber: ${widget.targetNumber}");
    print("   - gameMode: ${widget.gameMode}");

    try {
      // Initialize the operation configuration
      operation = OperationConfig.forOperation(widget.operationName);
      print("   ✅ Operation config initialized");

      // Set the background gradient based on operation
      _setBackgroundGradient();
      print("   ✅ Background gradient set");

      // Set target number based on difficulty level
      if (widget.targetNumber != null) {
        targetNumber = widget.targetNumber!;
      } else {
        final random = Random();
        targetNumber = widget.difficultyLevel.getRandomCenterNumber(random);
      }
      print("   ✅ Target number set: $targetNumber");

      // Generate game numbers
      print("   🎲 Generating game numbers...");
      _generateGameNumbers();
      print("   ✅ Game numbers generated");

      // Start game timer
      print("   ⏰ Starting game timer...");
      _startGameTimer();
      print("   ✅ Game timer started");

      print("   💾 Loading control mode preference...");
      _loadControlModePreference();
      print("   ✅ Control mode preference loaded");

      print("   🔧 Loading rotation speed preference...");
      _loadRotationSpeedPreference();
      print("   ✅ Rotation speed preference loaded");

      print("   🏆 Loading high score for current level...");
      _loadCurrentLevelHighScore();
      print("   ✅ High score loaded");

      print("🎮 GameScreen.initState() COMPLETED SUCCESSFULLY");
    } catch (e, stackTrace) {
      print("❌ ERROR in GameScreen.initState(): $e");
      print("   Stack trace: $stackTrace");
      rethrow;
    }
  }

  @override
  void dispose() {
    print("🔥 GameScreen.dispose() called");

    // Stop the timer FIRST to prevent any more setState calls
    _isTimerRunning = false;
    print("🔥 Timer stopped");

    _gameTimer?.cancel();
    _gameTimer = null;
    print("🔥 Timer cancelled");

    // Clear all animations to prevent setState calls
    starAnimations.clear();
    _activePenaltyAnimations.clear();
    print("🔥 Animations cleared");

    // Call super.dispose() LAST
    super.dispose();
    print("🔥 Super.dispose() called");
  }

  void _toggleControlMode() {
    // Add mounted check to prevent setState after disposal
    if (!mounted) return;

    setState(() {
      _isDragMode = !_isDragMode;
    });

    // Save preference asynchronously
    _saveControlModePreference();

    // Show feedback only if still mounted
    if (mounted) {
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
  }

  // Optional: Save/load preference
  void _saveControlModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drag_mode', _isDragMode);
  }

  void _loadControlModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDragMode = prefs.getBool('drag_mode') ?? false; // Default to swipe
      });
    }
  }

  void _loadRotationSpeedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final speedLevel =
        prefs.getInt('rotation_speed') ?? 5; // Default to Normal (level 5)
    final loadedSpeed = RotationSpeed.fromLevel(speedLevel);

    if (mounted) {
      setState(() {
        _rotationSpeed = loadedSpeed;
      });
    }
  }

  void _loadCurrentLevelHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _currentHighScore = '--:--';
      });
      return;
    }

    try {
      final userService = UserService();
      final allCompletions = await userService.getLevelCompletions(user.uid);

      // Filter completions for this operation
      final operationCompletions = allCompletions
          .where(
              (completion) => completion.operationName == widget.operationName)
          .toList();

      String bestTime = _getBestTimeForCurrentLevel(operationCompletions);

      if (mounted) {
        setState(() {
          _currentHighScore = bestTime;
        });
      }
    } catch (e) {
      print('Error loading high score: $e');
      if (mounted) {
        setState(() {
          _currentHighScore = '--:--';
        });
      }
    }
  }

  String _getBestTimeForCurrentLevel(List<LevelCompletionModel> completions) {
    final bestTime = HighScoreService.getBestTimeForLevel(
      completions: completions,
      operationName: widget.operationName,
      difficultyLevel: widget.difficultyLevel,
      targetNumber: targetNumber,
    );
    
    print('🏆 High score for ${widget.operationName} target $targetNumber: $bestTime');
    print('🏆 High score in ms: ${HighScoreService.parseHighScoreToMs(bestTime)}');
    
    return bestTime;
  }


  void _startGameTimer() {
    _startTime = DateTime.now();
    _isTimerRunning = true;

    // Update timer every 100ms
    _gameTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      // Check if widget is still mounted AND timer should be running
      if (_isTimerRunning && mounted) {
        setState(() {
          _elapsedTimeMs =
              DateTime.now().difference(_startTime!).inMilliseconds;
        });
      } else {
        // Cancel timer if widget is disposed or timer should stop
        timer.cancel();
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
          Colors.green.shade200,
        ];
        break;
      case 'subtraction':
        backgroundGradient = [
          Colors.purple.shade100,
          Colors.purple.shade200,
        ];
        break;
      case 'multiplication':
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade200,
        ];
        break;
      case 'division':
        backgroundGradient = [
          Colors.orange.shade100,
          Colors.orange.shade200,
        ];
        break;
      default:
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade200,
        ];
    }
  }
// Update _generateGameNumbers method with debug logging:

  void _generateGameNumbers() {
    print("🎲 _generateGameNumbers START");
    print("   - gameMode: ${widget.gameMode}");
    print("   - operation: ${widget.operationName}");
    print("   - targetNumber: $targetNumber");

    final random = Random();

    List<int> innerNumbers;
    List<int> outerNumbers;

    try {
      if (widget.operationName == 'multiplication' ||
          widget.operationName == 'division') {
        print("   📊 Using Times Table Ring Mode");
        // Times Table Ring Mode: inner ring 1-12, outer ring has all 12 correct answers + 4 distractors
        innerNumbers = List.generate(12, (index) => index + 1); // 1-12
        print("   ✅ Inner numbers (1-12): $innerNumbers");

        print("   🎯 Generating Times Table Ring outer numbers...");
        outerNumbers =
            GameGenerator.generateTimesTableRingNumbers(targetNumber, random);
        print("   ✅ Outer numbers generated: $outerNumbers");
      } else if (widget.operationName == 'addition' ||
          widget.operationName == 'subtraction') {
        print("   📊 Using Addition/Subtraction Ring Mode (12 answers)");
        // Ring Mode for addition/subtraction: inner ring 1-12, outer ring has all 12 correct answers + 4 distractors
        innerNumbers = List.generate(12, (index) => index + 1); // 1-12
        print("   ✅ Inner numbers (1-12): $innerNumbers");

        switch (widget.operationName) {
          case 'addition':
            print("   🎯 Generating addition ring outer numbers...");
            outerNumbers = GameGenerator.generateAdditionRingNumbers(
                targetNumber, widget.difficultyLevel.maxOuterNumber, random);
            break;
          case 'subtraction':
            print("   🎯 Generating subtraction ring outer numbers...");
            outerNumbers = GameGenerator.generateSubtractionRingNumbers(
                targetNumber, widget.difficultyLevel.maxOuterNumber, random);
            break;
          default:
            print("   🎯 Generating default addition ring outer numbers...");
            outerNumbers = GameGenerator.generateAdditionRingNumbers(
                targetNumber, widget.difficultyLevel.maxOuterNumber, random);
            break;
        }
        print("   ✅ Outer numbers generated: $outerNumbers");
      } else if (widget.operationName == 'multiplication') {
        print("   ✖️ Using Standard Multiplication Mode");
        innerNumbers = List.generate(12, (index) => index + 1); // 1-12
        print("   ✅ Inner numbers (1-12): $innerNumbers");

        print("   🎯 Generating standard multiplication outer numbers...");
        outerNumbers =
            GameGenerator.generateMultiplicationNumbers(targetNumber, random);
        print("   ✅ Outer numbers generated: $outerNumbers");
      } else if (widget.operationName == 'division') {
        print("   ➗ Using Standard Division Mode");
        innerNumbers = List.generate(12, (index) => index + 1); // 1-12
        print("   ✅ Inner numbers (1-12): $innerNumbers");

        print("   🎯 Generating standard division outer numbers...");
        outerNumbers =
            GameGenerator.generateDivisionNumbers(targetNumber, random);
        print("   ✅ Outer numbers generated: $outerNumbers");
      } else {
        print("   ➕➖ Using Addition/Subtraction Standard Mode");
        // Original logic for other operations
        innerNumbers = widget.difficultyLevel.innerRingNumbers;
        print("   ✅ Inner numbers from difficulty: $innerNumbers");

        switch (widget.operationName) {
          case 'addition':
            print("   🎯 Generating addition outer numbers...");
            outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
                targetNumber, widget.difficultyLevel.maxOuterNumber, random);
            break;
          case 'subtraction':
            print("   🎯 Generating subtraction outer numbers...");
            outerNumbers = GameGenerator.generateSubtractionNumbers(
                innerNumbers,
                targetNumber,
                widget.difficultyLevel.maxOuterNumber,
                random);
            break;
          default:
            print("   🎯 Generating default (addition) outer numbers...");
            outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
                targetNumber, widget.difficultyLevel.maxOuterNumber, random);
            break;
        }
        print("   ✅ Outer numbers generated: $outerNumbers");
      }

      print("   🔄 Creating ring models...");
      // Initialize ring models
      innerRingModel = RingModel(
        numbers: innerNumbers,
        color: _getInnerRingColor(),
        cornerIndices: [0, 3, 6, 9], // Inner ring corners
      );
      print("   ✅ Inner ring model created");

      outerRingModel = RingModel(
        numbers: outerNumbers,
        color: _getOuterRingColor(),
        cornerIndices: [0, 4, 8, 12], // Outer ring corners
      );
      print("   ✅ Outer ring model created");

      print("🎲 _generateGameNumbers COMPLETED SUCCESSFULLY");
    } catch (e, stackTrace) {
      print("❌ ERROR in _generateGameNumbers: $e");
      print("   Stack trace: $stackTrace");
      rethrow;
    }
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
    // Get numbers at corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

    final result =
        operation.checkEquation(innerNumber, outerNumber, targetNumber);

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
          // In _showStarAnimation method, update the onComplete callback:
          onComplete: () {
            // Remove this animation when it's complete, but only if mounted
            if (mounted) {
              setState(() {
                starAnimations.removeWhere((element) {
                  if (element is StarAnimation) {
                    return element.startPosition == startPosition &&
                        element.endPosition == endPosition;
                  }
                  return false;
                });
              });
            }
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

      // Handle the number drop based on game mode
      _onNumberDrop(cornerIndex);
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

  /// Handle number drop - supports both locking (standard mode) and greying out (times table ring mode)
  void _onNumberDrop(int cornerIndex) {
    // In times table ring mode, grey out the numbers instead of locking
    _greyOutNumbers(cornerIndex);
  }

  /// Grey out numbers in times table ring mode instead of locking them
  void _greyOutNumbers(int cornerIndex) {
    // Get current numbers at these positions
    final outerNumber = outerRingModel
        .getNumberAtPosition(outerRingModel.cornerIndices[cornerIndex]);
    final innerNumber = innerRingModel
        .getNumberAtPosition(innerRingModel.cornerIndices[cornerIndex]);

    // Create equation key to track unique equations solved
    final equationKey = '$innerNumber×$targetNumber=$outerNumber';

    // If this exact equation was already solved, don't count it again
    if (solvedEquations.contains(equationKey)) {
      return;
    }

    // Get corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    // Create a locked equation object (for tracking purposes)
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

    // Update state - grey out instead of lock
    setState(() {
      // Track this specific equation as solved
      solvedEquations.add(equationKey);

      // Add to locked equations list for tracking progress only
      lockedEquations.add(lockedEquation);

      // Add number pairs to greyed out set (track the actual numbers)
      greyedOutPairs.add('inner_$innerNumber');
      greyedOutPairs.add('outer_$outerNumber');

      // Add star animation
      _showStarAnimation(cornerIndex);

      // Check if all 12 equations are complete (times table ring win condition)
      if (solvedEquations.length >= 12) {
        // All 12 unique equations solved
        isGameComplete = true;
        _stopGameTimer(); // Stop timer when game is complete
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            _showWinDialog();
          }
        });
      }
    });

    // Visual feedback removed - user requested no bottom popups
  }

  void _addTimePenalty(int cornerIndex) {
    print("🔴 DEBUG: _addTimePenalty called for cornerIndex: $cornerIndex");

    // Mark that a mistake was made
    _hasMadeMistakes = true;

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
      // In _addTimePenalty method, update the onComplete callback:
      onComplete: () {
        print("🔴 DEBUG: Animation $animationId completed, calling onComplete");

        // Use a post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print("🔴 DEBUG: Post-frame callback executing for $animationId");
          // CRITICAL: Check if widget is still mounted before setState
          if (mounted && _activePenaltyAnimations.containsKey(animationId)) {
            print(
                "🔴 DEBUG: Widget is mounted, proceeding with setState for $animationId");
            setState(() {
              final removed = _activePenaltyAnimations.remove(animationId);
              print(
                  "🔴 DEBUG: Removed animation $animationId: ${removed != null}");
            });
          } else {
            print(
                "🔴 DEBUG: Widget not mounted or animation already removed, skipping setState for $animationId");
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
      greyedOutNumbers: greyedOutPairs,
      gameMode: widget.gameMode,
      starAnimations: [
        ...starAnimations,
        ..._activePenaltyAnimations
            .values // 🔥 Use values directly, no separate list!
      ],
      isGameComplete: isGameComplete,
      elapsedTimeMs: _displayedElapsedTimeMs,
      currentHighScore: _currentHighScore,
      isGameRunning: _isTimerRunning,
      onUpdateInnerRing: _updateInnerRing,
      onUpdateOuterRing: _updateOuterRing,
      onTileTap: _handleTileTap,
      onEquationTap: _handleEquationTap,
      onShowSettings: _showGameSettings,
      isDragMode: _isDragMode,
      onToggleMode: _toggleControlMode,
      rotationSpeed: _rotationSpeed,
      showEquationHighlight: _showEquationHighlight,
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

        // Track mistakes and perfect completions for unlock system
        if ((widget.operationName == 'multiplication' ||
                widget.operationName == 'division') &&
            widget.targetNumber != null) {
          if (_hasMadeMistakes) {
            // Track that mistakes were made in this level
            await userService.trackMistake(userId, widget.operationName,
                widget.difficultyLevel.displayName, widget.targetNumber!);
            print("Mistake tracked for unlock system");
          } else {
            // Track perfect completion for potential unlocks
            final newlyUnlockedTables =
                await userService.trackPerfectCompletion(
                    userId,
                    widget.operationName,
                    widget.difficultyLevel.displayName,
                    widget.targetNumber!);
            print("Perfect completion tracked for unlock system");

            // Show celebration if new tables were unlocked
            if (newlyUnlockedTables.isNotEmpty && mounted) {
              // Small delay to let the completion dialog finish
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted) {
                  UnlockCelebrationService()
                      .showUnlockCelebration(context, newlyUnlockedTables);
                }
              });
            }
          }
        }

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
                            : Colors.grey.withValues(alpha: 0.3),
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
                  'Total time: ${StarRatingCalculator.formatTime(completionTimeMs)}',
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
                    greyedOutPairs.clear();
                    solvedEquations.clear();
                    isGameComplete = false;
                    starAnimations = [];
                    _activePenaltyAnimations.clear();
                    _totalPenaltyTimeMs = 0;
                    _penaltyCounter = 0;

                    if (widget.operationName == 'multiplication' ||
                        widget.operationName == 'division') {
                      targetNumber = widget.targetNumber ?? targetNumber;
                    } else {
                      // Keep the same target number for "Play Again" instead of randomizing
                      targetNumber = targetNumber;
                    }

                    _generateGameNumbers();
                    _elapsedTimeMs = 0;
                    _startGameTimer();
                  });
                  // Refresh high score immediately after resetting the game
                  _loadCurrentLevelHighScore();
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

  void _showGameSettings() async {
    // Light haptic feedback when showing settings
    _hapticService.lightImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSettingsScreen(
          operation: operation,
          isDragMode: _isDragMode,
          onToggleMode: _toggleControlMode,
        ),
      ),
    );
    
    // Reload rotation speed when returning from settings
    _loadRotationSpeedPreference();
  }
}

// Add this extension method
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
