import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/levels.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _unlockedCount = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedCount = prefs.getInt('unlocked') ?? 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        title: const Text(
          'Select Level',
          style: TextStyle(
            color: Color(0xFF3D2B1F),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8B7355)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: allLevels.length,
          itemBuilder: (context, i) {
            final level = allLevels[i];
            final unlocked = level.id <= _unlockedCount;
            return _LevelTile(
              level: level,
              unlocked: unlocked,
              onTap: unlocked
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(levelIndex: i),
                        ),
                      );
                      _loadProgress();
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final dynamic level;
  final bool unlocked;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.unlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFEDE5D5) : const Color(0xFFDDD5C5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? const Color(0xFFE85D75)
                : const Color(0xFFBBB0A0),
            width: 2,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFFE85D75).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unlocked ? Icons.crop_square : Icons.lock,
              color: unlocked
                  ? const Color(0xFFE85D75)
                  : const Color(0xFFBBB0A0),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              '${level.id}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: unlocked
                    ? const Color(0xFF3D2B1F)
                    : const Color(0xFFBBB0A0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
