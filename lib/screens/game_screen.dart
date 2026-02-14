import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/chess_move.dart';
import '../models/player_stats.dart';
import '../models/game_history.dart' as history;
import '../services/chess_engine.dart';
import '../services/storage_service.dart';
import 'game_over_screen.dart';
import 'promotion_dialog.dart';

class GameScreen extends StatefulWidget {
  final String whitePlayerName;
  final String blackPlayerName;
  final history.TimeControl timeControl;
  final bool showLegalMoves;
  final bool showCoordinates;

  const GameScreen({
    super.key,
    this.whitePlayerName = 'Player 1',
    this.blackPlayerName = 'Player 2',
    this.timeControl = history.TimeControl.blitz5,
    this.showLegalMoves = true,
    this.showCoordinates = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  int _selectedIndex = -1;
  List<int> _legalMoveSquares = [];
  List<int> _capturedByWhite = [];
  List<int> _capturedByBlack = [];
  
  // Timers
  late Duration _whiteTime;
  late Duration _blackTime;
  Timer? _gameTimer;
  
  // Game record
  final List<history.MoveRecord> _moveRecords = [];
  int _moveNumber = 1;
  
  // Player stats
  PlayerStats? _whitePlayerStats;
  PlayerStats? _blackPlayerStats;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
    _whiteTime = widget.timeControl.initialTime;
    _blackTime = widget.timeControl.initialTime;
    _loadPlayerStats();
    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlayerStats() async {
    _whitePlayerStats = await StorageService.instance.getPlayer(widget.whitePlayerName);
    _blackPlayerStats = await StorageService.instance.getPlayer(widget.blackPlayerName);
    setState(() {});
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_gameState.result != GameResult.ongoing) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_gameState.isWhiteTurn) {
          _whiteTime -= const Duration(milliseconds: 100);
          if (_whiteTime <= Duration.zero) {
            _whiteTime = Duration.zero;
            _handleTimeOut(isWhite: true);
          }
        } else {
          _blackTime -= const Duration(milliseconds: 100);
          if (_blackTime <= Duration.zero) {
            _blackTime = Duration.zero;
            _handleTimeOut(isWhite: false);
          }
        }
      });
    });
  }

  void _handleTimeOut({required bool isWhite}) {
    _gameTimer?.cancel();
    
    final result = isWhite ? GameResult.blackWins : GameResult.whiteWins;
    final endReason = GameEndReason.timeOut;
    
    setState(() {
      _gameState = _gameState.copyWith(
        result: result,
        endReason: endReason,
      );
    });
    
    _showGameOverScreen();
  }

  void _handleTap(int index) {
    if (_gameState.result != GameResult.ongoing) return;

    final piece = _gameState.board[index];
    
    // If a piece is already selected
    if (_selectedIndex != -1) {
      // Check if this is a legal move
      final legalMove = _legalMoveSquares.contains(index);
      
      if (legalMove) {
        // Find the actual move
        final move = _gameState.legalMoves.firstWhere(
          (m) => m.fromIndex == _selectedIndex && m.toIndex == index,
          orElse: () => ChessMove(fromIndex: _selectedIndex, toIndex: index),
        );
        
        // Check for pawn promotion
        final movingPiece = _gameState.board[_selectedIndex];
        if (movingPiece?.type == ChessPieceType.pawn) {
          final toRow = ChessMove.getRow(index);
          final isWhite = movingPiece?.color == ChessPieceColor.white;
          if ((isWhite && toRow == 0) || (!isWhite && toRow == 7)) {
            _showPromotionDialog(move);
            return;
          }
        }
        
        _executeMove(move);
      } else if (piece != null && 
          (piece.color == ChessPieceColor.white) == _gameState.isWhiteTurn) {
        // Select a different piece
        _selectPiece(index);
      } else {
        // Deselect
        _deselectPiece();
      }
    } else {
      // No piece selected, try to select one
      if (piece != null && 
          (piece.color == ChessPieceColor.white) == _gameState.isWhiteTurn) {
        _selectPiece(index);
      }
    }
  }

  void _selectPiece(int index) {
    setState(() {
      _selectedIndex = index;
      _legalMoveSquares = _gameState.legalMoves
          .where((m) => m.fromIndex == index)
          .map((m) => m.toIndex)
          .toList();
    });
  }

  void _deselectPiece() {
    setState(() {
      _selectedIndex = -1;
      _legalMoveSquares = [];
    });
  }

  Future<void> _showPromotionDialog(ChessMove baseMove) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromotionDialog(
        isWhite: _gameState.isWhiteTurn,
      ),
    );

    if (result != null && mounted) {
      final promotionMove = ChessMove(
        fromIndex: baseMove.fromIndex,
        toIndex: baseMove.toIndex,
        promotionPiece: result,
      );
      _executeMove(promotionMove);
    } else {
      _deselectPiece();
    }
  }

  void _executeMove(ChessMove move) {
    final capturedPiece = _gameState.board[move.toIndex];
    
    // Track captured pieces
    if (capturedPiece != null) {
      if (_gameState.isWhiteTurn) {
        _capturedByWhite.add(move.toIndex);
      } else {
        _capturedByBlack.add(move.toIndex);
      }
    }
    
    // Handle en passant capture
    if (move.isEnPassant && move.capturedPieceIndex != null) {
      if (_gameState.isWhiteTurn) {
        _capturedByWhite.add(move.capturedPieceIndex!);
      } else {
        _capturedByBlack.add(move.capturedPieceIndex!);
      }
    }
    
    // Add time increment
    if (widget.timeControl.increment != null) {
      if (_gameState.isWhiteTurn) {
        _whiteTime += widget.timeControl.increment!;
      } else {
        _blackTime += widget.timeControl.increment!;
      }
    }
    
    // Record the move
    final moveNotation = _generateMoveNotation(move);
    if (_gameState.isWhiteTurn) {
      _moveRecords.add(history.MoveRecord(
        moveNumber: _moveNumber,
        whiteMove: moveNotation,
        whiteTimeRemaining: _whiteTime,
      ));
    } else {
      if (_moveRecords.isNotEmpty) {
        final lastRecord = _moveRecords.last;
        _moveRecords[_moveRecords.length - 1] = history.MoveRecord(
          moveNumber: lastRecord.moveNumber,
          whiteMove: lastRecord.whiteMove,
          blackMove: moveNotation,
          whiteTimeRemaining: lastRecord.whiteTimeRemaining,
          blackTimeRemaining: _blackTime,
        );
      }
      _moveNumber++;
    }
    
    // Apply the move
    setState(() {
      _gameState = ChessEngine.applyMove(_gameState, move);
      _selectedIndex = -1;
      _legalMoveSquares = [];
    });
    
    // Check for game over
    if (_gameState.result != GameResult.ongoing) {
      _gameTimer?.cancel();
      _showGameOverScreen();
    }
  }

  String _generateMoveNotation(ChessMove move) {
    final piece = _gameState.board[move.fromIndex];
    if (piece == null) return '';
    
    final isCapture = _gameState.board[move.toIndex] != null || move.isEnPassant;
    final toRow = ChessMove.getRow(move.toIndex);
    final toCol = ChessMove.getCol(move.toIndex);
    
    // Castling
    if (move.isCastling) {
      return toCol == 6 ? 'O-O' : 'O-O-O';
    }
    
    final buffer = StringBuffer();
    
    // Piece letter
    if (piece.type != ChessPieceType.pawn) {
      buffer.write(_getPieceLetter(piece.type));
    }
    
    // Capture
    if (isCapture) {
      if (piece.type == ChessPieceType.pawn) {
        buffer.write(String.fromCharCode(97 + ChessMove.getCol(move.fromIndex)));
      }
      buffer.write('x');
    }
    
    // Destination
    buffer.write(String.fromCharCode(97 + toCol));
    buffer.write(8 - toRow);
    
    // Promotion
    if (move.promotionPiece != null) {
      buffer.write('=${move.promotionPiece!.toUpperCase()}');
    }
    
    // Check/Checkmate
    if (_gameState.isInCheck) {
      buffer.write('+');
    }
    
    return buffer.toString();
  }

  String _getPieceLetter(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.king: return 'K';
      case ChessPieceType.queen: return 'Q';
      case ChessPieceType.rook: return 'R';
      case ChessPieceType.bishop: return 'B';
      case ChessPieceType.knight: return 'N';
      case ChessPieceType.pawn: return '';
    }
  }

  void _showGameOverScreen() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(
            result: _convertGameResult(_gameState.result),
            endReason: _convertGameEndReason(_gameState.endReason!),
            whitePlayerName: widget.whitePlayerName,
            blackPlayerName: widget.blackPlayerName,
            whitePlayerStats: _whitePlayerStats,
            blackPlayerStats: _blackPlayerStats,
            moves: _moveRecords,
            timeControl: widget.timeControl,
            whiteTimeRemaining: _whiteTime,
            blackTimeRemaining: _blackTime,
          ),
        ),
      );
    });
  }

  history.GameResult _convertGameResult(GameResult result) {
    switch (result) {
      case GameResult.ongoing:
        return history.GameResult.draw;
      case GameResult.whiteWins:
        return history.GameResult.whiteWins;
      case GameResult.blackWins:
        return history.GameResult.blackWins;
      case GameResult.draw:
        return history.GameResult.draw;
    }
  }

  history.GameEndReason _convertGameEndReason(GameEndReason reason) {
    switch (reason) {
      case GameEndReason.checkmate:
        return history.GameEndReason.checkmate;
      case GameEndReason.stalemate:
        return history.GameEndReason.stalemate;
      case GameEndReason.insufficientMaterial:
        return history.GameEndReason.insufficientMaterial;
      case GameEndReason.fiftyMoveRule:
        return history.GameEndReason.fiftyMoveRule;
      case GameEndReason.threefoldRepetition:
        return history.GameEndReason.threefoldRepetition;
      case GameEndReason.resignation:
        return history.GameEndReason.resignation;
      case GameEndReason.timeOut:
        return history.GameEndReason.timeOut;
      case GameEndReason.agreement:
        return history.GameEndReason.agreement;
    }
  }

  void _resign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign'),
        content: Text('${_gameState.isWhiteTurn ? widget.whitePlayerName : widget.blackPlayerName}, are you sure you want to resign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameState = _gameState.copyWith(
                  result: _gameState.isWhiteTurn ? GameResult.blackWins : GameResult.whiteWins,
                  endReason: GameEndReason.resignation,
                );
              });
              _gameTimer?.cancel();
              _showGameOverScreen();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _offerDraw() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offer Draw'),
        content: Text('${_gameState.isWhiteTurn ? widget.whitePlayerName : widget.blackPlayerName} offers a draw. Accept?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameState = _gameState.copyWith(
                  result: GameResult.draw,
                  endReason: GameEndReason.agreement,
                );
              });
              _gameTimer?.cancel();
              _showGameOverScreen();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes >= 1) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      final tenths = (duration.inMilliseconds % 1000) ~/ 100;
      return '$seconds.$tenths';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(
          _gameState.result != GameResult.ongoing
              ? 'Game Over'
              : _gameState.isWhiteTurn
                  ? "${widget.whitePlayerName}'s Turn"
                  : "${widget.blackPlayerName}'s Turn",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _gameState.result == GameResult.ongoing ? _resign : null,
            tooltip: 'Resign',
          ),
          IconButton(
            icon: const Icon(Icons.handshake),
            onPressed: _gameState.result == GameResult.ongoing ? _offerDraw : null,
            tooltip: 'Offer Draw',
          ),
        ],
      ),
      body: Column(
        children: [
          // Black player info
          _buildPlayerInfo(
            name: widget.blackPlayerName,
            stats: _blackPlayerStats,
            time: _blackTime,
            isWhite: false,
            isActive: !_gameState.isWhiteTurn,
            capturedPieces: _capturedByWhite,
          ),
          
          // Check indicator for black
          if (_gameState.isInCheck && !_gameState.isWhiteTurn)
            Container(
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(
                child: Text(
                  'CHECK!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Chess board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Board
                        GridView.builder(
                          itemCount: 64,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                          ),
                          itemBuilder: (context, index) {
                            return _buildSquare(index, constraints);
                          },
                        ),
                        
                        // Coordinates
                        if (widget.showCoordinates)
                          Positioned.fill(
                            child: _buildCoordinates(constraints),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Check indicator for white
          if (_gameState.isInCheck && _gameState.isWhiteTurn)
            Container(
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(
                child: Text(
                  'CHECK!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // White player info
          _buildPlayerInfo(
            name: widget.whitePlayerName,
            stats: _whitePlayerStats,
            time: _whiteTime,
            isWhite: true,
            isActive: _gameState.isWhiteTurn,
            capturedPieces: _capturedByBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo({
    required String name,
    required PlayerStats? stats,
    required Duration time,
    required bool isWhite,
    required bool isActive,
    required List<int> capturedPieces,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isActive ? Colors.green.shade700.withOpacity(0.3) : Colors.grey.shade800,
      child: Row(
        children: [
          // Player icon
          CircleAvatar(
            backgroundColor: isWhite ? Colors.white : Colors.black,
            child: Icon(
              Icons.person,
              color: isWhite ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          
          // Player name and stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (stats != null)
                  Text(
                    'ELO: ${stats.eloRating} | W: ${stats.wins} L: ${stats.losses} D: ${stats.draws}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Captured pieces
          if (capturedPieces.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                _getCapturedPiecesString(capturedPieces, isWhite),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: time.inSeconds < 30 ? Colors.red.shade700 : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatTime(time),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCapturedPiecesString(List<int> capturedIndices, bool capturedByWhite) {
    final pieces = <String>[];
    for (final index in capturedIndices) {
      final piece = _gameState.board[index];
      if (piece != null) {
        pieces.add(piece.character);
      }
    }
    return pieces.join(' ');
  }

  Widget _buildSquare(int index, BoxConstraints constraints) {
    final row = index ~/ 8;
    final col = index % 8;
    final isWhite = (row + col) % 2 == 0;
    final piece = _gameState.board[index];
    final isSelected = index == _selectedIndex;
    final isLegalMove = _legalMoveSquares.contains(index);
    final isLastMove = _gameState.lastMove != null &&
        (_gameState.lastMove!.fromIndex == index || _gameState.lastMove!.toIndex == index);

    Color squareColor;
    if (isSelected) {
      squareColor = Colors.green.shade400;
    } else if (isLastMove) {
      squareColor = Colors.yellow.shade200.withOpacity(0.5);
    } else if (isWhite) {
      squareColor = Colors.grey.shade300;
    } else {
      squareColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        color: squareColor,
        child: Stack(
          children: [
            // Piece
            if (piece != null)
              Center(
                child: Text(
                  piece.character,
                  style: TextStyle(
                    fontSize: constraints.maxWidth / 10,
                    color: piece.color == ChessPieceColor.white
                        ? Colors.white
                        : Colors.black,
                    shadows: [
                      Shadow(
                        color: piece.color == ChessPieceColor.white
                            ? Colors.black
                            : Colors.white,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Legal move indicator
            if (isLegalMove && widget.showLegalMoves)
              if (piece != null)
                // Capture indicator
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.shade600,
                      width: 4,
                    ),
                  ),
                )
              else
                // Move indicator
                Center(
                  child: Container(
                    width: constraints.maxWidth / 16,
                    height: constraints.maxWidth / 16,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinates(BoxConstraints constraints) {
    return IgnorePointer(
      child: Stack(
        children: [
          // File labels (a-h)
          for (int col = 0; col < 8; col++)
            Positioned(
              bottom: 2,
              left: constraints.maxWidth / 8 * col + constraints.maxWidth / 8 - 12,
              child: Text(
                String.fromCharCode(97 + col),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          
          // Rank labels (1-8)
          for (int row = 0; row < 8; row++)
            Positioned(
              top: constraints.maxHeight / 8 * row + 2,
              left: 2,
              child: Text(
                (8 - row).toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
