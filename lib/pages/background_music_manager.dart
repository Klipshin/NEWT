import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Manages background music using the Singleton pattern with fade effects.
class BackgroundMusicManager {
  // 1. Static instance of the class (the Singleton)
  static final BackgroundMusicManager _instance =
      BackgroundMusicManager._internal();

  // 2. Factory constructor to always return the single instance
  factory BackgroundMusicManager() {
    return _instance;
  }

  // 3. Private constructor to prevent external creation
  BackgroundMusicManager._internal();

  // The actual AudioPlayer instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- Fade Properties ---
  final double _targetVolume =
      0.5; // Normal volume level for background music (0.0 to 1.0)
  final double _fadeStep = 0.05; // Volume increment/decrement per step
  final int _fadeDurationMs = 50; // Time between volume changes (50ms)
  Timer? _fadeTimer; // Timer object for managing the fade loop

  bool _isPlaying = false;
  bool _isInitialized = false;

  bool get isPlaying => _isPlaying;

  /// Starts the music at the normal volume, handling initialization.
  Future<void> startMusic() async {
    if (_isPlaying) return;

    if (!_isInitialized) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_targetVolume); // Set initial volume
      await _audioPlayer.play(AssetSource('sounds/guitar.mp3'));
      _isInitialized = true;
      _isPlaying = true;
    } else {
      await _audioPlayer.resume();
      _isPlaying = true;
    }
  }

  /// Gradually increases the volume from 0.0 to _targetVolume.
  Future<void> fadeInMusic() async {
    _fadeTimer?.cancel(); // Cancel any existing fade operation

    if (!_isInitialized) {
      // Start the music muted if it hasn't been initialized yet
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.0);
      await _audioPlayer.play(AssetSource('sounds/guitar.mp3'));
      _isInitialized = true;
      _isPlaying = true;
    } else if (!_isPlaying) {
      // Set volume to 0 before resuming for smooth fade
      await _audioPlayer.setVolume(0.0);
      await _audioPlayer.resume();
      _isPlaying = true;
    }

    // Perform the fade-in
    double currentVolume = 0.0;
    _fadeTimer = Timer.periodic(Duration(milliseconds: _fadeDurationMs), (
      timer,
    ) async {
      currentVolume += _fadeStep;

      if (currentVolume >= _targetVolume) {
        await _audioPlayer.setVolume(_targetVolume);
        timer.cancel();
        _fadeTimer = null;
      } else {
        await _audioPlayer.setVolume(currentVolume);
      }
    });
  }

  /// Gradually decreases the volume from current volume to 0.0, then pauses.
  Future<void> fadeOutMusic() async {
    if (!_isPlaying) return;

    _fadeTimer?.cancel(); // Cancel any existing fade operation

    // Get the starting volume
    double currentVolume = _targetVolume;

    _fadeTimer = Timer.periodic(Duration(milliseconds: _fadeDurationMs), (
      timer,
    ) async {
      currentVolume -= _fadeStep;

      if (currentVolume <= 0.0) {
        await _audioPlayer.setVolume(0.0);
        await _audioPlayer.pause();
        _isPlaying = false;
        timer.cancel();
        _fadeTimer = null;
      } else {
        await _audioPlayer.setVolume(currentVolume);
      }
    });
  }

  /// Method to pause the music instantly (use fadeOutMusic for effect).
  Future<void> pauseMusic() async {
    _fadeTimer?.cancel();
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  /// Method to resume the music instantly (use fadeInMusic for effect).
  Future<void> resumeMusic() async {
    _fadeTimer?.cancel();
    if (!_isPlaying && _isInitialized) {
      await _audioPlayer.resume();
      await _audioPlayer.setVolume(
        _targetVolume,
      ); // Instantly set volume to target
      _isPlaying = true;
    }
  }

  /// Method to toggle the sound state
  Future<void> toggleSound() async {
    if (_isPlaying) {
      await fadeOutMusic(); // Use fade out for a smoother experience
    } else {
      await fadeInMusic(); // Use fade in for a smoother experience
    }
  }

  /// Dispose of the player resources (should ideally only be called when exiting the app)
  void dispose() {
    _fadeTimer?.cancel();
    _audioPlayer.dispose();
  }
}
