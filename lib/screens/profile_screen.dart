import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_skills_game/screens/admin_screen.dart';
import 'package:math_skills_game/screens/auth/login_screen.dart';
import 'package:math_skills_game/services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _displayNameController = TextEditingController();

  final AdminService _adminService = AdminService();

  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _streakData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (docSnapshot.exists && mounted) {
          // Get streak data
          final streakData = await _userService.getStreakStats(userId);

          final userData = docSnapshot.data()!;
          final completedGames = userData['completedGames'] ?? {};

          // Calculate the sum of all operation counts
          int additionCount = completedGames['addition'] ?? 0;
          int subtractionCount = completedGames['subtraction'] ?? 0;
          int multiplicationCount = completedGames['multiplication'] ?? 0;
          int divisionCount = completedGames['division'] ?? 0;

          int calculatedTotal = additionCount +
              subtractionCount +
              multiplicationCount +
              divisionCount;

          // Use the calculated total instead of the stored total
          userData['totalGames'] = calculatedTotal;

          setState(() {
            _userData = userData;
            _streakData = streakData;
            _displayNameController.text = _userData?['displayName'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDisplayName() async {
    if (_displayNameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Display name cannot be empty')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'displayName': _displayNameController.text.trim(),
        });

        await _authService.currentUser?.updateDisplayName(
          _displayNameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
        }

        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }

  void _showStreakInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.deepOrange,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'About Streaks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice math every day to build your streak! Each day you complete at least one practice session, your streak grows. Miss a day and your streak resets to zero.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Benefits of maintaining a streak:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Builds consistent learning habits\n• Improves long-term retention\n• Makes learning math more fun\n• Track your dedication to math practice',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Keep your streak alive to earn special rewards!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrange.shade400,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userData == null
              ? Center(child: Text('Could not load profile data'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar and Name Section
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (_isEditing) ...[
                              TextField(
                                controller: _displayNameController,
                                decoration: InputDecoration(
                                  labelText: 'Display Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _updateDisplayName,
                                    child: Text('Save'),
                                  ),
                                  SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _displayNameController.text =
                                            _userData?['displayName'] ?? '';
                                      });
                                    },
                                    child: Text('Cancel'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                _userData?['displayName'] ?? 'Player',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _userData?['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Level: ${_userData?['level'] ?? 'Novice'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 24),
                      Divider(),
                      SizedBox(height: 16),

                      // Streak Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Streak Stats'),
                          GestureDetector(
                            onTap: _showStreakInfo,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'How streaks work',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Streak Cards (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStreakCard(
                              'Current Streak',
                              '${_streakData?['currentStreak'] ?? 0}',
                              Icons.local_fire_department_rounded,
                              Colors.deepOrange,
                              'days',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildStreakCard(
                              'Longest Streak',
                              '${_streakData?['longestStreak'] ?? 0}',
                              Icons.emoji_events_rounded,
                              Colors.amber,
                              'days',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Stats Section
                      _buildSectionTitle('Game Statistics'),
                      _buildStatCard(
                        'Total Games Played',
                        '${_userData?['totalGames'] ?? 0}',
                        Icons.sports_esports,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Stars Earned',
                        '${_userData?['totalStars'] ?? 0}',
                        Icons.star,
                        Colors.amber,
                      ),

                      SizedBox(height: 16),
                      _buildSectionTitle('Operation Stats'),

                      // Operation Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildOperationCard(
                            'Addition',
                            '${_userData?['completedGames']?['addition'] ?? 0}',
                            '+',
                            Colors.green,
                          ),
                          _buildOperationCard(
                            'Subtraction',
                            '${_userData?['completedGames']?['subtraction'] ?? 0}',
                            '-',
                            Colors.purple,
                          ),
                          _buildOperationCard(
                            'Multiplication',
                            '${_userData?['completedGames']?['multiplication'] ?? 0}',
                            '×',
                            Colors.blue,
                          ),
                          _buildOperationCard(
                            'Division',
                            '${_userData?['completedGames']?['division'] ?? 0}',
                            '÷',
                            Colors.orange,
                          ),
                        ],
                      ),

                      if (_adminService.isCurrentUserAdmin()) ...[
                        SizedBox(height: 32),
                        Divider(),
                        _buildSectionTitle('Admin Tools'),
                        ListTile(
                          leading: Icon(Icons.admin_panel_settings,
                              color: Colors.red),
                          title: Text('Admin Dashboard'),
                          subtitle: Text('Manage leaderboards and user data'),
                          tileColor: Colors.red.shade50,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminScreen()),
                            );
                          },
                        ),
                      ],
                      SizedBox(height: 32),
                      Divider(),

                      // Account Management Section
                      _buildSectionTitle('Account'),
                      ListTile(
                        leading: Icon(Icons.lock_reset, color: Colors.blue),
                        title: Text('Reset Password'),
                        onTap: () {
                          // Show reset password dialog
                          _showResetPasswordDialog();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Logout'),
                        onTap: () {
                          // Show a simple loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return SimpleDialog(
                                title: Center(child: Text('Logging out...')),
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Perform logout after a brief delay to ensure dialog is shown
                          Future.delayed(Duration(milliseconds: 300), () async {
                            try {
                              // Sign out
                              await _authService.signOut();

                              // Navigate directly to login screen
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                                (route) => false,
                              );
                            } catch (e) {
                              print('Error during logout: $e');

                              // If there's an error, pop the dialog and show error
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to log out. Please try again.')),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    emailController.text = _userData?['email'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We will send a password reset link to your email address:',
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sending reset email...')),
                );

                try {
                  await _authService.resetPassword(emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send reset email')),
                  );
                }
              },
              child: Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStreakCard(
      String title, String value, IconData icon, Color color, String unit) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(
      String title, String count, String symbol, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count games',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
