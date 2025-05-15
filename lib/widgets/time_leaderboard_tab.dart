// lib/widgets/time_leaderboard_tab.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../models/level_completion_model.dart';
import 'time_leaderboard_detail.dart';

class TimeLeaderboardTab extends StatefulWidget {
  final List<LeaderboardEntry> additionLeaderboard;
  final List<LeaderboardEntry> subtractionLeaderboard;
  final List<LeaderboardEntry> multiplicationLeaderboard;
  final List<LeaderboardEntry> divisionLeaderboard;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final void Function(String operation, String difficulty) onDifficultyChanged;

  const TimeLeaderboardTab({
    Key? key,
    required this.additionLeaderboard,
    required this.subtractionLeaderboard,
    required this.multiplicationLeaderboard,
    required this.divisionLeaderboard,
    required this.currentUserId,
    required this.onRefresh,
    required this.onDifficultyChanged,
  }) : super(key: key);

  @override
  _TimeLeaderboardTabState createState() => _TimeLeaderboardTabState();
}

class _TimeLeaderboardTabState extends State<TimeLeaderboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _operationTabController;
  int _currentTabIndex = 0;
  String _currentDifficulty = 'All'; // Default to showing all difficulties
  bool _isLoading = true; // Add loading state

  // List of difficulty options
  final List<String> _difficulties = [
    'All',
    'Standard',
    'Challenging',
    'Expert',
    'Impossible'
  ];

  @override
  void initState() {
    super.initState();
    _operationTabController = TabController(length: 4, vsync: this);
    _operationTabController.addListener(() {
      if (!_operationTabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _operationTabController.index;
          _isLoading = true; // Set loading to true when changing tabs
        });

        // Call onDifficultyChanged when changing tabs
        String currentOperation = _getCurrentOperation();
        widget.onDifficultyChanged(currentOperation, _currentDifficulty);

        // Use a shorter delay for smoother experience
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });

    // Trigger an initial data load for the default tab (Addition)
    Future.delayed(Duration.zero, () {
      String currentOperation = _getCurrentOperation();
      widget.onDifficultyChanged(currentOperation, _currentDifficulty);
    });

    // Shorter initial loading time
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _operationTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOperationTabBar(),
        _buildDifficultySelector(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoading = true;
              });
              await widget.onRefresh();
              setState(() {
                _isLoading = false;
              });
            },
            child: _buildCurrentOperationTab(),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _operationTabController,
        isScrollable: true,
        indicatorColor: _getOperationColor(_currentTabIndex),
        labelColor: _getOperationColor(_currentTabIndex),
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(
            icon: Icon(Icons.add_circle),
            text: 'Addition',
          ),
          Tab(
            icon: Icon(Icons.remove_circle),
            text: 'Subtraction',
          ),
          Tab(
            icon: Icon(Icons.close),
            text: 'Multiplication',
          ),
          Tab(
            icon: Icon(Icons.pie_chart),
            text: 'Division',
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      height: 50,
      color: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _difficulties.length,
        itemBuilder: (context, index) {
          final difficulty = _difficulties[index];
          final isSelected = difficulty == _currentDifficulty;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentDifficulty = difficulty;
                _isLoading = true; // Set loading state when changing difficulty
              });

              // Call the callback with current operation and new difficulty
              String currentOperation = _getCurrentOperation();
              widget.onDifficultyChanged(currentOperation, difficulty);

              // Use Future.delayed with a longer delay to ensure data is fully loaded
              Future.delayed(Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getOperationColor(_currentTabIndex).withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _getOperationColor(_currentTabIndex)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? _getOperationColor(_currentTabIndex)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCurrentOperation() {
    switch (_currentTabIndex) {
      case 0:
        return 'addition';
      case 1:
        return 'subtraction';
      case 2:
        return 'multiplication';
      case 3:
        return 'division';
      default:
        return 'addition';
    }
  }

  Widget _buildCurrentOperationTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildTimeLeaderboard(widget.additionLeaderboard, 'addition',
            Colors.green, Icons.add_circle);
      case 1:
        return _buildTimeLeaderboard(widget.subtractionLeaderboard,
            'subtraction', Colors.purple, Icons.remove_circle);
      case 2:
        return _buildTimeLeaderboard(widget.multiplicationLeaderboard,
            'multiplication', Colors.blue, Icons.close);
      case 3:
        return _buildTimeLeaderboard(widget.divisionLeaderboard, 'division',
            Colors.orange, Icons.pie_chart);
      default:
        return Center(child: Text('No data available'));
    }
  }

  Widget _buildTimeLeaderboard(List<LeaderboardEntry> entries, String operation,
      Color operationColor, IconData operationIcon) {
    // Always show loading indicator while data is being processed
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(operationColor),
        ),
      );
    }

    // For 'All' difficulty, we already have the correct entries from the parent component
    // that were fetched from the main operation leaderboard
    List<LeaderboardEntry> filteredEntries = [];

    // Only filter and process entries when we're not loading
    // Make sure we have entries with valid times
    if (_currentDifficulty == 'All') {
      // For 'All' difficulty, ensure entries have the operation key
      filteredEntries = entries.where((entry) {
        return entry.bestTimes.containsKey(operation) &&
            entry.bestTimes[operation]! > 0;
      }).toList();

      // Debug output
      print('Operation: $operation, Entries count: ${filteredEntries.length}');

      // Log the first few entries for debugging
      if (filteredEntries.isNotEmpty) {
        for (int i = 0; i < min(3, filteredEntries.length); i++) {
          print(
              'Entry $i bestTime: ${filteredEntries[i].bestTimes[operation]}');
        }
      }

      // Sort by the operation time
      if (filteredEntries.isNotEmpty) {
        filteredEntries.sort((a, b) {
          final timeA = a.bestTimes[operation]!;
          final timeB = b.bestTimes[operation]!;
          return timeA.compareTo(timeB);
        });
      }
    } else {
      // Specific difficulty code - this part should work fine
      final difficultyKey = '$operation-${_currentDifficulty.toLowerCase()}';

      filteredEntries = entries.where((entry) {
        return entry.bestTimes.containsKey(difficultyKey) &&
            entry.bestTimes[difficultyKey]! > 0;
      }).toList();

      if (filteredEntries.isNotEmpty) {
        filteredEntries.sort((a, b) {
          final timeA = a.bestTimes[difficultyKey]!;
          final timeB = b.bestTimes[difficultyKey]!;
          return timeA.compareTo(timeB);
        });
      }
    }

    // Only show the empty state when we're not loading and have no entries
    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _currentDifficulty == 'All'
                  ? 'No time records available yet'
                  : 'No time records for $_currentDifficulty difficulty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16),
      itemCount: filteredEntries.length + 1, // +1 for the top 3 section
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTopThreeSection(
              filteredEntries, operation, operationColor, operationIcon);
        }

        final actualIndex = index - 1;
        final entry = filteredEntries[actualIndex];
        final rank = actualIndex + 1;

        return _buildLeaderboardItem(
            entry, rank, operation, operationColor, operationIcon);
      },
    );
  }

  Widget _buildTopThreeSection(List<LeaderboardEntry> entries, String operation,
      Color operationColor, IconData operationIcon) {
    if (entries.length < 3) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 180,
      child: Row(
        children: [
          // Second place
          if (entries.length > 1)
            Expanded(
              child: _buildTopPlaceItem(entries[1], 2, Colors.grey.shade300,
                  110, operation, operationColor, operationIcon),
            ),

          // First place (tallest)
          Expanded(
            flex: 3,
            child: _buildTopPlaceItem(entries[0], 1, Colors.amber.shade300, 140,
                operation, operationColor, operationIcon),
          ),

          // Third place
          if (entries.length > 2)
            Expanded(
              child: _buildTopPlaceItem(entries[2], 3, Colors.brown.shade300,
                  100, operation, operationColor, operationIcon),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPlaceItem(
      LeaderboardEntry entry,
      int place,
      Color color,
      double height,
      String operation,
      Color operationColor,
      IconData operationIcon) {
    // Get the best time for this operation and difficulty
    int bestTime = _getBestTime(entry, operation);

    return GestureDetector(
      onTap: () {
        TimeLeaderboardDetail.show(context, entry, place, operation);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: color,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Name and Score
          Text(
            entry.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: 14,
                color: operationColor,
              ),
              SizedBox(width: 2),
              Text(
                StarRatingCalculator.formatTime(bestTime),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: operationColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Podium
          Container(
            width: double.infinity,
            height: height,
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$place',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank,
      String operation, Color operationColor, IconData operationIcon) {
    final isCurrentUser = entry.userId == widget.currentUserId;
    final bestTime = _getBestTime(entry, operation);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser ? Colors.blue.shade200 : Colors.grey.shade200,
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildRank(rank, isCurrentUser),
        title: Text(
          entry.displayName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Level: ${entry.level}' +
              (_currentDifficulty != 'All' ? ' • $_currentDifficulty' : ''),
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: operationColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: operationColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: operationColor,
              ),
              SizedBox(width: 4),
              Text(
                StarRatingCalculator.formatTime(bestTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: operationColor,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          TimeLeaderboardDetail.show(
            context,
            entry,
            rank,
            operation,
          );
        },
      ),
    );
  }

  Widget _buildRank(int rank, bool isCurrentUser) {
    Color backgroundColor;
    Color textColor;

    switch (rank) {
      case 1:
        backgroundColor = Colors.amber;
        textColor = Colors.white;
        break;
      case 2:
        backgroundColor = Colors.grey.shade400;
        textColor = Colors.white;
        break;
      case 3:
        backgroundColor = Colors.brown.shade300;
        textColor = Colors.white;
        break;
      default:
        backgroundColor =
            isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade100;
        textColor = isCurrentUser ? Colors.blue : Colors.grey.shade700;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Color _getOperationColor(int index) {
    switch (index) {
      case 0:
        return Colors.green; // Addition
      case 1:
        return Colors.purple; // Subtraction
      case 2:
        return Colors.blue; // Multiplication
      case 3:
        return Colors.orange; // Division
      default:
        return Colors.blue;
    }
  }

  int _getBestTime(LeaderboardEntry entry, String operation) {
    // If a specific difficulty is selected, get that difficulty's time
    if (_currentDifficulty != 'All') {
      final difficultyKey = '$operation-${_currentDifficulty.toLowerCase()}';

      // Only return the specific difficulty time
      // Don't fall back to the general operation time
      if (entry.bestTimes.containsKey(difficultyKey) &&
          entry.bestTimes[difficultyKey]! > 0) {
        return entry.bestTimes[difficultyKey]!;
      }

      // If no specific difficulty time, return a very high value
      return 999999;
    }

    // If showing 'All' difficulties, return the overall best time for the operation
    return entry.bestTimes[operation] ?? 999999;
  }
}
