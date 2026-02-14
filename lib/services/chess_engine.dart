import 'package:flutter/foundation.dart';
import '../models/chess_piece.dart';
import '../models/chess_move.dart';

/// Result of a game
enum GameResult {
  ongoing,
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

/// Represents the complete state of a chess game
class GameState {
  final List<ChessPiece?> board;
  final bool isWhiteTurn;
  final ChessMove? lastMove;
  final bool whiteKingMoved;
  final bool blackKingMoved;
  final bool whiteRookAMoved; // A-file rook (queenside)
  final bool whiteRookHMoved; // H-file rook (kingside)
  final bool blackRookAMoved;
  final bool blackRookHMoved;
  final int? enPassantTargetIndex; // Square where en passant capture can occur
  final int halfMoveClock; // For 50-move rule
  final int fullMoveNumber;
  final List<String> positionHistory; // For threefold repetition
  final GameResult result;
  final GameEndReason? endReason;
  final bool isInCheck;
  final List<ChessMove> legalMoves;

  const GameState({
    required this.board,
    required this.isWhiteTurn,
    this.lastMove,
    this.whiteKingMoved = false,
    this.blackKingMoved = false,
    this.whiteRookAMoved = false,
    this.whiteRookHMoved = false,
    this.blackRookAMoved = false,
    this.blackRookHMoved = false,
    this.enPassantTargetIndex,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
    this.positionHistory = const [],
    this.result = GameResult.ongoing,
    this.endReason,
    this.isInCheck = false,
    this.legalMoves = const [],
  });

  /// Create initial game state
  factory GameState.initial() {
    final board = List<ChessPiece?>.filled(64, null);

    // Place pawns
    for (int i = 0; i < 8; i++) {
      board[8 + i] = ChessPiece(type: ChessPieceType.pawn, color: ChessPieceColor.black);
      board[48 + i] = ChessPiece(type: ChessPieceType.pawn, color: ChessPieceColor.white);
    }

    // Place rooks
    board[0] = ChessPiece(type: ChessPieceType.rook, color: ChessPieceColor.black);
    board[7] = ChessPiece(type: ChessPieceType.rook, color: ChessPieceColor.black);
    board[56] = ChessPiece(type: ChessPieceType.rook, color: ChessPieceColor.white);
    board[63] = ChessPiece(type: ChessPieceType.rook, color: ChessPieceColor.white);

    // Place knights
    board[1] = ChessPiece(type: ChessPieceType.knight, color: ChessPieceColor.black);
    board[6] = ChessPiece(type: ChessPieceType.knight, color: ChessPieceColor.black);
    board[57] = ChessPiece(type: ChessPieceType.knight, color: ChessPieceColor.white);
    board[62] = ChessPiece(type: ChessPieceType.knight, color: ChessPieceColor.white);

    // Place bishops
    board[2] = ChessPiece(type: ChessPieceType.bishop, color: ChessPieceColor.black);
    board[5] = ChessPiece(type: ChessPieceType.bishop, color: ChessPieceColor.black);
    board[58] = ChessPiece(type: ChessPieceType.bishop, color: ChessPieceColor.white);
    board[61] = ChessPiece(type: ChessPieceType.bishop, color: ChessPieceColor.white);

    // Place queens
    board[3] = ChessPiece(type: ChessPieceType.queen, color: ChessPieceColor.black);
    board[59] = ChessPiece(type: ChessPieceType.queen, color: ChessPieceColor.white);

    // Place kings
    board[4] = ChessPiece(type: ChessPieceType.king, color: ChessPieceColor.black);
    board[60] = ChessPiece(type: ChessPieceType.king, color: ChessPieceColor.white);

    return GameState(
      board: board,
      isWhiteTurn: true,
      legalMoves: ChessEngine.generateAllLegalMoves(board, true, false, false, false, false, false, false, null),
    );
  }

