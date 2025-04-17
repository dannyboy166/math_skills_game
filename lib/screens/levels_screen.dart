// lib/screens/levels_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_skills_game/models/difficulty_level.dart';
import 'package:math_skills_game/models/level_completion_model.dart';
import 'package:math_skills_game/screens/game_screen.dart';
import 'package:math_skills_game/services/user_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load level data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
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

  // Find stars for a specific level
  int _getStarsForLevel(String difficulty, int targetNumber) {
    final completion = _completedLevels.firstWhere(
      (level) => 
          level.difficultyName == difficulty && 
          level.targetNumber == targetNumber,
      orElse: () => LevelCompletionModel(
        operationName: widget.operationName,
        difficultyName: difficulty,
        targetNumber: targetNumber,
        stars: 0,
        completionTimeMs: 0,
        completedAt: DateTime.now(),
      ),
    );
    
    return completion.stars;
  }

  // Get best time for a specific level
  String _getBestTimeForLevel(String difficulty, int targetNumber) {
    final completion = _completedLevels.firstWhere(
      (level) => 
          level.difficultyName == difficulty && 
          level.targetNumber == targetNumber,
      orElse: () => LevelCompletionModel(
        operationName: widget.operationName,
        difficultyName: difficulty,
        targetNumber: targetNumber,
        stars: 0,
        completionTimeMs: 0,
        completedAt: DateTime.now(),
      ),
    );
    
    if (completion.completionTimeMs == 0) {
      return '--:--';
    }
    
    return StarRatingCalculator.formatTime(completion.completionTimeMs);
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
                    
                    // Standard difficulty
                    _buildDifficultySection(
                      'Standard', 
                      operationColor,
                      [1, 2, 3, 4, 5],
                    ),
                    SizedBox(height: 24),
                    
                    // Challenging difficulty
                    _buildDifficultySection(
                      'Challenging', 
                      operationColor,
                      [6, 7, 8, 9, 10],
                    ),
                    SizedBox(height: 24),
                    
                    // Expert difficulty
                    _buildDifficultySection(
                      'Expert', 
                      operationColor,
                      [11, 12, 13, 14, 15],
                    ),
                    SizedBox(height: 24),
                    
                    // Impossible difficulty
                    _buildDifficultySection(
                      'Impossible', 
                      operationColor,
                      [20, 25, 30, 40, 50],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOperationHeader(Color operationColor) {
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
                  _getOperationDescription(),
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

  String _getOperationDescription() {
    switch (widget.operationName) {
      case 'addition':
        return 'Practice addition skills with various difficulty levels';
      case 'subtraction':
        return 'Master subtraction with increasingly challenging problems';
      case 'multiplication':
        return 'Learn multiplication tables in a fun and interactive way';
      case 'division':
        return 'Practice division with different difficulty levels';
      default:
        return 'Practice your math skills';
    }
  }

  Widget _buildDifficultySection(
    String difficultyName, 
    Color operationColor,
    List<int> targetNumbers,
  ) {
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: targetNumbers.length,
          itemBuilder: (context, index) {
            final targetNumber = targetNumbers[index];
            final stars = _getStarsForLevel(difficultyName, targetNumber);
            final bestTime = _getBestTimeForLevel(difficultyName, targetNumber);
            
            return _buildLevelCard(
              operationColor,
              difficultyName,
              targetNumber,
              stars,
              bestTime,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    Color operationColor,
    String difficultyName,
    int targetNumber,
    int stars,
    String bestTime,
  ) {
    final bool isLocked = widget.operationName == 'multiplication' || 
                          widget.operationName == 'division';
    final String levelTitle = isLocked 
        ? '$targetNumber${_getOperationSymbol()} Table' 
        : 'Target: $targetNumber';
        
    return GestureDetector(
      onTap: () {
        // Get the difficulty level enum value
        DifficultyLevel difficultyLevel;
        switch (difficultyName) {
          case 'Standard':
            difficultyLevel = DifficultyLevel.standard;
            break;
          case 'Challenging':
            difficultyLevel = DifficultyLevel.challenging;
            break;
          case 'Expert':
            difficultyLevel = DifficultyLevel.Expert;
            break;
          case 'Impossible':
            difficultyLevel = DifficultyLevel.Impossible;
            break;
          default:
            difficultyLevel = DifficultyLevel.standard;
        }
        
        // Navigate to the game screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              operationName: widget.operationName,
              difficultyLevel: difficultyLevel,
              targetNumber: targetNumber,
            ),
          ),
        ).then((_) {
          // Reload data when returning from game screen
          _loadLevelData();
        });
      },
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star,
                  size: 22,
                  color: index < stars 
                      ? Colors.amber 
                      : Colors.grey.withOpacity(0.3),
                );
              }),
            ),
            SizedBox(height: 8),
            Text(
              levelTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: operationColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  bestTime,
                  style: TextStyle(
                    fontSize: 14,
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