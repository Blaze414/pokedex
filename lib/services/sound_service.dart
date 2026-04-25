import 'package:audioplayers/audioplayers.dart';

/// Singleton that owns a dedicated [AudioPlayer] for UI tap sounds.
/// Pre-loading the source removes the small delay on first tap.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  static const String _plinkAsset = 'sounds/plink.mp3';

  /// Call once at app startup (e.g. in main() or initState of HomeScreen).
  Future<void> init() async {
    if (_ready) return;
    await _player.setSource(AssetSource(_plinkAsset));
    await _player.setVolume(1.0);
    // Release mode keeps the player open between plays.
    await _player.setReleaseMode(ReleaseMode.stop);
    _ready = true;
  }

  /// Play the plink sound. Safe to call even before [init] completes.
  Future<void> playPlink() async {
    try {
      if (!_ready) await init();
      // Seek to start so rapid taps each play from the beginning.
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Silently swallow audio errors — never crash the UI over a sound.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}