import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/player_stats.dart';
import '../models/game_history.dart';

/// Service for persisting and retrieving chess data
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  /// Get the application documents directory
  Future<Directory> get _appDir async {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported for file storage');
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Get the path to the players data file
  Future<String> get _playersPath async {
    final dir = await _appDir;
    return '${dir.path}/chess_players.json';
  }

  /// Get the path to the game history file
  Future<String> get _gameHistoryPath async {
    final dir = await _appDir;
    return '${dir.path}/chess_history.json';
  }

  /// Get the path to the settings file
  Future<String> get _settingsPath async {
    final dir = await _appDir;
    return '${dir.path}/chess_settings.json';
  }

  // ==================== PLAYER STATS ====================

  /// Save player statistics
  Future<void> savePlayerStats(Map<String, PlayerStats> players) async {
    try {
      final file = File(await _playersPath);
      final data = players.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving player stats: $e');
    }
  }

  /// Load player statistics
  Future<Map<String, PlayerStats>> loadPlayerStats() async {
    try {
      final file = File(await _playersPath);
      if (!await file.exists()) {
        return {};
      }
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.map((key, value) => 
        MapEntry(key, PlayerStats.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Error loading player stats: $e');
      return {};
    }
  }

  /// Save a single player's stats
  Future<void> savePlayer(PlayerStats player) async {
    final players = await loadPlayerStats();
    players[player.name] = player;
    await savePlayerStats(players);
  }

  /// Get a player by name
  Future<PlayerStats?> getPlayer(String name) async {
    final players = await loadPlayerStats();
    return players[name];
  }

  /// Create or update a player after a game
  Future<PlayerStats> updatePlayerAfterGame({
    required String playerName,
    required bool isWinner,
    required bool isDraw,
    required int eloChange,
    required int opponentElo,
  }) async {
    final players = await loadPlayerStats();
    var player = players[playerName];
    
    if (player == null) {
      player = PlayerStats(
        name: playerName,
        createdAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
      );
    }

    int newWins = player.wins;
    int newLosses = player.losses;
    int newDraws = player.draws;
    int newCurrentStreak = player.currentStreak;
    int newBestStreak = player.bestStreak;

    if (isWinner) {
      newWins++;
      newCurrentStreak++;
      if (newCurrentStreak > newBestStreak) {
        newBestStreak = newCurrentStreak;
      }
    } else if (isDraw) {
      newDraws++;
      newCurrentStreak = 0;
    } else {
      newLosses++;
      newCurrentStreak = 0;
    }

    final updatedPlayer = player.copyWith(
      eloRating: player.eloRating + eloChange,
      gamesPlayed: player.gamesPlayed + 1,
      wins: newWins,
      losses: newLosses,
      draws: newDraws,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      lastPlayedAt: DateTime.now(),
    );

    players[playerName] = updatedPlayer;
    await savePlayerStats(players);

    return updatedPlayer;
  }

  // ==================== GAME HISTORY ====================

  /// Save game history
  Future<void> saveGameHistory(List<GameRecord> history) async {
    try {
      final file = File(await _gameHistoryPath);
      final data = history.map((g) => g.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving game history: $e');
    }
  }

  /// Load game history
  Future<List<GameRecord>> loadGameHistory() async {
    try {
      final file = File(await _gameHistoryPath);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final data = jsonDecode(content) as List;
      return data.map((g) => GameRecord.fromJson(g as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading game history: $e');
      return [];
    }
  }

  /// Add a game to history
  Future<void> addGameToHistory(GameRecord game) async {
    final history = await loadGameHistory();
    history.insert(0, game); // Add to beginning
    // Keep only last 100 games
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    await saveGameHistory(history);
  }

  /// Get games for a specific player
  Future<List<GameRecord>> getPlayerGames(String playerName) async {
    final history = await loadGameHistory();
    return history.where((g) => 
      g.whitePlayerName == playerName || g.blackPlayerName == playerName
    ).toList();
  }

  /// Get recent games (last N games)
  Future<List<GameRecord>> getRecentGames({int count = 10}) async {
    final history = await loadGameHistory();
    return history.take(count).toList();
  }

  // ==================== SETTINGS ====================

  /// Save settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final file = File(await _settingsPath);
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Load settings
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = File(await _settingsPath);
      if (!await file.exists()) {
        return _defaultSettings();
      }
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return _defaultSettings();
    }
  }

  /// Default settings
  Map<String, dynamic> _defaultSettings() {
    return {
      'whitePlayerName': 'Player 1',
      'blackPlayerName': 'Player 2',
      'timeControl': TimeControl.blitz5.toJson(),
      'showLegalMoves': true,
      'showLastMove': true,
      'showCoordinates': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
      'autoQueen': false,
      'flipBoard': false,
      'theme': 'dark',
    };
  }

  /// Get a specific setting
  Future<T?> getSetting<T>(String key) async {
    final settings = await loadSettings();
    return settings[key] as T?;
  }

  /// Set a specific setting
  Future<void> setSetting(String key, dynamic value) async {
    final settings = await loadSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // ==================== LEADERBOARD ====================

  /// Get leaderboard sorted by ELO rating
  Future<List<PlayerStats>> getLeaderboard({int limit = 10}) async {
    final players = await loadPlayerStats();
    final sorted = players.values.toList()
      ..sort((a, b) => b.eloRating.compareTo(a.eloRating));
    return sorted.take(limit).toList();
  }

  /// Get leaderboard sorted by win rate
  Future<List<PlayerStats>> getLeaderboardByWinRate({int limit = 10}) async {
    final players = await loadPlayerStats();
    final sorted = players.values.toList()
      ..sort((a, b) => b.winRate.compareTo(a.winRate));
    return sorted.take(limit).toList();
  }

  /// Get leaderboard sorted by total games
  Future<List<PlayerStats>> getLeaderboardByGames({int limit = 10}) async {
    final players = await loadPlayerStats();
    final sorted = players.values.toList()
      ..sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
    return sorted.take(limit).toList();
  }

  // ==================== STATISTICS ====================

  /// Get overall statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    final players = await loadPlayerStats();
    final games = await loadGameHistory();

    int totalGames = games.length;
    int whiteWins = games.where((g) => g.result == GameResult.whiteWins).length;
    int blackWins = games.where((g) => g.result == GameResult.blackWins).length;
    int draws = games.where((g) => g.result == GameResult.draw).length;

    double avgElo = 0;
    if (players.isNotEmpty) {
      avgElo = players.values.map((p) => p.eloRating).reduce((a, b) => a + b) / players.length;
    }

    return {
      'totalPlayers': players.length,
      'totalGames': totalGames,
      'whiteWins': whiteWins,
      'blackWins': blackWins,
      'draws': draws,
      'averageElo': avgElo,
      'highestElo': players.isEmpty ? 0 : players.values.map((p) => p.eloRating).reduce((a, b) => a > b ? a : b),
      'mostGames': players.isEmpty ? null : players.values.reduce((a, b) => a.gamesPlayed > b.gamesPlayed ? a : b),
      'bestWinRate': players.isEmpty ? null : players.values.where((p) => p.gamesPlayed >= 5).reduce((a, b) => a.winRate > b.winRate ? a : b),
    };
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final playersFile = File(await _playersPath);
      final historyFile = File(await _gameHistoryPath);
      final settingsFile = File(await _settingsPath);

      if (await playersFile.exists()) await playersFile.delete();
      if (await historyFile.exists()) await historyFile.delete();
      if (await settingsFile.exists()) await settingsFile.delete();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}
