import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/ad_service.dart';

/// Top-right gameplay Hint control.
///
/// Tapping it reveals the **completed board** — a backtracking solver
/// ([GameState.solveHint]) computes a placement for every remaining piece and
/// BoardPainter draws the full solution as a preview overlay.
///
/// A **rewarded ad** gates the hint, but only **once per level**: the first tap
/// this level plays the ad and, on reward, unlocks hints for the rest of the
/// level so further taps reveal instantly. If the board can no longer be solved
/// (a piece is blocking completion) the user is told to undo/reset — no ad. If
/// no rewarded ad is available (e.g. offline), the hint is granted anyway so
/// gameplay is never blocked by ad availability.
class HintButton extends StatelessWidget {
  final GameState gameState;
  const HintButton({super.key, required this.gameState});

  void _onPressed(BuildContext context) {
    final solution = gameState.solveHint();
    if (solution == null) {
      _showDialog(
        context,
        'No hint available',
        'A placed piece is blocking the solution. Try Undo or Reset, then '
            'ask for a hint again.',
      );
      return;
    }

    void reveal() => gameState.showHintSolution(solution);

    // The rewarded ad is charged only once per level; after that, hints are
    // free for the rest of the level.
    if (gameState.hintUnlocked) {
      reveal();
      return;
    }

    final shown = AdService.instance.showRewarded(onReward: () {
      gameState.markHintUnlocked();
      reveal();
    });
    if (!shown) {
      // No ad ready (offline / not yet loaded): don't block the player.
      gameState.markHintUnlocked();
      reveal();
    }
  }

  void _showDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.lightbulb_outline, color: Color(0xFFE85D75)),
      onPressed: () => _onPressed(context),
      tooltip: 'Hint',
    );
  }
}
