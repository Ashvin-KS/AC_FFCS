import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// Dialog for selecting a piece for pawn promotion
class PromotionDialog extends StatelessWidget {
  final bool isWhite;

  const PromotionDialog({
    super.key,
    required this.isWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Promotion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPieceButton(context, ChessPieceType.queen, 'q', '♕', '♛'),
                _buildPieceButton(context, ChessPieceType.rook, 'r', '♖', '♜'),
                _buildPieceButton(context, ChessPieceType.bishop, 'b', '♗', '♝'),
                _buildPieceButton(context, ChessPieceType.knight, 'n', '♘', '♞'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceButton(
    BuildContext context,
    ChessPieceType type,
    String code,
    String whiteSymbol,
    String blackSymbol,
  ) {
    final symbol = isWhite ? whiteSymbol : blackSymbol;
    
    return InkWell(
      onTap: () => Navigator.pop(context, code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 40,
              color: isWhite ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
