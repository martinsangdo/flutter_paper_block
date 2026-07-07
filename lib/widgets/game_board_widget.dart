import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../painters/board_painter.dart';

class GameBoardWidget extends StatefulWidget {
  final GameState gameState;
  final double cellSize;

  const GameBoardWidget({
    super.key,
    required this.gameState,
    required this.cellSize,
  });

  @override
  State<GameBoardWidget> createState() => GameBoardWidgetState();
}

class GameBoardWidgetState extends State<GameBoardWidget> {
  Piece? _ghostPiece;
  int _ghostCol = 0;
  int _ghostRow = 0;
  bool _ghostValid = false;

  /// Converts the drop position to the piece's top-left origin cell. With the
  /// tray's default `childDragAnchorStrategy`, [localPos] is already the piece's
  /// top-left corner in board-local coords, so we just snap it to the grid.
  (int, int) _originFor(Piece piece, Offset localPos) {
    final cs = widget.cellSize;
    final col = (localPos.dx / cs).round();
    final row = (localPos.dy / cs).round();
    return (col, row);
  }

  void updateGhost(Piece? piece, Offset localPos) {
    if (piece == null) {
      setState(() => _ghostPiece = null);
      return;
    }
    final (col, row) = _originFor(piece, localPos);
    final valid = widget.gameState.canPlace(piece, col, row);
    setState(() {
      _ghostPiece = piece;
      _ghostCol = col;
      _ghostRow = row;
      _ghostValid = valid;
    });
  }

  void clearGhost() => setState(() => _ghostPiece = null);

  bool tryPlace(Piece piece, Offset localPos) {
    final (col, row) = _originFor(piece, localPos);
    if (widget.gameState.canPlace(piece, col, row)) {
      widget.gameState.placePiece(piece, col, row);
      setState(() => _ghostPiece = null);
      return true;
    }
    setState(() => _ghostPiece = null);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    final boardW = gs.level.cols * widget.cellSize;
    final boardH = gs.level.rows * widget.cellSize;

    return ListenableBuilder(
      listenable: gs,
      builder: (context, child) => Container(
        width: boardW,
        height: boardH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            size: Size(boardW, boardH),
            painter: BoardPainter(
              cols: gs.level.cols,
              rows: gs.level.rows,
              targetCells: gs.level.targetSet,
              placedCells: gs.placedCells,
              cellSize: widget.cellSize,
              ghostPiece: _ghostPiece,
              ghostCol: _ghostCol,
              ghostRow: _ghostRow,
              ghostValid: _ghostValid,
            ),
          ),
        ),
      ),
    );
  }
}
