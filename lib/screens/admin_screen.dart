// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/services/admin_service.dart';

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

  TextEditingController _userIdController = TextEditingController();
  String _syncTargetUserId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Tools'),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    ElevatedButton.icon(
                      onPressed:
                          _isSyncing ? null : _forceSyncCurrentUserLeaderboards,
                      icon: Icon(Icons.sync),
                      label: Text('Force Sync Current User Leaderboards'),
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
            if (_isMigratingUser || _isMigratingAll || _isRefreshing)
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

// Remember to dispose the controller in the dispose method
  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}
