// Verifies GameState.solveHint returns a *correct* full solution: a placement
// for every remaining piece that is valid under canPlace and exactly tiles the
// target. Placing that whole solution must complete every level.

import 'package:flutter_test/flutter_test.dart';
import 'package:paper_block_game/data/levels.dart';
import 'package:paper_block_game/models/game_state.dart';

void main() {
  test('solveHint returns the full solution and null once complete', () {
    final gs = GameState(allLevels.first);
    final solution = gs.solveHint();
    expect(solution, isNotNull);
    // Placing the full solution completes the board.
    for (final (piece, col, row) in solution!) {
      expect(gs.canPlace(piece, col, row), isTrue);
      gs.placePiece(piece, col, row);
    }
    expect(gs.isComplete, isTrue);
    expect(gs.solveHint(), isNull, reason: 'no hint once the board is solved');
  });

  test('solveHint solves every level', () {
    for (final level in allLevels) {
      final gs = GameState(level);
      final solution = gs.solveHint();
      expect(solution, isNotNull, reason: 'Level ${level.id}: no solution');
      // The solution must cover every remaining piece exactly once.
      expect(solution!.length, gs.remainingPieces.length,
          reason: 'Level ${level.id}: solution misses pieces');
      for (final (piece, col, row) in solution) {
        expect(gs.canPlace(piece, col, row), isTrue,
            reason: 'Level ${level.id}: hinted placement is invalid');
        gs.placePiece(piece, col, row);
      }
      expect(gs.isComplete, isTrue,
          reason: 'Level ${level.id}: solution did not complete the level');
    }
  });

  test('following a fresh hint one piece at a time also completes the level', () {
    // Placing just the first piece of each recomputed solution must still drive
    // the board to completion — hints stay valid as the board fills.
    final level = allLevels[10];
    final gs = GameState(level);
    var guard = level.pieces.length + 1;
    while (!gs.isComplete && guard-- > 0) {
      final solution = gs.solveHint();
      expect(solution, isNotNull);
      final (piece, col, row) = solution!.first;
      gs.placePiece(piece, col, row);
    }
    expect(gs.isComplete, isTrue);
  });
}