  /// Copy with new values
  GameState copyWith({
    List<ChessPiece?>? board,
    bool? isWhiteTurn,
    ChessMove? lastMove,
    bool? whiteKingMoved,
    bool? blackKingMoved,
    bool? whiteRookAMoved,
    bool? whiteRookHMoved,
    bool? blackRookAMoved,
    bool? blackRookHMoved,
    int? enPassantTargetIndex,
    int? halfMoveClock,
    int? fullMoveNumber,
    List<String>? positionHistory,
    GameResult? result,
    GameEndReason? endReason,
    bool? isInCheck,
    List<ChessMove>? legalMoves,
  }) {
    return GameState(
      board: board ?? this.board,
      isWhiteTurn: isWhiteTurn ?? this.isWhiteTurn,
      lastMove: lastMove ?? this.lastMove,
      whiteKingMoved: whiteKingMoved ?? this.whiteKingMoved,
      blackKingMoved: blackKingMoved ?? this.blackKingMoved,
      whiteRookAMoved: whiteRookAMoved ?? this.whiteRookAMoved,
      whiteRookHMoved: whiteRookHMoved ?? this.whiteRookHMoved,
      blackRookAMoved: blackRookAMoved ?? this.blackRookAMoved,
      blackRookHMoved: blackRookHMoved ?? this.blackRookHMoved,
      enPassantTargetIndex: enPassantTargetIndex,
      halfMoveClock: halfMoveClock ?? this.halfMoveClock,
      fullMoveNumber: fullMoveNumber ?? this.fullMoveNumber,
      positionHistory: positionHistory ?? this.positionHistory,
      result: result ?? this.result,
      endReason: endReason ?? this.endReason,
      isInCheck: isInCheck ?? this.isInCheck,
      legalMoves: legalMoves ?? this.legalMoves,
    );
  }
}

/// Chess engine that handles all game logic
class ChessEngine {
  /// Get all possible moves for a piece at the given index (pseudo-legal)
  static List<ChessMove> getPossibleMovesForPiece(
    List<ChessPiece?> board,
    int index,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    final piece = board[index];
    if (piece == null) return [];

    final row = ChessMove.getRow(index);
    final col = ChessMove.getCol(index);
    final isWhite = piece.color == ChessPieceColor.white;
    final moves = <ChessMove>[];

    switch (piece.type) {
      case ChessPieceType.pawn:
        moves.addAll(_getPawnMoves(board, index, row, col, isWhite, enPassantTargetIndex));
        break;
      case ChessPieceType.rook:
        moves.addAll(_getSlidingMoves(board, index, row, col, isWhite, _rookDirections));
        break;
      case ChessPieceType.knight:
        moves.addAll(_getKnightMoves(board, index, row, col, isWhite));
        break;
      case ChessPieceType.bishop:
        moves.addAll(_getSlidingMoves(board, index, row, col, isWhite, _bishopDirections));
        break;
      case ChessPieceType.queen:
        moves.addAll(_getSlidingMoves(board, index, row, col, isWhite, _queenDirections));
        break;
      case ChessPieceType.king:
        moves.addAll(_getKingMoves(
          board, index, row, col, isWhite,
          whiteKingMoved, blackKingMoved,
          whiteRookAMoved, whiteRookHMoved,
          blackRookAMoved, blackRookHMoved,
        ));
        break;
    }

    return moves;
  }

  static const List<List<int>> _rookDirections = [[0, 1], [0, -1], [1, 0], [-1, 0]];
  static const List<List<int>> _bishopDirections = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
  static const List<List<int>> _queenDirections = [
    [0, 1], [0, -1], [1, 0], [-1, 0],
    [1, 1], [1, -1], [-1, 1], [-1, -1],
  ];
  static const List<List<int>> _knightMoves = [
    [2, 1], [2, -1], [-2, 1], [-2, -1],
    [1, 2], [1, -2], [-1, 2], [-1, -2],
  ];

