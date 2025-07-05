// lib/widgets/leaderboard_tab.dart
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/haptic_service.dart';
import 'leaderboard_detail.dart';

class LeaderboardTab extends StatelessWidget {
  final List<LeaderboardEntry>? leaderboardEntries;
  final String currentUserId;
  final int Function(LeaderboardEntry) valueSelector;
  final String valueLabel;
  final IconData valueIcon;
  final Color valueColor;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  const LeaderboardTab({
    Key? key,
    required this.leaderboardEntries,
    required this.currentUserId,
    required this.valueSelector,
    required this.valueLabel,
    required this.valueIcon,
    required this.valueColor,
    required this.onRefresh,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If leaderboardEntries is null OR we're explicitly loading, show loading indicator
    // This ensures the loading indicator shows as the default initial state
    if (leaderboardEntries == null || isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Leaderboard...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state only when entries list is explicitly empty (not null) AND not loading
    if (leaderboardEntries!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No data available yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticService().mediumImpact();
        await onRefresh();
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8),
        itemCount: leaderboardEntries!.length + 1, // +1 for the top 3 section
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTopThreeSection(context);
          }
          
          final actualIndex = index - 1;
          final entry = leaderboardEntries![actualIndex];
          final rank = actualIndex + 1;
          
          return _buildLeaderboardItem(context, entry, rank);
        },
      ),
    );
  }

  Widget _buildTopThreeSection(BuildContext context) {
    if (leaderboardEntries == null || leaderboardEntries!.length < 3) {
      return SizedBox.shrink();
    }

    // Ensure our top section has a fixed height with proper constraints
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 225, // Slightly increased height to resolve the 2-pixel overflow
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
        children: [
          // Second place
          if (leaderboardEntries!.length > 1)
            Expanded(
              child: _buildTopPlaceItem(
                context,
                leaderboardEntries![1],
                2,
                Colors.grey.shade300,
                90,  // Reduced from 110 to make it shorter than gold but taller than bronze
              ),
            ),
          
          // First place (tallest)
          Expanded(
            flex: 3,
            child: _buildTopPlaceItem(
              context,
              leaderboardEntries![0],
              1,
              Colors.amber.shade300,
              140,  // Keep gold the tallest
            ),
          ),
          
          // Third place
          if (leaderboardEntries!.length > 2)
            Expanded(
              child: _buildTopPlaceItem(
                context,
                leaderboardEntries![2],
                3,
                Colors.brown.shade300,
                60,  // Reduced from 100 to make it clearly the shortest
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPlaceItem(BuildContext context, LeaderboardEntry entry, int place, Color color, double podiumHeight) {
    // Calculate total height needed and ensure it fits within constraints
    return GestureDetector(
      onTap: () {
        LeaderboardDetailBottomSheet.show(context, entry, place);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The LayoutBuilder helps us understand how much space we have
          double availableHeight = constraints.maxHeight;
          
          // Make sure podium doesn't exceed available space
          double adjustedPodiumHeight = podiumHeight;
          
          // Calculate needed height for other elements
          double topElementsHeight = 112; // Increased from 110 to account for the extra height needed
          
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
                      color: Colors.black.withValues(alpha: 0.1),
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
                height: 40, // Increased from 38 to 40 to fix the 2-pixel overflow
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
                          valueIcon,
                          size: 14,
                          color: valueColor,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${valueSelector(entry)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: valueColor,
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
                      color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildLeaderboardItem(BuildContext context, LeaderboardEntry entry, int rank) {
    final isCurrentUser = entry.userId == currentUserId;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser 
              ? Colors.blue.shade200 
              : Colors.grey.shade200,
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
        leading: _buildRank(rank, isCurrentUser),
        title: Text(
          entry.displayName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Level: ${entry.level} · Favorite: ${entry.favoriteOperation}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: valueColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                valueIcon,
                size: 16,
                color: valueColor,
              ),
              SizedBox(width: 4),
              Text(
                '${valueSelector(entry)} $valueLabel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          LeaderboardDetailBottomSheet.show(
            context,
            entry,
            rank,
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
        backgroundColor = isCurrentUser 
            ? Colors.blue.shade100 
            : Colors.grey.shade100;
        textColor = isCurrentUser 
            ? Colors.blue 
            : Colors.grey.shade700;
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