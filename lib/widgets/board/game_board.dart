import 'package:flutter/material.dart';
import '../../models/game_operation.dart';
import '../celebrations/celebration_overlay.dart';
import '../center_target.dart';
import '../square_ring.dart';
import 'corner_detector.dart';
import 'equation_overlay.dart';
import 'game_board_controller.dart';

class GameBoard extends StatefulWidget {
  final int targetNumber;
  final GameOperation operation;

  const GameBoard({
    Key? key,
    required this.targetNumber,
    required this.operation,
  }) : super(key: key);

  @override
  GameBoardState createState() => GameBoardState();
}

class GameBoardState extends State<GameBoard> {
  // Controller that handles the game logic and state
  late GameBoardController _controller;

  // Keys for the rings
  final GlobalKey<State<AnimatedSquareRing>> innerRingKey =
      GlobalKey<State<AnimatedSquareRing>>();

  @override
  void initState() {
    super.initState();

    // Initialize the controller
    _controller = GameBoardController(
      targetNumber: widget.targetNumber,
      operation: widget.operation,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      innerRingKey: innerRingKey,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width and adjust the container size
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.95; // Use 95% of screen width

    // Define ring sizes
    final outerRingSize = boardSize * 0.95;
    final innerRingSize = boardSize * 0.58; // Smaller inner ring

    // Update ring models with new sizes
    _controller.updateRingModels(outerRingSize, innerRingSize);

    return Stack(
      children: [
        // Main game board
        Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: widget.operation.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              AnimatedSquareRing(
                ringModel: _controller.outerRingModel,
                onRotate: _controller.rotateOuterRing,
                solvedCorners: _controller.solvedCorners,
                isInner: false,
                tileSizeFactor: 0.12,
                cornerSizeFactor: 1.6,
              ),

              // Inner ring
              Container(
                width: innerRingSize,
                height: innerRingSize,
                child: AnimatedSquareRing(
                  key: innerRingKey,
                  ringModel: _controller.innerRingModel,
                  onRotate: _controller.rotateInnerRing,
                  solvedCorners: _controller.solvedCorners,
                  isInner: true,
                  tileSizeFactor: 0.16,
                  cornerSizeFactor: 1.4,
                ),
              ),

              // Center number (fixed)
              CenterTarget(targetNumber: widget.targetNumber),

              // Equation overlays (operators and equals signs)
              EquationOverlay(
                boardSize: boardSize,
                innerRingSize: innerRingSize,
                outerRingSize: outerRingSize,
                operationSymbol: widget.operation.symbol,
              ),

              // Corner detectors for checking equations
              ...List.generate(
                4,
                (index) => CornerDetector(
                  cornerIndex: index,
                  boardSize: boardSize,
                  isSolved: _controller.solvedCorners[index],
                  operationColor: widget.operation.color,
                  burstKey: _controller.getBurstKey(index),
                  onTap: () => _controller.checkCornerEquation(index),
                  onSwipe: _controller.handleCornerSwipe,
                ),
              ),

              // Add confetti widgets for celebrations
              ..._controller.buildConfettiWidgets(boardSize),
            ],
          ),
        ),

        // Celebration overlay when game is completed
        if (_controller.isShowingCelebration)
          Positioned.fill(
            child: CelebrationOverlay(
              isPlaying: true,
              onComplete: _controller.hideCelebration,
            ),
          ),
      ],
    );
  }
}