  /// Get pawn moves including captures, double push, en passant
  static List<ChessMove> _getPawnMoves(
    List<ChessPiece?> board,
    int index,
    int row,
    int col,
    bool isWhite,
    int? enPassantTargetIndex,
  ) {
    final moves = <ChessMove>[];
    final direction = isWhite ? -1 : 1;
    final startRow = isWhite ? 6 : 1;
    final promotionRow = isWhite ? 0 : 7;

    // Single push
    final singlePushRow = row + direction;
    if (ChessMove.isValidPosition(singlePushRow, col)) {
      final singlePushIndex = ChessMove.indexFromPosition(singlePushRow, col);
      if (board[singlePushIndex] == null) {
        if (singlePushRow == promotionRow) {
          // Pawn promotion
          for (final piece in ['q', 'r', 'b', 'n']) {
            moves.add(ChessMove(
              fromIndex: index,
              toIndex: singlePushIndex,
              promotionPiece: piece,
            ));
          }
        } else {
          moves.add(ChessMove(fromIndex: index, toIndex: singlePushIndex));
        }

        // Double push from starting position
        if (row == startRow) {
          final doublePushRow = row + 2 * direction;
          final doublePushIndex = ChessMove.indexFromPosition(doublePushRow, col);
          if (board[doublePushIndex] == null) {
            moves.add(ChessMove(fromIndex: index, toIndex: doublePushIndex));
          }
        }
      }
    }

    // Captures
    for (final captureCol in [col - 1, col + 1]) {
      if (ChessMove.isValidPosition(singlePushRow, captureCol)) {
        final captureIndex = ChessMove.indexFromPosition(singlePushRow, captureCol);
        final targetPiece = board[captureIndex];

        if (targetPiece != null && targetPiece.color != (isWhite ? ChessPieceColor.white : ChessPieceColor.black)) {
          if (singlePushRow == promotionRow) {
            for (final piece in ['q', 'r', 'b', 'n']) {
              moves.add(ChessMove(
                fromIndex: index,
                toIndex: captureIndex,
                promotionPiece: piece,
              ));
            }
          } else {
            moves.add(ChessMove(fromIndex: index, toIndex: captureIndex));
          }
        }

        // En passant
        if (captureIndex == enPassantTargetIndex) {
          moves.add(ChessMove(
            fromIndex: index,
            toIndex: captureIndex,
            isEnPassant: true,
            capturedPieceIndex: ChessMove.indexFromPosition(row, captureCol),
          ));
        }
      }
    }

    return moves;
  }

  /// Get sliding piece moves (rook, bishop, queen)
  static List<ChessMove> _getSlidingMoves(
    List<ChessPiece?> board,
    int index,
    int row,
    int col,
    bool isWhite,
    List<List<int>> directions,
  ) {
    final moves = <ChessMove>[];
    final friendlyColor = isWhite ? ChessPieceColor.white : ChessPieceColor.black;

    for (final dir in directions) {
      int newRow = row + dir[0];
      int newCol = col + dir[1];

      while (ChessMove.isValidPosition(newRow, newCol)) {
        final newIndex = ChessMove.indexFromPosition(newRow, newCol);
        final targetPiece = board[newIndex];

        if (targetPiece == null) {
          moves.add(ChessMove(fromIndex: index, toIndex: newIndex));
        } else {
          if (targetPiece.color != friendlyColor) {
            moves.add(ChessMove(fromIndex: index, toIndex: newIndex));
          }
          break;
        }

        newRow += dir[0];
        newCol += dir[1];
      }
    }

    return moves;
  }

