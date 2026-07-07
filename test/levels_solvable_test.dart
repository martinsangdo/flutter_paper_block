// Guarantees every level is solvable under the real game rules: pieces are
// placed in their authored orientation (no rotation/flip) and must exactly
// tile the target cells with no gaps or overlaps.

import 'package:flutter_test/flutter_test.dart';
import 'package:paper_block_game/data/levels.dart';
import 'package:paper_block_game/models/level.dart';

/// Backtracking exact-cover solver mirroring GameState.canPlace: a placement is
/// valid iff every absolute cell of the piece is a target cell and unoccupied.
bool _isSolvable(Level level) {
  final target = level.targetSet;

  // Precompute every legal placement (set of covered cells) for each piece.
  final placements = <List<Set<(int, int)>>>[];
  int minC = 1 << 30, minR = 1 << 30, maxC = -(1 << 30), maxR = -(1 << 30);
  for (final cell in target) {
    if (cell.$1 < minC) minC = cell.$1;
    if (cell.$1 > maxC) maxC = cell.$1;
    if (cell.$2 < minR) minR = cell.$2;
    if (cell.$2 > maxR) maxR = cell.$2;
  }

  for (final piece in level.pieces) {
    final pls = <Set<(int, int)>>[];
    for (int oc = minC; oc <= maxC; oc++) {
      for (int or = minR; or <= maxR; or++) {
        final cells = piece.absoluteCells(oc, or);
        if (cells.every(target.contains)) {
          pls.add(cells.toSet());
        }
      }
    }
    if (pls.isEmpty) return false; // a piece that fits nowhere => unsolvable
    placements.add(pls);
  }

  final used = List<bool>.filled(level.pieces.length, false);

  bool backtrack(Set<(int, int)> covered) {
    if (covered.length == target.length) return true;

    // Choose the uncovered cell with the fewest candidate placements.
    (int, int)? bestCell;
    List<(int, int)>? bestOptions; // (pieceIndex, placementIndex)
    for (final cell in target) {
      if (covered.contains(cell)) continue;
      final options = <(int, int)>[];
      for (int i = 0; i < placements.length; i++) {
        if (used[i]) continue;
        for (int j = 0; j < placements[i].length; j++) {
          final pl = placements[i][j];
          if (pl.contains(cell) && !pl.any(covered.contains)) {
            options.add((i, j));
          }
        }
      }
      if (options.isEmpty) return false; // dead cell
      if (bestOptions == null || options.length < bestOptions.length) {
        bestCell = cell;
        bestOptions = options;
      }
    }
    if (bestCell == null) return true;

    for (final (i, j) in bestOptions!) {
      used[i] = true;
      final next = {...covered, ...placements[i][j]};
      if (backtrack(next)) return true;
      used[i] = false;
    }
    return false;
  }

  return backtrack(<(int, int)>{});
}

void main() {
  test('all levels have matching piece/target cell counts', () {
    for (final level in allLevels) {
      final pieceCells =
          level.pieces.fold<int>(0, (sum, p) => sum + p.cells.length);
      expect(pieceCells, level.targetCells.length,
          reason: 'Level ${level.id} (${level.name}): pieces cover '
              '$pieceCells cells but target has ${level.targetCells.length}');
    }
  });

  test('level ids are sequential 1..N', () {
    for (int i = 0; i < allLevels.length; i++) {
      expect(allLevels[i].id, i + 1);
    }
  });

  test('every level is solvable (no rotation)', () {
    for (final level in allLevels) {
      expect(_isSolvable(level), isTrue,
          reason: 'Level ${level.id} (${level.name}) is not solvable');
    }
  });
}
