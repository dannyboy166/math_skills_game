// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:number_ninja/models/rotation_speed.dart';
import 'package:number_ninja/screens/about_app_screen.dart';
import 'package:number_ninja/screens/privacy_settings_screen.dart';
import 'package:number_ninja/screens/landing_screen.dart';
import 'package:number_ninja/services/haptic_service.dart';
import 'package:number_ninja/services/sound_service.dart';
import 'package:number_ninja/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  final HapticService _hapticService = HapticService();
  final AuthService _authService = AuthService();

  // Local state for settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isDragMode = false;
  RotationSpeed _rotationSpeed = RotationSpeed.defaultSpeed;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current settings from services and preferences
    setState(() {
      _soundEnabled = _soundService.isSoundEnabled;
      _vibrationEnabled = _hapticService.isVibrationEnabled;
      _isDragMode = prefs.getBool('drag_mode') ?? false;

      // Load rotation speed (default to level 5 - Normal)
      final speedLevel = prefs.getInt('rotation_speed') ?? 5;
      _rotationSpeed = RotationSpeed.fromLevel(speedLevel);
    });
  }

  Future<void> _toggleSound() async {
    _soundService.toggleSound();

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundService.isSoundEnabled);

    setState(() {
      _soundEnabled = _soundService.isSoundEnabled;
    });

    // Play a sound for feedback if sound is enabled
    if (_soundEnabled) {
      _soundService.playCorrect();
    }
  }

  Future<void> _toggleVibration() async {
    await _hapticService.toggleVibration();

    setState(() {
      _vibrationEnabled = _hapticService.isVibrationEnabled;
    });

    // Provide haptic feedback if vibration is enabled
    if (_vibrationEnabled) {
      _hapticService.mediumImpact();
    }
  }

  Future<void> _toggleControlMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drag_mode', !_isDragMode);

    setState(() {
      _isDragMode = !_isDragMode;
    });

    // Provide feedback
    if (_vibrationEnabled) {
      _hapticService.mediumImpact();
    }
    if (_soundEnabled) {
      _soundService.playCorrect();
    }
  }

  Future<void> _changeRotationSpeed(RotationSpeed newSpeed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rotation_speed', newSpeed.level);

    setState(() {
      _rotationSpeed = newSpeed;
    });

    // Provide feedback
    if (_vibrationEnabled) {
      _hapticService.lightImpact();
    }
    if (_soundEnabled) {
      _soundService.playCorrect();
    }
  }

  Widget _buildAccountSection() {
    final authService = AuthService();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reset Password Setting - only show for email/password users
        if (authService.isEmailPasswordUser)
          _buildNavigationSetting(
            'Reset Password',
            'Change your login password',
            Icons.lock_reset,
            Colors.blue,
            () => _showResetPasswordDialog(),
          ),

        // Show different setting for OAuth users
        if (!authService.isEmailPasswordUser && authService.currentUser != null)
          _buildNavigationSetting(
            'Account Settings',
            'Manage your ${_getProviderDisplayName(authService.userAuthProvider)} account',
            Icons.account_circle,
            Colors.blue,
            () => _showAccountInfoDialog(),
          ),

        // Logout Setting
        _buildNavigationSetting(
          'Logout',
          'Sign out of your account',
          Icons.logout,
          Colors.red,
          () => _showLogoutDialog(),
        ),
      ],
    );
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    emailController.text = _authService.currentUser?.email ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Reset Password 🔐',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'We will send a password reset link to your email address: 📧',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address ✉️',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel ❌',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Show fun loading message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                              SizedBox(width: 16),
                              Text('Sending reset email... 📧'),
                            ],
                          ),
                          backgroundColor: Colors.blue.shade600,
                        ),
                      );

                      try {
                        await _authService
                            .resetPassword(emailController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Password reset email sent! 📬'),
                              ],
                            ),
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Failed to send reset email 😔'),
                              ],
                            ),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Send Reset Link 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Logout 👋',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Are you sure you want to logout? 🤔\n\nYou can always come back to continue your math ninja journey! 🥷',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Stay 😊',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _performLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Logout 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // Show a fun loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.purple.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Logging out... 🥷',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Thanks for practicing math today!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Add debug before logout
    print("SETTINGS DEBUG: Starting logout process");
    print(
        "SETTINGS DEBUG: Current user before logout: ${_authService.currentUser?.uid ?? 'null'}");

    // Perform logout after a brief delay to ensure dialog is shown
    Future.delayed(Duration(milliseconds: 500), () async {
      try {
        // Sign out
        await _authService.signOut();

        // Check after signout
        print("SETTINGS DEBUG: Logout completed");
        print(
            "SETTINGS DEBUG: Current user after logout: ${_authService.currentUser?.uid ?? 'null'}");

        // Navigate to landing screen and clear the stack
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LandingScreen()),
            (route) => false, // This removes all previous routes
          );
        }

        print("SETTINGS DEBUG: Navigated to landing screen");
      } catch (e) {
        print("SETTINGS DEBUG: Error during logout: $e");

        // If there's an error, pop the dialog and show error
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to log out. Please try again. 😔'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Game Settings'),

            // Sound Toggle
            _buildSettingSwitch(
              'Sound Effects',
              'Turn game sounds on or off',
              Icons.volume_up,
              _soundEnabled,
              _toggleSound,
              Colors.blue,
            ),

            // Vibration Toggle
            _buildSettingSwitch(
              'Vibration',
              'Turn haptic feedback on or off',
              Icons.vibration,
              _vibrationEnabled,
              _toggleVibration,
              Colors.purple,
            ),

            // Control Mode Toggle
            _buildSettingSwitch(
              'Control Mode',
              _isDragMode ? 'Currently using Drag Mode' : 'Currently using Swipe Mode',
              _isDragMode ? Icons.drag_indicator : Icons.swipe,
              _isDragMode,
              _toggleControlMode,
              Colors.green,
            ),

            // Ring Rotation Speed
            _buildRotationSpeedSetting(),

            _buildSectionHeader('Account'),

            _buildPlaceholderSetting(
              'Notification Settings',
              'Manage game notifications',
              Icons.notifications,
              Colors.red,
            ),

            _buildNavigationSetting(
              'Data & Privacy',
              'Manage your data and privacy settings',
              Icons.security,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacySettingsScreen(),
                  ),
                );
              },
            ),

            _buildAccountSection(),

            _buildNavigationSetting(
              'About',
              'App information and credits',
              Icons.info,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutAppScreen(),
                  ),
                );
              },
            ),


            SizedBox(height: 20),

            // Version number
            Center(
              child: Text(
                'Number Ninja v1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Divider(
            color: Colors.blue[300],
            thickness: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function() onChanged,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        value: value,
        onChanged: (newValue) {
          onChanged();
        },
        activeColor: color,
      ),
    );
  }

  Widget _buildRotationSpeedSetting() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rotate_right,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ring Rotation Speed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Control how fast the rings rotate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Speed selection slider
            Column(
              children: [
                Text(
                  'Current: ${_rotationSpeed.displayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(height: 8),
                Slider(
                  value: _rotationSpeed.level.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.orange,
                  inactiveColor: Colors.orange.withValues(alpha: 0.3),
                  onChanged: (value) {
                    final newSpeed = RotationSpeed.fromLevel(value.round());
                    _changeRotationSpeed(newSpeed);
                  },
                ),

                // Speed labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: TextStyle(
                        fontSize: 12,
                        color: _rotationSpeed.level == 1
                            ? Colors.orange[700]
                            : Colors.grey[500],
                        fontWeight: _rotationSpeed.level == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 12,
                        color: _rotationSpeed.level == 5
                            ? Colors.orange[700]
                            : Colors.grey[500],
                        fontWeight: _rotationSpeed.level == 5
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '10',
                      style: TextStyle(
                        fontSize: 12,
                        color: _rotationSpeed.level == 10
                            ? Colors.orange[700]
                            : Colors.grey[500],
                        fontWeight: _rotationSpeed.level == 10
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Speed descriptions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slowest',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Normal',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Maximum',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar(); // Hide any existing one
          messenger.showSnackBar(
            SnackBar(
              content: Text('This feature will be available soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationSetting(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper method to get user-friendly provider names
  String _getProviderDisplayName(String? providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'password':
        return 'Email';
      default:
        return 'account';
    }
  }

  // Show account info dialog for OAuth users
  void _showAccountInfoDialog() {
    final authService = AuthService();
    final provider = _getProviderDisplayName(authService.userAuthProvider);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You signed in with $provider.'),
              SizedBox(height: 16),
              Text('To manage your password or account settings, please visit your $provider account settings.'),
              if (provider == 'Google') ...[
                SizedBox(height: 12),
                Text('Visit: myaccount.google.com', style: TextStyle(color: Colors.blue)),
              ],
              if (provider == 'Apple') ...[
                SizedBox(height: 12),
                Text('Visit: Settings > Sign-In & Security on your Apple device', style: TextStyle(color: Colors.blue)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

}