  /// Get knight moves
  static List<ChessMove> _getKnightMoves(
    List<ChessPiece?> board,
    int index,
    int row,
    int col,
    bool isWhite,
  ) {
    final moves = <ChessMove>[];
    final friendlyColor = isWhite ? ChessPieceColor.white : ChessPieceColor.black;

    for (final move in _knightMoves) {
      final newRow = row + move[0];
      final newCol = col + move[1];

      if (ChessMove.isValidPosition(newRow, newCol)) {
        final newIndex = ChessMove.indexFromPosition(newRow, newCol);
        final targetPiece = board[newIndex];

        if (targetPiece == null || targetPiece.color != friendlyColor) {
          moves.add(ChessMove(fromIndex: index, toIndex: newIndex));
        }
      }
    }

    return moves;
  }

  /// Get king moves including castling
  static List<ChessMove> _getKingMoves(
    List<ChessPiece?> board,
    int index,
    int row,
    int col,
    bool isWhite,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
  ) {
    final moves = <ChessMove>[];
    final friendlyColor = isWhite ? ChessPieceColor.white : ChessPieceColor.black;

    // Normal king moves
    for (final dir in _queenDirections) {
      final newRow = row + dir[0];
      final newCol = col + dir[1];

      if (ChessMove.isValidPosition(newRow, newCol)) {
        final newIndex = ChessMove.indexFromPosition(newRow, newCol);
        final targetPiece = board[newIndex];

        if (targetPiece == null || targetPiece.color != friendlyColor) {
          moves.add(ChessMove(fromIndex: index, toIndex: newIndex));
        }
      }
    }

    // Castling
    final kingMoved = isWhite ? whiteKingMoved : blackKingMoved;
    if (!kingMoved && !isSquareAttacked(board, index, !isWhite)) {
      final kingRow = isWhite ? 7 : 0;
      final rookAIndex = ChessMove.indexFromPosition(kingRow, 0);
      final rookHIndex = ChessMove.indexFromPosition(kingRow, 7);

      // Kingside castling
      final rookHMoved = isWhite ? whiteRookHMoved : blackRookHMoved;
      if (!rookHMoved &&
          board[rookHIndex]?.type == ChessPieceType.rook &&
          board[ChessMove.indexFromPosition(kingRow, 5)] == null &&
          board[ChessMove.indexFromPosition(kingRow, 6)] == null &&
          !isSquareAttacked(board, ChessMove.indexFromPosition(kingRow, 5), !isWhite) &&
          !isSquareAttacked(board, ChessMove.indexFromPosition(kingRow, 6), !isWhite)) {
        moves.add(ChessMove(
          fromIndex: index,
          toIndex: ChessMove.indexFromPosition(kingRow, 6),
          isCastling: true,
        ));
      }

      // Queenside castling
      final rookAMoved = isWhite ? whiteRookAMoved : blackRookAMoved;
      if (!rookAMoved &&
          board[rookAIndex]?.type == ChessPieceType.rook &&
          board[ChessMove.indexFromPosition(kingRow, 1)] == null &&
          board[ChessMove.indexFromPosition(kingRow, 2)] == null &&
          board[ChessMove.indexFromPosition(kingRow, 3)] == null &&
          !isSquareAttacked(board, ChessMove.indexFromPosition(kingRow, 2), !isWhite) &&
          !isSquareAttacked(board, ChessMove.indexFromPosition(kingRow, 3), !isWhite)) {
        moves.add(ChessMove(
          fromIndex: index,
          toIndex: ChessMove.indexFromPosition(kingRow, 2),
          isCastling: true,
        ));
      }
    }

    return moves;
  }

