import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showLegalMoves = true;
  bool _showCoordinates = true;
  bool _autoQueen = false;
  bool _flipBoard = false;
  String _theme = 'dark';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.instance.loadSettings();
    setState(() {
      _soundEnabled = settings['soundEnabled'] as bool? ?? true;
      _vibrationEnabled = settings['vibrationEnabled'] as bool? ?? true;
      _showLegalMoves = settings['showLegalMoves'] as bool? ?? true;
      _showCoordinates = settings['showCoordinates'] as bool? ?? true;
      _autoQueen = settings['autoQueen'] as bool? ?? false;
      _flipBoard = settings['flipBoard'] as bool? ?? false;
      _theme = settings['theme'] as String? ?? 'dark';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings({
      'soundEnabled': _soundEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'showLegalMoves': _showLegalMoves,
      'showCoordinates': _showCoordinates,
      'autoQueen': _autoQueen,
      'flipBoard': _flipBoard,
      'theme': _theme,
    });
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all player statistics, game history, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Game Settings
                _buildSectionHeader('Game Settings'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show Legal Moves', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Highlight squares where pieces can move',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _showLegalMoves,
                        onChanged: (value) {
                          setState(() => _showLegalMoves = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Show Coordinates', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Display file (a-h) and rank (1-8) labels',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _showCoordinates,
                        onChanged: (value) {
                          setState(() => _showCoordinates = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Auto Queen', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Automatically promote pawns to queens',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _autoQueen,
                        onChanged: (value) {
                          setState(() => _autoQueen = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Flip Board', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Flip board after each move',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _flipBoard,
                        onChanged: (value) {
                          setState(() => _flipBoard = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sound & Haptics
                _buildSectionHeader('Sound & Haptics'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Sound Effects', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Play sounds for moves and captures',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() => _soundEnabled = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                        secondary: Icon(
                          _soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Vibration', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Vibrate on moves and captures',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() => _vibrationEnabled = value);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                        secondary: Icon(
                          _vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Theme
                _buildSectionHeader('Appearance'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Dark Theme', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Dark background with light squares',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: 'dark',
                        groupValue: _theme,
                        onChanged: (value) {
                          setState(() => _theme = value!);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Light Theme', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Light background with dark squares',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        value: 'light',
                        groupValue: _theme,
                        onChanged: (value) {
                          setState(() => _theme = value!);
                          _saveSettings();
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Data Management
                _buildSectionHeader('Data Management'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                        subtitle: Text(
                          'Delete all players, games, and settings',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        onTap: _showClearDataDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About
                _buildSectionHeader('About'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.grey.shade400),
                        title: const Text('Version', style: TextStyle(color: Colors.white)),
                        trailing: const Text('2.0.0', style: TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.code, color: Colors.grey.shade400),
                        title: const Text('Built with Flutter', style: TextStyle(color: Colors.white)),
                        trailing: Icon(Icons.open_in_new, color: Colors.grey.shade400, size: 16),
                        onTap: () {
                          // Could open Flutter website
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Credits
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Offline Chess',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A fully-featured local multiplayer chess game',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Features:',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '• Complete chess rules with special moves\n'
                        '• ELO rating system\n'
                        '• Game timers with increments\n'
                        '• Move history and PGN export\n'
                        '• Player statistics and leaderboards',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
