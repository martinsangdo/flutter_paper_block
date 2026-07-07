import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays the game's sound effects (bundled WAVs under assets/sounds/) with a
/// persisted on/off setting, plus light haptics on mobile. All playback is a
/// no-op while [enabled] is false.
class SoundService extends ChangeNotifier {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const String _prefsKey = 'soundOn';
  bool _enabled = true;
  bool get enabled => _enabled;

  // Short effects (pickup/place/invalid) share one low-latency player; the
  // longer completion chime gets its own so it isn't cut off.
  final AudioPlayer _sfx = AudioPlayer(playerId: 'pb_sfx')
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _music = AudioPlayer(playerId: 'pb_music')
    ..setReleaseMode(ReleaseMode.stop);

  static const _assets = <String>[
    'sounds/pickup.wav',
    'sounds/place.wav',
    'sounds/invalid.wav',
    'sounds/complete.wav',
  ];

  /// Loads the saved preference (defaults to on) and warms the asset cache so
  /// the first play is snappy. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;
    try {
      await AudioCache.instance.loadAll(_assets);
    } catch (_) {
      // Preload is best-effort (e.g. web); sounds still play on demand.
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    _enabled = !_enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _enabled);
  }

  Future<void> _play(AudioPlayer player, String asset, double volume) async {
    if (!_enabled) return;
    try {
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Never let audio failures affect gameplay.
    }
  }

  /// Feedback when a drag starts from the tray.
  void playPickup() => _play(_sfx, 'sounds/pickup.wav', 0.5);

  /// Feedback for successfully placing a piece.
  void playPlace() {
    _play(_sfx, 'sounds/place.wav', 0.9);
    HapticFeedback.lightImpact();
  }

  /// Feedback for a rejected (invalid) drop.
  void playInvalid() {
    _play(_sfx, 'sounds/invalid.wav', 0.7);
    HapticFeedback.selectionClick();
  }

  /// Feedback for completing a level.
  void playComplete() {
    _play(_music, 'sounds/complete.wav', 0.9);
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _sfx.dispose();
    _music.dispose();
    super.dispose();
  }
}
