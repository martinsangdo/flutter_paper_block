import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/levels.dart';
import '../route_observer.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with RouteAware {
  int _unlockedCount = 1;
  Set<int> _completed = <int>{};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when a route pushed above this one (gameplay) is popped and the
  // level list becomes visible again — refresh unlock/completion state so
  // newly unlocked levels show immediately.
  @override
  void didPopNext() => _loadProgress();

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList('completed') ?? <String>[];
    setState(() {
      _unlockedCount = prefs.getInt('unlocked') ?? 1;
      _completed = done.map(int.parse).toSet();
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
            final completed = _completed.contains(level.id);
            return _LevelTile(
              level: level,
              unlocked: unlocked,
              completed: completed,
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
  final bool completed;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.completed,
    this.onTap,
  });

  static const Color _locked = Color(0xFFBBB0A0);
  static const Color _coral = Color(0xFFE85D75);
  static const Color _green = Color(0xFF5DC48F);

  @override
  Widget build(BuildContext context) {
    // Accent drives border, icon and shadow: green = completed, coral =
    // unlocked-not-done, muted = locked.
    final Color accent = !unlocked
        ? _locked
        : completed
            ? _green
            : _coral;

    final IconData icon = !unlocked
        ? Icons.lock
        : completed
            ? Icons.check_circle
            : Icons.crop_square;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFEDE5D5) : const Color(0xFFDDD5C5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent, width: 2),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 20),
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
