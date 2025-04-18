// lib/widgets/leaderboard_detail.dart
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import 'package:intl/intl.dart';

class LeaderboardDetailBottomSheet extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const LeaderboardDetailBottomSheet({
    Key? key,
    required this.entry,
    required this.rank,
  }) : super(key: key);

  static void show(BuildContext context, LeaderboardEntry entry, int rank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LeaderboardDetailBottomSheet(
        entry: entry,
        rank: rank,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total Stars', entry.totalStars.toString(),
                    Icons.star, Colors.amber),
                _buildStatCard('Games Played', entry.totalGames.toString(),
                    Icons.sports_esports, Colors.blue),
                _buildStatCard('Longest Streak', '${entry.longestStreak} days',
                    Icons.local_fire_department_rounded, Colors.deepOrange),
                _buildStatCard(
                    'Favorite',
                    entry.favoriteOperation,
                    _getOperationIcon(entry.favoriteOperation),
                    _getOperationColor(entry.favoriteOperation)),
              ],
            ),
            SizedBox(height: 24),

            // Operations breakdown
            Text(
              'Star Progress by Operation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Stars earned out of maximum possible stars',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 12),

            // For each operation, we'll show the progress toward maximum stars
            // Addition (60 max stars)
            LinearProgressIndicator(
              value: _getStarProgressValue('addition'),
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            _buildStarProgressLabel('Addition', 'addition', Colors.green, 60),
            SizedBox(height: 8),

            // Subtraction (60 max stars)
            LinearProgressIndicator(
              value: _getStarProgressValue('subtraction'),
              backgroundColor: Colors.grey.shade200,
              color: Colors.purple,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            _buildStarProgressLabel(
                'Subtraction', 'subtraction', Colors.purple, 60),
            SizedBox(height: 8),

            // Multiplication (45 max stars)
            LinearProgressIndicator(
              value: _getStarProgressValue('multiplication'),
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            _buildStarProgressLabel(
                'Multiplication', 'multiplication', Colors.blue, 45),
            SizedBox(height: 8),

            // Division (45 max stars)
            LinearProgressIndicator(
              value: _getStarProgressValue('division'),
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            _buildStarProgressLabel('Division', 'division', Colors.orange, 45),

            SizedBox(height: 24),

            Text(
              'Last updated: ${_formatDate(entry.lastUpdated)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),
          ],
        ),
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
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressLabel(
      String label, String operation, Color color, int maxStars) {
    // Use actual stars for this operation
    final operationStars = entry.operationStars[operation] ?? 0;
    final cappedStars = operationStars > maxStars ? maxStars : operationStars;

    final percentage = _getStarProgressValue(operation) * 100;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getOperationIcon(label),
                size: 14,
                color: color,
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber,
              ),
              SizedBox(width: 4),
              Text(
                '$cappedStars/$maxStars (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getStarProgressValue(String operation) {
    final operationStars = entry.operationStars[operation] ?? 0;

    int maxStars;
    switch (operation) {
      case 'addition':
      case 'subtraction':
        maxStars = 60;
        break;
      case 'multiplication':
      case 'division':
        maxStars = 45;
        break;
      default:
        maxStars = 60;
    }

    final progress = operationStars / maxStars;
    // Cap at 1.0 (100%)
    return progress > 1.0 ? 1.0 : progress;
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

  IconData _getOperationIcon(String operation) {
    final lowerOp = operation.toLowerCase();
    if (lowerOp.contains('add')) return Icons.add_circle;
    if (lowerOp.contains('sub')) return Icons.remove_circle;
    if (lowerOp.contains('mult')) return Icons.close;
    if (lowerOp.contains('div')) return Icons.pie_chart;
    return Icons.calculate;
  }

  Color _getOperationColor(String operation) {
    final lowerOp = operation.toLowerCase();
    if (lowerOp.contains('add')) return Colors.green;
    if (lowerOp.contains('sub')) return Colors.purple;
    if (lowerOp.contains('mult')) return Colors.blue;
    if (lowerOp.contains('div')) return Colors.orange;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
