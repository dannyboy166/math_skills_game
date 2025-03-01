import 'package:flutter/material.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatelessWidget {
  final int targetNumber;
  final String operation;

  const GameScreen({
    super.key,
    required this.targetNumber,
    required this.operation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice $operation with $targetNumber'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GameBoard(
            targetNumber: targetNumber, 
            operation: operation,
          ),
        ),
      ),
    );
  }
}