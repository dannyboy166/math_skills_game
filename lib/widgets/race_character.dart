// lib/widgets/race_character.dart
import 'package:flutter/material.dart';
import 'dart:async';

/// A widget that shows two racing characters:
/// 1. High score character - moves at the pace needed to beat the current high score
/// 2. Player character - moves forward 1/12th of the track for each star earned
class RaceCharacter extends StatefulWidget {
  final int highScoreTimeMs; // High score time in milliseconds
  final int currentElapsedTimeMs; // Current game elapsed time
  final int completedStars; // Number of stars completed (0-12)
  final bool isGameRunning; // Whether the game is currently active
  final bool isGameComplete; // Whether the game is finished
  final double width; // Width of the racing track
  final Color characterColor; // Color theme for the characters

  const RaceCharacter({
    Key? key,
    required this.highScoreTimeMs,
    required this.currentElapsedTimeMs,
    required this.completedStars,
    required this.isGameRunning,
    required this.isGameComplete,
    required this.width,
    required this.characterColor,
  }) : super(key: key);

  @override
  State<RaceCharacter> createState() => _RaceCharacterState();
}

class _RaceCharacterState extends State<RaceCharacter>
    with TickerProviderStateMixin {
  // High score character animations
  late AnimationController _highScoreRunController;
  late AnimationController _highScorePositionController;
  late Animation<double> _highScoreRunAnimation;
  late Animation<double> _highScorePositionAnimation;
  
  // Player character animations
  late AnimationController _playerRunController;
  late AnimationController _playerPositionController;
  late Animation<double> _playerRunAnimation;
  late Animation<double> _playerPositionAnimation;
  
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    // High score character animations
    _highScoreRunController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _highScoreRunAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highScoreRunController,
      curve: Curves.easeInOut,
    ));

    _highScorePositionController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _highScorePositionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highScorePositionController,
      curve: Curves.linear,
    ));

    // Player character animations
    _playerRunController = AnimationController(
      duration: Duration(milliseconds: 350), // Slightly different timing
      vsync: this,
    );
    _playerRunAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playerRunController,
      curve: Curves.easeInOut,
    ));

    _playerPositionController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _playerPositionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playerPositionController,
      curve: Curves.easeOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    if (widget.isGameRunning && !widget.isGameComplete) {
      _highScoreRunController.repeat(reverse: true);
      _playerRunController.repeat(reverse: true);
      _startPositionUpdates();
    }
  }

  void _startPositionUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || !widget.isGameRunning || widget.isGameComplete) {
        timer.cancel();
        return;
      }
      _updatePositions();
    });
  }

  void _updatePositions() {
    // Update high score character position based on time
    if (widget.highScoreTimeMs > 0) {
      double highScoreProgress = widget.currentElapsedTimeMs / widget.highScoreTimeMs;
      highScoreProgress = highScoreProgress.clamp(0.0, 1.0);
      _highScorePositionController.animateTo(highScoreProgress);
    }

    // Update player character position based on stars completed
    double playerProgress = widget.completedStars / 12.0;
    playerProgress = playerProgress.clamp(0.0, 1.0);
    _playerPositionController.animateTo(playerProgress);
  }

  @override
  void didUpdateWidget(RaceCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Restart animations if game state changed
    if (oldWidget.isGameRunning != widget.isGameRunning ||
        oldWidget.isGameComplete != widget.isGameComplete) {
      if (widget.isGameRunning && !widget.isGameComplete) {
        _startAnimations();
      } else {
        _highScoreRunController.stop();
        _playerRunController.stop();
        _updateTimer?.cancel();
      }
    }

    // Update player position immediately if stars changed
    if (oldWidget.completedStars != widget.completedStars) {
      double playerProgress = widget.completedStars / 12.0;
      playerProgress = playerProgress.clamp(0.0, 1.0);
      _playerPositionController.animateTo(playerProgress);
    }
  }

  @override
  void dispose() {
    _highScoreRunController.dispose();
    _highScorePositionController.dispose();
    _playerRunController.dispose();
    _playerPositionController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRaceTrack(
      children: [
        // High score character (top lane)
        if (widget.highScoreTimeMs > 0)
          AnimatedBuilder(
            animation: Listenable.merge([_highScorePositionAnimation, _highScoreRunAnimation]),
            builder: (context, child) {
              return Positioned(
                left: _highScorePositionAnimation.value * (widget.width - 40), // 40 is character width
                top: 10, // Top lane (centered in upper half)
                child: _buildAnimatedCharacter(
                  isHighScore: true,
                  runAnimation: _highScoreRunAnimation,
                ),
              );
            },
          ),
        
        // Player character (bottom lane)
        AnimatedBuilder(
          animation: Listenable.merge([_playerPositionAnimation, _playerRunAnimation]),
          builder: (context, child) {
            return Positioned(
              left: _playerPositionAnimation.value * (widget.width - 40), // 40 is character width
              top: 30, // Bottom lane (centered in lower half)
              child: _buildAnimatedCharacter(
                isHighScore: false,
                runAnimation: _playerRunAnimation,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRaceTrack({required List<Widget> children}) {
    return Container(
      width: widget.width,
      height: 70, // Increased height for two lanes
      child: Stack(
        children: [
          // Race track background
          Container(
            height: 50, // Increased height for two lanes
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Stack(
              children: [
                // Center divider line to separate the two lanes
                Positioned(
                  top: 25, // Middle of the 50px track
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Finish line
                Positioned(
                  right: 5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade300],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Characters
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnimatedCharacter({
    required bool isHighScore,
    required Animation<double> runAnimation,
  }) {
    return Container(
      width: 40,
      height: 30, // Increased height for bigger characters
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Character shadow
          Positioned(
            bottom: 3,
            child: Container(
              width: 25,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Character body
          _buildCharacterIcon(
            isHighScore: isHighScore,
            runAnimation: runAnimation,
          ),
        ],
      ),
    );
  }


  Widget _buildCharacterIcon({
    required bool isHighScore,
    required Animation<double> runAnimation,  
  }) {
    Color characterColor;
    
    if (isHighScore) {
      // High score character - golden/orange theme
      characterColor = Colors.orange.shade600;
    } else {
      // Player character - use theme color
      characterColor = widget.characterColor;
      
      // Change color based on progress vs high score position
      if (widget.highScoreTimeMs > 0 && widget.isGameRunning) {
        double playerProgress = widget.completedStars / 12.0;
        double highScoreProgress = widget.currentElapsedTimeMs / widget.highScoreTimeMs;
        
        if (playerProgress > highScoreProgress) {
          characterColor = Colors.green; // Player is ahead
        } else if (playerProgress < highScoreProgress * 0.8) {
          characterColor = Colors.red; // Player is falling behind
        }
      }
    }

    // Always use running person icon for both characters
    IconData characterIcon = widget.isGameRunning && !widget.isGameComplete
        ? Icons.directions_run
        : widget.isGameComplete
            ? Icons.emoji_events // Trophy when game is complete
            : Icons.person;

    return Transform.scale(
      scale: 1.0 + (runAnimation.value * 0.1), // Slight bounce when running
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: characterColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          characterIcon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}