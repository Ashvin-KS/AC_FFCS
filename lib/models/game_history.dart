import 'chess_move.dart';
import 'chess_piece.dart';
import 'player_stats.dart';

/// Represents a single move in a game record
class MoveRecord {
  final int moveNumber;
  final String whiteMove; // Algebraic notation
  final String? blackMove;
  final Duration? whiteTimeRemaining;
  final Duration? blackTimeRemaining;

  const MoveRecord({
    required this.moveNumber,
    required this.whiteMove,
    this.blackMove,
    this.whiteTimeRemaining,
    this.blackTimeRemaining,
  });

  Map<String, dynamic> toJson() {
    return {
      'moveNumber': moveNumber,
      'whiteMove': whiteMove,
      'blackMove': blackMove,
      'whiteTimeRemaining': whiteTimeRemaining?.inSeconds,
      'blackTimeRemaining': blackTimeRemaining?.inSeconds,
    };
  }

  factory MoveRecord.fromJson(Map<String, dynamic> json) {
    return MoveRecord(
      moveNumber: json['moveNumber'] as int,
      whiteMove: json['whiteMove'] as String,
      blackMove: json['blackMove'] as String?,
      whiteTimeRemaining: json['whiteTimeRemaining'] != null
          ? Duration(seconds: json['whiteTimeRemaining'] as int)
          : null,
      blackTimeRemaining: json['blackTimeRemaining'] != null
          ? Duration(seconds: json['blackTimeRemaining'] as int)
          : null,
    );
  }
}

/// Result of a completed game
enum GameResult {
  whiteWins,
  blackWins,
  draw,
}

/// Reason for game ending
enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,
  fiftyMoveRule,
  threefoldRepetition,
  resignation,
  timeOut,
  agreement,
}

/// Time control settings
class TimeControl {
  final Duration initialTime;
  final Duration? increment; // Time added per move

  const TimeControl({
    required this.initialTime,
    this.increment,
  });

  /// Standard time controls
  static const TimeControl bullet1 = TimeControl(
    initialTime: Duration(minutes: 1),
    increment: Duration(seconds: 1),
  );

  static const TimeControl bullet2 = TimeControl(
    initialTime: Duration(minutes: 2),
    increment: Duration(seconds: 1),
  );

  static const TimeControl blitz3 = TimeControl(
    initialTime: Duration(minutes: 3),
    increment: Duration.zero,
  );

  static const TimeControl blitz5 = TimeControl(
    initialTime: Duration(minutes: 5),
    increment: Duration(seconds: 3),
  );

  static const TimeControl rapid10 = TimeControl(
    initialTime: Duration(minutes: 10),
    increment: Duration(seconds: 5),
  );

  static const TimeControl rapid15 = TimeControl(
    initialTime: Duration(minutes: 15),
    increment: Duration(seconds: 10),
  );

  static const TimeControl classical30 = TimeControl(
    initialTime: Duration(minutes: 30),
    increment: Duration.zero,
  );

  static const TimeControl unlimited = TimeControl(
    initialTime: Duration(hours: 24),
  );

  String get displayName {
    final minutes = initialTime.inMinutes;
    final incrementSec = increment?.inSeconds ?? 0;
    
    if (initialTime >= const Duration(hours: 1)) {
      return 'Unlimited';
    }
    
    if (incrementSec > 0) {
      return '$minutes+$incrementSec';
    }
    return '$minutes min';
  }

  String get category {
    final minutes = initialTime.inMinutes;
    if (minutes < 3) return 'Bullet';
    if (minutes < 10) return 'Blitz';
    if (minutes < 30) return 'Rapid';
    return 'Classical';
  }

  Map<String, dynamic> toJson() {
    return {
      'initialTime': initialTime.inSeconds,
      'increment': increment?.inSeconds,
    };
  }

  factory TimeControl.fromJson(Map<String, dynamic> json) {
    return TimeControl(
      initialTime: Duration(seconds: json['initialTime'] as int),
      increment: json['increment'] != null
          ? Duration(seconds: json['increment'] as int)
          : null,
    );
  }
}

