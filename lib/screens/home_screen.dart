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
        title: const Text(
          'Math Skills Game',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue.shade100,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Choose a number to practice:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (int i = 2; i <= 12; i++)
                  _buildNumberButton(i),
              ],
            ),
            const SizedBox(height: 60),
            const Text(
              'Choose operation:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOperationButton('+', 'addition'),
                const SizedBox(width: 16),
                _buildOperationButton('-', 'subtraction'),
                const SizedBox(width: 16),
                _buildOperationButton('×', 'multiplication'),
                const SizedBox(width: 16),
                _buildOperationButton('÷', 'division'),
              ],
            ),
            const SizedBox(height: 80),
            _buildStartGameButton(),
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
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(35),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationButton(String symbol, String operation) {
    final isSelected = selectedOperation == operation;
    return InkWell(
      onTap: () {
        setState(() {
          selectedOperation = operation;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(35),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartGameButton() {
    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 220,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Text(
            'Start Game',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}