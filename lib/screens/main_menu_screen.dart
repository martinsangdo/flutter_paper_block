import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/levels.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int? _lastLevelIndex;

  @override
  void initState() {
    super.initState();
    _loadLastLevel();
  }

  Future<void> _loadLastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('lastLevel');
    if (idx != null && idx >= 0 && idx < allLevels.length) {
      setState(() => _lastLevelIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildTitle(),
            const Spacer(flex: 1),
            _buildPaperArt(),
            const Spacer(flex: 2),
            if (_lastLevelIndex != null) ...[
              _buildContinueButton(context),
              const SizedBox(height: 12),
            ],
            _buildPlayButton(context),
            const SizedBox(height: 40),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'PAPER',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFF3D2B1F),
            letterSpacing: 8,
            height: 1.0,
          ),
        ),
        const Text(
          'BLOCK',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE85D75),
            letterSpacing: 8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF8B7355),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Fit the pieces into the shape',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPaperArt() {
    // Decorative block grid preview
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _colorBlock(const Color(0xFFE85D75)),
        _colorBlock(const Color(0xFF5B8AD4)),
        _colorBlock(const Color(0xFF5DC48F)),
      ],
    );
  }

  Widget _colorBlock(Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final idx = _lastLevelIndex!;
    final levelNum = allLevels[idx].id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameScreen(levelIndex: idx)),
        ).then((_) => _loadLastLevel()),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF5B8AD4),
            borderRadius: BorderRadius.circular(29),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B6AAF).withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'CONTINUE  ·  LV $levelNum',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LevelSelectScreen(),
          ),
        ).then((_) => _loadLastLevel()),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE85D75),
            borderRadius: BorderRadius.circular(29),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC04060).withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'PLAY',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
