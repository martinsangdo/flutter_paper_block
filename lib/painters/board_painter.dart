import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

class BoardPainter extends CustomPainter {
  final int cols, rows;
  final Set<(int, int)> targetCells;
  final Map<(int, int), PlacedInfo> placedCells;
  final double cellSize;

  final Piece? ghostPiece;
  final int ghostCol, ghostRow;
  final bool ghostValid;

  // Full-solution hint overlay: each remaining piece with its solved origin.
  final List<(Piece, int, int)> hintSolution;

  static const _bgColor = Color(0xFFFFFFFF);
  static const _gridColor = Color(0xFFB8D4F0);
  static const _sketchColor = Color(0xFF1A1A1A);
  static const _targetBg = Color(0xFFF8F8F8);
  static const _hintColor = Color(0xFFFFC107);

  BoardPainter({
    required this.cols,
    required this.rows,
    required this.targetCells,
    required this.placedCells,
    required this.cellSize,
    this.ghostPiece,
    this.ghostCol = 0,
    this.ghostRow = 0,
    this.ghostValid = false,
    this.hintSolution = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);
    _drawTargetCells(canvas);
    _drawPlacedPieces(canvas);
    if (hintSolution.isNotEmpty) _drawHint(canvas);
    if (ghostPiece != null) _drawGhost(canvas);
    _drawTargetBorders(canvas);
  }

  /// Draws the full-solution preview: every remaining piece in its solved
  /// position, in its own color with a golden hint border, so the board reads
  /// as the completed picture. Cells already filled for real are skipped.
  void _drawHint(Canvas canvas) {
    final border = Paint()
      ..color = _hintColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (final (piece, col, row) in hintSolution) {
      for (final cell in piece.absoluteCells(col, row)) {
        if (placedCells.containsKey(cell)) continue; // already placed for real
        final rect = _cellRect(cell.$1, cell.$2).deflate(1);
        canvas.drawRect(
          rect,
          Paint()..color = piece.color.withValues(alpha: 0.45),
        );
        _drawHatching(canvas, rect, piece.darkColor.withValues(alpha: 0.4));
        canvas.drawRect(rect, border);
      }
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bgColor,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.6;

    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(c * cellSize, 0),
        Offset(c * cellSize, rows * cellSize),
        paint,
      );
    }
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellSize),
        Offset(cols * cellSize, r * cellSize),
        paint,
      );
    }
  }

  void _drawTargetCells(Canvas canvas) {
    final paint = Paint()..color = _targetBg;
    for (final cell in targetCells) {
      if (!placedCells.containsKey(cell)) {
        canvas.drawRect(_cellRect(cell.$1, cell.$2), paint);
      }
    }
  }

  void _drawPlacedPieces(Canvas canvas) {
    for (final entry in placedCells.entries) {
      final cell = entry.key;
      final info = entry.value;
      _drawSketchCell(canvas, cell.$1, cell.$2, info.color, info.darkColor);
    }
  }

  void _drawGhost(Canvas canvas) {
    final piece = ghostPiece!;
    final ghostCells = piece.absoluteCells(ghostCol, ghostRow);
    final color = ghostValid
        ? piece.color.withValues(alpha: 0.3)
        : Colors.red.withValues(alpha: 0.2);
    final borderColor = ghostValid
        ? _sketchColor.withValues(alpha: 0.4)
        : Colors.red.withValues(alpha: 0.5);

    for (final cell in ghostCells) {
      final rect = _cellRect(cell.$1, cell.$2).deflate(1);
      canvas.drawRect(rect, Paint()..color = color);
      _drawSketchBorder(canvas, rect, borderColor, strokeWidth: 1.5);
    }
  }

  void _drawTargetBorders(Canvas canvas) {
    for (final cell in targetCells) {
      final c = cell.$1, r = cell.$2;
      final rect = _cellRect(c, r);
      final left = rect.left;
      final top = rect.top;
      final right = rect.right;
      final bottom = rect.bottom;

      if (!targetCells.contains((c, r - 1))) {
        _drawSketchLine(canvas, Offset(left, top), Offset(right, top), c, r, 0);
      }
      if (!targetCells.contains((c, r + 1))) {
        _drawSketchLine(canvas, Offset(left, bottom), Offset(right, bottom), c, r, 1);
      }
      if (!targetCells.contains((c - 1, r))) {
        _drawSketchLine(canvas, Offset(left, top), Offset(left, bottom), c, r, 2);
      }
      if (!targetCells.contains((c + 1, r))) {
        _drawSketchLine(canvas, Offset(right, top), Offset(right, bottom), c, r, 3);
      }
    }
  }

  void _drawSketchLine(Canvas canvas, Offset a, Offset b, int c, int r, int edge) {
    // Deterministic wobble based on position
    final seed = (c * 7 + r * 13 + edge * 31).toDouble();
    final w1 = (math.sin(seed) * 1.2);
    final w2 = (math.cos(seed + 1) * 1.0);

    final raw = Offset(-(b.dy - a.dy), b.dx - a.dx).normalize();
    final perp = Offset(raw.dx * 0.8, raw.dy * 0.8);

    final paint1 = Paint()
      ..color = _sketchColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final paint2 = Paint()
      ..color = _sketchColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      a + Offset(perp.dx * w1.sign, perp.dy * w1.sign) + Offset(w1 * 0.3, w2 * 0.3),
      b + Offset(perp.dx * w2.sign, perp.dy * w2.sign) + Offset(w2 * 0.3, w1 * 0.3),
      paint1,
    );
    canvas.drawLine(
      a + perp + Offset(w2 * 0.5, w1 * 0.5),
      b + Offset(perp.dx * 0.5, perp.dy * 0.5) + Offset(w1 * 0.5, w2 * 0.5),
      paint2,
    );
  }

  void _drawSketchCell(Canvas canvas, int c, int r, Color fillColor, Color darkColor) {
    final rect = _cellRect(c, r).deflate(1);

    // Fill
    canvas.drawRect(rect, Paint()..color = fillColor.withValues(alpha: 0.85));

    // Diagonal hatching
    _drawHatching(canvas, rect, darkColor.withValues(alpha: 0.5));

    // Sketchy border
    _drawSketchBorder(canvas, rect, _sketchColor, strokeWidth: 2.0);
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
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = strokeWidth * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Main border
    canvas.drawRect(rect, paint);
    // Slight offset second pass for sketch feel
    canvas.drawRect(rect.inflate(0.8).shift(const Offset(0.8, 0.8)), paint2);
  }

  Rect _cellRect(int c, int r) =>
      Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.placedCells != placedCells ||
      old.ghostPiece != ghostPiece ||
      old.ghostCol != ghostCol ||
      old.ghostRow != ghostRow ||
      old.ghostValid != ghostValid ||
      !listEquals(old.hintSolution, hintSolution) ||
      old.cellSize != cellSize;
}

extension _OffsetExt on Offset {
  Offset normalize() {
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return Offset.zero;
    return Offset(dx / len, dy / len);
  }
}
