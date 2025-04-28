// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_skills_game/services/leaderboard_updater.dart';
import 'package:math_skills_game/widgets/leaderboard_loading.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../widgets/leaderboard_tab.dart';
import '../widgets/time_leaderboard_tab.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late TabController _tabController;
  bool _isLoading = true;
  int _currentUserRank = 0;
  String _currentUserId = '';

  // Data for each leaderboard type
  List<LeaderboardEntry> _starLeaderboard = [];
  List<LeaderboardEntry> _streakLeaderboard = [];
  List<LeaderboardEntry> _gamesLeaderboard = [];
  // Time-based leaderboards
  List<LeaderboardEntry> _additionTimeLeaderboard = [];
  List<LeaderboardEntry> _subtractionTimeLeaderboard = [];
  List<LeaderboardEntry> _multiplicationTimeLeaderboard = [];
  List<LeaderboardEntry> _divisionTimeLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
      // First load the stars leaderboard (default tab)
      await _loadStarsLeaderboard();

      // Get user's rank
      final rank = await _leaderboardService.getCurrentUserRankByStars();

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
    if (tabIndex == 0 && _starLeaderboard.isNotEmpty) return;
    if (tabIndex == 1 && _streakLeaderboard.isNotEmpty) return;
    if (tabIndex == 2 && _gamesLeaderboard.isNotEmpty) return;
    if (tabIndex == 3 && (_additionTimeLeaderboard.isEmpty || 
                         _subtractionTimeLeaderboard.isEmpty ||
                         _multiplicationTimeLeaderboard.isEmpty ||
                         _divisionTimeLeaderboard.isEmpty)) {
      // For tab 3 (Time), load all operation time leaderboards
      setState(() {
        _isLoading = true;
      });
      try {
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

    setState(() {
      _isLoading = true;
    });

    try {
      switch (tabIndex) {
        case 0:
          await _loadStarsLeaderboard();
          break;
        case 1:
          await _loadStreakLeaderboard();
          break;
        case 2:
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

  Future<void> _loadStarsLeaderboard() async {
    final leaderboard = await _leaderboardService.getTopUsersByStars();
    if (mounted) {
      setState(() {
        _starLeaderboard = leaderboard;
      });
    }
  }

  Future<void> _loadStreakLeaderboard() async {
    final leaderboard = await _leaderboardService.getTopUsersByStreak();
    if (mounted) {
      setState(() {
        _streakLeaderboard = leaderboard;
      });
    }
  }

  Future<void> _loadGamesLeaderboard() async {
    final leaderboard = await _leaderboardService.getTopUsersByGamesPlayed();
    if (mounted) {
      setState(() {
        _gamesLeaderboard = leaderboard;
      });
    }
  }

  Future<void> _loadTimeLeaderboard(String operation) async {
    final leaderboard = await _leaderboardService.getTopUsersByBestTime(operation);
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
              child: _isLoading
                  ? Center(child: LeaderboardLoading())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        LeaderboardTab(
                          leaderboardEntries: _starLeaderboard,
                          currentUserId: _currentUserId,
                          valueSelector: (entry) => entry.totalStars,
                          valueLabel: 'stars',
                          valueIcon: Icons.star,
                          valueColor: Colors.amber,
                          onRefresh: _refreshCurrentTab,
                        ),
                        LeaderboardTab(
                          leaderboardEntries: _streakLeaderboard,
                          currentUserId: _currentUserId,
                          valueSelector: (entry) => entry.longestStreak,
                          valueLabel: 'days',
                          valueIcon: Icons.local_fire_department_rounded,
                          valueColor: Colors.deepOrange,
                          onRefresh: _refreshCurrentTab,
                        ),
                        LeaderboardTab(
                          leaderboardEntries: _gamesLeaderboard,
                          currentUserId: _currentUserId,
                          valueSelector: (entry) => entry.totalGames,
                          valueLabel: 'games',
                          valueIcon: Icons.sports_esports,
                          valueColor: Colors.blue,
                          onRefresh: _refreshCurrentTab,
                        ),
                        TimeLeaderboardTab(
                          additionLeaderboard: _additionTimeLeaderboard,
                          subtractionLeaderboard: _subtractionTimeLeaderboard,
                          multiplicationLeaderboard: _multiplicationTimeLeaderboard,
                          divisionLeaderboard: _divisionTimeLeaderboard,
                          currentUserId: _currentUserId,
                          onRefresh: _refreshCurrentTab,
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
            icon: Icon(Icons.star),
            text: 'Stars',
          ),
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