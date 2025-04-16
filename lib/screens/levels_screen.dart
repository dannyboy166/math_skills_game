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