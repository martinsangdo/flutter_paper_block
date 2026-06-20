import 'package:flutter/material.dart';
import 'dart:math' as math;

@immutable
class PieceCell {
  final int dx, dy;
  const PieceCell(this.dx, this.dy);

  @override
  bool operator ==(Object other) =>
      other is PieceCell && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
}

@immutable
class Piece {
  final String id;
  final List<PieceCell> cells;
  final Color color;
  final Color darkColor;

  const Piece({
    required this.id,
    required this.cells,
    required this.color,
    required this.darkColor,
  });

  List<(int, int)> absoluteCells(int originCol, int originRow) =>
      cells.map((c) => (originCol + c.dx, originRow + c.dy)).toList();

  int get width =>
      cells.isEmpty ? 0 : cells.map((c) => c.dx).reduce(math.max) + 1;

  int get height =>
      cells.isEmpty ? 0 : cells.map((c) => c.dy).reduce(math.max) + 1;

  int get minDx =>
      cells.isEmpty ? 0 : cells.map((c) => c.dx).reduce(math.min);

  int get minDy =>
      cells.isEmpty ? 0 : cells.map((c) => c.dy).reduce(math.min);
}
