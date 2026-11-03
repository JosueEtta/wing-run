import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// One place for all game sounds: looping music + collision effect.
class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final instance = AudioService._();

  static const _musicFile = 'audio/music.ogg';
  static const _crashFile = 'audio/crash.wav';

  final _music = AudioPlayer();
  final _sfx = AudioPlayer();
  bool _musicWanted = false;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);

    // Let the music and the effects play together. Without this, the crash
    // sound takes Android's audio focus and the music stops.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );

    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(0.4); // keep the music below the effects
    await _sfx.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> playMusic() async {
    _musicWanted = true;
    try {
      await _music.play(AssetSource(_musicFile));
    } catch (e) {
      debugPrint('Music error: $e');
    }
  }

  /// Safety net: if the music stopped for any reason, start it again.
  Future<void> ensureMusic() async {
    if (!_musicWanted) return;
    try {
      if (_music.state == PlayerState.playing) return;
      if (_music.state == PlayerState.paused) {
        await _music.resume();
      } else {
        await _music.play(AssetSource(_musicFile));
      }
    } catch (e) {
      debugPrint('Music error: $e');
    }
  }

  Future<void> playCrash() async {
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(_crashFile));
    } catch (e) {
      debugPrint('Crash sound error: $e');
    }
  }

  /// Pause the music when the app goes to the background, resume on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _music.pause();
    } else if (state == AppLifecycleState.resumed && _musicWanted) {
      _music.resume();
    }
  }
}