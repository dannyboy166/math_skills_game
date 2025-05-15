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
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _isMigratingAll ? null : _migrateAllUsers,
                      icon: Icon(Icons.people),
                      label: Text('Migrate All Users (Careful!)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshLeaderboards,
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh All Leaderboards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
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
          'Are you sure you want to continue?'
        ),
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
    ) ?? false;
    
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
}