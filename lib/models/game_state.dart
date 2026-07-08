import 'package:flutter/material.dart';
import 'level.dart';
import 'piece.dart';

class PlacedInfo {
  final String pieceId;
  final Color color;
  final Color darkColor;
  const PlacedInfo({
    required this.pieceId,
    required this.color,
    required this.darkColor,
  });
}

class GameState extends ChangeNotifier {
  final Level level;
  late List<Piece> _remaining;
  // Maps grid cell -> placed piece info
  late Map<(int, int), PlacedInfo> _placed;
  // Ids of placed pieces, in the order they were placed (undo stack).
  late List<String> _history;

  // Active hint: the full solution for the remaining pieces — each piece with
  // its solved origin cell. Empty when no hint is showing. BoardPainter draws
  // these as a preview so the board reads as the completed picture.
  List<(Piece, int, int)> _hintSolution = [];

  // Whether the rewarded hint ad has already been shown for this level. After
  // the first paid hint, further hints this level reveal instantly (no ad).
  bool _hintUnlocked = false;

  GameState(this.level) {
    _remaining = List.from(level.pieces);
    _placed = {};
    _history = [];
  }

  List<Piece> get remainingPieces => List.unmodifiable(_remaining);
  Map<(int, int), PlacedInfo> get placedCells =>
      Map.unmodifiable(_placed);

  List<(Piece, int, int)> get hintSolution => List.unmodifiable(_hintSolution);
  bool get hintUnlocked => _hintUnlocked;

  bool get canUndo => _history.isNotEmpty;

  bool get isComplete =>
      level.targetCells.every((cell) => _placed.containsKey(cell));

  bool canPlace(Piece piece, int col, int row) {
    final target = level.targetSet;
    for (final cell in piece.absoluteCells(col, row)) {
      if (!target.contains(cell)) return false;
      if (_placed.containsKey(cell)) return false;
    }
    return true;
  }

  void placePiece(Piece piece, int col, int row) {
    if (!canPlace(piece, col, row)) return;
    final info = PlacedInfo(
      pieceId: piece.id,
      color: piece.color,
      darkColor: piece.darkColor,
    );
    for (final cell in piece.absoluteCells(col, row)) {
      _placed[cell] = info;
    }
    _remaining.removeWhere((p) => p.id == piece.id);
    _history.add(piece.id);
    // Clear any hint once the player places a piece — it may no longer apply.
    _hintSolution = [];
    notifyListeners();
  }

  /// Reveals [solution] — a placement for every remaining piece — as the active
  /// hint overlay, replacing any previous one.
  void showHintSolution(List<(Piece, int, int)> solution) {
    _hintSolution = solution;
    notifyListeners();
  }

  /// Marks the rewarded hint ad as watched for this level, so subsequent hints
  /// this level reveal without showing another ad.
  void markHintUnlocked() {
    _hintUnlocked = true;
  }

  void clearHint() {
    if (_hintSolution.isEmpty) return;
    _hintSolution = [];
    notifyListeners();
  }

  /// Solves the current board and returns a placement for **every** remaining
  /// piece (the full completed-board solution), or null if the position is no
  /// longer solvable (e.g. a piece was placed somewhere that blocks completion).
  ///
  /// Runs an exact-cover backtracking search over the *uncovered* target cells
  /// using only the remaining pieces, mirroring [canPlace] semantics (fixed
  /// orientation, cells must be inside the target and unoccupied).
  List<(Piece, int, int)>? solveHint() {
    final uncovered = level.targetSet.difference(_placed.keys.toSet());
    if (uncovered.isEmpty || _remaining.isEmpty) return null;

    // Every legal placement per remaining piece, as (originCol, originRow, cells).
    final placements = <List<(int, int, Set<(int, int)>)>>[];
    for (final piece in _remaining) {
      final pls = <(int, int, Set<(int, int)>)>[];
      for (final (oc, or) in uncovered) {
        // Anchor each candidate so the piece's first cell tries every open cell;
        // dedup happens naturally since identical cell-sets map to the same key.
        final baseCol = oc - piece.cells.first.dx;
        final baseRow = or - piece.cells.first.dy;
        final cells = piece.absoluteCells(baseCol, baseRow);
        if (cells.every(uncovered.contains)) {
          pls.add((baseCol, baseRow, cells.toSet()));
        }
      }
      if (pls.isEmpty) return null; // a piece that fits nowhere => unsolvable
      placements.add(pls);
    }

    final used = List<bool>.filled(_remaining.length, false);
    final chosen = List<int?>.filled(_remaining.length, null);

    bool backtrack(Set<(int, int)> covered) {
      if (covered.length == uncovered.length) return true;

      // Pick the uncovered cell with the fewest candidate placements (MRV).
      (int, int)? bestCell;
      List<(int, int)>? bestOptions; // (pieceIndex, placementIndex)
      for (final cell in uncovered) {
        if (covered.contains(cell)) continue;
        final options = <(int, int)>[];
        for (int i = 0; i < placements.length; i++) {
          if (used[i]) continue;
          for (int j = 0; j < placements[i].length; j++) {
            final pl = placements[i][j].$3;
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
        chosen[i] = j;
        if (backtrack({...covered, ...placements[i][j].$3})) return true;
        used[i] = false;
        chosen[i] = null;
      }
      return false;
    }

    if (!backtrack(<(int, int)>{})) return null;

    // Return a placement for every remaining piece — the full solution, which
    // BoardPainter draws as the completed-board preview.
    final solution = <(Piece, int, int)>[];
    for (int i = 0; i < _remaining.length; i++) {
      final j = chosen[i];
      if (j == null) continue;
      final (oc, or, _) = placements[i][j];
      solution.add((_remaining[i], oc, or));
    }
    return solution.isEmpty ? null : solution;
  }

  void removePiece(String pieceId) {
    _placed.removeWhere((_, info) => info.pieceId == pieceId);
    _history.remove(pieceId);
    final piece = level.pieces.firstWhere((p) => p.id == pieceId);
    _remaining.add(piece);
    notifyListeners();
  }

  /// Removes the most recently placed piece, returning it to the tray.
  void undo() {
    if (_history.isEmpty) return;
    removePiece(_history.last);
  }

  void reset() {
    _remaining = List.from(level.pieces);
    _placed = {};
    _history = [];
    _hintSolution = [];
    notifyListeners();
  }
}
