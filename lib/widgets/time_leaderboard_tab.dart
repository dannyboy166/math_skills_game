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
  final Future<void> Function(String operation, String difficulty) onDifficultyChanged;

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
  String _currentDifficulty = 'All';
  bool _isLoading = true;
  
  // Track current and pending operations/difficulties
  String _currentOperation = 'addition';
  String _pendingOperation = '';
  String _pendingDifficulty = '';
  
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
        _currentTabIndex = _operationTabController.index;
        _currentOperation = _getCurrentOperation();
        
        // Set pending changes and trigger data loading
        _loadData(_currentOperation, _currentDifficulty);
      }
    });

    // Initial data load
    _loadData('addition', 'All');
  }

  // Method to handle data loading and state changes
  void _loadData(String operation, String difficulty) {
    setState(() {
      _isLoading = true;
      _pendingOperation = operation;
      _pendingDifficulty = difficulty;
    });

    // Call the parent's callback to load the data
    widget.onDifficultyChanged(operation, difficulty).then((_) {
      // Only update if this is still the pending request (prevent race conditions)
      if (mounted && _pendingOperation == operation && _pendingDifficulty == difficulty) {
        setState(() {
          _currentOperation = operation;
          _currentDifficulty = difficulty;
          _isLoading = false;
          _pendingOperation = '';
          _pendingDifficulty = '';
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
              
              // After refresh, reload current selection
              await widget.onDifficultyChanged(_currentOperation, _currentDifficulty);
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
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
              if (difficulty != _currentDifficulty && !_isLoading) {
                _loadData(_currentOperation, difficulty);
              }
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
    print(
        'LEADERBOARD DEBUG: build leaderboard for $operation | difficulty: $_currentDifficulty | loading: $_isLoading | entries.length: ${entries.length}');

    if (_isLoading) {
      print('LEADERBOARD DEBUG: Still loading...');
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(operationColor),
        ),
      );
    }

    // Only filter when not loading
    List<LeaderboardEntry> filteredEntries = _getFilteredEntries(entries, operation);

    if (filteredEntries.isEmpty) {
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

    return _buildLeaderboardList(filteredEntries, operation, operationColor, operationIcon);
  }

  // Method to handle filtering of entries
  List<LeaderboardEntry> _getFilteredEntries(List<LeaderboardEntry> entries, String operation) {
    List<LeaderboardEntry> filteredEntries = [];

    if (_currentDifficulty == 'All') {
      print('LEADERBOARD DEBUG: Filtering for general operation: $operation');

      filteredEntries = entries.where((entry) {
        final hasValidTime = entry.bestTimes.containsKey(operation) &&
            entry.bestTimes[operation]! > 0;
        if (!hasValidTime) {
          print(
              'SKIP ENTRY: ${entry.displayName} has no valid time for $operation');
        }
        return hasValidTime;
      }).toList();

      if (filteredEntries.isNotEmpty) {
        print(
            'LEADERBOARD DEBUG: First valid entry: ${filteredEntries.first.displayName}, time: ${filteredEntries.first.bestTimes[operation]}');
      }

      filteredEntries.sort((a, b) {
        final timeA = a.bestTimes[operation]!;
        final timeB = b.bestTimes[operation]!;
        return timeA.compareTo(timeB);
      });
    } else {
      final difficultyKey = '$operation-${_currentDifficulty.toLowerCase()}';
      print('LEADERBOARD DEBUG: Filtering for difficulty: $difficultyKey');

      filteredEntries = entries.where((entry) {
        final hasValidTime = entry.bestTimes.containsKey(difficultyKey) &&
            entry.bestTimes[difficultyKey]! > 0;
        if (!hasValidTime) {
          print(
              'SKIP ENTRY: ${entry.displayName} has no valid time for $difficultyKey');
        }
        return hasValidTime;
      }).toList();

      if (filteredEntries.isNotEmpty) {
        print(
            'LEADERBOARD DEBUG: First valid entry: ${filteredEntries.first.displayName}, time: ${filteredEntries.first.bestTimes[difficultyKey]}');
      }

      filteredEntries.sort((a, b) {
        final timeA = a.bestTimes[difficultyKey]!;
        final timeB = b.bestTimes[difficultyKey]!;
        return timeA.compareTo(timeB);
      });
    }
    
    return filteredEntries;
  }

  // Method to build the leaderboard list
  Widget _buildLeaderboardList(List<LeaderboardEntry> entries, String operation, 
      Color operationColor, IconData operationIcon) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 16),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTopThreeSection(
              entries, operation, operationColor, operationIcon);
        }

        final actualIndex = index - 1;
        final entry = entries[actualIndex];
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

    // Ensure our top section has a fixed height with proper constraints
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 225, // Increased height to accommodate all elements
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
        children: [
          // Second place
          if (entries.length > 1)
            Expanded(
              child: _buildTopPlaceItem(entries[1], 2, Colors.grey.shade300,
                  90, operation, operationColor, operationIcon),
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
                  60, operation, operationColor, operationIcon),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPlaceItem(
      LeaderboardEntry entry,
      int place,
      Color color,
      double podiumHeight,
      String operation,
      Color operationColor,
      IconData operationIcon) {
    // Get the best time for this operation and difficulty
    int bestTime = _getBestTime(entry, operation);

    // Calculate total height needed and ensure it fits within constraints
    return GestureDetector(
      onTap: () {
        TimeLeaderboardDetail.show(context, entry, place, operation);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The LayoutBuilder helps us understand how much space we have
          double availableHeight = constraints.maxHeight;
          
          // Make sure podium doesn't exceed available space
          double adjustedPodiumHeight = podiumHeight;
          
          // Calculate needed height for other elements
          double topElementsHeight = 112; // Avatar, name, score, spacing
          
          // Adjust podium height if needed to fit everything
          if (topElementsHeight + podiumHeight > availableHeight) {
            adjustedPodiumHeight = availableHeight - topElementsHeight;
            // Ensure minimum height
            adjustedPodiumHeight = adjustedPodiumHeight.clamp(50.0, podiumHeight);
          }
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
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

              // Name and Score - keep these components compact
              Container(
                height: 40, // Fixed height for name and score
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Podium with adjusted height
              Container(
                width: double.infinity,
                height: adjustedPodiumHeight,
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
          );
        }
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
    final key = _currentDifficulty == 'All'
        ? operation
        : '$operation-${_currentDifficulty.toLowerCase()}';

    final time = entry.bestTimes[key];
    print(
        'DEBUG: ${entry.displayName} best time for "$key": ${time ?? 'none'}');

    return time ?? 999999;
  }
}