// lib/controllers/ring_animation_controller.dart
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'dart:math' as math;

class RingAnimationController {
  // Animation controller for rotation
  late AnimationController _animationController;
  final TickerProvider _vsync;
  
  // Track whether we're currently animating
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  // Track tile positions for animation
  Map<int, Offset> _currentPositions = {};
  Map<int, Offset> _targetPositions = {};
  Map<int, int> _positionToNumber = {};
  Map<int, int> _previousPositionToNumber = {};
  
  // Track tile sizes for smooth transitions
  Map<int, double> _currentSizes = {};
  Map<int, double> _targetSizes = {};
  
  // Track tile color opacities for smooth transitions
  Map<int, double> _currentOpacities = {};
  Map<int, double> _targetOpacities = {};

  // Corner size multiplier (25% larger for corners)
  final double _cornerSize = 1.20;
  final double _regularSize = 1.0;
  
  // Corner and regular opacity
  final double _cornerOpacity = 1.0;
  final double _regularOpacity = 0.6;
  
  // Transition rate - controls how quickly changes happen
  double _transitionRate = 1.0;

  // Callback for when animation completes
  VoidCallback? _onAnimationComplete;

  RingAnimationController(this._vsync, {double transitionRate = 1.0}) {
    _transitionRate = transitionRate;
    _initializeAnimationController();
  }

  void _initializeAnimationController() {
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 400), // Slightly longer for smoother transition
    );

    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
        _animationController.reset();
        
        if (_onAnimationComplete != null) {
          _onAnimationComplete!();
        }
      }
    });
  }

  void updateTransitionRate(double rate) {
    _transitionRate = rate;
  }

  void setOnAnimationComplete(VoidCallback callback) {
    _onAnimationComplete = callback;
  }

  void dispose() {
    _animationController.dispose();
  }

  void updatePositionMappings({
    required RingModel ringModel,
    required double size,
    required double tileSize,
    required bool isInner,
  }) {
    _positionToNumber.clear();
    _currentPositions.clear();
    _targetPositions.clear();
    _targetSizes.clear();
    _targetOpacities.clear();

    final itemCount = ringModel.numbers.length;

    for (int i = 0; i < itemCount; i++) {
      final number = ringModel.getNumberAtPosition(i);
      _positionToNumber[i] = number;

      // Determine if this position is a corner
      final isCorner = ringModel.cornerIndices.contains(i);
      
      // Set the target size for this position
      _targetSizes[i] = isCorner ? _cornerSize : _regularSize;
      
      // Set the target opacity for this position
      _targetOpacities[i] = isCorner ? _cornerOpacity : _regularOpacity;
      
      // If we don't have a current size for this index, initialize it
      if (!_currentSizes.containsKey(i)) {
        _currentSizes[i] = _targetSizes[i]!;
      }
      
      // If we don't have a current opacity for this index, initialize it
      if (!_currentOpacities.containsKey(i)) {
        _currentOpacities[i] = _targetOpacities[i]!;
      }

      // Calculate the position for this tile, using the target size
      final position = isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              i, size, tileSize, 
              cornerSizeMultiplier: _targetSizes[i]!)
          : SquarePositionUtils.calculateSquarePosition(
              i, size, tileSize,
              cornerSizeMultiplier: _targetSizes[i]!);

      _targetPositions[i] = position;
      _currentPositions[i] = position;
    }
  }

  void prepareAnimation({
    required RingModel ringModel,
    required double size,
    required double tileSize,
    required bool isInner,
  }) {
    // Store current positions and numbers before updating
    _previousPositionToNumber = Map.from(_positionToNumber);

    // Update position mappings for new model
    updatePositionMappings(
      ringModel: ringModel,
      size: size, 
      tileSize: tileSize,
      isInner: isInner
    );

    // Don't animate if there's no previous data
    if (_previousPositionToNumber.isEmpty) return;

    // Prepare animation states
    _isAnimating = true;

    // For each position in the new model, find where its number was in the old model
    final itemCount = ringModel.numbers.length;
    for (int i = 0; i < itemCount; i++) {
      final currentNumber = _positionToNumber[i];

      // Find this number's previous position
      int? previousPosition;
      for (final entry in _previousPositionToNumber.entries) {
        if (entry.value == currentNumber) {
          previousPosition = entry.key;
          break;
        }
      }

      if (previousPosition != null) {
        // Determine if previous position was a corner
        final wasPreviousCorner = ringModel.cornerIndices.contains(previousPosition);
        
        // Set the current size based on the previous position
        _currentSizes[i] = wasPreviousCorner ? _cornerSize : _regularSize;
        
        // Set the current opacity based on the previous position
        _currentOpacities[i] = wasPreviousCorner ? _cornerOpacity : _regularOpacity;
        
        // Calculate the old physical position of this number using the previous size
        final oldPosition = isInner
            ? SquarePositionUtils.calculateInnerSquarePosition(
                previousPosition, size, tileSize,
                cornerSizeMultiplier: _currentSizes[i]!)
            : SquarePositionUtils.calculateSquarePosition(
                previousPosition, size, tileSize,
                cornerSizeMultiplier: _currentSizes[i]!);

        // Set as current position for animation
        _currentPositions[i] = oldPosition;
      }
    }
  }

  void startAnimation() {
    if (_isAnimating) {
      _animationController.forward();
    }
  }

  // This method is called by SimpleRing to build animated tiles
  AnimatedTileInfo getAnimatedTileInfo(int index, bool isCorner, bool isLocked) {
    // Offset position
    Offset startPosition = _currentPositions[index] ?? _targetPositions[index]!;
    Offset endPosition = _targetPositions[index]!;
    
    // Size
    double startSize = _currentSizes[index] ?? (isCorner ? _cornerSize : _regularSize);
    double endSize = _targetSizes[index] ?? (isCorner ? _cornerSize : _regularSize);
    
    // Opacity
    double startOpacity = _currentOpacities[index] ?? (isCorner ? _cornerOpacity : _regularOpacity);
    double endOpacity = _targetOpacities[index] ?? (isCorner ? _cornerOpacity : _regularOpacity);
    
    return AnimatedTileInfo(
      startPosition: startPosition,
      endPosition: endPosition,
      startSize: startSize,
      endSize: endSize,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      animationController: _animationController,
      transitionRate: _transitionRate
    );
  }
  
  bool shouldAnimate() {
    return _isAnimating;
  }
}

