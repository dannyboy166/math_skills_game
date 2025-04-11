import 'dart:math';

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
  int? selectedMultiplicationTable;

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
                _buildOperationButton('÷', 'division'),
              ],
            ),

            SizedBox(height: 30),

            if (selectedOperation == 'multiplication' ||
                selectedOperation == 'division')
              _buildMultiplicationTablesUI()
            else
              Column(
                children: [
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
                  _buildDifficultyInfo(),
                ],
              ),

            Spacer(),

            ElevatedButton(
              onPressed: () {
                // Don't allow starting multiplication/division game without selecting a table
                if ((selectedOperation == 'multiplication' ||
                        selectedOperation == 'division') &&
                    selectedMultiplicationTable == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a table first'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      operationName: selectedOperation,
                      difficultyLevel: selectedLevel,
                      // Pass the selected table if applicable
                      targetNumber: (selectedOperation == 'multiplication' ||
                                  selectedOperation == 'division') &&
                              selectedMultiplicationTable != null
                          ? selectedMultiplicationTable
                          : null,
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
                // Reset multiplication table if changing operations
                if (operation != 'multiplication') {
                  selectedMultiplicationTable = null;
                }
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
        case DifficultyLevel.Expert:
          return Colors.orange.shade600;
        case DifficultyLevel.Impossible:
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
      case DifficultyLevel.Expert:
        centerRange = '11-20';
        innerRange = '1-12';
        outerRange = '1-36';
        break;
      case DifficultyLevel.Impossible:
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

  Widget _buildMultiplicationTablesUI() {
    String operation =
        selectedOperation == 'multiplication' ? 'times' : 'division';
    String symbol = selectedOperation == 'multiplication' ? '×' : '÷';

    return Column(
      children: [
        Text(
          'Choose $operation table:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        // Random selection based on difficulty
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildCategoryButton('Standard', [1, 2, 5, 10]),
            _buildCategoryButton('Challenging', [3, 4, 6, 11]),
            _buildCategoryButton('Expert', [7, 8, 9, 12]),
            _buildCategoryButton('Impossible', [13, 14, 15]),
          ],
        ),

        SizedBox(height: 15),
        Text(
          'Or select specific times table:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),

        // Specific table selection
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            for (int i = 1; i <= 15; i++) _buildTableButton(i),
          ],
        ),

        SizedBox(height: 20),

        // Selected table info
        if (selectedMultiplicationTable != null)
          Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Text(
                  '$selectedMultiplicationTable$symbol Table',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTableColor(selectedMultiplicationTable!)),
                ),
                SizedBox(height: 10),
                if (selectedOperation == 'multiplication')
                  Text(
                      'Find products of $selectedMultiplicationTable in the outer ring')
                else
                  Text(
                      'Find numbers that, when divided by inner ring numbers, equal $selectedMultiplicationTable'),
                SizedBox(height: 5),
                Text('Inner ring will contain numbers 1-12'),
              ],
            ),
          ),
      ],
    );
  }

// Helper method to build category button
  Widget _buildCategoryButton(String categoryName, List<int> tables) {
    final bool isSelected = selectedMultiplicationTable != null &&
        tables.contains(selectedMultiplicationTable);

    Color getColor() {
      switch (categoryName) {
        case 'Standard':
          return Colors.green.shade600;
        case 'Challenging':
          return Colors.blue.shade600;
        case 'Expert':
          return Colors.orange.shade600;
        case 'Impossible':
          return Colors.red.shade600;
        default:
          return Colors.blue;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          // Select a random table from this category
          final Random random = Random();
          selectedMultiplicationTable = tables[random.nextInt(tables.length)];
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
          categoryName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

// Helper method to build individual table button
  Widget _buildTableButton(int tableNumber) {
    final bool isSelected = selectedMultiplicationTable == tableNumber;

    // Get difficulty category of this table
    String getCategory() {
      if ([1, 2, 5, 10].contains(tableNumber)) return 'Standard';
      if ([3, 4, 6, 11].contains(tableNumber)) return 'Challenging';
      if ([7, 8, 9, 12].contains(tableNumber)) return 'Expert';
      return 'Impossible';
    }

    Color getColor() {
      final category = getCategory();
      switch (category) {
        case 'Standard':
          return Colors.green.shade600;
        case 'Challenging':
          return Colors.blue.shade600;
        case 'Expert':
          return Colors.orange.shade600;
        case 'Impossible':
          return Colors.red.shade600;
        default:
          return Colors.blue;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedMultiplicationTable = tableNumber;
        });
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? getColor() : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: getColor().withOpacity(0.5), blurRadius: 3)]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$tableNumber×',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (getCategory() == 'Impossible')
              Positioned(
                right: 3,
                bottom: 3,
                child: Icon(
                  Icons.star,
                  size: 10,
                  color: isSelected ? Colors.white70 : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

// Helper method to get color for a specific table
  Color _getTableColor(int tableNumber) {
    if ([1, 2, 5, 10].contains(tableNumber)) return Colors.green.shade600;
    if ([3, 4, 6, 11].contains(tableNumber)) return Colors.blue.shade600;
    if ([7, 8, 9, 12].contains(tableNumber)) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