  /// Check if a square is attacked by the opponent
  static bool isSquareAttacked(List<ChessPiece?> board, int index, bool byWhite) {
    final row = ChessMove.getRow(index);
    final col = ChessMove.getCol(index);
    final attackerColor = byWhite ? ChessPieceColor.white : ChessPieceColor.black;

    // Check for pawn attacks
    final pawnDirection = byWhite ? 1 : -1;
    for (final pawnCol in [col - 1, col + 1]) {
      final pawnRow = row + pawnDirection;
      if (ChessMove.isValidPosition(pawnRow, pawnCol)) {
        final pawnIndex = ChessMove.indexFromPosition(pawnRow, pawnCol);
        final piece = board[pawnIndex];
        if (piece?.type == ChessPieceType.pawn && piece?.color == attackerColor) {
          return true;
        }
      }
    }

    // Check for knight attacks
    for (final move in _knightMoves) {
      final knightRow = row + move[0];
      final knightCol = col + move[1];
      if (ChessMove.isValidPosition(knightRow, knightCol)) {
        final knightIndex = ChessMove.indexFromPosition(knightRow, knightCol);
        final piece = board[knightIndex];
        if (piece?.type == ChessPieceType.knight && piece?.color == attackerColor) {
          return true;
        }
      }
    }

    // Check for king attacks
    for (final dir in _queenDirections) {
      final kingRow = row + dir[0];
      final kingCol = col + dir[1];
      if (ChessMove.isValidPosition(kingRow, kingCol)) {
        final kingIndex = ChessMove.indexFromPosition(kingRow, kingCol);
        final piece = board[kingIndex];
        if (piece?.type == ChessPieceType.king && piece?.color == attackerColor) {
          return true;
        }
      }
    }

    // Check for rook/queen attacks (straight lines)
    for (final dir in _rookDirections) {
      int checkRow = row + dir[0];
      int checkCol = col + dir[1];
      while (ChessMove.isValidPosition(checkRow, checkCol)) {
        final checkIndex = ChessMove.indexFromPosition(checkRow, checkCol);
        final piece = board[checkIndex];
        if (piece != null) {
          if (piece.color == attackerColor &&
              (piece.type == ChessPieceType.rook || piece.type == ChessPieceType.queen)) {
            return true;
          }
          break;
        }
        checkRow += dir[0];
        checkCol += dir[1];
      }
    }

    // Check for bishop/queen attacks (diagonals)
    for (final dir in _bishopDirections) {
      int checkRow = row + dir[0];
      int checkCol = col + dir[1];
      while (ChessMove.isValidPosition(checkRow, checkCol)) {
        final checkIndex = ChessMove.indexFromPosition(checkRow, checkCol);
        final piece = board[checkIndex];
        if (piece != null) {
          if (piece.color == attackerColor &&
              (piece.type == ChessPieceType.bishop || piece.type == ChessPieceType.queen)) {
            return true;
          }
          break;
        }
        checkRow += dir[0];
        checkCol += dir[1];
      }
    }

    return false;
  }

  /// Find the king's position
  static int findKing(List<ChessPiece?> board, bool isWhite) {
    final kingColor = isWhite ? ChessPieceColor.white : ChessPieceColor.black;
    for (int i = 0; i < 64; i++) {
      final piece = board[i];
      if (piece?.type == ChessPieceType.king && piece?.color == kingColor) {
        return i;
      }
    }
    return -1;
  }

  /// Check if the given side is in check
  static bool isInCheck(List<ChessPiece?> board, bool isWhite) {
    final kingIndex = findKing(board, isWhite);
    if (kingIndex == -1) return false;
    return isSquareAttacked(board, kingIndex, !isWhite);
  }

