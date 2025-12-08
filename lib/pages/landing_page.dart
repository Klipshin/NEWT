import 'package:flutter/material.dart';
import 'package:newt_2/pages/storybooks.dart';
import 'games_menu.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'background_music_manager.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // using the global music manager instead of a local AudioPlayer
  final BackgroundMusicManager _musicManager = BackgroundMusicManager();

  // Initialize with the current global state of the music manager
  late bool _isPlaying;
  double _swayValue = -0.1;
  bool _bounceUp = true;

  @override
  void initState() {
    super.initState();
    _playMusic();
    _startSwaying();
    _startBouncing();
    // Initialize local state based on manager's current state
    _isPlaying = _musicManager.isPlaying;
  }

  void _startBouncing() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _bounceUp = !_bounceUp;
        });
        return true;
      }
      return false;
    });
  }

  void _startSwaying() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() {
          _swayValue = _swayValue == -0.1 ? 0.1 : -0.1;
        });
        return true;
      }
      return false;
    });
  }

  void _playMusic() async {
    // Starts music if not already running
    await _musicManager.startMusic();
    // Update local state for UI icon
    setState(() {
      _isPlaying = _musicManager.isPlaying;
    });
  }

  void _toggleSound() async {
    // Toggle the local state first for immediate UI feedback
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // Then toggle the actual music
    await _musicManager.toggleSound();
  }

  // Navigation functions no longer need pause/resume because the music
  // is now managed by the global manager and persists.
  void _navigateToGames() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamesMenu()),
    );
  }

  void _navigateToStorybooks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryBooksPage()),
    );
  }

  @override
  void dispose() {
    // DO NOT DISPOSE THE AUDIO PLAYER HERE. The manager holds it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.82,
              child: Image.asset(
                'assets/images/landingv00.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo (NEWT)
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            child: Center(
              child: ZoomTapAnimation(
                begin: 1.0,
                end: 0.90,
                child: Image.asset('assets/images/newt3.png', width: 350),
              ),
            ),
          ),

          // Play Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.60,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, _bounceUp ? -10 : 0, 0),
              child: GestureDetector(
                onTap: _navigateToGames,
                child: Center(
                  child: Image.asset('assets/images/play.png', width: 220),
                ),
              ),
            ),
          ),

          // Story Time Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.50,
            left: MediaQuery.of(context).size.width * 0.05,
            child: AnimatedRotation(
              turns: _swayValue / (2 * 3.14159),
              duration: const Duration(milliseconds: 2500),
              curve: Curves.easeInOut,
              child: GestureDetector(
                onTap: _navigateToStorybooks,
                child: Image.asset('assets/images/storytime0.png', width: 200),
              ),
            ),
          ),

          // Sound Toggle
          Positioned(
            bottom: 25,
            right: 25,
            child: GestureDetector(
              onTap: _toggleSound,
              child: Image.asset(
                _isPlaying
                    ? 'assets/images/volume.png'
                    : 'assets/images/volumeoff.png',
                width: 55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
