import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central haptic + sound feedback so the app *feels* alive.
///
/// - All calls are fire-and-forget and never throw (safe to call anywhere).
/// - Sound and haptics can be toggled independently and are persisted.
/// - Sound assets are synthesized WAVs under assets/sounds/ (see
///   tool/generate_sounds.py), so there are no external/licensed files.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  static const _soundKey = 'feedback_sound_enabled';
  static const _hapticKey = 'feedback_haptic_enabled';

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _loaded = false;

  final Map<String, AudioPlayer> _players = {};
  AudioPlayer? _loopPlayer;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  /// Load persisted preferences. Safe to call multiple times.
  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_soundKey) ?? true;
      _hapticEnabled = prefs.getBool(_hapticKey) ?? true;
    } catch (_) {
      // keep defaults
    }
    _loaded = true;
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    if (!value) {
      await stopLoop();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundKey, value);
    } catch (_) {}
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticKey, value);
    } catch (_) {}
  }

  AudioPlayer _player(String name) {
    return _players.putIfAbsent(name, () {
      final p = AudioPlayer(playerId: 'oxyn_$name');
      p.setReleaseMode(ReleaseMode.stop);
      // Low-latency mode is best-effort; ignore if unsupported.
      p.setPlayerMode(PlayerMode.lowLatency);
      return p;
    });
  }

  Future<void> _playAsset(String file) async {
    if (!_soundEnabled) return;
    try {
      final p = _player(file);
      await p.stop();
      await p.play(AssetSource('sounds/$file'), volume: 1.0);
    } catch (e) {
      if (kDebugMode) debugPrint('FeedbackService sound error ($file): $e');
    }
  }

  Future<void> _haptic(Future<void> Function() fn) async {
    if (!_hapticEnabled) return;
    try {
      await fn();
    } catch (_) {}
  }

  // --- Semantic feedback -----------------------------------------------------

  /// Light tap for ordinary buttons / list rows.
  Future<void> tap() async {
    await _haptic(HapticFeedback.selectionClick);
    await _playAsset('tap.wav');
  }

  /// A selection / toggle / reveal with a playful pop.
  Future<void> select() async {
    await _haptic(HapticFeedback.lightImpact);
    await _playAsset('pop.wav');
  }

  /// Screen / sheet transition whoosh.
  Future<void> whoosh() async {
    await _playAsset('whoosh.wav');
  }

  /// Positive completion (scan done, cleaned, purchase success...).
  Future<void> success() async {
    await _haptic(HapticFeedback.mediumImpact);
    await _playAsset('success.wav');
  }

  /// Strong electric strike (battery 100%, big reveal).
  Future<void> strike() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _playAsset('zap.wav');
  }

  /// A tiny warning nudge.
  Future<void> warn() async {
    await _haptic(HapticFeedback.mediumImpact);
    await _playAsset('pop.wav');
  }

  // --- Looping charge hum (battery hold-to-charge) ---------------------------

  Future<void> startLoop() async {
    if (!_soundEnabled) return;
    try {
      _loopPlayer ??= AudioPlayer(playerId: 'oxyn_loop');
      await _loopPlayer!.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer!.stop();
      await _loopPlayer!.play(AssetSource('sounds/charge.wav'), volume: 0.9);
    } catch (e) {
      if (kDebugMode) debugPrint('FeedbackService loop error: $e');
    }
  }

  Future<void> stopLoop() async {
    try {
      await _loopPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    await _loopPlayer?.dispose();
    _loopPlayer = null;
  }
}

/// Short global accessor.
FeedbackService get feedback => FeedbackService.instance;