  /// Make a move on a copy of the board and return the new board
  static List<ChessPiece?> makeMove(List<ChessPiece?> board, ChessMove move) {
    final newBoard = List<ChessPiece?>.from(board);
    final piece = newBoard[move.fromIndex];

    if (piece == null) return newBoard;

    // Handle en passant capture
    if (move.isEnPassant && move.capturedPieceIndex != null) {
      newBoard[move.capturedPieceIndex!] = null;
    }

    // Handle castling
    if (move.isCastling) {
      final row = ChessMove.getRow(move.toIndex);
      if (ChessMove.getCol(move.toIndex) == 6) {
        // Kingside
        newBoard[ChessMove.indexFromPosition(row, 5)] = newBoard[ChessMove.indexFromPosition(row, 7)];
        newBoard[ChessMove.indexFromPosition(row, 7)] = null;
      } else {
        // Queenside
        newBoard[ChessMove.indexFromPosition(row, 3)] = newBoard[ChessMove.indexFromPosition(row, 0)];
        newBoard[ChessMove.indexFromPosition(row, 0)] = null;
      }
    }

    // Handle promotion
    if (move.promotionPiece != null) {
      ChessPieceType promotionType;
      switch (move.promotionPiece) {
        case 'q':
          promotionType = ChessPieceType.queen;
          break;
        case 'r':
          promotionType = ChessPieceType.rook;
          break;
        case 'b':
          promotionType = ChessPieceType.bishop;
          break;
        case 'n':
          promotionType = ChessPieceType.knight;
          break;
        default:
          promotionType = ChessPieceType.queen;
      }
      newBoard[move.toIndex] = ChessPiece(type: promotionType, color: piece.color);
    } else {
      newBoard[move.toIndex] = piece;
    }

    newBoard[move.fromIndex] = null;

    return newBoard;
  }

  /// Check if a move leaves the king in check (illegal)
  static bool isMoveLegal(
    List<ChessPiece?> board,
    ChessMove move,
    bool isWhite,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    final newBoard = makeMove(board, move);
    return !isInCheck(newBoard, isWhite);
  }

  /// Generate all legal moves for the current position
  static List<ChessMove> generateAllLegalMoves(
    List<ChessPiece?> board,
    bool isWhiteTurn,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    final legalMoves = <ChessMove>[];
    final friendlyColor = isWhiteTurn ? ChessPieceColor.white : ChessPieceColor.black;

    for (int i = 0; i < 64; i++) {
      final piece = board[i];
      if (piece?.color == friendlyColor) {
        final possibleMoves = getPossibleMovesForPiece(
          board, i,
          whiteKingMoved, blackKingMoved,
          whiteRookAMoved, whiteRookHMoved,
          blackRookAMoved, blackRookHMoved,
          enPassantTargetIndex,
        );

        for (final move in possibleMoves) {
          if (isMoveLegal(
            board, move, isWhiteTurn,
            whiteKingMoved, blackKingMoved,
            whiteRookAMoved, whiteRookHMoved,
            blackRookAMoved, blackRookHMoved,
            enPassantTargetIndex,
          )) {
            legalMoves.add(move);
          }
        }
      }
    }

    return legalMoves;
  }

  /// Check for checkmate
  static bool isCheckmate(
    List<ChessPiece?> board,
    bool isWhiteTurn,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    if (!isInCheck(board, isWhiteTurn)) return false;

    final legalMoves = generateAllLegalMoves(
      board, isWhiteTurn,
      whiteKingMoved, blackKingMoved,
      whiteRookAMoved, whiteRookHMoved,
      blackRookAMoved, blackRookHMoved,
      enPassantTargetIndex,
    );

    return legalMoves.isEmpty;
  }

  /// Check for stalemate
  static bool isStalemate(
    List<ChessPiece?> board,
    bool isWhiteTurn,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    if (isInCheck(board, isWhiteTurn)) return false;

    final legalMoves = generateAllLegalMoves(
      board, isWhiteTurn,
      whiteKingMoved, blackKingMoved,
      whiteRookAMoved, whiteRookHMoved,
      blackRookAMoved, blackRookHMoved,
      enPassantTargetIndex,
    );

    return legalMoves.isEmpty;
  }

