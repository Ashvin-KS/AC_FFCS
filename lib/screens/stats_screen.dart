import 'package:flutter/material.dart';
import '../models/player_stats.dart';
import '../models/game_history.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlayerStats> _playersByElo = [];
  List<PlayerStats> _playersByWinRate = [];
  List<GameRecord> _recentGames = [];
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final byElo = await StorageService.instance.getLeaderboard(limit: 20);
    final byWinRate = await StorageService.instance.getLeaderboardByWinRate(limit: 20);
    final games = await StorageService.instance.getRecentGames(count: 20);
    final stats = await StorageService.instance.getOverallStats();
    
    setState(() {
      _playersByElo = byElo;
      _playersByWinRate = byWinRate;
      _recentGames = games;
      _overallStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Leaderboard'),
            Tab(text: 'Game History'),
            Tab(text: 'Overview'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(),
                _buildHistoryTab(),
                _buildOverviewTab(),
              ],
            ),
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // By ELO Rating
        const Text(
          'By ELO Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (_playersByElo.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No players yet. Play some games!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _playersByElo.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return _buildPlayerListTile(index, player);
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 24),
        
        // By Win Rate
        const Text(
          'By Win Rate (min 5 games)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (_playersByWinRate.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No players with 5+ games yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _playersByWinRate.where((p) => p.gamesPlayed >= 5).take(10).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return _buildPlayerListTile(index, player, showWinRate: true);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerListTile(int index, PlayerStats player, {bool showWinRate = false}) {
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
            showWinRate ? '${player.winRate.toStringAsFixed(1)}%' : '${player.eloRating}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            showWinRate 
                ? EloCalculator.getRatingCategory(player.eloRating)
                : '${player.gamesPlayed} games',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_recentGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No games played yet',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentGames.length,
      itemBuilder: (context, index) {
        final game = _recentGames[index];
        return _buildGameCard(game);
      },
    );
  }

  Widget _buildGameCard(GameRecord game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Players and result
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        game.whitePlayerName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${game.whitePlayerElo}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: game.result == GameResult.whiteWins
                        ? Colors.white.withOpacity(0.2)
                        : game.result == GameResult.blackWins
                            ? Colors.black.withOpacity(0.3)
                            : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.resultDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        game.blackPlayerName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${game.blackPlayerElo}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Game info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      game.timeControl.displayName,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${game.totalMoves} moves',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  game.endReasonDescription,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Date
            Text(
              _formatDate(game.playedAt),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewStat(
                      icon: Icons.people,
                      label: 'Total Players',
                      value: '${_overallStats['totalPlayers'] ?? 0}',
                    ),
                    _buildOverviewStat(
                      icon: Icons.games,
                      label: 'Total Games',
                      value: '${_overallStats['totalGames'] ?? 0}',
                    ),
                    _buildOverviewStat(
                      icon: Icons.star,
                      label: 'Avg ELO',
                      value: (_overallStats['averageElo'] as double?)?.toStringAsFixed(0) ?? '0',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Game outcomes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Game Outcomes',
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
                      child: _buildOutcomeBar(
                        'White Wins',
                        _overallStats['whiteWins'] ?? 0,
                        Colors.white,
                        _overallStats['totalGames'] ?? 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOutcomeBar(
                        'Black Wins',
                        _overallStats['blackWins'] ?? 0,
                        Colors.black,
                        _overallStats['totalGames'] ?? 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOutcomeBar(
                        'Draws',
                        _overallStats['draws'] ?? 0,
                        Colors.amber,
                        _overallStats['totalGames'] ?? 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Records
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (_overallStats['highestElo'] != null && _overallStats['highestElo'] > 0)
                  _buildRecordRow(
                    'Highest ELO',
                    '${_overallStats['highestElo']}',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                if (_overallStats['mostGames'] != null)
                  _buildRecordRow(
                    'Most Games',
                    '${(_overallStats['mostGames'] as PlayerStats).name} (${(_overallStats['mostGames'] as PlayerStats).gamesPlayed})',
                    Icons.games,
                    Colors.blue,
                  ),
                if (_overallStats['bestWinRate'] != null)
                  _buildRecordRow(
                    'Best Win Rate',
                    '${(_overallStats['bestWinRate'] as PlayerStats).name} (${(_overallStats['bestWinRate'] as PlayerStats).winRate.toStringAsFixed(1)}%)',
                    Icons.trending_up,
                    Colors.green,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade400, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOutcomeBar(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade700,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildRecordRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade400)),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
