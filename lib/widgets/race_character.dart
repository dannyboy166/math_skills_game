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
  final String highScoreString; // Raw high score string to distinguish loading vs no score

  const RaceCharacter({
    Key? key,
    required this.highScoreTimeMs,
    required this.currentElapsedTimeMs,
    required this.completedStars,
    required this.isGameRunning,
    required this.isGameComplete,
    required this.width,
    required this.characterColor,
    required this.highScoreString,
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

  // Victory celebration animations
  late AnimationController _victoryController;
  late Animation<double> _victoryBounceAnimation;

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

    // Victory celebration animation
    _victoryController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _victoryBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _victoryController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    print('🏃 RaceCharacter: _startAnimations called - running=${widget.isGameRunning}, complete=${widget.isGameComplete}, shouldShow=$_shouldShowHighScoreOpponent');
    
    if (widget.isGameRunning && !widget.isGameComplete) {
      if (_shouldShowHighScoreOpponent) {
        print('🏃 RaceCharacter: Starting high score animations');
        _highScoreRunController.repeat(reverse: true);
      }
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
      double highScoreProgress =
          widget.currentElapsedTimeMs / widget.highScoreTimeMs;
      highScoreProgress = highScoreProgress.clamp(0.0, 1.0);
      _highScorePositionController.animateTo(highScoreProgress);
    } else if (_shouldShowHighScoreOpponent) {
      // If we should show opponent but don't have valid time data, keep it at start
      _highScorePositionController.animateTo(0.0);
    }

    // Update player character position based on stars completed
    double playerProgress = widget.completedStars / 12.0;
    playerProgress = playerProgress.clamp(0.0, 1.0);
    _playerPositionController.animateTo(playerProgress);
  }

  @override
  void didUpdateWidget(RaceCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart animations if game state changed or high score data became available
    if (oldWidget.isGameRunning != widget.isGameRunning ||
        oldWidget.isGameComplete != widget.isGameComplete ||
        oldWidget.highScoreString != widget.highScoreString) {
      if (widget.isGameRunning && !widget.isGameComplete) {
        _startAnimations();
// Reset victory message flag
      } else {
        _highScoreRunController.stop();
        _playerRunController.stop();
        _updateTimer?.cancel();

        // Trigger victory celebration if game just completed
        if (widget.isGameComplete && !oldWidget.isGameComplete) {
          _triggerVictoryCelebration();
        }
      }
    }

    // Update player position immediately if stars changed
    if (oldWidget.completedStars != widget.completedStars) {
      double playerProgress = widget.completedStars / 12.0;
      playerProgress = playerProgress.clamp(0.0, 1.0);
      _playerPositionController.animateTo(playerProgress);
    }
  }

  void _triggerVictoryCelebration() {
    _victoryController.forward().then((_) {
      _victoryController.reverse();
    });
  }

  // Determine if high score opponent should be shown
  bool get _shouldShowHighScoreOpponent {
    // Show opponent if we have a valid high score time, OR if high score string indicates a score exists
    // This handles cases where the time might be 0 due to parsing issues but we know a score exists
    final shouldShow = widget.highScoreTimeMs > 0 || 
           (widget.highScoreString.isNotEmpty && widget.highScoreString != '--:--');
    
    print('🏃 RaceCharacter: shouldShow=$shouldShow, timeMs=${widget.highScoreTimeMs}, string="${widget.highScoreString}"');
    
    return shouldShow;
  }

  // Determine who won the race
  bool get _playerWon {
    if (!widget.isGameComplete || widget.highScoreTimeMs <= 0) return false;
    return widget.currentElapsedTimeMs < widget.highScoreTimeMs;
  }

  bool get _highScoreWon {
    if (!widget.isGameComplete || widget.highScoreTimeMs <= 0) return false;
    return widget.currentElapsedTimeMs >= widget.highScoreTimeMs;
  }

  // Get race status message
  String get _raceStatusMessage {
    if (!widget.isGameComplete) return '';

    if (widget.highScoreTimeMs <= 0) {
      return 'First completion! New record set! 🎉';
    }

    if (_playerWon) {
      return 'NEW HIGH SCORE! You beat your record! 🏆';
    } else {
      double timeRatio = widget.currentElapsedTimeMs / widget.highScoreTimeMs;

      if (timeRatio <= 1.2) {
        return 'So close! Just ${((timeRatio - 1) * 100).toStringAsFixed(0)}% slower than your record';
      } else if (timeRatio <= 1.5) {
        return 'Good effort! You\'re getting closer to your record';
      } else if (timeRatio <= 2.0) {
        return 'Keep practicing! You\'re about halfway to your record pace';
      } else {
        return 'Room for improvement! Try to solve equations faster';
      }
    }
  }

  @override
  void dispose() {
    _highScoreRunController.dispose();
    _highScorePositionController.dispose();
    _playerRunController.dispose();
    _playerPositionController.dispose();
    _victoryController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Race explanation (only show when game is running)
        if (widget.isGameRunning &&
            !widget.isGameComplete &&
            _shouldShowHighScoreOpponent)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: widget.characterColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: widget.characterColor),
                SizedBox(width: 6),
                Text(
                  'Race your high score!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.characterColor,
                  ),
                ),
              ],
            ),
          ),

        // Race track
        _buildRaceTrack(
          children: [
            // High score character (top lane)
            if (_shouldShowHighScoreOpponent)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _highScorePositionAnimation,
                  _highScoreRunAnimation,
                  _victoryBounceAnimation
                ]),
                builder: (context, child) {
                  return Positioned(
                    left: _highScorePositionAnimation.value *
                        (widget.width - 40), // 40 is character width
                    top: 10, // Top lane (centered in upper half)
                    child: Transform.scale(
                      scale:
                          _highScoreWon ? _victoryBounceAnimation.value : 1.0,
                      child: _buildAnimatedCharacter(
                        isHighScore: true,
                        runAnimation: _highScoreRunAnimation,
                      ),
                    ),
                  );
                },
              ),

            // Player character (bottom lane)
            AnimatedBuilder(
              animation: Listenable.merge([
                _playerPositionAnimation,
                _playerRunAnimation,
                _victoryBounceAnimation
              ]),
              builder: (context, child) {
                return Positioned(
                  left: _playerPositionAnimation.value *
                      (widget.width - 40), // 40 is character width
                  top: 30, // Bottom lane (centered in lower half)
                  child: Transform.scale(
                    scale: _playerWon ? _victoryBounceAnimation.value : 1.0,
                    child: _buildAnimatedCharacter(
                      isHighScore: false,
                      runAnimation: _playerRunAnimation,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // Race status message (only show when game is complete)
        if (widget.isGameComplete && _raceStatusMessage.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _playerWon
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _playerWon ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _playerWon ? Icons.emoji_events : Icons.timer,
                  color: _playerWon ? Colors.green : Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _raceStatusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _playerWon
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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
                // Checkered finish line pattern
                Positioned(
                  right: 2,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    width: 8,
                    child: Column(
                      children: [
                        // Create checkered pattern
                        for (int i = 0; i < 6; i++)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: (i % 2 == 0)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: (i % 2 == 0)
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
    IconData characterIcon;

    if (isHighScore) {
      // High score character - golden/orange theme
      characterColor = Colors.orange.shade600;

      // Show trophy only if high score character won
      if (widget.isGameComplete) {
        characterIcon = _highScoreWon ? Icons.emoji_events : Icons.person;
      } else {
        characterIcon =
            widget.isGameRunning ? Icons.directions_run : Icons.person;
      }
    } else {
      // Player character - use theme color
      characterColor = widget.characterColor;

      // Change color based on progress vs high score position
      if (widget.highScoreTimeMs > 0 && widget.isGameRunning) {
        double playerProgress = widget.completedStars / 12.0;
        double highScoreProgress =
            widget.currentElapsedTimeMs / widget.highScoreTimeMs;

        if (playerProgress > highScoreProgress) {
          characterColor = Colors.green; // Player is ahead
        } else if (playerProgress < highScoreProgress * 0.8) {
          characterColor = Colors.red; // Player is falling behind
        }
      }

      // Show trophy only if player won
      if (widget.isGameComplete) {
        characterIcon = _playerWon ? Icons.emoji_events : Icons.person;
      } else {
        characterIcon =
            widget.isGameRunning ? Icons.directions_run : Icons.person;
      }
    }

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
