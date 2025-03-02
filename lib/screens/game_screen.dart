import 'package:flutter/material.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  final int targetNumber;
  final String operation;

  const GameScreen({
    super.key,
    required this.targetNumber,
    required this.operation,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    
    // Controller for pulse effect on score
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getOperationColor() {
    switch (widget.operation) {
      case 'addition': return Colors.green;
      case 'subtraction': return Colors.purple;
      case 'multiplication': return Colors.blue;
      case 'division': return Colors.orange;
      default: return Colors.blue;
    }
  }
  
  String _getOperationEmoji() {
    switch (widget.operation) {
      case 'addition': return '➕';
      case 'subtraction': return '➖';
      case 'multiplication': return '✖️';
      case 'division': return '➗';
      default: return '🔢';
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationColor = _getOperationColor();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              operationColor.withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.3, 0.65],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context, operationColor),
              
              // Game Stats
              _buildGameStats(operationColor),
              
              // Game Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Decorative corner elements
                          Positioned(
                            right: -40,
                            bottom: -40,
                            child: Opacity(
                              opacity: 0.1,
                              child: Text(
                                _getOperationEmoji(),
                                style: const TextStyle(
                                  fontSize: 120,
                                ),
                              ),
                            ),
                          ),
                          
                          // Game Board
                          Center(
                            child: GameBoard(
                              targetNumber: widget.targetNumber,
                              operation: widget.operation,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color operationColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          
          // Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Practice ${widget.operation} with ${widget.targetNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats(Color operationColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Timer
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: operationColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '02:30',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          // Divider
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
          
          // Score
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: operationColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Text(
                    'Score: 120',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87.withOpacity(
                        0.7 + (_pulseController.value * 0.3),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}