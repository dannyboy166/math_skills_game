// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:number_ninja/services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminService _adminService = AdminService();
  bool _isMigratingUser = false;
  bool _isMigratingAll = false;
  bool _isRefreshing = false;
  String _statusMessage = '';

  bool _isSyncing = false;
  bool _isRecalculatingStars = false;
  bool _isAddingAgeParameters = false;
  bool _isFixingTimeTables = false;
  bool _isResettingGameData = false;

  TextEditingController _userIdController = TextEditingController();
  String _syncTargetUserId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Management Section
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage user accounts and fix user data issues.',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAddingAgeParameters ? null : _addAllAgeParameters,
                      icon: Icon(Icons.person_add),
                      label: Text('Add Age Parameters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isFixingTimeTables ? null : _fixUnlockedTimeTables,
                      icon: Icon(Icons.lock_open),
                      label: Text('Fix Unlocked Time Tables'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard Migration Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use these tools to migrate data to the new scalable leaderboard system.',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isMigratingUser ? null : _migrateCurrentUser,
                      icon: Icon(Icons.person),
                      label: Text('Migrate Current User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isMigratingAll ? null : _migrateAllUsers,
                      icon: Icon(Icons.people),
                      label: Text('Migrate All Users (Careful!)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshLeaderboards,
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh All Leaderboards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _isSyncing ? null : _forceSyncCurrentUserLeaderboards,
                      icon: Icon(Icons.sync),
                      label: Text('Force Sync Current User Leaderboards'
                      ),
                      
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stars Fix Tools Card
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stars Fix Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fix total stars calculation for all users based on their actual level completions.',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isRecalculatingStars ? null : _recalculateTotalStars,
                      icon: Icon(Icons.star_border),
                      label: Text('Recalculate Total Stars for All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _debugCurrentUserStars,
                      icon: Icon(Icons.bug_report),
                      label: Text('Debug My Level Completions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Data Reset Tools Card
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Reset Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'DESTRUCTIVE: Reset all game data while preserving user accounts.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isResettingGameData ? null : _resetAllGameData,
                      icon: Icon(Icons.refresh),
                      label: Text('Reset All Game Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add this UI somewhere in your admin screen
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Specific User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'User ID',
                        hintText: 'Enter user ID to sync',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSyncing
                              ? null
                              : () {
                                  setState(() {
                                    _syncTargetUserId =
                                        _userIdController.text.trim();
                                  });
                                  _syncSpecificUserLeaderboards();
                                },
                          icon: Icon(Icons.sync),
                          label: Text('Sync User Leaderboards'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor:
                                Colors.white, // Set text/icon color to white
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSyncing
                              ? null
                              : () {
                                  _userIdController.text =
                                      'rr3R7bbW1xSZ35KXd8KjVHAxpYI3';
                                  setState(() {
                                    _syncTargetUserId =
                                        'rr3R7bbW1xSZ35KXd8KjVHAxpYI3';
                                  });
                                },
                          child: Text('User 2'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade300,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (_statusMessage.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            if (_isMigratingUser || _isMigratingAll || _isRefreshing || _isRecalculatingStars || _isAddingAgeParameters || _isFixingTimeTables || _isResettingGameData)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      _getProgressMessage(),
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            
            // Crashlytics Testing Section
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crashlytics Testing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Test Firebase Crashlytics crash reporting and dSYM upload.',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testCrash,
                      icon: Icon(Icons.bug_report),
                      label: Text('Force Test Crash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _logTestError,
                      icon: Icon(Icons.error_outline),
                      label: Text('Log Test Error'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documentation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDocItem(
                      'Add Age Parameters',
                      'Adds age=11 to all users who are missing the age parameter.',
                      'Safe to run multiple times, only affects users missing age data.',
                    ),
                    _buildDocItem(
                      'Fix Unlocked Time Tables',
                      'Updates unlocked time tables for all users based on their age.',
                      'Ensures proper time table access based on user age settings.',
                    ),
                    _buildDocItem(
                      'Migrate Current User',
                      'Updates the current user\'s data in the new leaderboard system.',
                      'Fast and safe to use anytime.',
                    ),
                    _buildDocItem(
                      'Migrate All Users',
                      'Migrates all users to the new leaderboard system.',
                      'Use carefully! Could be slow with many users.',
                    ),
                    _buildDocItem(
                      'Refresh Leaderboards',
                      'Rebuilds all leaderboards from user data.',
                      'Use after migrations or if leaderboards need fixing.',
                    ),
                    _buildDocItem(
                      'Force Sync Current User Leaderboards',
                      'Forces all of your best times to be synced to the leaderboard system.',
                      'Use this if your high scores aren\'t showing up correctly in the leaderboards.',
                    ),
                    _buildDocItem(
                      'Recalculate Total Stars',
                      'Recalculates the total stars field for all users based on their actual level completions.',
                      'Use this to fix incorrect total star counts, especially for legacy users.',
                    ),
                    _buildDocItem(
                      'Reset All Game Data',
                      'DESTRUCTIVE: Resets all game data for all users while preserving user accounts.',
                      'This permanently deletes all scores, completions, stars, and leaderboard entries. Use when game mechanics change significantly.',
                    ),
                    _buildDocItem(
                      'Force Test Crash',
                      'Forces the app to crash to test Firebase Crashlytics reporting.',
                      'The crash report will appear in Firebase Console after a few minutes. Use this to verify dSYM upload is working.',
                    ),
                    _buildDocItem(
                      'Log Test Error',
                      'Logs a non-fatal error to Firebase Crashlytics for testing.',
                      'Creates an error report without crashing the app. Useful for testing error logging functionality.',
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getProgressMessage() {
    if (_isMigratingUser) return 'Migrating your data...';
    if (_isMigratingAll) return 'Migrating all users...';
    if (_isRefreshing) return 'Refreshing leaderboards...';
    if (_isSyncing) return 'Syncing leaderboards for current user...';
    if (_isRecalculatingStars) return 'Recalculating total stars for all users...';
    if (_isAddingAgeParameters) return 'Adding age parameters to all users...';
    if (_isFixingTimeTables) return 'Fixing unlocked time tables for all users...';
    if (_isResettingGameData) return 'Resetting all game data...';
    return '';
  }

  Widget _buildDocItem(String title, String description, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(description),
          SizedBox(height: 4),
          Text(
            'Note: $note',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateCurrentUser() async {
    setState(() {
      _isMigratingUser = true;
      _statusMessage = 'Starting migration for current user...';
    });

    try {
      await _adminService.migrateCurrentUserData();

      setState(() {
        _statusMessage = 'Current user migration completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during migration: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isMigratingUser = false;
      });
    }
  }

  Future<void> _migrateAllUsers() async {
    // Show confirmation dialog first
    bool confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Migration'),
            content: Text(
                'This will migrate all users to the new leaderboard system. '
                'This operation might take a while depending on the number of users. '
                'Are you sure you want to continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isMigratingAll = true;
      _statusMessage = 'Starting migration for all users...';
    });

    try {
      await _adminService.migrateAllUsers();

      setState(() {
        _statusMessage = 'All users migration completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during migration: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isMigratingAll = false;
      });
    }
  }

  Future<void> _refreshLeaderboards() async {
    setState(() {
      _isRefreshing = true;
      _statusMessage = 'Starting leaderboard refresh...';
    });

    try {
      await _adminService.refreshAllLeaderboards();

      setState(() {
        _statusMessage = 'Leaderboard refresh completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leaderboard refresh completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error refreshing leaderboards: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leaderboard refresh failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _forceSyncCurrentUserLeaderboards() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Starting forced sync of current user leaderboards...';
    });

    try {
      await _adminService.forceSyncCurrentUserLeaderboards();

      setState(() {
        _statusMessage = 'Leaderboard sync completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leaderboard sync completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing leaderboards: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leaderboard sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _syncSpecificUserLeaderboards() async {
    if (_syncTargetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Starting forced sync for user: $_syncTargetUserId';
    });

    try {
      await _adminService.forceLeaderboardSync(_syncTargetUserId);

      setState(() {
        _statusMessage = 'Leaderboard sync completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Leaderboard sync completed successfully for $_syncTargetUserId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing leaderboards: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leaderboard sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _recalculateTotalStars() async {
    // Show confirmation dialog first
    bool confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Total Stars Recalculation'),
            content: Text(
                'This will recalculate the total stars for ALL users based on their actual level completions. '
                'This operation might take a while depending on the number of users. '
                'Are you sure you want to continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isRecalculatingStars = true;
      _statusMessage = 'Starting total stars recalculation for all users...';
    });

    try {
      await _adminService.recalculateTotalStarsForAllUsers();

      setState(() {
        _statusMessage = 'Total stars recalculation completed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total stars recalculation completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during total stars recalculation: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total stars recalculation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRecalculatingStars = false;
      });
    }
  }

  Future<void> _debugCurrentUserStars() async {
    setState(() {
      _statusMessage = 'Getting level completion data...';
    });

    try {
      final debugData = await _adminService.debugCurrentUserLevelCompletions();
      
      if (debugData.containsKey('error')) {
        setState(() {
          _statusMessage = 'Debug Error: ${debugData['error']}';
        });
        return;
      }

      final completions = debugData['completions'] as List<Map<String, dynamic>>;
      final levelGroupings = debugData['levelGroupings'] as List<Map<String, dynamic>>;
      final totalStars = debugData['calculatedTotalStars'];
      final totalCompletions = debugData['totalCompletions'];

      // Show detailed dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Level Completions Debug'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Individual Completions: $totalCompletions'),
                  Text('Calculated Total Stars: $totalStars',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 16),
                  TabBar(
                    tabs: [
                      Tab(text: 'Actual Levels (${levelGroupings.length})'),
                      Tab(text: 'Raw Data ($totalCompletions)'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Level Groupings Tab
                        ListView.builder(
                          itemCount: levelGroupings.length,
                          itemBuilder: (context, index) {
                            final group = levelGroupings[index];
                            final individualCompletions = group['individualCompletions'] as List;
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            group['levelTitle'],
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${group['bestStars']} ⭐',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (individualCompletions.length > 1) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        'From ${individualCompletions.length} individual completions',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Raw Completions Tab
                        ListView.builder(
                          itemCount: completions.length,
                          itemBuilder: (context, index) {
                            final completion = completions[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 4),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${completion['operation']} ${completion['difficulty']} #${completion['targetNumber']}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${completion['stars']} ⭐',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );

      setState(() {
        _statusMessage = 'Debug completed - check dialog for details';
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Debug failed: $e';
      });
    }
  }

  Future<void> _addAllAgeParameters() async {
    setState(() {
      _isAddingAgeParameters = true;
      _statusMessage = 'Adding age parameters to all users...';
    });

    try {
      await _adminService.addAllAgeParameters(defaultAge: 11);
      
      setState(() {
        _statusMessage = 'Age parameters added successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added age parameters to all users'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding age parameters: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding age parameters: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingAgeParameters = false;
      });
    }
  }

  Future<void> _fixUnlockedTimeTables() async {
    setState(() {
      _isFixingTimeTables = true;
      _statusMessage = 'Fixing unlocked time tables for all users...';
    });

    try {
      await _adminService.fixUnlockedTimeTablesForAllUsers();
      
      setState(() {
        _statusMessage = 'Time tables fixed successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully fixed unlocked time tables for all users'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fixing time tables: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fixing time tables: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isFixingTimeTables = false;
      });
    }
  }

  Future<void> _resetAllGameData() async {
    // Show double confirmation dialog for this destructive operation
    bool confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('⚠️ DESTRUCTIVE OPERATION'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will PERMANENTLY reset ALL game data for ALL users including:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• All scores and best times'),
                Text('• All level completions'),
                Text('• All stars and achievements'),
                Text('• All leaderboard entries'),
                Text('• All game statistics'),
                SizedBox(height: 16),
                Text(
                  'User accounts will be preserved (email, name, age, etc.)',
                  style: TextStyle(color: Colors.green.shade700),
                ),
                SizedBox(height: 16),
                Text(
                  'This cannot be undone. Are you absolutely sure?',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes, Reset All Data'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // Second confirmation
    bool doubleConfirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Final Confirmation'),
            content: Text(
              'Type "RESET ALL DATA" to confirm this destructive operation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final TextEditingController confirmController = TextEditingController();
                      return AlertDialog(
                        title: Text('Type to Confirm'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Type "RESET ALL DATA" exactly:'),
                            SizedBox(height: 8),
                            TextField(
                              controller: confirmController,
                              decoration: InputDecoration(
                                hintText: 'RESET ALL DATA',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(false);
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (confirmController.text.trim() == 'RESET ALL DATA') {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Text does not match. Operation cancelled.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(false);
                              }
                            },
                            child: Text('Confirm Reset'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;

    if (!doubleConfirmed) return;

    setState(() {
      _isResettingGameData = true;
      _statusMessage = 'Starting destructive reset of all game data...';
    });

    try {
      await _adminService.resetAllGameData();

      setState(() {
        _statusMessage = 'All game data has been reset successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All game data reset completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error resetting game data: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game data reset failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResettingGameData = false;
      });
    }
  }

  void _testCrash() {
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Force Test Crash'),
        content: Text(
          'This will force the app to crash to test Crashlytics reporting. '
          'The crash will appear in your Firebase Console after a few minutes. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Force a crash after a short delay to allow dialog to close
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Future.delayed(Duration(seconds: 1), () {
                if (kReleaseMode) {
                  FirebaseCrashlytics.instance.crash();
                } else {
                  // In debug mode, just show a message instead of crashing
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Crash test skipped in debug mode. Use release mode to test Crashlytics.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Crash App'),
          ),
        ],
      ),
    );
  }

  void _logTestError() async {
    try {
      // Log a test error to Crashlytics
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.recordError(
          'Test error from admin panel',
          StackTrace.current,
          reason: 'Testing Crashlytics error logging',
          information: [
            DiagnosticsProperty('timestamp', DateTime.now().toString()),
            DiagnosticsProperty('user_id', 'admin_test'),
            DiagnosticsProperty('test_type', 'manual_error_logging'),
          ],
        );
      } else {
        // In debug mode, just show a message instead of logging to Crashlytics
        if (kDebugMode) {
          print('Debug mode: Test error would be logged to Crashlytics: Test error from admin panel');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test error logged to Crashlytics'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Remember to dispose the controller in the dispose method
  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}
