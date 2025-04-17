// lib/screens/levels_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_skills_game/models/difficulty_level.dart';
import 'package:math_skills_game/models/level_completion_model.dart';
import 'package:math_skills_game/screens/game_screen.dart';
import 'package:math_skills_game/services/user_service.dart';
import 'dart:math';

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

  @override
  void initState() {
    super.initState();
    _loadLevelData();
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
            .where((level) => level.operationName == widget.operationName)
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

  // Get color for this operation
  Color _getOperationColor() {
    switch (widget.operationName) {
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
    switch (widget.operationName) {
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
    return widget.operationName.substring(0, 1).toUpperCase() +
        widget.operationName.substring(1);
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
    if (widget.operationName == 'multiplication' ||
        widget.operationName == 'division') {
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

  // Navigate to game screen with appropriate parameters
  void _navigateToGame(String difficulty, Map<String, dynamic> level) {
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
        difficultyEnum = DifficultyLevel.Expert;
        break;
      case 'Impossible':
        difficultyEnum = DifficultyLevel.Impossible;
        break;
      default:
        difficultyEnum = DifficultyLevel.standard;
    }

    // For tables (multiplication/division), use exact target number
    // For addition/subtraction with exact targets, use that exact number
    // For range-based levels (Expert/Impossible addition/subtraction), pick random number in range
    int targetToUse = level['targetNumber'];

    // Generate a random number within the range for Expert and Impossible ranges
    if ((widget.operationName == 'addition' ||
            widget.operationName == 'subtraction') &&
        level['rangeStart'] != level['rangeEnd']) {
      final random = Random();
      targetToUse = level['rangeStart'] +
          random.nextInt(level['rangeEnd'] - level['rangeStart'] + 1);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          operationName: widget.operationName,
          difficultyLevel: difficultyEnum,
          targetNumber: targetToUse,
        ),
      ),
    ).then((_) {
      // Reload data when returning from game screen
      _loadLevelData();
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
        backgroundColor: operationColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: operationColor))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    operationColor.withOpacity(0.1),
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
    );
  }

  Widget _buildOperationHeader(Color operationColor) {
    String description;
    if (widget.operationName == 'multiplication') {
      description = 'Learn multiplication tables in a fun and interactive way';
    } else if (widget.operationName == 'division') {
      description = 'Practice division with different tables';
    } else if (widget.operationName == 'addition') {
      description = 'Practice addition with various center numbers';
    } else {
      description = 'Master subtraction with increasing difficulty';
    }

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: operationColor.withOpacity(0.2),
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
              color: operationColor.withOpacity(0.2),
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
            color: difficultyColor.withOpacity(0.2),
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
            crossAxisCount: widget.operationName == 'addition' ||
                    widget.operationName == 'subtraction'
                ? 3
                : 2,
            childAspectRatio:
                difficultyName == 'Expert' || difficultyName == 'Impossible'
                    ? 1.1
                    : 1.3,
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
    if (widget.operationName == 'multiplication' ||
        widget.operationName == 'division') {
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

    return GestureDetector(
      onTap: () => _navigateToGame(difficultyName, level),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star,
                  size: 20,
                  color: index < stars
                      ? Colors.amber
                      : Colors.grey.withOpacity(0.3),
                );
              }),
            ),
            SizedBox(height: 6),

            // Level title
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: operationColor,
              ),
              textAlign: TextAlign.center,
            ),

            // For range-based levels, add a subtitle with less height
            if (isRange &&
                (widget.operationName == 'addition' ||
                    widget.operationName == 'subtraction')) ...[
              SizedBox(height: 1), // Reduce spacing
              Text(
                'Target Range',
                style: TextStyle(
                  fontSize: 10, // Smaller font size
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: 4),

            // Best time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  bestTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