  /// Check for insufficient material (draw)
  static bool hasInsufficientMaterial(List<ChessPiece?> board) {
    final whitePieces = <ChessPieceType>[];
    final blackPieces = <ChessPieceType>[];

    for (final piece in board) {
      if (piece != null) {
        if (piece.color == ChessPieceColor.white) {
          whitePieces.add(piece.type);
        } else {
          blackPieces.add(piece.type);
        }
      }
    }

    // King vs King
    if (whitePieces.length == 1 && blackPieces.length == 1) {
      return true;
    }

    // King + minor piece vs King
    if (whitePieces.length == 1 && blackPieces.length == 2) {
      if (blackPieces.contains(ChessPieceType.knight) || blackPieces.contains(ChessPieceType.bishop)) {
        return true;
      }
    }
    if (blackPieces.length == 1 && whitePieces.length == 2) {
      if (whitePieces.contains(ChessPieceType.knight) || whitePieces.contains(ChessPieceType.bishop)) {
        return true;
      }
    }

    // King + bishop vs King + bishop (same color bishops)
    if (whitePieces.length == 2 && blackPieces.length == 2) {
      final whiteBishopIndex = board.indexWhere((p) => 
        p?.type == ChessPieceType.bishop && p?.color == ChessPieceColor.white);
      final blackBishopIndex = board.indexWhere((p) => 
        p?.type == ChessPieceType.bishop && p?.color == ChessPieceColor.black);
      
      if (whiteBishopIndex != -1 && blackBishopIndex != -1) {
        final whiteBishopSquareColor = (ChessMove.getRow(whiteBishopIndex) + ChessMove.getCol(whiteBishopIndex)) % 2;
        final blackBishopSquareColor = (ChessMove.getRow(blackBishopIndex) + ChessMove.getCol(blackBishopIndex)) % 2;
        if (whiteBishopSquareColor == blackBishopSquareColor) {
          return true;
        }
      }
    }

    return false;
  }

  /// Generate a position key for repetition detection
  static String generatePositionKey(
    List<ChessPiece?> board,
    bool isWhiteTurn,
    bool whiteKingMoved,
    bool blackKingMoved,
    bool whiteRookAMoved,
    bool whiteRookHMoved,
    bool blackRookAMoved,
    bool blackRookHMoved,
    int? enPassantTargetIndex,
  ) {
    final buffer = StringBuffer();
    
    for (final piece in board) {
      if (piece == null) {
        buffer.write('0');
      } else {
        buffer.write('${piece.color.name[0]}${piece.type.name[0]}');
      }
    }
    
    buffer.write(isWhiteTurn ? 'w' : 'b');
    buffer.write(whiteKingMoved ? 'K' : '');
    buffer.write(blackKingMoved ? 'k' : '');
    buffer.write(whiteRookAMoved ? 'Q' : '');
    buffer.write(whiteRookHMoved ? 'q' : '');
    buffer.write(blackRookAMoved ? 'A' : '');
    buffer.write(blackRookHMoved ? 'a' : '');
    buffer.write(enPassantTargetIndex?.toString() ?? '-');
    
    return buffer.toString();
  }

  /// Check for threefold repetition
  static bool isThreefoldRepetition(List<String> positionHistory, String currentPosition) {
    int count = 0;
    for (final position in positionHistory) {
      if (position == currentPosition) {
        count++;
      }
    }
    return count >= 2; // Current position + 2 previous occurrences
  }

