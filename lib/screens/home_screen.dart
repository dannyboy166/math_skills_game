import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_operation.dart';
import '../operations/operation_factory.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedNumber = 2;
  String selectedOperation = 'multiplication';
  late final AnimationController _controller;
  late final AnimationController _bounceController;
  
  // Background color animation
  late final AnimationController _backgroundController;
  late final Animation<Color?> _colorAnimation;
  final List<Color> _backgroundColors = [
    Colors.blue.shade100,
    Colors.purple.shade100,
    Colors.pink.shade100,
    Colors.teal.shade100,
  ];
  
  // Get all available operations
  final List<GameOperation> _operations = OperationFactory.getAllOperations();
  
  @override
  void initState() {
    super.initState();
    
    // Controller for rotating animation
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Controller for bouncing animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Background color animation controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Background color animation
    _colorAnimation = TweenSequence<Color?>(
      _backgroundColors.map((color) {
        return TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: color, end: _backgroundColors[
            (_backgroundColors.indexOf(color) + 1) % _backgroundColors.length
          ]),
        );
      }).toList(),
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _colorAnimation.value ?? Colors.blue.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Animated title
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.purple.shade400,
                                Colors.pink.shade400,
                                Colors.orange.shade400,
                              ],
                              stops: const [0.0, 0.3, 0.6, 1.0],
                              tileMode: TileMode.clamp,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Math Skills Game',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated subtitle
                                AnimatedBuilder(
                                  animation: _bounceController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _bounceController.value * 10 - 5),
                                      child: Text(
                                        'Choose a number to practice:',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.indigo.shade800,
                                          shadows: [
                                            Shadow(
                                              color: Colors.indigo.shade200,
                                              blurRadius: 2,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 30),
                                // Number selection grid
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (int i = 2; i <= 12; i++)
                                      _buildNumberButton(i),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  'Choose operation:',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.indigo.shade200,
                                        blurRadius: 2,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // Operation buttons row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _operations.map((op) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: _buildOperationButton(op.symbol, op.name),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 50),
                                // Start game button
                                _buildStartGameButton(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNumberButton(int number) {
    final isSelected = selectedNumber == number;
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: isSelected ? 1.1 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedNumber = number;
              });
            },
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade100, Colors.grey.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: isSelected ? 12 : 5,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationButton(String symbol, String operation) {
    final isSelected = selectedOperation == operation;
    final operationColor = _getOperationColor(operation);
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: isSelected ? 1.1 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedOperation = operation;
              });
            },
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          operationColor.shade400,
                          operationColor.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade100, Colors.grey.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? operationColor.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: isSelected ? 12 : 5,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  MaterialColor _getOperationColor(String operation) {
    switch (operation) {
      case 'addition':
        return Colors.green;
      case 'subtraction':
        return Colors.purple;
      case 'multiplication':
        return Colors.blue;
      case 'division':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildStartGameButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => GameScreen(
                    targetNumber: selectedNumber,
                    operationName: selectedOperation,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var begin = const Offset(1.0, 0.0);
                    var end = Offset.zero;
                    var curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 220,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated confetti particles
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(220, 70),
                        painter: ConfettiPainter(_controller.value),
                      );
                    },
                  ),
                  // Button text with animated scale
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _bounceController.value * 0.2,
                        child: const Text(
                          'Start Game!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for confetti effect on button
class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<Confetti> particles = List.generate(20, (index) => Confetti());

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      final particleSize = particle.size * 5;
      final rotationAngle = animationValue * particle.rotationSpeed;
      
      final position = Offset(
        (particle.x + animationValue * particle.speedX) % 1.0 * size.width,
        (particle.y + animationValue * particle.speedY) % 1.0 * size.height,
      );
      
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotationAngle);
      
      // Draw different confetti shapes
      if (particle.shapeType < 0.33) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: particleSize, height: particleSize * 2),
          paint,
        );
      } else if (particle.shapeType < 0.66) {
        // Circle
        canvas.drawCircle(Offset.zero, particleSize, paint);
      } else {
        // Triangle
        final path = Path()
          ..moveTo(0, -particleSize)
          ..lineTo(-particleSize, particleSize)
          ..lineTo(particleSize, particleSize)
          ..close();
        canvas.drawPath(path, paint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Confetti {
  final double x;
  final double y;
  final double size;
  final double speedX;
  final double speedY;
  final double rotationSpeed;
  final double shapeType;  // Used to determine shape
  final Color color;

  Confetti()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 0.2 + 0.1,
        speedX = (math.Random().nextDouble() - 0.5) * 0.5,
        speedY = (math.Random().nextDouble() - 0.5) * 0.5,
        rotationSpeed = math.Random().nextDouble() * 10,
        shapeType = math.Random().nextDouble(),
        color = [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.pink,
        ][math.Random().nextInt(7)];
}