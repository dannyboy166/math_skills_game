// lib/screens/home_screen.dart (Redesigned)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'profile_screen.dart';
import '../models/difficulty_level.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedOperation;
  DifficultyLevel selectedLevel = DifficultyLevel.standard;
  int? selectedMultiplicationTable;
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return LevelsScreen(
          operationName: selectedOperation ?? 'addition',
        );
      case 2:
        return _buildLeaderboardScreen();
      case 3:
        return ProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              label: 'Levels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Scores',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeCard(),
                      SizedBox(height: 24),
                      
                      // Operation selection
                      Text(
                        'Choose Operation',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      _buildOperationGrid(),
                      
                      // Show difficulty selection only if an operation is selected
                      if (selectedOperation != null) ...[
                        SizedBox(height: 30),
                        
                        selectedOperation == 'multiplication' || selectedOperation == 'division'
                          ? _buildMultiplicationTablesUI()
                          : _buildDifficultySelection(),
                          
                        SizedBox(height: 30),
                        
                        _buildStartGameButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 22,
            child: Icon(
              Icons.calculate_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Math Skills Game',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              return CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                radius: 18,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Let's Practice Math!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Choose an operation below to start playing and improve your math skills!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildStreakCircle('M', true),
              _buildStreakCircle('T', false),
              _buildStreakCircle('W', true),
              _buildStreakCircle('T', true),
              _buildStreakCircle('F', false),
              _buildStreakCircle('S', false),
              _buildStreakCircle('S', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCircle(String day, bool completed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? Colors.amber
                    : Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: completed
                      ? Colors.amber.shade600
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: completed
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            SizedBox(height: 4),
            Text(
              day,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildOperationCard(
          'Addition', 
          '+', 
          Colors.green,
          'addition',
          Icons.add_circle_rounded,
        ),
        _buildOperationCard(
          'Subtraction', 
          '-', 
          Colors.purple,
          'subtraction',
          Icons.remove_circle_rounded,
        ),
        _buildOperationCard(
          'Multiplication', 
          '×', 
          Colors.blue,
          'multiplication',
          Icons.close_rounded,
        ),
        _buildOperationCard(
          'Division', 
          '÷', 
          Colors.orange,
          'division',
          Icons.pie_chart_rounded,
        ),
      ],
    );
  }

  Widget _buildOperationCard(String title, String symbol, Color color, String operation, IconData icon) {
    final bool isSelected = selectedOperation == operation;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOperation = operation;
          selectedMultiplicationTable = null; // Reset when changing operation
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? color.withOpacity(0.5) 
                : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 40, 
              color: isSelected ? Colors.white : color,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.3) 
                  : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Difficulty',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildDifficultyCard(DifficultyLevel.standard, 'Standard', Colors.green, 'Center number: 1-5'),
            _buildDifficultyCard(DifficultyLevel.challenging, 'Challenging', Colors.blue, 'Center number: 6-10'),
            _buildDifficultyCard(DifficultyLevel.Expert, 'Expert', Colors.orange, 'Center number: 11-20'),
            _buildDifficultyCard(DifficultyLevel.Impossible, 'Impossible', Colors.red, 'Center number: 21-50'),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(DifficultyLevel level, String title, Color color, String description) {
    final bool isSelected = selectedLevel == level;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = level;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? color.withOpacity(0.5) 
                : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 32,
              color: isSelected ? Colors.white : color,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplicationTablesUI() {
    final String operation = selectedOperation == 'multiplication' ? 'Multiplication' : 'Division';
    final String symbol = selectedOperation == 'multiplication' ? '×' : '÷';
    final Color color = selectedOperation == 'multiplication' ? Colors.blue : Colors.orange;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose $operation Table',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        // Categories grid
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildTableCategoryCard('Standard', [1, 2, 5, 10], Colors.green),
            _buildTableCategoryCard('Challenging', [3, 4, 6, 11], Colors.blue),
            _buildTableCategoryCard('Expert', [7, 8, 9, 12], Colors.orange),
            _buildTableCategoryCard('Impossible', [13, 14, 15], Colors.red),
          ],
        ),
        
        SizedBox(height: 20),
        
        Text(
          'Or Select Specific Table',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        // Tables grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            final number = index + 1;
            return _buildTableNumberCard(number);
          },
        ),
        
        SizedBox(height: 20),
        
        // Selected table info
        if (selectedMultiplicationTable != null)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$selectedMultiplicationTable$symbol',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$operation Table of $selectedMultiplicationTable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        selectedOperation == 'multiplication'
                          ? 'Find products of $selectedMultiplicationTable in the outer ring'
                          : 'Find numbers that, when divided, equal $selectedMultiplicationTable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildTableCategoryCard(String category, List<int> tables, Color color) {
    final bool hasSelectedTable = selectedMultiplicationTable != null && 
                                 tables.contains(selectedMultiplicationTable);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          final random = Random();
          selectedMultiplicationTable = tables[random.nextInt(tables.length)];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasSelectedTable ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hasSelectedTable 
                ? color.withOpacity(0.5) 
                : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: hasSelectedTable ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSelectedTable ? Icons.check_circle_rounded : Icons.star_rounded,
              size: 32,
              color: hasSelectedTable ? Colors.white : color,
            ),
            SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasSelectedTable ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tables: ${tables.join(", ")}',
              style: TextStyle(
                fontSize: 12,
                color: hasSelectedTable ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTableNumberCard(int number) {
    // Determine category and color
    Color color;
    if ([1, 2, 5, 10].contains(number)) {
      color = Colors.green;
    } else if ([3, 4, 6, 11].contains(number)) {
      color = Colors.blue;
    } else if ([7, 8, 9, 12].contains(number)) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    final bool isSelected = selectedMultiplicationTable == number;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMultiplicationTable = number;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? color.withOpacity(0.5) 
                : Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartGameButton() {
    // Determine button color based on operation
    Color buttonColor;
    if (selectedOperation == 'addition') {
      buttonColor = Colors.green;
    } else if (selectedOperation == 'subtraction') {
      buttonColor = Colors.purple;
    } else if (selectedOperation == 'multiplication') {
      buttonColor = Colors.blue;
    } else {
      buttonColor = Colors.orange;
    }
    
    bool canStartGame = true;
    String? errorMessage;
    
    // Check if all required selections have been made
    if (selectedOperation == null) {
      canStartGame = false;
    } else if ((selectedOperation == 'multiplication' || selectedOperation == 'division') && 
              selectedMultiplicationTable == null) {
      canStartGame = false;
      errorMessage = 'Please select a table first';
    }
    
    return Column(
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
        ],
        
        ElevatedButton(
          onPressed: canStartGame ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  operationName: selectedOperation!,
                  difficultyLevel: selectedLevel,
                  targetNumber: (selectedOperation == 'multiplication' ||
                              selectedOperation == 'division') &&
                          selectedMultiplicationTable != null
                      ? selectedMultiplicationTable
                      : null,
                ),
              ),
            );
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: buttonColor.withOpacity(0.5),
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded, size: 24),
              SizedBox(width: 8),
              Text(
                'Start Game',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Placeholder for Leaderboard screen (to be implemented)
  Widget _buildLeaderboardScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 80,
            color: Colors.blue.shade200,
          ),
          SizedBox(height: 16),
          Text(
            'Leaderboard Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Challenge your friends and see who can get the highest score!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}