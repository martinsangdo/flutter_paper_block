import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/levels.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../services/ad_service.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/piece_tray_widget.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameState _gameState;
  late AnimationController _completeController;
  late Animation<double> _completeAnim;
  bool _showComplete = false;

  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _saveLastLevel();
    _gameState = GameState(allLevels[widget.levelIndex]);
    _completeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completeAnim = CurvedAnimation(
      parent: _completeController,
      curve: Curves.elasticOut,
    );
    _gameState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onStateChange);
    _gameState.dispose();
    _completeController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (_gameState.isComplete && !_showComplete) {
      _unlockNext();
      setState(() => _showComplete = true);
      _completeController.forward();
    }
  }

  Future<void> _saveLastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastLevel', widget.levelIndex);
  }

  Future<void> _unlockNext() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('unlocked') ?? 1;
    final nextId = allLevels[widget.levelIndex].id + 1;
    if (nextId > current && nextId <= allLevels.length) {
      await prefs.setInt('unlocked', nextId);
    }
  }

  void _reset() {
    setState(() => _showComplete = false);
    _completeController.reset();
    _gameState.reset();
  }

  void _nextLevel() {
    final next = widget.levelIndex + 1;
    if (next < allLevels.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(levelIndex: next)),
      );
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  double _calcCellSize(BoxConstraints constraints) {
    final level = _gameState.level;
    final maxW = (constraints.maxWidth - 32) / level.cols;
    final maxH = (constraints.maxHeight * 0.55) / level.rows;
    return (maxW < maxH ? maxW : maxH).clamp(28.0, 56.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = _calcCellSize(constraints);
            return Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBoardArea(cellSize),
                ),
                _buildTray(cellSize),
                ListenableBuilder(
                  listenable: AdService.instance,
                  builder: (context, _) => _buildBanner(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final level = _gameState.level;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8B7355)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Level ${level.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B7355),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  level.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D2B1F),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: AdService.instance,
            builder: (context, _) => IconButton(
              icon: Icon(
                Icons.lightbulb_outline,
                color: AdService.instance.isRewardedLoaded
                    ? const Color(0xFFE85D75)
                    : const Color(0xFFCCBBAA),
              ),
              onPressed: AdService.instance.isRewardedLoaded
                  ? _showRewardedHint
                  : null,
              tooltip: 'Hint (watch ad)',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B7355)),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea(double cellSize) {
    final level = _gameState.level;
    final boardW = level.cols * cellSize;
    final boardH = level.rows * cellSize;

    final boardWidget = GameBoardWidget(
      key: _boardKey,
      gameState: _gameState,
      cellSize: cellSize,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: DragTarget<Piece>(
            onWillAcceptWithDetails: (details) {
              _getBoardWidget()
                  ?.updateGhost(details.data, _globalToLocal(details.offset));
              return true;
            },
            onMove: (details) {
              _getBoardWidget()
                  ?.updateGhost(details.data, _globalToLocal(details.offset));
            },
            onLeave: (_) => _getBoardWidget()?.clearGhost(),
            onAcceptWithDetails: (details) {
              _getBoardWidget()
                  ?.tryPlace(details.data, _globalToLocal(details.offset));
            },
            builder: (context, candidateData, rejectedData) {
              return SizedBox(
                width: boardW,
                height: boardH,
                child: boardWidget,
              );
            },
          ),
        ),
        if (_showComplete) _buildCompleteOverlay(),
      ],
    );
  }

  GameBoardWidgetState? _getBoardWidget() {
    return (_boardKey.currentState as GameBoardWidgetState?);
  }

  Offset _globalToLocal(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  Widget _buildTray(double cellSize) {
    return ListenableBuilder(
      listenable: _gameState,
      builder: (context, child) => Container(
        margin: const EdgeInsets.all(12),
        child: PieceTrayWidget(
          pieces: _gameState.remainingPieces,
          cellSize: cellSize,
        ),
      ),
    );
  }

  void _showRewardedHint() {
    AdService.instance.showRewarded(
      onRewarded: () {
        if (!mounted) return;
        final remaining = _gameState.remainingPieces;
        if (remaining.isEmpty) return;
        final hint = remaining.first;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hint: try placing the ${hint.color} piece first!'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF5B8AD4),
        ));
      },
    );
  }

  Widget _buildBanner() {
    final banner = AdService.instance.bannerAd;
    if (banner == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }

  Widget _buildCompleteOverlay() {
    final isLast = widget.levelIndex >= allLevels.length - 1;
    return ScaleTransition(
      scale: _completeAnim,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'Puzzle Complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D2B1F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Well done!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B7355),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _overlayButton(
                  label: 'Retry',
                  color: const Color(0xFF8B7355),
                  onTap: _reset,
                ),
                const SizedBox(width: 12),
                _overlayButton(
                  label: isLast ? 'Menu' : 'Next →',
                  color: const Color(0xFFE85D75),
                  onTap: _nextLevel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
