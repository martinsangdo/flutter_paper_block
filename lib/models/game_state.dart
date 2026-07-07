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

  GameState(this.level) {
    _remaining = List.from(level.pieces);
    _placed = {};
    _history = [];
  }

  List<Piece> get remainingPieces => List.unmodifiable(_remaining);
  Map<(int, int), PlacedInfo> get placedCells =>
      Map.unmodifiable(_placed);

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
    notifyListeners();
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
    notifyListeners();
  }
}
