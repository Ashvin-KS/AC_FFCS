import 'package:flutter/material.dart';

enum ChessPieceType { pawn, rook, knight, bishop, queen, king }

enum ChessPieceColor { white, black }

class ChessPiece {
  final ChessPieceType type;
  final ChessPieceColor color;

  ChessPiece({required this.type, required this.color});

  String get character {
    switch (color) {
      case ChessPieceColor.white:
        switch (type) {
          case ChessPieceType.pawn:
            return '♙';
          case ChessPieceType.rook:
            return '♖';
          case ChessPieceType.knight:
            return '♘';
          case ChessPieceType.bishop:
            return '♗';
          case ChessPieceType.queen:
            return '♕';
          case ChessPieceType.king:
            return '♔';
        }
      case ChessPieceColor.black:
        switch (type) {
          case ChessPieceType.pawn:
            return '♟';
          case ChessPieceType.rook:
            return '♜';
          case ChessPieceType.knight:
            return '♞';
          case ChessPieceType.bishop:
            return '♝';
          case ChessPieceType.queen:
            return '♛';
          case ChessPieceType.king:
            return '♚';
        }
    }
  }
}
