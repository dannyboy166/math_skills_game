// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/services/sound_service.dart';
import 'package:math_skills_game/services/haptic_service.dart';
import 'package:math_skills_game/services/admin_service.dart';
import 'package:math_skills_game/models/rotation_speed.dart';
import 'package:math_skills_game/screens/privacy_settings_screen.dart';
import 'package:math_skills_game/screens/about_app_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  final HapticService _hapticService = HapticService();
  final AdminService _adminService = AdminService();

  // Local state for settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
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
                'Math Skills Game v1.0.0',
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
          color: color.withOpacity(0.3),
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
            color: color.withOpacity(0.1),
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
          color: color.withOpacity(0.3),
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
            color: color.withOpacity(0.1),
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

  Widget _buildAdminButton(
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
}
