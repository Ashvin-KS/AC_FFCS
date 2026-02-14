/// Player statistics model for tracking chess performance
class PlayerStats {
  final String name;
  final int eloRating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;
  final DateTime lastPlayedAt;

  const PlayerStats({
    required this.name,
    this.eloRating = 1200,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
    required this.lastPlayedAt,
  });

  /// Calculate win rate as a percentage
  double get winRate {
    if (gamesPlayed == 0) return 0.0;
    return (wins / gamesPlayed) * 100;
  }

  /// Calculate performance rating based on results
  double get performanceRating {
    if (gamesPlayed == 0) return eloRating.toDouble();
    // Simple performance metric
    final scorePercentage = (wins + draws * 0.5) / gamesPlayed;
    return eloRating * (0.5 + scorePercentage);
  }

  /// Get total points (1 for win, 0.5 for draw)
  double get totalPoints => wins.toDouble() + (draws * 0.5);

  /// Copy with new values
  PlayerStats copyWith({
    String? name,
    int? eloRating,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
  }) {
    return PlayerStats(
      name: name ?? this.name,
      eloRating: eloRating ?? this.eloRating,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'eloRating': eloRating,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      name: json['name'] as String,
      eloRating: json['eloRating'] as int? ?? 1200,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'PlayerStats(name: $name, elo: $eloRating, games: $gamesPlayed, wins: $wins, losses: $losses, draws: $draws)';
  }
}

/// ELO rating calculator using the standard formula
class EloCalculator {
  /// K-factor determines how much ratings change per game
  /// Higher K-factor = more volatile ratings
  static const double defaultKFactor = 32.0;

  /// Calculate expected score for a player against an opponent
  /// Returns a value between 0 and 1
  static double expectedScore(int playerRating, int opponentRating) {
    return 1.0 / (1.0 + pow(10, (opponentRating - playerRating) / 400.0));
  }

  /// Calculate new rating after a game
  /// actualScore: 1 for win, 0.5 for draw, 0 for loss
  static int calculateNewRating({
    required int currentRating,
    required int opponentRating,
    required double actualScore,
    double kFactor = defaultKFactor,
  }) {
    final expected = expectedScore(currentRating, opponentRating);
    final change = kFactor * (actualScore - expected);
    return (currentRating + change).round();
  }

  /// Calculate rating changes for both players after a game
  /// Returns (whiteNewRating, blackNewRating)
  static (int, int) calculateRatingChanges({
    required int whiteRating,
    required int blackRating,
    required double whiteScore, // 1 for win, 0.5 for draw, 0 for loss
    double kFactor = defaultKFactor,
  }) {
    final newWhiteRating = calculateNewRating(
      currentRating: whiteRating,
      opponentRating: blackRating,
      actualScore: whiteScore,
      kFactor: kFactor,
    );

    final newBlackRating = calculateNewRating(
      currentRating: blackRating,
      opponentRating: whiteRating,
      actualScore: 1.0 - whiteScore,
      kFactor: kFactor,
    );

    return (newWhiteRating, newBlackRating);
  }

  /// Get rating category based on ELO
  static String getRatingCategory(int rating) {
    if (rating < 1000) return 'Beginner';
    if (rating < 1200) return 'Novice';
    if (rating < 1400) return 'Intermediate';
    if (rating < 1600) return 'Advanced';
    if (rating < 1800) return 'Expert';
    if (rating < 2000) return 'Candidate Master';
    if (rating < 2200) return 'Master';
    if (rating < 2400) return 'Senior Master';
    return 'Grandmaster';
  }

  /// Get rating change description
  static String getRatingChangeDescription(int change) {
    if (change > 0) return '+$change';
    return change.toString();
  }
}

/// Helper function for power calculation (dart:math pow returns num)
double pow(double base, double exponent) {
  if (exponent == 0) return 1;
  if (exponent == 1) return base;
  
  double result = 1;
  final absExponent = exponent.abs();
  
  for (int i = 0; i < absExponent.toInt(); i++) {
    result *= base;
  }
  
  // Handle fractional part approximately
  final fractional = absExponent - absExponent.toInt();
  if (fractional > 0) {
    result *= base * fractional + (1 - fractional);
  }
  
  return exponent < 0 ? 1 / result : result;
}