class AnimatedTileInfo {
  final Offset startPosition;
  final Offset endPosition;
  final double startSize;
  final double endSize;
  final double startOpacity;
  final double endOpacity;
  final AnimationController animationController;
  final double transitionRate;
  
  const AnimatedTileInfo({
    required this.startPosition,
    required this.endPosition,
    required this.startSize,
    required this.endSize,
    required this.startOpacity,
    required this.endOpacity,
    required this.animationController,
    required this.transitionRate,
  });
  
  // Helper method to calculate current position
  Offset calculateCurrentPosition(double progress) {
    return Offset(
      startPosition.dx + (progress * (endPosition.dx - startPosition.dx)),
      startPosition.dy + (progress * (endPosition.dy - startPosition.dy))
    );
  }
  
  // Helper method to calculate current size with easing
  double calculateCurrentSize(double progress) {
    // Apply the transition rate to control how quickly changes happen
    double adjustedProgress = progress;
    
    // Apply the rate: higher values make changes happen earlier in the animation
    if (transitionRate != 1.0) {
      adjustedProgress = transitionRate > 1.0
          ? math.pow(adjustedProgress, 1 / transitionRate).toDouble()
          : math.pow(adjustedProgress, transitionRate).toDouble();
    }
    
    // Apply easing curve on top of the rate adjustment
    final easedProgress = Curves.easeInOut.transform(adjustedProgress);
    
    // Calculate the animated size
    return startSize + (easedProgress * (endSize - startSize));
  }
  
  // Helper method to calculate current opacity with easing
  double calculateCurrentOpacity(double progress) {
    // Apply the transition rate to control how quickly changes happen
    double adjustedProgress = progress;
    
    // Apply the rate: higher values make changes happen earlier in the animation
    if (transitionRate != 1.0) {
      adjustedProgress = transitionRate > 1.0
          ? math.pow(adjustedProgress, 1 / transitionRate).toDouble()
          : math.pow(adjustedProgress, transitionRate).toDouble();
    }
    
    // Apply easing curve on top of the rate adjustment
    final easedProgress = Curves.easeInOut.transform(adjustedProgress);
    
    // Calculate the animated opacity
    return startOpacity + (easedProgress * (endOpacity - startOpacity));
  }
}