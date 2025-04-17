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
                    SizedBox(height: 20),
                    
                    // Standard Difficulty Section
                    _buildDifficultySection('Standard', operationColor, DifficultyLevel.standard),
                    
                    // Challenging Difficulty Section
                    _buildDifficultySection('Challenging', operationColor, DifficultyLevel.challenging),
                    
                    // Expert Difficulty Section
                    _buildDifficultySection('Expert', operationColor, DifficultyLevel.Expert),
                    
                    // Impossible Difficulty Section 
                    _buildDifficultySection('Impossible', operationColor, DifficultyLevel.Impossible),
                    
                    SizedBox(height: 20),
                    
                    // Times Tables Section - Only for multiplication and division
                    if (widget.operationName == 'multiplication' || widget.operationName == 'division')
                      _buildTimesTablesSection(operationColor),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Operation header with symbol and description
  Widget _buildOperationHeader(Color operationColor) {
    String description;
    switch (widget.operationName) {
      case 'addition':
        description = 'Form equations like: inner + target = outer';
        break;
      case 'subtraction':
        description = 'Form equations like: outer - inner = target';
        break;
      case 'multiplication':
        description = 'Form equations like: inner × target = outer';
        break;
      case 'division':
        description = 'Form equations like: outer ÷ inner = target';
        break;
      default:
        description = 'Form equations at the corners';
        break;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: operationColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Operation symbol circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: operationColor.withOpacity(0.2),
                border: Border.all(color: operationColor, width: 2),
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
            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatOperationName()} Levels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Complete levels faster to earn more stars!',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a section for each difficulty level
  Widget _buildDifficultySection(String title, Color operationColor, DifficultyLevel difficultyLevel) {
    // Get numbers that correspond to this difficulty
    List<int> levelNumbers = [];
    
    switch (difficultyLevel) {
      case DifficultyLevel.standard:
        levelNumbers = List.generate(5, (index) => index + 1); // 1-5
        break;
      case DifficultyLevel.challenging:
        levelNumbers = List.generate(5, (index) => index + 6); // 6-10
        break;
      case DifficultyLevel.Expert:
        levelNumbers = List.generate(10, (index) => index + 11); // 11-20
        break;
      case DifficultyLevel.Impossible:
        levelNumbers = List.generate(10, (index) => index + 21); // 21-30 (showing 10 levels only)
        break;
    }
    
    // Get section color based on difficulty
    Color sectionColor;
    switch (difficultyLevel) {
      case DifficultyLevel.standard:
        sectionColor = Colors.green.shade600;
        break;
      case DifficultyLevel.challenging:
        sectionColor = Colors.blue.shade600;
        break;
      case DifficultyLevel.Expert:
        sectionColor = Colors.orange.shade600;
        break;
      case DifficultyLevel.Impossible:
        sectionColor = Colors.red.shade600;
        break;
      default:
        sectionColor = operationColor;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Divider(color: sectionColor.withOpacity(0.5), thickness: 2),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Level grid
          GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: levelNumbers.length,
            itemBuilder: (context, index) {
              final targetNumber = levelNumbers[index];
              
              // Find completion data for this level if it exists
              final completionData = _completedLevels.firstWhere(
                (level) => 
                    level.operationName == widget.operationName && 
                    level.difficultyName == title &&
                    level.targetNumber == targetNumber,
                orElse: () => LevelCompletionModel(
                  operationName: '',
                  difficultyName: '',
                  targetNumber: 0,
                  stars: 0,
                  completionTimeMs: 0,
                  completedAt: DateTime.now(),
                ),
              );
              
              // Number of stars earned
              final stars = completionData.operationName.isEmpty ? 0 : completionData.stars;
              
              return _buildLevelTile(
                targetNumber: targetNumber,
                stars: stars,
                color: sectionColor,
                difficultyLevel: difficultyLevel,
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Build a level selection tile with star rating
  Widget _buildLevelTile({
    required int targetNumber,
    required int stars,
    required Color color,
    required DifficultyLevel difficultyLevel,
  }) {
    final bool isCompleted = stars > 0;
    
    return InkWell(
      onTap: () {
        // Navigate to game screen with this level configuration
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
          // Refresh data when returning from game screen
          _loadLevelData();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isCompleted ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Target number
            Text(
              '$targetNumber',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCompleted ? color : Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: index < stars ? Colors.amber : Colors.grey.shade400,
                  size: 16,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build times tables section for multiplication and division
  Widget _buildTimesTablesSection(Color operationColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: operationColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Times Tables',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Divider(color: operationColor.withOpacity(0.5), thickness: 2),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Times tables description
        Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.operationName == 'multiplication'
                ? 'Practice specific multiplication tables. Find products of the selected number.'
                : 'Practice specific division tables. Find numbers that divide evenly by the selected number.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        
        // Times tables grid
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.0,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 15, // Tables 1-15
          itemBuilder: (context, index) {
            final tableNumber = index + 1;
            
            // Find completion data for this table if it exists
            final completionData = _completedLevels.firstWhere(
              (level) => 
                  level.operationName == widget.operationName && 
                  level.targetNumber == tableNumber,
              orElse: () => LevelCompletionModel(
                operationName: '',
                difficultyName: '',
                targetNumber: 0,
                stars: 0,
                completionTimeMs: 0,
                completedAt: DateTime.now(),
              ),
            );
            
            // Number of stars earned
            final stars = completionData.operationName.isEmpty ? 0 : completionData.stars;
            
            // Determine color based on difficulty category
            Color tableColor;
            DifficultyLevel tableDifficulty;
            
            if ([1, 2, 5, 10].contains(tableNumber)) {
              tableColor = Colors.green.shade600;
              tableDifficulty = DifficultyLevel.standard;
            } else if ([3, 4, 6, 11].contains(tableNumber)) {
              tableColor = Colors.blue.shade600;
              tableDifficulty = DifficultyLevel.challenging;
            } else if ([7, 8, 9, 12].contains(tableNumber)) {
              tableColor = Colors.orange.shade600;
              tableDifficulty = DifficultyLevel.Expert;
            } else {
              tableColor = Colors.red.shade600;
              tableDifficulty = DifficultyLevel.Impossible;
            }
            
            return _buildTimesTableTile(
              tableNumber: tableNumber,
              stars: stars,
              color: tableColor,
              difficultyLevel: tableDifficulty,
            );
          },
        ),
      ],
    );
  }
  
  // Build a times table selection tile with star rating
  Widget _buildTimesTableTile({
    required int tableNumber,
    required int stars,
    required Color color,
    required DifficultyLevel difficultyLevel,
  }) {
    final bool isCompleted = stars > 0;
    final String symbol = widget.operationName == 'multiplication' ? '×' : '÷';
    
    return InkWell(
      onTap: () {
        // Navigate to game screen with this table
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              operationName: widget.operationName,
              difficultyLevel: difficultyLevel,
              targetNumber: tableNumber,
            ),
          ),
        ).then((_) {
          // Refresh data when returning from game screen
          _loadLevelData();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isCompleted ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Table number with symbol
            Text(
              '$tableNumber$symbol',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCompleted ? color : Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 5),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: index < stars ? Colors.amber : Colors.grey.shade400,
                  size: 12,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}