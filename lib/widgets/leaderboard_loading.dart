// lib/widgets/leaderboard_loading.dart
import 'package:flutter/material.dart';

class LeaderboardLoading extends StatelessWidget {
  const LeaderboardLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Trophy icon with shimmering effect
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade100,
                Colors.blue.shade200,
                Colors.blue.shade300,
                Colors.blue.shade200,
                Colors.blue.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        
        // Loading text
        Text(
          'Loading Leaderboard...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 16),
        
        // Animated loading indicator
        Container(
          width: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.blue.shade100,
              color: Colors.blue.shade500,
            ),
          ),
        ),
        SizedBox(height: 24),
        
        // Placeholder items (shimmer effect)
        _buildShimmerItem(),
        _buildShimmerItem(),
        _buildShimmerItem(),
      ],
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}