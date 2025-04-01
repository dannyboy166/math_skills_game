import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedNumber = 2;
  String selectedOperation = 'multiplication';
  
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
              'Choose a number to practice:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            
            // Number grid
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 2; i <= 12; i++)
                  _buildNumberButton(i),
              ],
            ),
            
            SizedBox(height: 30),
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
            
            Spacer(),
            
            // Start button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      targetNumber: selectedNumber,
                      operationName: selectedOperation,
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
  
  Widget _buildNumberButton(int number) {
    final isSelected = selectedNumber == number;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedNumber = number;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 5)]
              : null,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildOperationButton(String symbol, String operation) {
    final isSelected = selectedOperation == operation;
    
    Color getColor() {
      switch (operation) {
        case 'addition': return Colors.green;
        case 'subtraction': return Colors.purple;
        case 'multiplication': return Colors.blue;
        case 'division': return Colors.orange;
        default: return Colors.grey;
      }
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedOperation = operation;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? getColor() : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: getColor().withOpacity(0.5), blurRadius: 5)]
              : null,
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}