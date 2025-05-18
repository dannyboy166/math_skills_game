import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_skills_game/services/leaderboard_updater.dart';
import 'package:math_skills_game/services/scalable_leaderboard_service.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/leaderboard_tab.dart';
import '../widgets/time_leaderboard_tab.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  // Use the scalable leaderboard service
  final ScalableLeaderboardService _leaderboardService =
      ScalableLeaderboardService();
  late TabController _tabController;
  bool _isLoading = true;
  int _currentUserRank = 0;
  String _currentUserId = '';

  // Data for each leaderboard type
  List<LeaderboardEntry>? _streakLeaderboard;
  List<LeaderboardEntry>? _gamesLeaderboard;
  // Time-based leaderboards
  List<LeaderboardEntry>? _additionTimeLeaderboard;
  List<LeaderboardEntry>? _subtractionTimeLeaderboard;
  List<LeaderboardEntry>? _multiplicationTimeLeaderboard;
  List<LeaderboardEntry>? _divisionTimeLeaderboard;

// Add only these state variables
  DateTime? _streakLeaderboardLastUpdated;
  DateTime? _gamesLeaderboardLastUpdated;

  // Track currently loading time leaderboards to prevent race conditions
  final Map<String, bool> _loadingTimeLeaderboards = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Initialize all leaderboard lists as null to trigger loading state
    _streakLeaderboard = null;
    _gamesLeaderboard = null;
    _additionTimeLeaderboard = null;
    _subtractionTimeLeaderboard = null;
    _multiplicationTimeLeaderboard = null;
    _divisionTimeLeaderboard = null;

    // Start the leaderboard updater
    LeaderboardUpdater().startUpdates();

    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadTabData(_tabController.index);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First load the games leaderboard (now the default tab)
      await _loadGamesLeaderboard();

      // Get user's rank from the scalable leaderboard
      final userData = await _leaderboardService.getUserLeaderboardData(
          _currentUserId, ScalableLeaderboardService.GAMES_LEADERBOARD);

      final rank = userData['rank'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _currentUserRank = rank;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading initial leaderboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// Add this method to your LeaderboardScreen class
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Not yet updated';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
  }

  Future<void> _loadTabData(int tabIndex) async {
    // Time tab is now index 1
    if (tabIndex == 1) {
      // Always set loading state to true when entering time tab
      setState(() {
        _isLoading = true;
      });

      try {
        // Load all operation time leaderboards
        await Future.wait([
          _loadTimeLeaderboard('addition'),
          _loadTimeLeaderboard('subtraction'),
          _loadTimeLeaderboard('multiplication'),
          _loadTimeLeaderboard('division'),
        ]);
      } catch (e) {
        print('Error loading time leaderboards: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    // For other tabs, check if data is already loaded
    if (tabIndex == 0 &&
        _gamesLeaderboard != null &&
        _gamesLeaderboard!.isNotEmpty) return;
    if (tabIndex == 2 &&
        _streakLeaderboard != null &&
        _streakLeaderboard!.isNotEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      switch (tabIndex) {
        case 0:
          await _loadGamesLeaderboard();
          break;
        case 2:
          await _loadStreakLeaderboard();
          break;
      }
    } catch (e) {
      print('Error loading tab data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStreakLeaderboard() async {
    // Use the scalable service to get top entries
    final leaderboard = await _leaderboardService.getTopLeaderboardEntries(
        ScalableLeaderboardService.STREAK_LEADERBOARD,
        limit: 20);

    // Get last updated time
    final lastUpdated = await _leaderboardService.getLeaderboardLastUpdateTime(
        ScalableLeaderboardService.STREAK_LEADERBOARD);

    if (mounted) {
      setState(() {
        _streakLeaderboard = leaderboard;
        _streakLeaderboardLastUpdated = lastUpdated;
      });
    }
  }

  Future<void> _loadGamesLeaderboard() async {
    // Use the scalable service to get top entries
    final leaderboard = await _leaderboardService.getTopLeaderboardEntries(
        ScalableLeaderboardService.GAMES_LEADERBOARD,
        limit: 20);

    // Get last updated time
    final lastUpdated = await _leaderboardService.getLeaderboardLastUpdateTime(
        ScalableLeaderboardService.GAMES_LEADERBOARD);

    if (mounted) {
      setState(() {
        _gamesLeaderboard = leaderboard;
        _gamesLeaderboardLastUpdated = lastUpdated;
      });
    }
  }

// Modified to track loading state and prevent race conditions
  Future<void> _loadTimeLeaderboard(String operation,
      {String? difficulty}) async {
    // Create a unique key for this load operation
    final loadKey = difficulty != null && difficulty != 'All'
        ? '$operation-${difficulty.toLowerCase()}'
        : operation;

    // If already loading this exact combination, return the existing operation
    if (_loadingTimeLeaderboards[loadKey] == true) {
      print(
          'LEADERBOARD DEBUG: Already loading $loadKey, skipping duplicate request');
      // Wait for the existing operation to complete
      while (_loadingTimeLeaderboards[loadKey] == true) {
        await Future.delayed(Duration(milliseconds: 50));
      }
      return;
    }

    // Mark this combination as loading
    _loadingTimeLeaderboards[loadKey] = true;
    print('LEADERBOARD DEBUG: Started loading $loadKey');

    try {
      String leaderboardType = _getTimeLeaderboardType(operation);

      if (difficulty != null && difficulty != 'All') {
        // Load difficulty-specific leaderboard from scalable service
        final leaderboard =
            await _leaderboardService.getTopEntriesForDifficulty(
                leaderboardType, difficulty.toLowerCase(), 20);

        if (mounted) {
          setState(() {
            switch (operation) {
              case 'addition':
                _additionTimeLeaderboard = leaderboard;
                break;
              case 'subtraction':
                _subtractionTimeLeaderboard = leaderboard;
                break;
              case 'multiplication':
                _multiplicationTimeLeaderboard = leaderboard;
                break;
              case 'division':
                _divisionTimeLeaderboard = leaderboard;
                break;
            }
            // Use a single variable for all time leaderboard timestamps
          });
        }
      } else {
        // Load overall operation leaderboard from scalable service
        final leaderboard = await _leaderboardService
            .getTopLeaderboardEntries(leaderboardType, limit: 20);

        if (mounted) {
          setState(() {
            switch (operation) {
              case 'addition':
                _additionTimeLeaderboard = leaderboard;
                break;
              case 'subtraction':
                _subtractionTimeLeaderboard = leaderboard;
                break;
              case 'multiplication':
                _multiplicationTimeLeaderboard = leaderboard;
                break;
              case 'division':
                _divisionTimeLeaderboard = leaderboard;
                break;
            }
            // Use a single variable for all time leaderboard timestamps
          });
        }
      }
      print('LEADERBOARD DEBUG: Finished loading $loadKey');
    } catch (e) {
      print('Error loading time leaderboard for $loadKey: $e');
    } finally {
      // Mark this combination as no longer loading
      _loadingTimeLeaderboards[loadKey] = false;
    }
  }

  // Helper method to get the correct leaderboard type for time leaderboards
  String _getTimeLeaderboardType(String operation) {
    switch (operation) {
      case 'addition':
        return ScalableLeaderboardService.ADDITION_TIME;
      case 'subtraction':
        return ScalableLeaderboardService.SUBTRACTION_TIME;
      case 'multiplication':
        return ScalableLeaderboardService.MULTIPLICATION_TIME;
      case 'division':
        return ScalableLeaderboardService.DIVISION_TIME;
      default:
        return ScalableLeaderboardService.ADDITION_TIME;
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _loadTabData(_tabController.index);
  }

// Add this method to your LeaderboardScreen class
  Widget _buildUpdateInfo(String leaderboardType, DateTime? lastUpdated) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                'Last updated: ${_formatTimestamp(lastUpdated)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // Add different messages based on leaderboard type
          if (leaderboardType == ScalableLeaderboardService.STREAK_LEADERBOARD)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Streak updates occur once per day.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (leaderboardType ==
              ScalableLeaderboardService.GAMES_LEADERBOARD)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.blue.shade300),
                  SizedBox(width: 4),
                  Text(
                    'Updates every 15 minutes to optimize performance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),

            // Add this AnimatedBuilder to detect tab changes
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                // Only show update info for games and streaks tabs
                if (_tabController.index == 0) {
                  return _buildUpdateInfo(
                      ScalableLeaderboardService.GAMES_LEADERBOARD,
                      _gamesLeaderboardLastUpdated);
                } else if (_tabController.index == 2) {
                  return _buildUpdateInfo(
                      ScalableLeaderboardService.STREAK_LEADERBOARD,
                      _streakLeaderboardLastUpdated);
                }
                // No info for time tab
                return SizedBox.shrink();
              },
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  LeaderboardTab(
                    leaderboardEntries: _gamesLeaderboard,
                    currentUserId: _currentUserId,
                    valueSelector: (entry) => entry.totalGames,
                    valueLabel: 'games',
                    valueIcon: Icons.sports_esports,
                    valueColor: Colors.blue,
                    onRefresh: _refreshCurrentTab,
                    isLoading: _isLoading, // Pass global loading state
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: TimeLeaderboardTab(
                          additionLeaderboard: _additionTimeLeaderboard ?? [],
                          subtractionLeaderboard:
                              _subtractionTimeLeaderboard ?? [],
                          multiplicationLeaderboard:
                              _multiplicationTimeLeaderboard ?? [],
                          divisionLeaderboard: _divisionTimeLeaderboard ?? [],
                          currentUserId: _currentUserId,
                          onRefresh: _refreshCurrentTab,
                          onDifficultyChanged: (operation, difficulty) async {
                            // Now returns the Future from _loadTimeLeaderboard
                            await _loadTimeLeaderboard(operation,
                                difficulty: difficulty);
                          },
                        ),
                      ),
                    ],
                  ),
                  LeaderboardTab(
                    leaderboardEntries: _streakLeaderboard,
                    currentUserId: _currentUserId,
                    valueSelector: (entry) => entry.longestStreak,
                    valueLabel: 'days',
                    valueIcon: Icons.local_fire_department_rounded,
                    valueColor: Colors.deepOrange,
                    onRefresh: _refreshCurrentTab,
                    isLoading: _isLoading, // Pass global loading state
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                color: Colors.blue,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (_currentUserRank > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Rank: #$_currentUserRank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Text(
            'See how you compare with other players',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(
            icon: Icon(Icons.sports_esports),
            text: 'Games',
          ),
          Tab(
            icon: Icon(Icons.timer),
            text: 'Time',
          ),
          Tab(
            icon: Icon(Icons.local_fire_department_rounded),
            text: 'Streaks',
          ),
        ],
      ),
    );
  }
}
