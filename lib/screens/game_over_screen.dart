import 'package:flutter/material.dart';
import '../models/player_stats.dart';
import '../models/game_history.dart' as history;
import '../services/storage_service.dart';
import 'home_screen.dart';

class GameOverScreen extends StatefulWidget {
  final history.GameResult result;
  final history.GameEndReason endReason;
  final String whitePlayerName;
  final String blackPlayerName;
  final PlayerStats? whitePlayerStats;
  final PlayerStats? blackPlayerStats;
  final List<history.MoveRecord> moves;
  final history.TimeControl timeControl;
  final Duration whiteTimeRemaining;
  final Duration blackTimeRemaining;

  const GameOverScreen({
    super.key,
    required this.result,
    required this.endReason,
    required this.whitePlayerName,
    required this.blackPlayerName,
    this.whitePlayerStats,
    this.blackPlayerStats,
    required this.moves,
    required this.timeControl,
    required this.whiteTimeRemaining,
    required this.blackTimeRemaining,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _isSaving = false;
  bool _saved = false;
  int? _whiteEloChange;
  int? _blackEloChange;
  PlayerStats? _updatedWhiteStats;
  PlayerStats? _updatedBlackStats;

  @override
  void initState() {
    super.initState();
    _calculateEloChanges();
  }

  void _calculateEloChanges() {
    final whiteElo = widget.whitePlayerStats?.eloRating ?? 1200;
    final blackElo = widget.blackPlayerStats?.eloRating ?? 1200;

    double whiteScore;
    switch (widget.result) {
      case history.GameResult.whiteWins:
        whiteScore = 1.0;
        break;
      case history.GameResult.blackWins:
        whiteScore = 0.0;
        break;
      case history.GameResult.draw:
        whiteScore = 0.5;
        break;
    }

    final (newWhiteElo, newBlackElo) = EloCalculator.calculateRatingChanges(
      whiteRating: whiteElo,
      blackRating: blackElo,
      whiteScore: whiteScore,
    );

    _whiteEloChange = newWhiteElo - whiteElo;
    _blackEloChange = newBlackElo - blackElo;
  }

  Future<void> _saveGame() async {
    if (_saved || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update player stats
      final isWhiteWinner = widget.result == history.GameResult.whiteWins;
      final isDraw = widget.result == history.GameResult.draw;

      _updatedWhiteStats = await StorageService.instance.updatePlayerAfterGame(
        playerName: widget.whitePlayerName,
        isWinner: isWhiteWinner,
        isDraw: isDraw,
        eloChange: _whiteEloChange!,
        opponentElo: widget.blackPlayerStats?.eloRating ?? 1200,
      );

      _updatedBlackStats = await StorageService.instance.updatePlayerAfterGame(
        playerName: widget.blackPlayerName,
        isWinner: !isWhiteWinner && !isDraw,
        isDraw: isDraw,
        eloChange: _blackEloChange!,
        opponentElo: widget.whitePlayerStats?.eloRating ?? 1200,
      );

      // Create game record
      final gameRecord = history.GameRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        playedAt: DateTime.now(),
        whitePlayerName: widget.whitePlayerName,
        blackPlayerName: widget.blackPlayerName,
        whitePlayerElo: widget.whitePlayerStats?.eloRating ?? 1200,
        blackPlayerElo: widget.blackPlayerStats?.eloRating ?? 1200,
        whitePlayerEloChange: _whiteEloChange,
        blackPlayerEloChange: _blackEloChange,
        result: widget.result,
        endReason: widget.endReason,
        moves: widget.moves,
        timeControl: widget.timeControl,
        whiteTimeRemaining: widget.whiteTimeRemaining,
        blackTimeRemaining: widget.blackTimeRemaining,
      );

      await StorageService.instance.addGameToHistory(gameRecord);

      setState(() {
        _saved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving game: $e')),
        );
      }
    }
  }

  String _getResultText() {
    switch (widget.result) {
      case history.GameResult.whiteWins:
        return '${widget.whitePlayerName} Wins!';
      case history.GameResult.blackWins:
        return '${widget.blackPlayerName} Wins!';
      case history.GameResult.draw:
        return 'Draw!';
    }
  }

  String _getEndReasonText() {
    switch (widget.endReason) {
      case history.GameEndReason.checkmate:
        return 'by Checkmate';
      case history.GameEndReason.stalemate:
        return 'by Stalemate';
      case history.GameEndReason.insufficientMaterial:
        return 'by Insufficient Material';
      case history.GameEndReason.fiftyMoveRule:
        return 'by 50-Move Rule';
      case history.GameEndReason.threefoldRepetition:
        return 'by Threefold Repetition';
      case history.GameEndReason.resignation:
        return 'by Resignation';
      case history.GameEndReason.timeOut:
        return 'on Time';
      case history.GameEndReason.agreement:
        return 'by Agreement';
    }
  }

  IconData _getResultIcon() {
    switch (widget.result) {
      case history.GameResult.whiteWins:
        return Icons.emoji_events;
      case history.GameResult.blackWins:
        return Icons.emoji_events;
      case history.GameResult.draw:
        return Icons.handshake;
    }
  }

  Color _getResultColor() {
    switch (widget.result) {
      case history.GameResult.whiteWins:
        return Colors.white;
      case history.GameResult.blackWins:
        return Colors.black;
      case history.GameResult.draw:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Result banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getResultIcon(),
                      size: 64,
                      color: _getResultColor(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getResultText(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEndReasonText(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ELO changes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating Changes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPlayerEloCard(
                          name: widget.whitePlayerName,
                          currentElo: widget.whitePlayerStats?.eloRating ?? 1200,
                          eloChange: _whiteEloChange ?? 0,
                          isWhite: true,
                          updatedStats: _updatedWhiteStats,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.result == history.GameResult.draw ? '½-½' :
                            widget.result == history.GameResult.whiteWins ? '1-0' : '0-1',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildPlayerEloCard(
                          name: widget.blackPlayerName,
                          currentElo: widget.blackPlayerStats?.eloRating ?? 1200,
                          eloChange: _blackEloChange ?? 0,
                          isWhite: false,
                          updatedStats: _updatedBlackStats,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Game summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Game Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Moves', '${widget.moves.length}'),
                    _buildSummaryRow('Time Control', widget.timeControl.displayName),
                    _buildSummaryRow('Category', widget.timeControl.category),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Move list
              if (widget.moves.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moves',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.moves.length,
                          itemBuilder: (context, index) {
                            final move = widget.moves[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${move.moveNumber}.',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      move.whiteMove,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  if (move.blackMove != null)
                                    Text(
                                      move.blackMove!,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : (_saved ? null : _saveGame),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_saved ? Icons.check : Icons.save),
                      label: Text(_saved ? 'Saved' : 'Save Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _saved ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // New game button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerEloCard({
    required String name,
    required int currentElo,
    required int eloChange,
    required bool isWhite,
    required PlayerStats? updatedStats,
  }) {
    final changeColor = eloChange > 0 ? Colors.green : (eloChange < 0 ? Colors.red : Colors.grey);
    final changeText = eloChange > 0 ? '+$eloChange' : eloChange.toString();

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isWhite ? Colors.white : Colors.black,
          child: Icon(
            Icons.person,
            color: isWhite ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${updatedStats?.eloRating ?? currentElo}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                changeText,
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (updatedStats != null)
          Text(
            EloCalculator.getRatingCategory(updatedStats.eloRating),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade400),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
