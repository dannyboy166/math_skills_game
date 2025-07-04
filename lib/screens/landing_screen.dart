// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:number_ninja/screens/auth/login_screen.dart';
import 'package:number_ninja/screens/auth/register_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Configure animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation for bouncing effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticInOut,
      ),
    );

    // Rotation animation for math symbols
    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(),
                    SizedBox(height: 40),
                    _buildWelcomeText(),
                  ],
                ),
              ),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating background math symbols
        ..._buildMathSymbols(),

        // Main logo with bounce effect
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "123",
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontFamily: 'ComicSans',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMathSymbols() {
    final symbols = ["+", "-", "×", "÷", "=", "%"];
    final positions = [
      Offset(120, -30),
      Offset(-100, 20),
      Offset(110, 50),
      Offset(-90, -40),
      Offset(30, 80),
      Offset(-30, -80),
    ];
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ];
    final sizes = [40.0, 50.0, 45.0, 48.0, 42.0, 44.0];

    return List.generate(symbols.length, (index) {
      return AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: positions[index],
            child: Transform.rotate(
              angle: _rotateAnimation.value * (index % 2 == 0 ? 1 : -1) * 3.14,
              child: Text(
                symbols[index],
                style: TextStyle(
                  fontSize: sizes[index],
                  fontWeight: FontWeight.bold,
                  color: colors[index],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Number Ninja",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Make learning math fun with games and challenges!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Login Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.3),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(double.infinity, 60),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, size: 28),
                SizedBox(width: 8),
                Text(
                  "I Already Have an Account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Register Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow.shade600,
              foregroundColor: Colors.blue.shade900,
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.3),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: Size(double.infinity, 60),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 28),
                SizedBox(width: 8),
                Text(
                  "Create a New Account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Optional section for parents or teachers
          GestureDetector(
            onTap: () {
              // Could navigate to parent info screen or show a dialog
              _showParentInfoDialog();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "For Parents & Teachers",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showParentInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "For Parents & Teachers",
            style: TextStyle(color: Colors.blue.shade800),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Number Ninja helps children practice essential math skills through fun, engaging gameplay.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  "Features:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                _buildFeatureItem(
                    "Addition, subtraction, multiplication, and division practice"),
                _buildFeatureItem("Progressive difficulty levels"),
                _buildFeatureItem(
                    "Daily streak tracking for consistent practice"),
                _buildFeatureItem(
                    "Leaderboards to encourage friendly competition"),
                _buildFeatureItem(
                    "Secure account system to track your child's progress"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Got it!",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
