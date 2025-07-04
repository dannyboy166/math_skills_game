// lib/screens/home_screen.dart (Redesigned)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:math_skills_game/screens/leaderboard_screen.dart';
import 'package:math_skills_game/widgets/custom_bottom_nav_bar.dart';
import 'package:math_skills_game/widgets/streak_flame_widget.dart';
import 'dart:math';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'profile_screen.dart';
import '../models/difficulty_level.dart';
import '../models/game_mode.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/daily_streak.dart';

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
  final UserService _userService = UserService();

  // Track unlocked time tables
  List<int> _unlockedTimeTables = [];
  bool _isLoadingUnlocks = true;

  // Weekly streak data
  WeeklyStreak _weeklyStreak = WeeklyStreak.currentWeek();
  bool _isLoadingStreak = true; // Add this if not already defined
  int _currentStreak = 0;
  int _longestStreak = 0;

  // Stream subscriptions
  StreamSubscription? _weeklyStreakSubscription;
  StreamSubscription? _streakStatsSubscription;
  StreamSubscription? _unlockedTimeTablesSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize with empty data
    _weeklyStreak = WeeklyStreak.currentWeek();

    // Start listening to streams when signed in
    _listenToStreakData();
    _listenToUnlockData();
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _weeklyStreakSubscription?.cancel();
    _streakStatsSubscription?.cancel();
    _unlockedTimeTablesSubscription?.cancel();
    super.dispose();
  }

  void _listenToStreakData() {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoadingStreak = true;
    });

    // Listen to weekly streak
    _weeklyStreakSubscription?.cancel();
    _weeklyStreakSubscription = _userService
        .weeklyStreakStream(_authService.currentUser!.uid)
        .listen((weeklyStreak) {
      if (mounted) {
        setState(() {
          _weeklyStreak = weeklyStreak;
          _isLoadingStreak = false;
        });
      }
    }, onError: (e) {
      print('Error in weekly streak stream: $e');
      if (mounted) {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    });

    // Listen to streak stats
    _streakStatsSubscription?.cancel();
    _streakStatsSubscription = _userService
        .streakStatsStream(_authService.currentUser!.uid)
        .listen((stats) {
      if (mounted) {
        setState(() {
          _currentStreak = stats['currentStreak'] ?? 0;
          _longestStreak = stats['longestStreak'] ?? 0;
        });
      }
    }, onError: (e) {
      print('Error in streak stats stream: $e');
    });
  }

  void _listenToUnlockData() {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoadingUnlocks = true;
    });

    // Listen to unlocked time tables
    _unlockedTimeTablesSubscription?.cancel();
    _unlockedTimeTablesSubscription = _userService
        .unlockedTimeTablesStream(_authService.currentUser!.uid)
        .listen((unlockedTables) {
      if (mounted) {
        setState(() {
          _unlockedTimeTables = unlockedTables;
          _isLoadingUnlocks = false;
        });
      }
    }, onError: (e) {
      print('Error in unlocked time tables stream: $e');
      if (mounted) {
        setState(() {
          _isLoadingUnlocks = false;
        });
      }
    });
  }

  Future<void> _loadStreakData() async {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoadingStreak = true;
    });

    try {
      // Load weekly streak
      final weeklyStreak = await _userService
          .getCurrentWeekStreak(_authService.currentUser!.uid);

      // Load streak stats
      final streakStats =
          await _userService.getStreakStats(_authService.currentUser!.uid);

      if (mounted) {
        setState(() {
          _weeklyStreak = weeklyStreak;
          _currentStreak = streakStats['currentStreak'] ?? 0;
          _longestStreak = streakStats['longestStreak'] ?? 0;
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      print('Error loading streak data: $e');
      if (mounted) {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // Reload streak data when navigating to home tab
            if (index == 0) {
              _loadStreakData();
            }
          });
        },
      ),
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
                        selectedOperation == 'multiplication' ||
                                selectedOperation == 'division'
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

// In your home_screen.dart file, update the _buildHeader method
// Make sure to import the StreakFlameWidget at the top of the file:
// import 'package:math_skills_game/widgets/streak_flame_widget.dart';

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
          // Replace the profile avatar with StreakFlameWidget
          const StreakFlameWidget(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's Practice Math!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_currentStreak > 0)
                      Text(
                        "Current streak: $_currentStreak days" +
                            (_longestStreak > _currentStreak
                                ? " (Best: $_longestStreak)"
                                : ""),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
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
          _isLoadingStreak
              ? Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : _buildStreakRow(),
        ],
      ),
    );
  }
