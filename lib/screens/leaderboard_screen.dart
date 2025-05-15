// lib/screens/leaderboard_screen.dart
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
      // First load the streaks leaderboard (now the default tab)
      await _loadStreakLeaderboard();

      // Get user's rank from the scalable leaderboard
      final userData = await _leaderboardService.getUserLeaderboardData(
          _currentUserId, ScalableLeaderboardService.STREAK_LEADERBOARD);

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

  Future<void> _loadTabData(int tabIndex) async {
    // Time tab is index 2
    if (tabIndex == 2) {
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
        _streakLeaderboard != null &&
        _streakLeaderboard!.isNotEmpty) return;
    if (tabIndex == 1 &&
        _gamesLeaderboard != null &&
        _gamesLeaderboard!.isNotEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      switch (tabIndex) {
        case 0:
          await _loadStreakLeaderboard();
          break;
        case 1:
          await _loadGamesLeaderboard();
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

    if (mounted) {
      setState(() {
        _streakLeaderboard = leaderboard;
      });
    }
  }

  Future<void> _loadGamesLeaderboard() async {
    // Use the scalable service to get top entries
    final leaderboard = await _leaderboardService.getTopLeaderboardEntries(
        ScalableLeaderboardService.GAMES_LEADERBOARD,
        limit: 20);

    if (mounted) {
      setState(() {
        _gamesLeaderboard = leaderboard;
      });
    }
  }

  Future<void> _loadTimeLeaderboard(String operation,
      {String? difficulty}) async {
    String leaderboardType = _getTimeLeaderboardType(operation);

    if (difficulty != null && difficulty != 'All') {
      // Load difficulty-specific leaderboard from scalable service
      final leaderboard = await _leaderboardService.getTopEntriesForDifficulty(
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
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                  TimeLeaderboardTab(
                    additionLeaderboard: _additionTimeLeaderboard ?? [],
                    subtractionLeaderboard: _subtractionTimeLeaderboard ?? [],
                    multiplicationLeaderboard:
                        _multiplicationTimeLeaderboard ?? [],
                    divisionLeaderboard: _divisionTimeLeaderboard ?? [],
                    currentUserId: _currentUserId,
                    onRefresh: _refreshCurrentTab,
                    onDifficultyChanged: (operation, difficulty) {
                      _loadTimeLeaderboard(operation, difficulty: difficulty);
                    },
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
            icon: Icon(Icons.local_fire_department_rounded),
            text: 'Streaks',
          ),
          Tab(
            icon: Icon(Icons.sports_esports),
            text: 'Games',
          ),
          Tab(
            icon: Icon(Icons.timer),
            text: 'Time',
          ),
        ],
      ),
    );
  }
}
