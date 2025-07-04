// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leaderboard_service.dart';
import '../services/haptic_service.dart';
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
  // Use the leaderboard service
  final LeaderboardService _leaderboardService = LeaderboardService();
  late TabController _tabController;
  bool _isLoading = true;
  String _currentUserId = '';

  // Leaderboard data
  List<LeaderboardEntry>? _gamesLeaderboard;
  Map<String, List<LeaderboardEntry>> _timeLeaderboards = {
    'addition': [],
    'subtraction': [],
    'multiplication': [],
    'division': [],
  };

  // Track last updated time
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // 2 tabs: Games and Time
    _tabController.addListener(_handleTabChange);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Load initial data
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      HapticService().lightImpact();
      _loadTabData(_tabController.index);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load games leaderboard (default tab)
      await _loadGamesLeaderboard();

      // Get user's rank

      if (mounted) {
        setState(() {
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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('DEBUG: Loading data for tab index $tabIndex');
      switch (tabIndex) {
        case 0: // Games tab
          await _loadGamesLeaderboard();
          // Explicitly fetch and log the timestamp
          final timestamp =
              await _leaderboardService.getLeaderboardLastUpdateTime(
                  LeaderboardService.GAMES_LEADERBOARD);
          print('DEBUG: Retrieved timestamp for Games tab: $timestamp');

          if (mounted && timestamp != null) {
            setState(() {
              _lastUpdated = timestamp;
              print('DEBUG: Updated _lastUpdated state to: $_lastUpdated');
            });
          }
          break;
        case 1: // Time tab
          await _loadAllTimeLeaderboards();
          break;
      }
    } catch (e) {
      print('Error loading tab data for index $tabIndex: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGamesLeaderboard() async {
    final entries = await _leaderboardService.getTopLeaderboardEntries(
        LeaderboardService.GAMES_LEADERBOARD,
        limit: 20);

    final lastUpdated = await _leaderboardService
        .getLeaderboardLastUpdateTime(LeaderboardService.GAMES_LEADERBOARD);

    if (mounted) {
      setState(() {
        _gamesLeaderboard = entries;
        _lastUpdated = lastUpdated;
      });
    }
  }

  Future<void> _loadAllTimeLeaderboards() async {
    try {
      // Load all time leaderboards in parallel
      final futures = <Future>[];

      for (final operation in [
        'addition',
        'subtraction',
        'multiplication',
        'division'
      ]) {
        futures.add(_loadTimeLeaderboard(operation));
      }

      await Future.wait(futures);
    } catch (e) {
      print('Error loading time leaderboards: $e');
    }
  }

  Future<void> _loadTimeLeaderboard(String operation,
      {String? difficulty}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final leaderboardType = _getTimeLeaderboardType(operation);

      List<LeaderboardEntry> entries;
      if (difficulty != null && difficulty != 'All') {
        entries = await _leaderboardService.getTopEntriesForDifficulty(
            leaderboardType, difficulty.toLowerCase(), 20);
      } else {
        entries = await _leaderboardService
            .getTopLeaderboardEntries(leaderboardType, limit: 20);
      }

      if (mounted) {
        setState(() {
          _timeLeaderboards[operation] = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tab data for operation $operation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeLeaderboardType(String operation) {
    switch (operation) {
      case 'addition':
        return LeaderboardService.ADDITION_TIME;
      case 'subtraction':
        return LeaderboardService.SUBTRACTION_TIME;
      case 'multiplication':
        return LeaderboardService.MULTIPLICATION_TIME;
      case 'division':
        return LeaderboardService.DIVISION_TIME;
      default:
        return LeaderboardService.ADDITION_TIME;
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
                  // Games Tab
                  LeaderboardTab(
                    leaderboardEntries: _gamesLeaderboard,
                    currentUserId: _currentUserId,
                    valueSelector: (entry) => entry.totalGames,
                    valueLabel: 'games',
                    valueIcon: Icons.sports_esports,
                    valueColor: Colors.blue,
                    onRefresh: _refreshCurrentTab,
                    isLoading: _isLoading,
                  ),

                  // Time Tab
                  TimeLeaderboardTab(
                    additionLeaderboard: _timeLeaderboards['addition'] ?? [],
                    subtractionLeaderboard:
                        _timeLeaderboards['subtraction'] ?? [],
                    multiplicationLeaderboard:
                        _timeLeaderboards['multiplication'] ?? [],
                    divisionLeaderboard: _timeLeaderboards['division'] ?? [],
                    currentUserId: _currentUserId,
                    onRefresh: _refreshCurrentTab,
                    onDifficultyChanged: (operation, difficulty) async {
                      await _loadTimeLeaderboard(operation,
                          difficulty: difficulty);
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
        ],
      ),
    );
  }
}