// REPLACE the _buildStreakRow method in your home_screen.dart with this fixed version

  Widget _buildStreakRow() {
    // Day abbreviations (Sunday to Saturday)
    final dayAbbreviations = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // Get today's info for comparison
    final now = DateTime.now();
    final todayWeekday = now.weekday == 7 ? 0 : now.weekday; // Sunday = 0

    return Row(
      children: List.generate(7, (index) {
        // Get the streak status for this day of week
        final dayStreak = _weeklyStreak.getDayStreak(index);
        final bool completed = dayStreak?.completed ?? false;

        // Check if this day represents today
        final isToday = index == todayWeekday;

        // Debug information
        if (isToday) {
          print(
              'STREAK ROW DEBUG: Today is day $index ($dayAbbreviations[index])');
          print('STREAK ROW DEBUG: Today completed: $completed');
          print('STREAK ROW DEBUG: Current streak count: $_currentStreak');
        }

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
                        : (isToday
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2)),
                    border: Border.all(
                      color: completed
                          ? Colors.amber.shade600
                          : (isToday
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.5)),
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : (isToday
                          ? Icon(
                              Icons.today,
                              color: Colors.white.withOpacity(0.8),
                              size: 12,
                            )
                          : null),
                ),
                SizedBox(height: 4),
                Text(
                  dayAbbreviations[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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

// Updated _buildOperationCard method to fix alignment issues
  Widget _buildOperationCard(String title, String symbol, Color color,
      String operation, IconData icon) {
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Top icon circle
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : color,
            ),

            // Middle text
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),

            // Bottom symbol - Fixed vertical centering
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              // Add alignment to center the content vertically and horizontally
              alignment: Alignment.center,
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
            _buildDifficultyCard(DifficultyLevel.standard, 'Standard',
                Colors.green, 'Center number: 1-5'),
            _buildDifficultyCard(DifficultyLevel.challenging, 'Challenging',
                Colors.blue, 'Center number: 6-10'),
            _buildDifficultyCard(DifficultyLevel.expert, 'Expert',
                Colors.orange, 'Center number: 11-20'),
            _buildDifficultyCard(DifficultyLevel.impossible, 'Impossible',
                Colors.red, 'Center number: 21-50'),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(
      DifficultyLevel level, String title, Color color, String description) {
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
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplicationTablesUI() {
    final String operation =
        selectedOperation == 'multiplication' ? 'Multiplication' : 'Division';
    final String symbol = selectedOperation == 'multiplication' ? '×' : '÷';
    final Color color =
        selectedOperation == 'multiplication' ? Colors.blue : Colors.orange;

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
        SizedBox(height: 12),
        
        // Add encouraging message for locked tables
        _buildUnlockMessage(),
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

  Widget _buildTableCategoryCard(
      String category, List<int> tables, Color color) {
    final bool hasSelectedTable = selectedMultiplicationTable != null &&
        tables.contains(selectedMultiplicationTable);
    
    // Check if any tables in this category are unlocked
    final bool hasUnlockedTables = tables.any((table) => _unlockedTimeTables.contains(table));
    final int unlockedCount = tables.where((table) => _unlockedTimeTables.contains(table)).length;

    return GestureDetector(
      onTap: hasUnlockedTables ? () {
        setState(() {
          final random = Random();
          // Only select from unlocked tables
          final unlockedTablesInCategory = tables.where((table) => _unlockedTimeTables.contains(table)).toList();
          if (unlockedTablesInCategory.isNotEmpty) {
            selectedMultiplicationTable = unlockedTablesInCategory[random.nextInt(unlockedTablesInCategory.length)];
          }
        });
      } : null,
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
              hasSelectedTable
                  ? Icons.check_circle_rounded
                  : Icons.star_rounded,
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
              hasUnlockedTables 
                  ? 'Tables: ${tables.join(", ")} ($unlockedCount/${tables.length} unlocked)'
                  : 'Tables: ${tables.join(", ")} (Locked)',
              style: TextStyle(
                fontSize: 12,
                color: hasSelectedTable
                    ? Colors.white.withOpacity(0.9)
                    : hasUnlockedTables
                        ? Colors.grey.shade600
                        : Colors.grey.shade500,
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
    DifficultyLevel difficulty;

    if ([1, 2, 5, 10].contains(number)) {
      color = Colors.green;
      difficulty = DifficultyLevel.standard;
    } else if ([3, 4, 6, 11].contains(number)) {
      color = Colors.blue;
      difficulty = DifficultyLevel.challenging;
    } else if ([7, 8, 9, 12].contains(number)) {
      color = Colors.orange;
      difficulty = DifficultyLevel.expert;
    } else {
      color = Colors.red;
      difficulty = DifficultyLevel.impossible;
    }

    final bool isSelected = selectedMultiplicationTable == number;
    final bool isUnlocked = _unlockedTimeTables.contains(number);
    final bool isLoading = _isLoadingUnlocks;

    return GestureDetector(
      onTap: isUnlocked ? () {
        setState(() {
          selectedMultiplicationTable = number;
          selectedLevel =
              difficulty; // THIS LINE IS CRUCIAL - Update the difficulty when selecting a table
        });
      } : null, // Disable tap if locked
      child: Container(
        decoration: BoxDecoration(
          color: isLoading 
              ? Colors.grey.shade100
              : !isUnlocked 
                  ? Colors.grey.shade200
                  : isSelected 
                      ? color 
                      : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isLoading
                  ? Colors.grey.withOpacity(0.1)
                  : !isUnlocked
                      ? Colors.grey.withOpacity(0.2)
                      : isSelected
                          ? color.withOpacity(0.5)
                          : Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isLoading
                ? Colors.grey.shade300
                : !isUnlocked
                    ? Colors.grey.shade400
                    : isSelected 
                        ? color 
                        : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLoading
                      ? Colors.grey.shade400
                      : !isUnlocked
                          ? Colors.grey.shade500
                          : isSelected 
                              ? Colors.white 
                              : color,
                ),
              ),
            ),
            // Show lock icon for locked tables
            if (!isUnlocked && !isLoading)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            // Show loading indicator
            if (isLoading)
              Positioned(
                bottom: 4,
                right: 4,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockMessage() {
    if (_isLoadingUnlocks) {
      return SizedBox.shrink(); // Don't show while loading
    }
    
    // Find the next table to unlock
    List<int> allTables = List.generate(15, (index) => index + 1);
    List<int> lockedTables = allTables.where((table) => !_unlockedTimeTables.contains(table)).toList();
    
    if (lockedTables.isEmpty) {
      // All tables unlocked - show celebration message
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade100, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 Amazing! You\'ve unlocked ALL times tables! 🎉',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(Icons.star, color: Colors.orange, size: 20),
          ],
        ),
      );
    }
    
    // Group locked tables by unlock requirements and find the next group to unlock
    List<List<int>> progressionGroups = [
      [1, 2, 5, 10],        // Basic tables (initial unlock)
      [3, 4, 6],            // Unlocked after completing any basic table
      [7, 8, 9],            // Unlocked after completing any intermediate table
      [11, 12],             // Unlocked after completing any advanced table
      [13, 14, 15],         // Unlocked after completing any expert table
    ];
    
    // Find which group contains the next tables to unlock
    List<int> nextGroupToUnlock = [];
    String tableToComplete = '';
    
    for (int i = 0; i < progressionGroups.length; i++) {
      List<int> group = progressionGroups[i];
      List<int> lockedInGroup = group.where((table) => lockedTables.contains(table)).toList();
      
      if (lockedInGroup.isNotEmpty) {
        nextGroupToUnlock = lockedInGroup;
        
        // Determine what they need to complete to unlock this group
        if (i == 1) {
          tableToComplete = 'any 1×, 2×, 5×, or 10× times table';
        } else if (i == 2) {
          tableToComplete = 'any 3×, 4×, or 6× times table';
        } else if (i == 3) {
          tableToComplete = 'any 7×, 8×, or 9× times table';
        } else if (i == 4) {
          tableToComplete = 'any 11× or 12× times table';
        }
        break;
      }
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open, color: Colors.blue.shade600, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade800,
                ),
                children: [
                  TextSpan(text: 'Complete '),
                  TextSpan(
                    text: tableToComplete,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' perfectly to unlock '),
                  TextSpan(
                    text: '${nextGroupToUnlock.map((table) => '$table×').join(', ')} tables',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                  ),
                  TextSpan(text: '! 🚀'),
                ],
              ),
            ),
          ),
          Icon(Icons.rocket_launch, color: Colors.purple.shade600, size: 16),
        ],
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
    } else if ((selectedOperation == 'multiplication' ||
            selectedOperation == 'division') &&
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
          onPressed: canStartGame
              ? () {
                  // For multiplication/division, determine difficulty based on the selected table
                  DifficultyLevel difficultyToUse = selectedLevel;

                  if ((selectedOperation == 'multiplication' ||
                          selectedOperation == 'division') &&
                      selectedMultiplicationTable != null) {
                    // Determine proper difficulty based on the table
                    if ([1, 2, 5, 10].contains(selectedMultiplicationTable)) {
                      difficultyToUse = DifficultyLevel.standard;
                    } else if ([3, 4, 6, 11]
                        .contains(selectedMultiplicationTable)) {
                      difficultyToUse = DifficultyLevel.challenging;
                    } else if ([7, 8, 9, 12]
                        .contains(selectedMultiplicationTable)) {
                      difficultyToUse =
                          DifficultyLevel.expert; // lowercase is correct
                    } else {
                      difficultyToUse =
                          DifficultyLevel.impossible; // lowercase is correct
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(
                        operationName: selectedOperation!,
                        difficultyLevel:
                            difficultyToUse, // ✅ Use the corrected difficulty
                        targetNumber: (selectedOperation == 'multiplication' ||
                                    selectedOperation == 'division') &&
                                selectedMultiplicationTable != null
                            ? selectedMultiplicationTable
                            : null,
                        gameMode: GameMode.timesTableRing,
                      ),
                    ),
                  );
                }
              : null,
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
              Icon(
                Icons.play_circle_fill_rounded,
                size: 24,
                color: Colors.white, // Add this line to make the icon white
              ),
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

  Widget _buildLeaderboardScreen() {
    return LeaderboardScreen();
  }
}