/// Complete record of a played game
class GameRecord {
  final String id;
  final DateTime playedAt;
  final String whitePlayerName;
  final String blackPlayerName;
  final int whitePlayerElo;
  final int blackPlayerElo;
  final int? whitePlayerEloChange;
  final int? blackPlayerEloChange;
  final GameResult result;
  final GameEndReason endReason;
  final List<MoveRecord> moves;
  final TimeControl timeControl;
  final Duration? whiteTimeRemaining;
  final Duration? blackTimeRemaining;
  final String? pgn; // Portable Game Notation

  const GameRecord({
    required this.id,
    required this.playedAt,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.whitePlayerElo,
    required this.blackPlayerElo,
    this.whitePlayerEloChange,
    this.blackPlayerEloChange,
    required this.result,
    required this.endReason,
    required this.moves,
    required this.timeControl,
    this.whiteTimeRemaining,
    this.blackTimeRemaining,
    this.pgn,
  });

  /// Get total number of moves
  int get totalMoves {
    if (moves.isEmpty) return 0;
    final lastMove = moves.last;
    return lastMove.blackMove != null ? lastMove.moveNumber : lastMove.moveNumber - 1;
  }

  /// Get game duration
  Duration get gameDuration {
    return timeControl.initialTime * 2 - 
           (whiteTimeRemaining ?? Duration.zero) - 
           (blackTimeRemaining ?? Duration.zero);
  }

  /// Get winner name (null for draw)
  String? get winnerName {
    switch (result) {
      case GameResult.whiteWins:
        return whitePlayerName;
      case GameResult.blackWins:
        return blackPlayerName;
      case GameResult.draw:
        return null;
    }
  }

  /// Get result description
  String get resultDescription {
    switch (result) {
      case GameResult.whiteWins:
        return '1-0';
      case GameResult.blackWins:
        return '0-1';
      case GameResult.draw:
        return '½-½';
    }
  }

  /// Get end reason description
  String get endReasonDescription {
    switch (endReason) {
      case GameEndReason.checkmate:
        return 'Checkmate';
      case GameEndReason.stalemate:
        return 'Stalemate';
      case GameEndReason.insufficientMaterial:
        return 'Insufficient material';
      case GameEndReason.fiftyMoveRule:
        return '50-move rule';
      case GameEndReason.threefoldRepetition:
        return 'Threefold repetition';
      case GameEndReason.resignation:
        return 'Resignation';
      case GameEndReason.timeOut:
        return 'Time out';
      case GameEndReason.agreement:
        return 'Draw by agreement';
    }
  }

  /// Generate PGN notation
  String generatePGN() {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln('[Event "Offline Chess"]');
    buffer.writeln('[Site "Local"]');
    buffer.writeln('[Date "${_formatDate(playedAt)}"]');
    buffer.writeln('[Round "1"]');
    buffer.writeln('[White "$whitePlayerName"]');
    buffer.writeln('[Black "$blackPlayerName"]');
    buffer.writeln('[WhiteElo "$whitePlayerElo"]');
    buffer.writeln('[BlackElo "$blackPlayerElo"]');
    buffer.writeln('[Result "$resultDescription"]');
    buffer.writeln('[TimeControl "${timeControl.displayName}"]');
    buffer.writeln('[Termination "${endReasonDescription}"]');
    buffer.writeln();
    
    // Moves
    for (final move in moves) {
      buffer.write('${move.moveNumber}. ${move.whiteMove}');
      if (move.blackMove != null) {
        buffer.write(' ${move.blackMove}');
      }
      buffer.write(' ');
    }
    
    buffer.write(resultDescription);
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playedAt': playedAt.toIso8601String(),
      'whitePlayerName': whitePlayerName,
      'blackPlayerName': blackPlayerName,
      'whitePlayerElo': whitePlayerElo,
      'blackPlayerElo': blackPlayerElo,
      'whitePlayerEloChange': whitePlayerEloChange,
      'blackPlayerEloChange': blackPlayerEloChange,
      'result': result.index,
      'endReason': endReason.index,
      'moves': moves.map((m) => m.toJson()).toList(),
      'timeControl': timeControl.toJson(),
      'whiteTimeRemaining': whiteTimeRemaining?.inSeconds,
      'blackTimeRemaining': blackTimeRemaining?.inSeconds,
      'pgn': pgn,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      whitePlayerName: json['whitePlayerName'] as String,
      blackPlayerName: json['blackPlayerName'] as String,
      whitePlayerElo: json['whitePlayerElo'] as int,
      blackPlayerElo: json['blackPlayerElo'] as int,
      whitePlayerEloChange: json['whitePlayerEloChange'] as int?,
      blackPlayerEloChange: json['blackPlayerEloChange'] as int?,
      result: GameResult.values[json['result'] as int],
      endReason: GameEndReason.values[json['endReason'] as int],
      moves: (json['moves'] as List).map((m) => MoveRecord.fromJson(m as Map<String, dynamic>)).toList(),
      timeControl: TimeControl.fromJson(json['timeControl'] as Map<String, dynamic>),
      whiteTimeRemaining: json['whiteTimeRemaining'] != null
          ? Duration(seconds: json['whiteTimeRemaining'] as int)
          : null,
      blackTimeRemaining: json['blackTimeRemaining'] != null
          ? Duration(seconds: json['blackTimeRemaining'] as int)
          : null,
      pgn: json['pgn'] as String?,
    );
  }
}

