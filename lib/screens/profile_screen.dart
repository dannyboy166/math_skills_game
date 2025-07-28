import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:number_ninja/screens/admin_screen.dart';
import 'package:number_ninja/screens/settings_screen.dart';
import 'package:number_ninja/services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _displayNameController = TextEditingController();

  final AdminService _adminService = AdminService();

  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _streakData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (docSnapshot.exists && mounted) {
          // Get streak data
          final streakData = await _userService.getStreakStats(userId);

          // Get level completions to calculate total stars
          final levelCompletions =
              await _userService.getLevelCompletions(userId);

          final userData = docSnapshot.data()!;
          final completedGames = userData['completedGames'] ?? {};

          // Calculate the sum of all operation counts
          int additionCount = completedGames['addition'] ?? 0;
          int subtractionCount = completedGames['subtraction'] ?? 0;
          int multiplicationCount = completedGames['multiplication'] ?? 0;
          int divisionCount = completedGames['division'] ?? 0;

          int calculatedTotal = additionCount +
              subtractionCount +
              multiplicationCount +
              divisionCount;

          // Calculate total stars from level completions (using same logic as levels screen)
          int totalStarsEarned =
              _calculateTotalStarsFromCompletions(levelCompletions);

          // Use the calculated totals instead of stored values
          userData['totalGames'] = calculatedTotal;
          userData['totalStars'] = totalStarsEarned;

          setState(() {
            _userData = userData;
            _streakData = streakData;
            _displayNameController.text = _userData?['displayName'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Display name cannot be empty')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'displayName': _displayNameController.text.trim(),
        });

        await _authService.currentUser?.updateDisplayName(
          _displayNameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
        }

        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }

  void _showStreakInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade300, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'About Streaks 🔥',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Practice math every day to build your streak! 📅 Each day you complete at least one practice session, your streak grows. Miss a day and your streak resets to zero. 😱',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Benefits of maintaining a streak: ⭐',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.purple.shade700,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎯 Builds consistent learning habits\n🧠 Improves long-term retention\n🎉 Makes learning math more fun\n📈 Track your dedication to math practice',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow.shade200, Colors.orange.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🏆 Keep your streak alive to earn special rewards and become a Math Ninja Master! 🥷',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Got it! 👍',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Calculate total stars using the same logic as the levels screen
  int _calculateTotalStarsFromCompletions(List<dynamic> levelCompletions) {
    int totalStars = 0;

    // Group completions by operation
    final Map<String, List<dynamic>> completionsByOperation = {};
    for (final completion in levelCompletions) {
      final operation = completion.operationName ?? '';
      if (!completionsByOperation.containsKey(operation)) {
        completionsByOperation[operation] = [];
      }
      completionsByOperation[operation]!.add(completion);
    }

    // Calculate stars for each operation using the same level ranges
    for (final operation in [
      'addition',
      'subtraction',
      'multiplication',
      'division'
    ]) {
      final operationCompletions = completionsByOperation[operation] ?? [];
      if (operationCompletions.isEmpty) continue;

      if (operation == 'multiplication' || operation == 'division') {
        // For multiplication/division, each table is its own level
        totalStars +=
            _calculateMultiplicationDivisionStars(operationCompletions);
      } else {
        // For addition/subtraction, use the range-based levels
        totalStars += _calculateAdditionSubtractionStars(operationCompletions);
      }
    }

    return totalStars;
  }

  int _calculateMultiplicationDivisionStars(List<dynamic> completions) {
    int stars = 0;

    // Group by difficulty and target number
    final Map<String, Map<int, int>> bestStarsByDifficultyAndTable = {};

    for (final completion in completions) {
      final difficulty = completion.difficultyName ?? '';
      final targetNumber = completion.targetNumber ?? 0;
      final completionStars = (completion.stars ?? 0) as int;

      if (!bestStarsByDifficultyAndTable.containsKey(difficulty)) {
        bestStarsByDifficultyAndTable[difficulty] = {};
      }

      final currentBest =
          bestStarsByDifficultyAndTable[difficulty]![targetNumber] ?? 0;
      bestStarsByDifficultyAndTable[difficulty]![targetNumber] =
          completionStars > currentBest ? completionStars : currentBest;
    }

    // Sum up all the best stars for each table
    for (final difficultyMap in bestStarsByDifficultyAndTable.values) {
      for (final tableStars in difficultyMap.values) {
        stars += tableStars;
      }
    }

    return stars;
  }

  int _calculateAdditionSubtractionStars(List<dynamic> completions) {
    int stars = 0;

    // Define the same level ranges as in levels_screen.dart
    final levelRanges = [
      // Standard: 1, 2, 3, 4, 5 (individual)
      {
        'difficulty': 'Standard',
        'ranges': [
          [1, 1],
          [2, 2],
          [3, 3],
          [4, 4],
          [5, 5]
        ]
      },
      // Challenging: 6, 7, 8, 9, 10 (individual)
      {
        'difficulty': 'Challenging',
        'ranges': [
          [6, 6],
          [7, 7],
          [8, 8],
          [9, 9],
          [10, 10]
        ]
      },
      // Expert: 11-12, 13-14, 15-16, 17-18, 19-20
      {
        'difficulty': 'Expert',
        'ranges': [
          [11, 12],
          [13, 14],
          [15, 16],
          [17, 18],
          [19, 20]
        ]
      },
      // Impossible: 21-26, 27-32, 33-38, 39-44, 45-50
      {
        'difficulty': 'Impossible',
        'ranges': [
          [21, 26],
          [27, 32],
          [33, 38],
          [39, 44],
          [45, 50]
        ]
      },
    ];

    for (final difficultyData in levelRanges) {
      final difficulty = difficultyData['difficulty'] as String;
      final ranges = difficultyData['ranges'] as List<List<int>>;

      for (final range in ranges) {
        final rangeStart = range[0];
        final rangeEnd = range[1];

        // Find all completions in this range for this difficulty
        final matchingCompletions = completions.where((completion) {
          final completionDifficulty = completion.difficultyName ?? '';
          final targetNumber = completion.targetNumber ?? 0;
          return completionDifficulty.toLowerCase() ==
                  difficulty.toLowerCase() &&
              targetNumber >= rangeStart &&
              targetNumber <= rangeEnd;
        }).toList();

        if (matchingCompletions.isNotEmpty) {
          // Take the maximum stars achieved in this range (same logic as levels screen)
          final maxStars = matchingCompletions
              .map((completion) => (completion.stars ?? 0) as int)
              .reduce((a, b) => a > b ? a : b);
          stars += maxStars;
        }
      }
    }

    return stars;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header with Ninja Theme
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade500,
                      Colors.blue.shade600,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Ninja avatar in circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.yellow.shade300,
                            Colors.orange.shade400
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ninja.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile 🥷',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Your ninja stats await!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit and Settings buttons
                    if (!_isEditing && !_isLoading)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading your ninja stats... 🥷',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _userData == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Colors.red.shade300,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Oops! Could not load profile data 😔',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Avatar and Name Section with Fun Background
                                _buildProfileHeader(),

                                SizedBox(height: 24),

                                // Streak Section with Fun Design
                                _buildStreakSection(),

                                SizedBox(height: 24),

                                // Stats Section with Colorful Cards
                                _buildStatsSection(),

                                SizedBox(height: 24),

                                // Operation Stats with Fun Design
                                _buildOperationStatsSection(),

                                // Admin section (if applicable)
                                if (_adminService.isCurrentUserAdmin()) ...[
                                  SizedBox(height: 32),
                                  _buildAdminSection(),
                                ],

                                SizedBox(height: 20),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade300,
              Colors.pink.shade300,
              Colors.orange.shade300,
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
            // Avatar with fun border and effects
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 15,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ),

            SizedBox(height: 20),

            if (_isEditing) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name ✏️',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed: _updateDisplayName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text('Save 💾',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _displayNameController.text =
                              _userData?['displayName'] ?? '';
                        });
                      },
                      child: Text('Cancel ❌',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                _userData?['displayName'] ?? 'Math Ninja',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _userData?['email'] ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech,
                        color: Colors.yellow.shade200, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Level: ${_userData?['level'] ?? 'Novice'} 🥷',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  'Streak Stats 🔥',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showStreakInfo,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'How it works',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Streak Cards (side by side with fun design)
        Row(
          children: [
            Expanded(
              child: _buildFunStreakCard(
                'Current Streak 🔥',
                '${_streakData?['currentStreak'] ?? 0}',
                Icons.local_fire_department_rounded,
                [Colors.orange.shade400, Colors.red.shade500],
                'days',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFunStreakCard(
                'Longest Streak 🏆',
                '${_streakData?['longestStreak'] ?? 0}',
                Icons.emoji_events_rounded,
                [Colors.yellow.shade400, Colors.orange.shade500],
                'days',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunStreakCard(String title, String value, IconData icon,
      List<Color> colors, String unit) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Text(
              'Game Statistics 📊',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildFunStatCard(
          'Total Games Played 🎮',
          '${_userData?['totalGames'] ?? 0}',
          Icons.sports_esports,
          [Colors.blue.shade400, Colors.purple.shade500],
        ),
        SizedBox(height: 12),
        _buildFunStatCard(
          'Total Stars Earned ⭐',
          '${_userData?['totalStars'] ?? 0}',
          Icons.star,
          [Colors.yellow.shade400, Colors.orange.shade500],
        ),
      ],
    );
  }

  Widget _buildFunStatCard(
      String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Add some fun decorative elements
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.7),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calculate, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text(
              'Operation Stats 🧮',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Operation Stats Grid with fun colors
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildFunOperationCard(
              'Addition 🟢',
              '${_userData?['completedGames']?['addition'] ?? 0}',
              '+',
              [Colors.green.shade400, Colors.green.shade600],
            ),
            _buildFunOperationCard(
              'Subtraction 🟣',
              '${_userData?['completedGames']?['subtraction'] ?? 0}',
              '-',
              [Colors.purple.shade400, Colors.purple.shade600],
            ),
            _buildFunOperationCard(
              'Multiplication 🔵',
              '${_userData?['completedGames']?['multiplication'] ?? 0}',
              '×',
              [Colors.blue.shade400, Colors.blue.shade600],
            ),
            _buildFunOperationCard(
              'Division 🟠',
              '${_userData?['completedGames']?['division'] ?? 0}',
              '÷',
              [Colors.orange.shade400, Colors.orange.shade600],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunOperationCard(
      String title, String count, String symbol, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Symbol in fun circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Title
            Text(
              title.split(' ')[0], // Just the operation name without emoji
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),

            // Games count
            Text(
              '$count games',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Admin Tools 🛠️',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade50, Colors.red.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300, width: 2),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            title: Text(
              'Admin Dashboard 👑',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Manage leaderboards and user data',
              style: TextStyle(color: Colors.red.shade700),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.red.shade400),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

}
