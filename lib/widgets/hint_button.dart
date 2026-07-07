import 'package:flutter/material.dart';

/// Top-right gameplay Hint control.
///
/// This is a PLACEHOLDER — no AdMob / rewarded-ad SDK is wired up yet. Tapping
/// it shows a "coming soon" dialog. To make it real later, replace the body of
/// [_onPressed] with the rewarded-ad flow (show ad → on reward, reveal a hint).
/// The button's placement and styling in the header stay unchanged.
class HintButton extends StatelessWidget {
  const HintButton({super.key});

  void _onPressed(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hint'),
        content: const Text('Hints are coming soon!'),
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