/// Move notation helper
class MoveNotation {
  /// Convert a move to standard algebraic notation
  static String toSAN({
    required ChessPieceType pieceType,
    required int fromIndex,
    required int toIndex,
    required bool isCapture,
    required bool isCheck,
    required bool isCheckmate,
    required bool isCastling,
    required bool isKingside,
    required String? promotion,
    required bool isEnPassant,
    required List<int> ambiguousFromSquares,
  }) {
    if (isCastling) {
      String notation = isKingside ? 'O-O' : 'O-O-O';
      if (isCheckmate) notation += '#';
      else if (isCheck) notation += '+';
      return notation;
    }

    final buffer = StringBuffer();
    
    // Piece letter (except for pawns)
    if (pieceType != ChessPieceType.pawn) {
      buffer.write(_getPieceLetter(pieceType));
    }
    
    // Disambiguation
    if (ambiguousFromSquares.isNotEmpty) {
      final fromCol = ChessMove.getCol(fromIndex);
      final fromRow = ChessMove.getRow(fromIndex);
      
      final sameCol = ambiguousFromSquares.any((i) => ChessMove.getCol(i) == fromCol);
      final sameRow = ambiguousFromSquares.any((i) => ChessMove.getRow(i) == fromRow);
      
      if (!sameCol) {
        buffer.write(String.fromCharCode(97 + fromCol));
      } else if (!sameRow) {
        buffer.write(8 - fromRow);
      } else {
        buffer.write(String.fromCharCode(97 + fromCol));
        buffer.write(8 - fromRow);
      }
    }
    
    // Capture
    if (isCapture) {
      if (pieceType == ChessPieceType.pawn) {
        buffer.write(String.fromCharCode(97 + ChessMove.getCol(fromIndex)));
      }
      buffer.write('x');
    }
    
    // Destination square
    final toCol = String.fromCharCode(97 + ChessMove.getCol(toIndex));
    final toRow = 8 - ChessMove.getRow(toIndex);
    buffer.write('$toCol$toRow');
    
    // Promotion
    if (promotion != null) {
      buffer.write('=$promotion');
    }
    
    // En passant
    if (isEnPassant) {
      buffer.write(' e.p.');
    }
    
    // Check/Checkmate
    if (isCheckmate) {
      buffer.write('#');
    } else if (isCheck) {
      buffer.write('+');
    }
    
    return buffer.toString();
  }

  static String _getPieceLetter(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.king:
        return 'K';
      case ChessPieceType.queen:
        return 'Q';
      case ChessPieceType.rook:
        return 'R';
      case ChessPieceType.bishop:
        return 'B';
      case ChessPieceType.knight:
        return 'N';
      case ChessPieceType.pawn:
        return '';
    }
  }
}
