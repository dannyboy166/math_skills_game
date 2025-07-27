// lib/screens/game_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/operation_config.dart';

class GameSettingsScreen extends StatefulWidget {
  final OperationConfig operation;
  final bool isDragMode;
  final VoidCallback onToggleMode;

  const GameSettingsScreen({
    super.key,
    required this.operation,
    required this.isDragMode,
    required this.onToggleMode,
  });

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  late bool _currentDragMode;
  
  @override
  void initState() {
    super.initState();
    _currentDragMode = widget.isDragMode;
  }
  
  void _handleToggleMode() {
    setState(() {
      _currentDragMode = !_currentDragMode;
    });
    widget.onToggleMode();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.operation.color,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.operation.color.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Controls'),
            _buildControlModeCard(),
            
            SizedBox(height: 24),
            
            _buildSectionHeader('How to Play'),
            _buildGameRulesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: widget.operation.color,
        ),
      ),
    );
  }

  Widget _buildControlModeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.operation.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.operation.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentDragMode ? Icons.drag_indicator : Icons.swipe,
                    color: widget.operation.color,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.operation.color,
                        ),
                      ),
                      Text(
                        _currentDragMode ? 'Currently using Drag Mode' : 'Currently using Swipe Mode',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                    'Swipe Mode',
                    'Swipe to rotate rings',
                    Icons.swipe,
                    !_currentDragMode,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModeOption(
                    'Drag Mode',
                    'Drag numbers directly',
                    Icons.drag_indicator,
                    _currentDragMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String title, String description, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _handleToggleMode();
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? widget.operation.color.withValues(alpha: 0.1)
            : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? widget.operation.color
              : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? widget.operation.color
                : Colors.grey.shade500,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected 
                  ? widget.operation.color
                  : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameRulesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.operation.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.operation.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: widget.operation.color,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Game Rules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.operation.color,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            _buildRule(
              '🎯',
              'Objective',
              'Complete 12 correct equations at the corner/diagonal positions to win',
              Colors.green,
            ),
            
            _buildRule(
              '🔄',
              'Controls',
              _currentDragMode 
                ? 'Drag numbers between inner and outer rings to align at corners'
                : 'Swipe to rotate rings and align numbers at diagonal corners',
              widget.operation.color,
            ),
            
            _buildRule(
              '➕',
              'Equations',
              'Form equations at corner positions: outer ${widget.operation.symbol} inner = center',
              Colors.blue,
            ),
            
            _buildRule(
              '⚠️',
              'Time Penalties',
              'Avoid mistakes to prevent time penalties that affect your score',
              Colors.red,
            ),
            
            _buildRule(
              '⭐',
              'Scoring',
              'Faster completion = more stars. Perfect games earn bonus points!',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String emoji, String title, String description, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 20),
              ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}