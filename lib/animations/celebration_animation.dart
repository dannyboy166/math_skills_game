// lib/animations/celebration_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class CelebrationAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final int starRating; // Add star rating parameter
  
  const CelebrationAnimation({
    Key? key,
    required this.onComplete,
    required this.starRating, // Make this required
  }) : super(key: key);

  @override
  CelebrationAnimationState createState() => CelebrationAnimationState();
}

class CelebrationAnimationState extends State<CelebrationAnimation> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late String _celebrationMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Select celebration message based on star rating
    _celebrationMessage = _getRandomCelebrationMessage(widget.starRating);
    
    // Confetti controller
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _confettiController.play();
    
    // Scale animation for celebratory text
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_scaleController);
    
    _scaleController.forward();
    
    // Call onComplete when animation is done
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
  
  // Get a random celebration message based on star rating
  String _getRandomCelebrationMessage(int stars) {
    final random = math.Random();
    
    // Different message sets based on star rating
    List<String> messages;
    
    if (stars == 0) {
      messages = [
        "Completed!",
        "Good effort!",
        "Keep trying!",
        "Nice job!",
        "You did it!",
      ];
    } else if (stars == 1) {
      messages = [
        "Well done!",
        "Great work!",
        "Excellent!",
        "Nice going!",
        "You got a star!",
      ];
    } else if (stars == 2) {
      messages = [
        "Impressive!",
        "Fantastic job!",
        "Brilliant work!",
        "Amazing!",
        "Superb!",
      ];
    } else { // 3 stars
      messages = [
        "Outstanding!",
        "Perfect!",
        "Excellent!",
        "Magnificent!",
        "Incredible!",
      ];
    }
    
    // Return a random message from the appropriate list
    return messages[random.nextInt(messages.length)];
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Center confetti
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
        
        // Top confetti blast
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
        
        // Celebratory text with animation
        Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _celebrationMessage,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star,
                              size: 40,
                              color: index < widget.starRating
                                  ? Colors.amber
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}