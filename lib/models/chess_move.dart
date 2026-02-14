/// Represents a chess move with all necessary information
class ChessMove {
  final int fromIndex;
  final int toIndex;
  final String? promotionPiece; // For pawn promotion
  final bool isCastling;
  final bool isEnPassant;
  final int? capturedPieceIndex; // For en passant capture

  const ChessMove({
    required this.fromIndex,
    required this.toIndex,
    this.promotionPiece,
    this.isCastling = false,
    this.isEnPassant = false,
    this.capturedPieceIndex,
  });

  /// Get the row from a board index (0-7)
  static int getRow(int index) => index ~/ 8;

  /// Get the column from a board index (0-7)
  static int getCol(int index) => index % 8;

  /// Convert row and column to board index
  static int indexFromPosition(int row, int col) => row * 8 + col;

  /// Check if a position is on the board
  static bool isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  @override
  String toString() {
    final fromCol = String.fromCharCode(97 + getCol(fromIndex));
    final fromRow = 8 - getRow(fromIndex);
    final toCol = String.fromCharCode(97 + getCol(toIndex));
    final toRow = 8 - getRow(toIndex);
    return '$fromCol$fromRow-$toCol$toRow';
  }

  /// Convert to algebraic notation (e.g., "e2-e4")
  String toAlgebraicNotation() {
    return toString();
  }
}
