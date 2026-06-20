import 'package:flutter/material.dart';
import '../models/piece.dart';

class PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;
  final double opacity;

  static const _sketchColor = Color(0xFF1A1A1A);

  const PiecePainter({
    required this.piece,
    required this.cellSize,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in piece.cells) {
      _drawSketchCell(canvas, cell.dx, cell.dy);
    }
  }

  void _drawSketchCell(Canvas canvas, int dx, int dy) {
    final rect = Rect.fromLTWH(
        dx * cellSize, dy * cellSize, cellSize, cellSize).deflate(1);

    // Fill
    canvas.drawRect(
      rect,
      Paint()..color = piece.color.withValues(alpha: 0.85 * opacity),
    );

    // Diagonal hatching
    _drawHatching(canvas, rect, piece.darkColor.withValues(alpha: 0.5 * opacity));

    // Sketchy border
    _drawSketchBorder(canvas, rect, _sketchColor.withValues(alpha: opacity), strokeWidth: 2.0);
  }

  void _drawHatching(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipRect(rect);

    final spacing = cellSize * 0.35;
    var offset = -rect.height;
    while (offset < rect.width) {
      final x1 = rect.left + offset;
      final y1 = rect.top;
      final x2 = rect.left + offset + rect.height;
      final y2 = rect.bottom;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      offset += spacing;
    }

    canvas.restore();
  }

  void _drawSketchBorder(Canvas canvas, Rect rect, Color color, {double strokeWidth = 2.0}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = color.withValues(alpha: color.a * 0.4)
      ..strokeWidth = strokeWidth * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect.inflate(0.8).shift(const Offset(0.8, 0.8)), paint2);
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.cellSize != cellSize || old.opacity != opacity;
}
