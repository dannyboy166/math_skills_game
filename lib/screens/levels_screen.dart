// lib/screens/levels_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:number_ninja/models/difficulty_level.dart';
import 'package:number_ninja/models/game_mode.dart';
import 'package:number_ninja/models/level_completion_model.dart';
import 'package:number_ninja/screens/game_screen.dart';
import 'package:number_ninja/services/user_service.dart';
import 'package:number_ninja/services/haptic_service.dart';
import 'package:number_ninja/widgets/operation_selector.dart';

class LevelsScreen extends StatefulWidget {
  final String operationName;

  const LevelsScreen({
    Key? key,
    required this.operationName,
  }) : super(key: key);

  @override
  _LevelsScreenState createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<LevelCompletionModel> _completedLevels = [];
  late String _currentOperation;

  // Track unlocked time tables
  List<int> _unlockedTimeTables = [];
  GameMode _selectedGameMode = GameMode.timesTableRing;
  Timer? _gameModeDebounceTimer;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _currentOperation = widget.operationName;
    _loadLevelData();
    _loadUnlockData();
  }

  @override
  void dispose() {
    _gameModeDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLevelData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final allCompletions = await _userService.getLevelCompletions(user.uid);

        // Filter completions for this operation
        _completedLevels = allCompletions
            .where((level) => level.operationName == _currentOperation)
            .toList();
      } catch (e) {
        print('Error loading level data: $e');
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load level data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnlockData() async {
    setState(() {});

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final unlockedTables =
            await _userService.getUnlockedTimeTables(user.uid);
        if (mounted) {
          setState(() {
            _unlockedTimeTables = unlockedTables;
          });
        }
      } catch (e) {
        print('Error loading unlock data: $e');
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleOperationChanged(String operation) {
    if (operation != _currentOperation) {
      setState(() {
        _currentOperation = operation;
      });
      _loadLevelData();
      _loadUnlockData(); // Reload unlock data when operation changes
    }
  }

  // Get color for this operation
  Color _getOperationColor() {
    switch (_currentOperation) {
      case 'addition':
        return Colors.green;
      case 'subtraction':
        return Colors.purple;
      case 'multiplication':
        return Colors.blue;
      case 'division':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Get symbol for this operation
  String _getOperationSymbol() {
    switch (_currentOperation) {
      case 'addition':
        return '+';
      case 'subtraction':
        return '-';
      case 'multiplication':
        return '×';
      case 'division':
        return '÷';
      default:
        return '';
    }
  }

  // Format operation name for display
  String _formatOperationName() {
    return _currentOperation.substring(0, 1).toUpperCase() +
        _currentOperation.substring(1);
  }

  // Get levels for multiplication and division
  List<Map<String, dynamic>> _getMultiplicationDivisionLevels(
      String difficulty) {
    switch (difficulty) {
      case 'Standard':
        return [1, 2, 5, 10]
            .map((number) => {
                  'title': '$number${_getOperationSymbol()} Table',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();
      case 'Challenging':
        return [3, 4, 6, 11]
            .map((number) => {
                  'title': '$number${_getOperationSymbol()} Table',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();
      case 'Expert':
        return [7, 8, 9, 12]
            .map((number) => {
                  'title': '$number${_getOperationSymbol()} Table',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();
      case 'Impossible':
        return [13, 14, 15]
            .map((number) => {
                  'title': '$number${_getOperationSymbol()} Table',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();
      default:
        return [];
    }
  }

  // Get levels for addition and subtraction
  List<Map<String, dynamic>> _getAdditionSubtractionLevels(String difficulty) {
    switch (difficulty) {
      case 'Standard':
        // Individual levels for 1, 2, 3, 4, 5
        return [1, 2, 3, 4, 5]
            .map((number) => {
                  'title': 'Level: $number',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();

      case 'Challenging':
        // Individual levels for 6, 7, 8, 9, 10
        return [6, 7, 8, 9, 10]
            .map((number) => {
                  'title': 'Level: $number',
                  'targetNumber': number,
                  'rangeStart': number,
                  'rangeEnd': number,
                })
            .toList();

      case 'Expert':
        // Range-based levels for Expert
        return [
          {
            'title': 'Level 11-12',
            'targetNumber': 11, // Representative number for UI
            'rangeStart': 11,
            'rangeEnd': 12,
          },
          {
            'title': 'Level 13-14',
            'targetNumber': 13,
            'rangeStart': 13,
            'rangeEnd': 14,
          },
          {
            'title': 'Level 15-16',
            'targetNumber': 15,
            'rangeStart': 15,
            'rangeEnd': 16,
          },
          {
            'title': 'Level 17-18',
            'targetNumber': 17,
            'rangeStart': 17,
            'rangeEnd': 18,
          },
          {
            'title': 'Level 19-20',
            'targetNumber': 19,
            'rangeStart': 19,
            'rangeEnd': 20,
          },
        ];

      case 'Impossible':
        // Range-based levels for Impossible
        return [
          {
            'title': 'Level 21-26',
            'targetNumber': 23,
            'rangeStart': 21,
            'rangeEnd': 26,
          },
          {
            'title': 'Level 27-32',
            'targetNumber': 29,
            'rangeStart': 27,
            'rangeEnd': 32,
          },
          {
            'title': 'Level 33-38',
            'targetNumber': 35,
            'rangeStart': 33,
            'rangeEnd': 38,
          },
          {
            'title': 'Level 39-44',
            'targetNumber': 41,
            'rangeStart': 39,
            'rangeEnd': 44,
          },
          {
            'title': 'Level 45-50',
            'targetNumber': 47,
            'rangeStart': 45,
            'rangeEnd': 50,
          },
        ];

      default:
        return [];
    }
  }

  // Get all levels for a specific difficulty
  List<Map<String, dynamic>> _getLevelsForDifficulty(String difficulty) {
    if (_currentOperation == 'multiplication' ||
        _currentOperation == 'division') {
      return _getMultiplicationDivisionLevels(difficulty);
    } else {
      return _getAdditionSubtractionLevels(difficulty);
    }
  }

  // Find the best stars achieved within a level range
  int _getBestStarsForLevel(Map<String, dynamic> level) {
    final rangeStart = level['rangeStart'];
    final rangeEnd = level['rangeEnd'];

    // Filter completions that fall within this range and for this difficulty
    final matchingCompletions = _completedLevels
        .where((completion) =>
            completion.targetNumber >= rangeStart &&
            completion.targetNumber <= rangeEnd)
        .toList();

    if (matchingCompletions.isEmpty) {
      return 0; // No completions yet
    }

    // Find the maximum stars achieved
    return matchingCompletions
        .map((completion) => completion.stars)
        .reduce((a, b) => a > b ? a : b);
  }

  // Find the best time achieved within a level range
  String _getBestTimeForLevel(Map<String, dynamic> level) {
    final rangeStart = level['rangeStart'];
    final rangeEnd = level['rangeEnd'];

    // Filter completions that fall within this range and have a valid time
    final matchingCompletions = _completedLevels
        .where((completion) =>
            completion.targetNumber >= rangeStart &&
            completion.targetNumber <= rangeEnd &&
            completion.completionTimeMs > 0)
        .toList();

    if (matchingCompletions.isEmpty) {
      return '--:--'; // No valid completions yet
    }

    // Find the minimum time (best time) achieved
    final bestCompletion = matchingCompletions
        .reduce((a, b) => a.completionTimeMs < b.completionTimeMs ? a : b);

    return StarRatingCalculator.formatTime(bestCompletion.completionTimeMs);
  }

  void _navigateToGame(String difficulty, Map<String, dynamic> level) {
    // Prevent multiple simultaneous navigations
    if (_isNavigating) {
      print("🚫 Navigation blocked - already navigating");
      return;
    }

    // For multiplication/division, check if the table is unlocked
    if ((_currentOperation == 'multiplication' ||
        _currentOperation == 'division')) {
      final targetNumber = level['targetNumber'];
      if (!_unlockedTimeTables.contains(targetNumber)) {
        // Show locked message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This table is locked! Complete previous tables perfectly to unlock it.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Cancel any pending mode changes before navigation
    _gameModeDebounceTimer?.cancel();

    setState(() {
      _isNavigating = true;
    });

    print("🎮 Navigating to game with mode: $_selectedGameMode");

    // Get difficulty level enum
    DifficultyLevel difficultyEnum;
    switch (difficulty) {
      case 'Standard':
        difficultyEnum = DifficultyLevel.standard;
        break;
      case 'Challenging':
        difficultyEnum = DifficultyLevel.challenging;
        break;
      case 'Expert':
        difficultyEnum = DifficultyLevel.expert;
        break;
      case 'Impossible':
        difficultyEnum = DifficultyLevel.impossible;
        break;
      default:
        difficultyEnum = DifficultyLevel.standard;
    }

    // For tables (multiplication/division), use exact target number
    // For addition/subtraction with exact targets, use that exact number
    // For range-based levels (Expert/Impossible addition/subtraction), pick random number in range
    int targetToUse = level['targetNumber'];

    // Generate a random number within the range for Expert and Impossible ranges
    if ((_currentOperation == 'addition' ||
            _currentOperation == 'subtraction') &&
        level['rangeStart'] != level['rangeEnd']) {
      final random = Random();
      targetToUse = level['rangeStart'] +
          random.nextInt(level['rangeEnd'] - level['rangeStart'] + 1);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          operationName: _currentOperation,
          difficultyLevel: difficultyEnum,
          targetNumber: targetToUse,
          gameMode: GameMode.timesTableRing,
        ),
      ),
    ).then((_) {
      // Mark navigation as complete and record time
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });

        print("🔙 Returned from game, reloading level data");
        _loadLevelData();
      }
    }).catchError((error) {
      // Handle navigation errors
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
      print("❌ Navigation error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color operationColor = _getOperationColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_formatOperationName()} Levels',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: operationColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add the operation selector at the top
          OperationSelector(
            currentOperation: _currentOperation,
            onOperationSelected: _handleOperationChanged,
          ),

          // Rest of the content in an Expanded widget
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: operationColor))
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          operationColor.withValues(alpha: 0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOperationHeader(operationColor),
                          SizedBox(height: 24),

                          // Build each difficulty section
                          for (String difficulty in [
                            'Standard',
                            'Challenging',
                            'Expert',
                            'Impossible'
                          ]) ...[
                            _buildDifficultySection(
                              difficulty,
                              operationColor,
                              _getLevelsForDifficulty(difficulty),
                            ),
                            SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationHeader(Color operationColor) {
    String description;
    if (_currentOperation == 'multiplication') {
      description = 'Learn multiplication tables in a fun and interactive way';
    } else if (_currentOperation == 'division') {
      description = 'Practice division with different tables';
    } else if (_currentOperation == 'addition') {
      description = 'Practice addition with all 12 inner numbers';
    } else {
      description = 'Master subtraction with all 12 inner numbers';
    }

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: operationColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: operationColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getOperationSymbol(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: operationColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatOperationName(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: operationColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                // Note: All operations now use Ring mode
                if (_currentOperation == 'multiplication' ||
                    _currentOperation == 'division' ||
                    _currentOperation == 'addition' ||
                    _currentOperation == 'subtraction') ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: operationColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: operationColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: operationColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complete all 12 answers to finish!',
                            style: TextStyle(
                              fontSize: 12,
                              color: operationColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(
    String difficultyName,
    Color operationColor,
    List<Map<String, dynamic>> levels,
  ) {
    if (levels.isEmpty) return SizedBox.shrink();

    // Determine color for this difficulty
    Color difficultyColor;
    switch (difficultyName) {
      case 'Standard':
        difficultyColor = Colors.green;
        break;
      case 'Challenging':
        difficultyColor = Colors.blue;
        break;
      case 'Expert':
        difficultyColor = Colors.orange;
        break;
      case 'Impossible':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.green;
    }

    // Get description text for this difficulty
    String description = _getDifficultyDescription(difficultyName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Difficulty header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            difficultyName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: difficultyColor,
            ),
          ),
        ),
        SizedBox(height: 8),

        // Difficulty description
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        SizedBox(height: 12),

        // Level cards grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _currentOperation == 'addition' ||
                    _currentOperation == 'subtraction'
                ? 3
                : 2,
            childAspectRatio:
                difficultyName == 'Expert' || difficultyName == 'Impossible'
                    ? 0.95 // Decreased from 1.1 (more height)
                    : 1.1, // Decreased from 1.3 (more height)
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final stars = _getBestStarsForLevel(level);
            final bestTime = _getBestTimeForLevel(level);

            return _buildLevelCard(
              operationColor,
              difficultyName,
              level,
              stars,
              bestTime,
            );
          },
        ),
      ],
    );
  }

  String _getDifficultyDescription(String difficultyName) {
    if (_currentOperation == 'multiplication' ||
        _currentOperation == 'division') {
      switch (difficultyName) {
        case 'Standard':
          return 'Standard tables: 1, 2, 5, and 10';
        case 'Challenging':
          return 'Intermediate tables: 3, 4, 6, and 11';
        case 'Expert':
          return 'Advanced tables: 7, 8, 9, and 12';
        case 'Impossible':
          return 'Master tables: 13, 14, and 15';
        default:
          return '';
      }
    } else {
      switch (difficultyName) {
        case 'Standard':
          return 'Individual center numbers 1-5';
        case 'Challenging':
          return 'Individual center numbers 6-10';
        case 'Expert':
          return 'Center number ranges from 11 to 20';
        case 'Impossible':
          return 'Center number ranges from 21 to 50';
        default:
          return '';
      }
    }
  }

  Widget _buildLevelCard(
    Color operationColor,
    String difficultyName,
    Map<String, dynamic> level,
    int stars,
    String bestTime,
  ) {
    final String title = level['title'];
    final bool isRange = level['rangeStart'] != level['rangeEnd'];

    // Check if this level is unlocked (for multiplication/division)
    bool isUnlocked = true;
    if ((_currentOperation == 'multiplication' ||
        _currentOperation == 'division')) {
      final targetNumber = level['targetNumber'];
      isUnlocked = _unlockedTimeTables.contains(targetNumber);
    }

    return GestureDetector(
      onTap: () {
        HapticService().lightImpact();
        _navigateToGame(difficultyName, level);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Stack(
          children: [
            // Main content - properly centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Icon(
                        Icons.star,
                        size: 20,
                        color: !isUnlocked
                            ? Colors.grey.withValues(alpha: 0.3)
                            : index < stars
                                ? Colors.amber
                                : Colors.grey.withValues(alpha: 0.3),
                      );
                    }),
                  ),
                  SizedBox(height: 4), // Reduced from 6

                  // Level title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, // Reduced from 15
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? operationColor : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // For range-based levels, add a subtitle with less height
                  if (isRange &&
                      (_currentOperation == 'addition' ||
                          _currentOperation == 'subtraction'))
                    Text(
                      'Target Range',
                      style: TextStyle(
                        fontSize: 10, // Smaller font size
                        color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Best time
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12, // Reduced from 14
                          color:
                              isUnlocked ? Colors.grey[600] : Colors.grey[400],
                        ),
                        SizedBox(width: 2), // Reduced from 4
                        Text(
                          isUnlocked ? bestTime : '--:--',
                          style: TextStyle(
                            fontSize: 11, // Reduced from 12
                            color: isUnlocked
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Show lock icon for locked levels
            if (!isUnlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
