// lib/widgets/time_leaderboard_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../models/level_completion_model.dart';

class TimeLeaderboardDetail extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final String operation;

  const TimeLeaderboardDetail({
    Key? key,
    required this.entry,
    required this.rank,
    required this.operation,
  }) : super(key: key);

  static void show(BuildContext context, LeaderboardEntry entry, int rank,
      String operation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RefreshableTimeLeaderboardDetail(
        entry: entry,
        rank: rank,
        operation: operation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get best time for the operation
    final bestTime = entry.bestTimes[operation] ?? 0;

    // Format the time to display
    final formattedTime =
        bestTime > 0 ? StarRatingCalculator.formatTime(bestTime) : 'No record';

    // Get operation details
    final String operationTitle = _getOperationTitle(operation);
    final Color operationColor = _getOperationColor(operation);
    final IconData operationIcon = _getOperationIcon(operation);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Player info header
          Row(
            children: [
              _buildRankCircle(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level: ${entry.level}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getLevelColor(entry.level),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Operation Time Record
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: operationColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: operationColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      operationIcon,
                      size: 28,
                      color: operationColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      operationTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: operationColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 36,
                      color: operationColor,
                    ),
                    SizedBox(width: 12),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: operationColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Best Completion Time',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Additional Stats
          Text(
            'Player Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Stars', entry.totalStars.toString(),
                  Icons.star, Colors.amber),
              _buildStatCard(
                  'Games Played',
                  (entry.operationCounts[operation] ?? 0).toString(),
                  operationIcon,
                  operationColor),
              _buildStatCard('All Games', entry.totalGames.toString(),
                  Icons.sports_esports, Colors.blue),
              _buildStatCard(
                  'Stars Earned',
                  (entry.operationStars[operation] ?? 0).toString(),
                  Icons.star_border_outlined,
                  Colors.deepOrange),
            ],
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRankCircle() {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (rank) {
      case 1:
        backgroundColor = Colors.amber;
        break;
      case 2:
        backgroundColor = Colors.grey.shade400;
        break;
      case 3:
        backgroundColor = Colors.brown.shade300;
        break;
      default:
        backgroundColor = Colors.blue;
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Master':
        return Colors.purple;
      case 'Expert':
        return Colors.orange;
      case 'Apprentice':
        return Colors.blue;
      case 'Novice':
      default:
        return Colors.green;
    }
  }

  String _getOperationTitle(String operation) {
    switch (operation) {
      case 'addition':
        return 'Addition';
      case 'subtraction':
        return 'Subtraction';
      case 'multiplication':
        return 'Multiplication';
      case 'division':
        return 'Division';
      default:
        return 'Unknown';
    }
  }

  Color _getOperationColor(String operation) {
    switch (operation) {
      case 'addition':
        return Colors.green;
      case 'subtraction':
        return Colors.purple;
      case 'multiplication':
        return Colors.blue;
      case 'division':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getOperationIcon(String operation) {
    switch (operation) {
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
}

class RefreshableTimeLeaderboardDetail extends StatefulWidget {
  final LeaderboardEntry entry;
  final int rank;
  final String operation;

  const RefreshableTimeLeaderboardDetail({
    Key? key,
    required this.entry,
    required this.rank,
    required this.operation,
  }) : super(key: key);

  @override
  _RefreshableTimeLeaderboardDetailState createState() =>
      _RefreshableTimeLeaderboardDetailState();
}

class _RefreshableTimeLeaderboardDetailState
    extends State<RefreshableTimeLeaderboardDetail> {
  late LeaderboardEntry _entry;
  late int _rank;
  late String _operation;
  bool _isLoading = true; // Start with loading true

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _rank = widget.rank;
    _operation = widget.operation;

    // Load data immediately
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      // Fetch updated user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_entry.userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _entry = LeaderboardEntry.fromDocument(userDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error refreshing time leaderboard detail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get operation color for the loading spinner
    Color operationColor = _getOperationColor(_operation);

    // Show loading spinner in center of bottom sheet if loading
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator at top
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(operationColor),
              ),
              SizedBox(height: 20),
              Text(
                'Loading ${_operation.capitalize()} stats...',
                style: TextStyle(color: operationColor),
              ),
            ],
          ),
        ),
      );
    }

    // Show content only when data is loaded
    return TimeLeaderboardDetail(
      entry: _entry,
      rank: _rank,
      operation: _operation,
    );
  }

  Color _getOperationColor(String operation) {
    switch (operation) {
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
}

// Add this extension for capitalizing the operation name
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
