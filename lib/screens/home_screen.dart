import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        title: const Text('Math Skills Game'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose a number to practice:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 2; i <= 12; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedNumber = i;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedNumber == i 
                            ? Colors.blue 
                            : Colors.grey.shade200,
                        foregroundColor: selectedNumber == i 
                            ? Colors.white 
                            : Colors.black,
                      ),
                      child: Text('$i'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Choose operation:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildOperationButton('Addition', 'addition', '+'),
                buildOperationButton('Subtraction', 'subtraction', '-'),
                buildOperationButton('Multiplication', 'multiplication', '×'),
                buildOperationButton('Division', 'division', '÷'),
              ],
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      targetNumber: selectedNumber,
                      operation: selectedOperation,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30, 
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOperationButton(String label, String value, String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedOperation = value;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedOperation == value 
              ? Colors.blue 
              : Colors.grey.shade200,
          foregroundColor: selectedOperation == value 
              ? Colors.white 
              : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Text(symbol, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}