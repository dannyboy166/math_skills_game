// lib/screens/home_screen.dart (Redesigned)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:number_ninja/screens/leaderboard_screen.dart';
import 'package:number_ninja/widgets/custom_bottom_nav_bar.dart';
import 'package:number_ninja/widgets/streak_flame_widget.dart';
import 'dart:math';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'profile_screen.dart';
import '../models/difficulty_level.dart';
import '../models/game_mode.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/haptic_service.dart';
import '../models/daily_streak.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? selectedOperation;
  DifficultyLevel selectedLevel = DifficultyLevel.standard;
  int? selectedMultiplicationTable;
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Animation controllers
  late AnimationController _ninjaAnimationController;
  late Animation<double> _ninjaScaleAnimation;
  
  // Scroll controller for header animations
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Track unlocked time tables
  List<int> _unlockedTimeTables = [];
  bool _isLoadingUnlocks = true;

  // Weekly streak data
  WeeklyStreak _weeklyStreak = WeeklyStreak.currentWeek();
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

    // Initialize animations
    _ninjaAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _ninjaScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _ninjaAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start breathing animation
    _ninjaAnimationController.repeat(reverse: true);
    
    // Listen to scroll for header animations
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

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
    
    // Dispose animations
    _ninjaAnimationController.dispose();
    _scrollController.dispose();
    
    super.dispose();
  }

  void _listenToStreakData() {
    if (_authService.currentUser == null) return;

    setState(() {});

    // Listen to weekly streak
    _weeklyStreakSubscription?.cancel();
    _weeklyStreakSubscription = _userService
        .weeklyStreakStream(_authService.currentUser!.uid)
        .listen((weeklyStreak) {
      if (mounted) {
        setState(() {
          _weeklyStreak = weeklyStreak;
        });
      }
    }, onError: (e) {
      print('Error in weekly streak stream: $e');
      if (mounted) {
        setState(() {});
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

    setState(() {});

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
        });
      }
    } catch (e) {
      print('Error loading streak data: $e');
      if (mounted) {
        setState(() {});
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
          HapticService().lightImpact();
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
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAnimatedHeader(),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
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
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    // Calculate header scaling based on scroll
    double headerScale = 1.0 - (_scrollOffset / 400).clamp(0.0, 0.4);
    double ninjaScale = 1.0 - (_scrollOffset / 300).clamp(0.0, 0.6);
    double titleOpacity = (1.0 - (_scrollOffset / 200)).clamp(0.0, 1.0);
    
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: false,
      snap: false,
      elevation: 8,
      shadowColor: Colors.blue.withValues(alpha: 0.3),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade500,
                Colors.blue.shade600,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Animated ninja with breathing effect
                  AnimatedBuilder(
                    animation: _ninjaScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: ninjaScale * _ninjaScaleAnimation.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow.shade300,
                                Colors.orange.shade400
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.5),
                                blurRadius: 10 * ninjaScale,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              width: 35,
                              height: 35,
                              child: Image.asset(
                                'assets/images/ninja.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.calculate_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(width: 16),
                  
                  // App title and subtitle with fade effect
                  Expanded(
                    child: Opacity(
                      opacity: titleOpacity,
                      child: Transform.scale(
                        scale: headerScale,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Number Ninja',
                              style: TextStyle(
                                fontSize: 22 * headerScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (titleOpacity > 0.5)
                              Text(
                                _getHeaderSubtitle(),
                                style: TextStyle(
                                  fontSize: 13 * headerScale,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Streak widget with scaling
                  Transform.scale(
                    scale: headerScale,
                    child: const StreakFlameWidget(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    final hour = DateTime.now().hour;

    if (_currentStreak >= 7) {
      return 'You\'re on fire! Keep it up!';
    } else if (_currentStreak > 0) {
      return 'Great progress today!';
    } else if (hour < 12) {
      return 'Good morning, mathematician!';
    } else if (hour < 17) {
      return 'Ready for some math fun?';
    } else {
      return 'Evening practice time!';
    }
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.pink.shade400,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with animated elements
          Row(
            children: [
              // Animated trophy/flame based on streak
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(
                  _currentStreak > 0
                      ? Icons.local_fire_department_rounded
                      : Icons.rocket_launch_rounded,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic title based on streak
                    Text(
                      _getWelcomeTitle(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Streak info with emoji
                    Text(
                      _getStreakMessage(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Fun weekly progress with bigger, more colorful circles
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  "This Week's Progress 📅",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                _buildFunStreakRow(),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Motivational message with emoji
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMotivationalQuote(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getWelcomeTitle() {
    if (_currentStreak == 0) {
      return "Ready to Start?";
    } else if (_currentStreak == 1) {
      return "Great Start! 🌟";
    } else if (_currentStreak < 7) {
      return "You're On Fire! 🔥";
    } else if (_currentStreak < 30) {
      return "Math Champion! 🏆";
    } else {
      return "Math Legend! 👑";
    }
  }

  String _getStreakMessage() {
    if (_currentStreak == 0) {
      return "Let's build your streak!";
    } else if (_currentStreak == 1) {
      return "🔥 1 day streak - Keep going!";
    } else {
      return "🔥 $_currentStreak day streak" +
          (_longestStreak > _currentStreak
              ? " (Best: $_longestStreak)"
              : " - Amazing!");
    }
  }

  String _getMotivationalQuote() {
    final quotes = [
      "Practice makes perfect! 💪",
      "Every expert was once a beginner! ⭐",
      "You're getting stronger every day! 🌱",
      "Math is your superpower! ⚡",
      "Keep up the awesome work! 🎉",
      "You've got this, champion! 🏆",
    ];

    return quotes[_currentStreak % quotes.length];
  }

  Widget _buildFunStreakRow() {
    final dayAbbreviations = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();
    final todayWeekday = now.weekday == 7 ? 0 : now.weekday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayStreak = _weeklyStreak.getDayStreak(index);
        final bool completed = dayStreak?.completed ?? false;
        final isToday = index == todayWeekday;

        return Column(
          children: [
            // Bigger, more colorful circles
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: completed
                    ? LinearGradient(
                        colors: [
                          Colors.yellow.shade300,
                          Colors.orange.shade400
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: completed
                    ? null
                    : (isToday
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2)),
                border: Border.all(
                  color: completed
                      ? Colors.yellow.shade600
                      : (isToday
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.5)),
                  width: 2.5,
                ),
                boxShadow: completed
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: completed
                  ? Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    )
                  : (isToday
                      ? Icon(
                          Icons.today,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        )
                      : Container()),
            ),
            SizedBox(height: 6),
            Text(
              dayAbbreviations[index],
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
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

// Updated _buildOperationCard method with hover animations
  Widget _buildOperationCard(String title, String symbol, Color color,
      String operation, IconData icon) {
    final bool isSelected = selectedOperation == operation;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) {
              // Scale down slightly on tap
            },
            onTapUp: (_) {
              // Scale back to normal
            },
            onTapCancel: () {
              // Scale back to normal if tap is cancelled
            },
            onTap: () {
              HapticService().lightImpact();
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
                        ? color.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.05),
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
                          ? Colors.white.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.1),
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
          ),
        );
      },
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
                  ? color.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.05),
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
                    ? Colors.white.withValues(alpha: 0.9)
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
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
    final bool hasUnlockedTables =
        tables.any((table) => _unlockedTimeTables.contains(table));
    final int unlockedCount =
        tables.where((table) => _unlockedTimeTables.contains(table)).length;

    return GestureDetector(
      onTap: hasUnlockedTables
          ? () {
              setState(() {
                final random = Random();
                // Only select from unlocked tables
                final unlockedTablesInCategory = tables
                    .where((table) => _unlockedTimeTables.contains(table))
                    .toList();
                if (unlockedTablesInCategory.isNotEmpty) {
                  selectedMultiplicationTable = unlockedTablesInCategory[
                      random.nextInt(unlockedTablesInCategory.length)];
                }
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: hasSelectedTable ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hasSelectedTable
                  ? color.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.05),
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
                    ? Colors.white.withValues(alpha: 0.9)
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
      onTap: isUnlocked
          ? () {
              setState(() {
                selectedMultiplicationTable = number;
                selectedLevel =
                    difficulty; // THIS LINE IS CRUCIAL - Update the difficulty when selecting a table
              });
            }
          : null, // Disable tap if locked
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
                  ? Colors.grey.withValues(alpha: 0.1)
                  : !isUnlocked
                      ? Colors.grey.withValues(alpha: 0.2)
                      : isSelected
                          ? color.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.05),
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
    List<int> lockedTables = allTables
        .where((table) => !_unlockedTimeTables.contains(table))
        .toList();

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
      [1, 2, 5, 10], // Basic tables (initial unlock)
      [3, 4, 6], // Unlocked after completing any basic table
      [7, 8, 9], // Unlocked after completing any intermediate table
      [11, 12], // Unlocked after completing any advanced table
      [13, 14, 15], // Unlocked after completing any expert table
    ];

    // Find which group contains the next tables to unlock
    List<int> nextGroupToUnlock = [];
    String tableToComplete = '';

    for (int i = 0; i < progressionGroups.length; i++) {
      List<int> group = progressionGroups[i];
      List<int> lockedInGroup =
          group.where((table) => lockedTables.contains(table)).toList();

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
                    text:
                        '${nextGroupToUnlock.map((table) => '$table×').join(', ')} tables',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700),
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
            shadowColor: buttonColor.withValues(alpha: 0.5),
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
