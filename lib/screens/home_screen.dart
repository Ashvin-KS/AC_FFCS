import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../models/game_history.dart';
import '../models/player_stats.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _whitePlayerController = TextEditingController(text: 'Player 1');
  final _blackPlayerController = TextEditingController(text: 'Player 2');
  TimeControl _selectedTimeControl = TimeControl.blitz5;
  bool _showLegalMoves = true;
  bool _showCoordinates = true;
  
  List<PlayerStats> _leaderboard = [];
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final leaderboard = await StorageService.instance.getLeaderboard(limit: 5);
    final stats = await StorageService.instance.getOverallStats();
    final settings = await StorageService.instance.loadSettings();
    
    setState(() {
      _leaderboard = leaderboard;
      _overallStats = stats;
      _isLoading = false;
      _whitePlayerController.text = settings['whitePlayerName'] as String? ?? 'Player 1';
      _blackPlayerController.text = settings['blackPlayerName'] as String? ?? 'Player 2';
      _showLegalMoves = settings['showLegalMoves'] as bool? ?? true;
      _showCoordinates = settings['showCoordinates'] as bool? ?? true;
      
      if (settings['timeControl'] != null) {
        _selectedTimeControl = TimeControl.fromJson(settings['timeControl'] as Map<String, dynamic>);
      }
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings({
      'whitePlayerName': _whitePlayerController.text,
      'blackPlayerName': _blackPlayerController.text,
      'timeControl': _selectedTimeControl.toJson(),
      'showLegalMoves': _showLegalMoves,
      'showCoordinates': _showCoordinates,
    });
  }

  void _startGame() {
    _saveSettings();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          whitePlayerName: _whitePlayerController.text,
          blackPlayerName: _blackPlayerController.text,
          timeControl: _selectedTimeControl,
          showLegalMoves: _showLegalMoves,
          showCoordinates: _showCoordinates,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _showTimeControlPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeControlChip(TimeControl.bullet1, '1+1', 'Bullet'),
                _buildTimeControlChip(TimeControl.bullet2, '2+1', 'Bullet'),
                _buildTimeControlChip(TimeControl.blitz3, '3 min', 'Blitz'),
                _buildTimeControlChip(TimeControl.blitz5, '5+3', 'Blitz'),
                _buildTimeControlChip(TimeControl.rapid10, '10+5', 'Rapid'),
                _buildTimeControlChip(TimeControl.rapid15, '15+10', 'Rapid'),
                _buildTimeControlChip(TimeControl.classical30, '30 min', 'Classical'),
                _buildTimeControlChip(TimeControl.unlimited, 'Unlimited', 'No limit'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeControlChip(TimeControl timeControl, String label, String category) {
    final isSelected = _selectedTimeControl.initialTime == timeControl.initialTime &&
        _selectedTimeControl.increment == timeControl.increment;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeControl = timeControl);
        Navigator.pop(context);
      },
      backgroundColor: Colors.grey.shade700,
      selectedColor: Colors.green.shade600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade300,
      ),
      avatar: Text(
        category[0],
        style: TextStyle(
          fontSize: 10,
          color: isSelected ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.gamepad,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Offline Chess',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1v1 Local Multiplayer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Player setup
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Players',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _whitePlayerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'White Player',
                                    labelStyle: TextStyle(color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.grey.shade700,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('vs', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _blackPlayerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Black Player',
                                    labelStyle: TextStyle(color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                                    filled: true,
                                    fillColor: Colors.grey.shade700,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time control
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Time Control',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showTimeControlPicker,
                                icon: const Icon(Icons.edit, size: 18),
                                label: Text(_selectedTimeControl.displayName),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _selectedTimeControl.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTimeControl.increment != null
                                    ? '${_selectedTimeControl.initialTime.inMinutes} min + ${_selectedTimeControl.increment!.inSeconds} sec/move'
                                    : '${_selectedTimeControl.initialTime.inMinutes} minutes',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick settings
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Game Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Show Legal Moves', style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                              'Highlight squares where pieces can move',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            value: _showLegalMoves,
                            onChanged: (value) => setState(() => _showLegalMoves = value),
                            activeColor: Colors.green,
                          ),
                          SwitchListTile(
                            title: const Text('Show Coordinates', style: TextStyle(color: Colors.white)),
                            subtitle: Text(
                              'Display file (a-h) and rank (1-8) labels',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            value: _showCoordinates,
                            onChanged: (value) => setState(() => _showCoordinates = value),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Start game button
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Start Game',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats overview
                    if (_overallStats.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Statistics',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const StatsScreen()),
                                    ).then((_) => _loadData());
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.people,
                                  label: 'Players',
                                  value: '${_overallStats['totalPlayers'] ?? 0}',
                                ),
                                _buildStatItem(
                                  icon: Icons.games,
                                  label: 'Games',
                                  value: '${_overallStats['totalGames'] ?? 0}',
                                ),
                                _buildStatItem(
                                  icon: Icons.emoji_events,
                                  label: 'Highest ELO',
                                  value: '${_overallStats['highestElo'] ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Leaderboard preview
                    if (_leaderboard.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Players',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._leaderboard.asMap().entries.map((entry) {
                              final index = entry.key;
                              final player = entry.value;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: index == 0
                                      ? Colors.amber
                                      : index == 1
                                          ? Colors.grey.shade400
                                          : index == 2
                                              ? Colors.brown
                                              : Colors.grey.shade700,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  'W: ${player.wins} | L: ${player.losses} | D: ${player.draws}',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${player.eloRating}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      EloCalculator.getRatingCategory(player.eloRating),
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Bottom actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StatsScreen()),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('Statistics'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade400, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _whitePlayerController.dispose();
    _blackPlayerController.dispose();
    super.dispose();
  }
}