  /// Apply a move to the game state and return the new state
  static GameState applyMove(GameState state, ChessMove move) {
    final newBoard = makeMove(state.board, move);
    final isWhite = state.board[move.fromIndex]?.color == ChessPieceColor.white;
    final newIsWhiteTurn = !state.isWhiteTurn;

    // Update castling rights
    bool newWhiteKingMoved = state.whiteKingMoved;
    bool newBlackKingMoved = state.blackKingMoved;
    bool newWhiteRookAMoved = state.whiteRookAMoved;
    bool newWhiteRookHMoved = state.whiteRookHMoved;
    bool newBlackRookAMoved = state.blackRookAMoved;
    bool newBlackRookHMoved = state.blackRookHMoved;

    if (move.fromIndex == 60 || move.toIndex == 60) newWhiteKingMoved = true;
    if (move.fromIndex == 4 || move.toIndex == 4) newBlackKingMoved = true;
    if (move.fromIndex == 56 || move.toIndex == 56) newWhiteRookAMoved = true;
    if (move.fromIndex == 63 || move.toIndex == 63) newWhiteRookHMoved = true;
    if (move.fromIndex == 0 || move.toIndex == 0) newBlackRookAMoved = true;
    if (move.fromIndex == 7 || move.toIndex == 7) newBlackRookHMoved = true;

    // Update en passant target
    int? newEnPassantTarget;
    final piece = state.board[move.fromIndex];
    if (piece?.type == ChessPieceType.pawn) {
      final fromRow = ChessMove.getRow(move.fromIndex);
      final toRow = ChessMove.getRow(move.toIndex);
      if ((toRow - fromRow).abs() == 2) {
        newEnPassantTarget = ChessMove.indexFromPosition(
          (fromRow + toRow) ~/ 2,
          ChessMove.getCol(move.fromIndex),
        );
      }
    }

    // Update move clocks
    final isCapture = state.board[move.toIndex] != null || move.isEnPassant;
    final isPawnMove = piece?.type == ChessPieceType.pawn;
    int newHalfMoveClock = (isCapture || isPawnMove) ? 0 : state.halfMoveClock + 1;
    int newFullMoveNumber = state.fullMoveNumber + (newIsWhiteTurn ? 1 : 0);

    // Generate position key for repetition
    final positionKey = generatePositionKey(
      newBoard, newIsWhiteTurn,
      newWhiteKingMoved, newBlackKingMoved,
      newWhiteRookAMoved, newWhiteRookHMoved,
      newBlackRookAMoved, newBlackRookHMoved,
      newEnPassantTarget,
    );
    final newPositionHistory = [...state.positionHistory, positionKey];

    // Check game end conditions
    final newInCheck = isInCheck(newBoard, newIsWhiteTurn);
    final newLegalMoves = generateAllLegalMoves(
      newBoard, newIsWhiteTurn,
      newWhiteKingMoved, newBlackKingMoved,
      newWhiteRookAMoved, newWhiteRookHMoved,
      newBlackRookAMoved, newBlackRookHMoved,
      newEnPassantTarget,
    );

    GameResult newResult = GameResult.ongoing;
    GameEndReason? newEndReason;

    if (newLegalMoves.isEmpty) {
      if (newInCheck) {
        newResult = newIsWhiteTurn ? GameResult.blackWins : GameResult.whiteWins;
        newEndReason = GameEndReason.checkmate;
      } else {
        newResult = GameResult.draw;
        newEndReason = GameEndReason.stalemate;
      }
    } else if (hasInsufficientMaterial(newBoard)) {
      newResult = GameResult.draw;
      newEndReason = GameEndReason.insufficientMaterial;
    } else if (newHalfMoveClock >= 100) {
      newResult = GameResult.draw;
      newEndReason = GameEndReason.fiftyMoveRule;
    } else if (isThreefoldRepetition(newPositionHistory, positionKey)) {
      newResult = GameResult.draw;
      newEndReason = GameEndReason.threefoldRepetition;
    }

    return state.copyWith(
      board: newBoard,
      isWhiteTurn: newIsWhiteTurn,
      lastMove: move,
      whiteKingMoved: newWhiteKingMoved,
      blackKingMoved: newBlackKingMoved,
      whiteRookAMoved: newWhiteRookAMoved,
      whiteRookHMoved: newWhiteRookHMoved,
      blackRookAMoved: newBlackRookAMoved,
      blackRookHMoved: newBlackRookHMoved,
      enPassantTargetIndex: newEnPassantTarget,
      halfMoveClock: newHalfMoveClock,
      fullMoveNumber: newFullMoveNumber,
      positionHistory: newPositionHistory,
      result: newResult,
      endReason: newEndReason,
      isInCheck: newInCheck,
      legalMoves: newLegalMoves,
    );
  }
}
