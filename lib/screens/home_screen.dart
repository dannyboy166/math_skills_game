import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../models/difficulty_level.dart'; // Import from models instead of defining locally

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedOperation = 'addition';
  DifficultyLevel selectedLevel = DifficultyLevel.standard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Math Skills Game'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose operation:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Operation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOperationButton('+', 'addition'),
                SizedBox(width: 10),
                _buildOperationButton('-', 'subtraction'),
                SizedBox(width: 10),
                _buildOperationButton('×', 'multiplication'),
                SizedBox(width: 10),
                _buildOperationButton('÷', 'division', enabled: false),
              ],
            ),

            SizedBox(height: 30),
            Text(
              'Choose difficulty:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final level in DifficultyLevel.values)
                  _buildLevelButton(level),
              ],
            ),

            SizedBox(height: 20),

            // Difficulty information
            _buildDifficultyInfo(),

            Spacer(),

            // Start button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      operationName: selectedOperation,
                      difficultyLevel: selectedLevel,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Start Game',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationButton(String symbol, String operation,
      {bool enabled = true}) {
    final isSelected = selectedOperation == operation;

    Color getColor() {
      if (!enabled) return Colors.grey.shade400;

      switch (operation) {
        case 'addition':
          return Colors.green;
        case 'subtraction':
          return Colors.purple;
        case 'multiplication':
          return Colors.blue;
        case 'division':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                selectedOperation = operation;
              });
            }
          : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected && enabled ? getColor() : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && enabled
              ? [BoxShadow(color: getColor().withOpacity(0.5), blurRadius: 5)]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isSelected && enabled ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (!enabled)
              Positioned(
                right: 5,
                bottom: 5,
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(DifficultyLevel level) {
    final isSelected = selectedLevel == level;

    Color getColor() {
      switch (level) {
        case DifficultyLevel.standard:
          return Colors.green.shade600;
        case DifficultyLevel.challenging:
          return Colors.blue.shade600;
        case DifficultyLevel.difficult:
          return Colors.orange.shade600;
        case DifficultyLevel.expert:
          return Colors.red.shade600;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedLevel = level;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? getColor() : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: getColor().withOpacity(0.5), blurRadius: 3)]
              : null,
        ),
        child: Text(
          level.displayName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyInfo() {
    String centerRange;
    String innerRange;
    String outerRange;

    switch (selectedLevel) {
      case DifficultyLevel.standard:
        centerRange = '1-5';
        innerRange = '1-12';
        outerRange = '1-18';
        break;
      case DifficultyLevel.challenging:
        centerRange = '6-10';
        innerRange = '1-12';
        outerRange = '1-24';
        break;
      case DifficultyLevel.difficult:
        centerRange = '11-20';
        innerRange = '1-12';
        outerRange = '1-36';
        break;
      case DifficultyLevel.expert:
        centerRange = '21-50';
        innerRange = '13-24';
        outerRange = '1-100';
        break;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty: ${selectedLevel.displayName}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• Center number: $centerRange'),
          Text('• Inner ring: $innerRange'),
          Text('• Outer ring: $outerRange'),
        ],
      ),
    );
  }
}
