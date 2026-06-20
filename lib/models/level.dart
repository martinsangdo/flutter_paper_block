import 'package:flutter/foundation.dart';
import 'piece.dart';

@immutable
class Level {
  final int id;
  final String name;
  final int cols, rows;
  final List<(int, int)> targetCells;
  final List<Piece> pieces;

  const Level({
    required this.id,
    required this.name,
    required this.cols,
    required this.rows,
    required this.targetCells,
    required this.pieces,
  });

  Set<(int, int)> get targetSet => Set.from(targetCells);

  static Level fromGrid({
    required int id,
    required String name,
    required List<String> rows,
    required List<Piece> pieces,
  }) {
    final numRows = rows.length;
    final numCols = rows.isEmpty ? 0 : rows[0].length;
    final target = <(int, int)>[];
    for (int r = 0; r < numRows; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        if (rows[r][c] == '#') target.add((c, r));
      }
    }
    return Level(
      id: id,
      name: name,
      cols: numCols,
      rows: numRows,
      targetCells: target,
      pieces: pieces,
    );
  }
}
