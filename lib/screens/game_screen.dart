import 'package:flutter/material.dart';
import '../models/game_operation.dart';
import '../operations/operation_factory.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  final int targetNumber;
  final String operationName;

  const GameScreen({
    super.key,
    required this.targetNumber,
    required this.operationName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final GameOperation operation;
  
  @override
  void initState() {
    super.initState();
    
    // Get the operation from the factory
    operation = OperationFactory.getOperation(widget.operationName);
    
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              operation.color.withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.3, 0.65],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context),
              
              // Game Stats
              _buildGameStats(),
              
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
                                operation.emoji,
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
                              operation: operation,
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

  Widget _buildAppBar(BuildContext context) {
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
                'Practice ${operation.displayName} with ${widget.targetNumber}',
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

  Widget _buildGameStats() {
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
                color: operation.color,
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
                color: operation.color,
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