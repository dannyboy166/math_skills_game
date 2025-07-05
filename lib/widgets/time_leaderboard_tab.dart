// lib/widgets/time_leaderboard_tab.dart
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
  final Future<void> Function(String operation, String difficulty)
      onDifficultyChanged;

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
  String _currentOperation = 'addition';
  String _currentDifficulty = 'All';
  bool _isLoading = false;

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
    _operationTabController.addListener(_handleOperationTabChanged);
  }

  @override
  void dispose() {
    _operationTabController.dispose();
    super.dispose();
  }

  void _handleOperationTabChanged() {
    if (!_operationTabController.indexIsChanging) {
      final newOperation =
          _getOperationFromIndex(_operationTabController.index);
      if (newOperation != _currentOperation) {
        // First set loading state to true BEFORE changing the operation
        setState(() {
          _isLoading = true;
          _currentOperation = newOperation;
        });

        // Then load the data for the new operation
        if (_currentDifficulty != 'All') {
          widget
              .onDifficultyChanged(_currentOperation, _currentDifficulty)
              .then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        } else {
          // Handle 'All' difficulty case
          widget.onRefresh().then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }
      }
    }
  }

  String _getOperationFromIndex(int index) {
    switch (index) {
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

  List<LeaderboardEntry> _getCurrentLeaderboard() {
    switch (_currentOperation) {
      case 'addition':
        return widget.additionLeaderboard;
      case 'subtraction':
        return widget.subtractionLeaderboard;
      case 'multiplication':
        return widget.multiplicationLeaderboard;
      case 'division':
        return widget.divisionLeaderboard;
      default:
        return [];
    }
  }

  List<LeaderboardEntry> _getFilteredEntries() {
    final entries = _getCurrentLeaderboard();
    if (entries.isEmpty) return [];

    final timeKey = _currentDifficulty == 'All'
        ? _currentOperation
        : '$_currentOperation-${_currentDifficulty.toLowerCase()}';

    // Filter entries with valid time for this operation/difficulty
    final filtered = entries.where((entry) {
      return entry.bestTimes.containsKey(timeKey) &&
          entry.bestTimes[timeKey]! > 0;
    }).toList();

    // Sort by time (lower is better)
    filtered.sort((a, b) {
      final timeA = a.bestTimes[timeKey] ?? 999999;
      final timeB = b.bestTimes[timeKey] ?? 999999;
      return timeA.compareTo(timeB);
    });

    return filtered;
  }

  Color _getOperationColor() {
    switch (_currentOperation) {
      case 'addition':
        return Colors.green;
      case 'subtraction':
        return Colors.purple;
      case 'multiplication':
        return Colors.blue;
      case 'division':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getOperationIcon() {
    switch (_currentOperation) {
      case 'addition':
        return Icons.add_circle;
      case 'subtraction':
        return Icons.remove_circle;
      case 'multiplication':
        return Icons.close;
      case 'division':
        return Icons.pie_chart;
      default:
        return Icons.calculate;
    }
  }

  int _getBestTime(LeaderboardEntry entry) {
    final timeKey = _currentDifficulty == 'All'
        ? _currentOperation
        : '$_currentOperation-${_currentDifficulty.toLowerCase()}';
    return entry.bestTimes[timeKey] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOperationTabs(),
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getOperationColor()),
                    ),
                  )
                : _buildLeaderboardContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _operationTabController,
        indicatorColor: _getOperationColor(),
        labelColor: _getOperationColor(),
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
      height: 60,
      color: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _difficulties.length,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final difficulty = _difficulties[index];
          final isSelected = difficulty == _currentDifficulty;

          return GestureDetector(
            onTap: () {
              if (difficulty != _currentDifficulty && !_isLoading) {
                setState(() {
                  _currentDifficulty = difficulty;
                  _isLoading = true;
                });

                widget
                    .onDifficultyChanged(_currentOperation, difficulty)
                    .then((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getOperationColor().withValues(alpha: 0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? _getOperationColor() : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? _getOperationColor() : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    final entries = _getFilteredEntries();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _currentDifficulty == 'All'
                  ? 'No time records available yet'
                  : 'No time records for $_currentDifficulty difficulty',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16),
      itemCount: entries.length + 1, // +1 for top three section
      itemBuilder: (context, index) {
        if (index == 0) {
          return entries.length >= 3
              ? _buildTopThreeSection(entries)
              : SizedBox.shrink();
        }

        final entry = entries[index - 1];
        final rank = index; // Rank starts at 1

        return _buildLeaderboardItem(entry, rank);
      },
    );
  }

  Widget _buildTopThreeSection(List<LeaderboardEntry> entries) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Remove fixed height or increase it to 240px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          Expanded(
            child: _buildTopPlaceItem(entries[1], 2, Colors.grey.shade300, 90),
          ),

          // First place (tallest)
          Expanded(
            flex: 3,
            child:
                _buildTopPlaceItem(entries[0], 1, Colors.amber.shade300, 140),
          ),

          // Third place
          Expanded(
            child: _buildTopPlaceItem(entries[2], 3, Colors.brown.shade300, 60),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlaceItem(
      LeaderboardEntry entry, int rank, Color color, double podiumHeight) {
    final bestTime = _getBestTime(entry);
    final operationColor = _getOperationColor();
    final operationIcon = _getOperationIcon(); // Now using the icon

    return GestureDetector(
      onTap: () {
        TimeLeaderboardDetail.show(context, entry, rank, _currentOperation);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName.substring(0, 1).toUpperCase()
                    : "?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Name and time
          Text(
            entry.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(operationIcon, size: 12, color: operationColor),
              SizedBox(width: 2),
              Text(
                StarRatingCalculator.formatTime(bestTime),
                style: TextStyle(
                  fontSize: 12,
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
            height: podiumHeight,
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 18,
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

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    final isCurrentUser = entry.userId == widget.currentUserId;
    final bestTime = _getBestTime(entry);
    final operationColor = _getOperationColor();
    final operationIcon = _getOperationIcon(); // Now using the icon

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildRankBadge(rank, isCurrentUser),
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
            color: operationColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: operationColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                operationIcon, // Now using the icon
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
            _currentOperation,
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isCurrentUser) {
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
}
