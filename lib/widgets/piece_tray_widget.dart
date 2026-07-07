import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../painters/piece_painter.dart';
import '../services/sound_service.dart';

class PieceTrayWidget extends StatelessWidget {
  final List<Piece> pieces;
  final double cellSize;

  const PieceTrayWidget({
    super.key,
    required this.pieces,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAD8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: pieces.isEmpty
          ? const Center(
              child: Text(
                'All pieces placed!',
                style: TextStyle(
                  color: Color(0xFF8B7355),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Keep the row at least as wide as the tray so a small number
                // of pieces stays centred, while more pieces overflow and scroll.
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pieces
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: _DraggablePiece(
                                  piece: p, cellSize: cellSize),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DraggablePiece extends StatefulWidget {
  final Piece piece;
  final double cellSize;

  const _DraggablePiece({required this.piece, required this.cellSize});

  @override
  State<_DraggablePiece> createState() => _DraggablePieceState();
}

class _DraggablePieceState extends State<_DraggablePiece> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.piece;
    final cs = widget.cellSize;
    final w = p.width * cs;
    final h = p.height * cs;

    final pieceWidget = CustomPaint(
      size: Size(w, h),
      painter: PiecePainter(piece: p, cellSize: cs),
    );

    final fadedWidget = CustomPaint(
      size: Size(w, h),
      painter: PiecePainter(piece: p, cellSize: cs, opacity: 0.35),
    );

    return Draggable<Piece>(
      data: p,
      // Vertical affinity: a drag starts instantly on vertical movement (the
      // board sits above, so pieces are picked up by dragging upward), while a
      // horizontal swipe falls through to the tray's scroll view — letting the
      // player scroll to reach every piece without a pickup delay.
      affinity: Axis.vertical,
      // Default childDragAnchorStrategy keeps the feedback exactly where the
      // player grabbed it — no jump on pickup, and the piece tracks the finger
      // from its original position instead of snapping to be centred on it.
      feedback: Material(
        color: Colors.transparent,
        child: CustomPaint(
          size: Size(w, h),
          painter: PiecePainter(piece: p, cellSize: cs),
        ),
      ),
      childWhenDragging: fadedWidget,
      onDragStarted: () {
        SoundService.instance.playPickup();
        setState(() => _isDragging = true);
      },
      onDragEnd: (details) => setState(() => _isDragging = false),
      onDraggableCanceled: (velocity, offset) => setState(() => _isDragging = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isDragging ? 0.35 : 1.0,
        child: pieceWidget,
      ),
    );
  }
}
