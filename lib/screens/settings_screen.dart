// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/services/sound_service.dart';
import 'package:math_skills_game/services/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  final HapticService _hapticService = HapticService();
  
  // Local state for settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Get current settings from services
    setState(() {
      _soundEnabled = _soundService.isSoundEnabled;
      _vibrationEnabled = _hapticService.isVibrationEnabled;
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
            
            _buildSectionHeader('Game Modes'),
            
            // Placeholder for future settings
            _buildPlaceholderSetting(
              'Dark Mode',
              'Change the app appearance',
              Icons.dark_mode,
              Colors.grey[800]!,
            ),
            
            _buildPlaceholderSetting(
              'Challenge Mode',
              'Enable timed challenges',
              Icons.timer,
              Colors.orange,
            ),
            
            _buildSectionHeader('Account'),
            
            _buildPlaceholderSetting(
              'Notification Settings',
              'Manage game notifications',
              Icons.notifications,
              Colors.red,
            ),
            
            _buildPlaceholderSetting(
              'Data & Privacy',
              'Manage your data',
              Icons.security,
              Colors.green,
            ),
            
            _buildPlaceholderSetting(
              'About',
              'App information and credits',
              Icons.info,
              Colors.blue,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This feature will be available soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}