// lib/screens/about_app_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
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
            _buildAppInfo(),
            SizedBox(height: 24),
            _buildSectionHeader('About the Game'),
            _buildInfoCard(
              'Educational Focus',
              'Number Ninja is designed to help children improve their mathematical abilities through fun, interactive ring-based puzzles.',
              Icons.school,
              Colors.green,
            ),
            _buildInfoCard(
              'Age Range',
              'Suitable for children aged 3-15+ with adaptive difficulty levels and age-appropriate content progression.',
              Icons.child_care,
              Colors.orange,
            ),
            _buildInfoCard(
              'Learning Benefits',
              'Enhances mental math, problem-solving skills, pattern recognition, and builds confidence in mathematics.',
              Icons.psychology,
              Colors.purple,
            ),
            _buildSectionHeader('Features'),
            _buildFeaturesList(),
            _buildSectionHeader('Development'),
            _buildInfoCard(
              'Built with Flutter',
              'Cross-platform development framework for iOS, Android, Web, and Desktop applications.',
              Icons.flutter_dash,
              Colors.blue,
            ),
            _buildInfoCard(
              'Firebase Backend',
              'Secure cloud storage for user data, real-time leaderboards, and authentication services.',
              Icons.cloud,
              Colors.red,
            ),
            _buildSectionHeader('Credits'),
            _buildCreditsSection(),
            _buildSectionHeader('Legal'),
            _buildLegalButtons(context),
            SizedBox(height: 20),
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.calculate,
                size: 40,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Number Ninja',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Interactive Mathematical Learning',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
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
              color: Colors.blue.shade700,
            ),
          ),
          Divider(
            color: Colors.blue.shade300,
            thickness: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
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
            SizedBox(width: 16),
            Expanded(
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
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
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

  Widget _buildFeaturesList() {
    final features = [
      'Ring-based math puzzles with drag-and-drop mechanics',
      'Multiple difficulty levels adapting to skill progression',
      'Four core operations: Addition, Subtraction, Multiplication, Division',
      'Global leaderboards and personal statistics tracking',
      'Daily and weekly streak challenges',
      'Audio feedback and haptic responses for engagement',
      'Safe, ad-free environment designed for children',
      'Cross-platform support (iOS, Android, Web, Desktop)',
    ];

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Key Features',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsSection() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple, size: 24),
                SizedBox(width: 8),
                Text(
                  'Development Team',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildCreditItem('Development', 'Flutter & Dart Framework'),
            _buildCreditItem('Backend Services', 'Google Firebase'),
            _buildCreditItem('Authentication', 'Firebase Auth, Google Sign-In, Sign in with Apple'),
            _buildCreditItem('Audio Assets', 'Custom sound effects for educational games'),
            _buildCreditItem('Design Philosophy', 'Child-focused UI/UX principles'),
            SizedBox(height: 16),
            Text(
              'Special thanks to the Flutter community and open-source contributors who made this project possible.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem(String role, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalButtons(BuildContext context) {
    return Column(
      children: [
        _buildLegalButton(
          'Privacy Policy',
          'View our privacy and data handling practices',
          Icons.privacy_tip,
          Colors.green,
          () => _showPrivacyPolicy(context),
        ),
        _buildLegalButton(
          'Terms of Service',
          'Read the terms and conditions of use',
          Icons.description,
          Colors.blue,
          () => _showTermsOfService(context),
        ),
        _buildLegalButton(
          'Open Source Licenses',
          'View licenses for third-party software',
          Icons.code,
          Colors.orange,
          () => _showLicenses(context),
        ),
      ],
    );
  }

  Widget _buildLegalButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
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
            size: 24,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Build Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12),
            _buildBuildInfo('Version', '1.0.0'),
            _buildBuildInfo('Build', '1'),
            _buildBuildInfo('Flutter SDK', '3.27.1'),
            _buildBuildInfo('Dart SDK', '3.6.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            '''Number Ninja Privacy Policy

Last updated: January 2025

We respect your privacy and are committed to protecting your personal data.

Information We Collect:
• Account information (email, display name)
• Game progress and statistics
• Device and usage information

How We Use Your Information:
• To provide and improve our services
• To track game progress and achievements
• To maintain leaderboards and statistics
• To provide customer support

Data Security:
• All data is encrypted in transit and at rest
• We use Firebase's secure infrastructure
• We never sell personal information to third parties

Your Rights:
• Access your personal data
• Request data deletion
• Export your data
• Opt out of data collection

For questions, contact us through the app settings.''',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(
            '''Number Ninja Terms of Service

Last updated: January 2025

By using this app, you agree to these terms.

Acceptable Use:
• Use the app for educational purposes
• Do not attempt to hack or exploit the system
• Respect other users in leaderboards
• Follow community guidelines

Account Responsibilities:
• Keep your login credentials secure
• Use accurate information during registration
• Notify us of any security breaches

Intellectual Property:
• The app and its content are protected by copyright
• You may not copy, modify, or distribute the app
• User-generated content remains your property

Service Availability:
• We strive for 99% uptime but cannot guarantee it
• Features may be updated or changed
• We reserve the right to suspend accounts for violations

Limitation of Liability:
• Use the app at your own risk
• We are not liable for any damages from app use
• Educational content is provided "as is"

Contact us through the app for any questions.''',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Number Ninja',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Number Ninja. All rights reserved.',
    );
  }
}