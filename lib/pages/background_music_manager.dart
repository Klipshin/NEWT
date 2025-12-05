import 'package:audioplayers/audioplayers.dart';

/// Manages background music using the Singleton pattern to ensure the player
/// persists across different widgets.
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
  bool _isPlaying = false;

  // Flag to track if the audio player has been initialized and is playing
  bool _isInitialized = false;

  bool get isPlaying => _isPlaying;

  // Method to initialize and start playing the music
  Future<void> startMusic() async {
    if (_isPlaying) return; // Already playing

    if (!_isInitialized) {
      // Configure and load the source only the first time
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/intro.mp3'));
      _isInitialized = true;
    } else {
      // Resume if already loaded
      await _audioPlayer.resume();
    }
    _isPlaying = true;
  }

  // Method to pause the music
  Future<void> pauseMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  // Method to resume the music
  Future<void> resumeMusic() async {
    if (!_isPlaying && _isInitialized) {
      await _audioPlayer.resume();
      _isPlaying = true;
    }
  }

  // Method to toggle the sound state
  Future<void> toggleSound() async {
    if (_isPlaying) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

  // Dispose of the player resources (should ideally only be called when exiting the app)
  void dispose() {
    _audioPlayer.dispose();
  }
}
