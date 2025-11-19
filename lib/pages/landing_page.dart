import 'package:flutter/material.dart';
import 'package:newt_2/pages/storybooks.dart';
import 'games_menu.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // For Music
  final AudioPlayer _sfxPlayer = AudioPlayer(); // For Sound Effects (NEW)

  bool _isPlaying = true;
  double _swayValue = -0.1;
  bool _bounceUp = true;

  @override
  void initState() {
    super.initState();
    _playMusic();
    _startSwaying();
    _startBouncing();
  }

  // ... (Keep _startBouncing, _startSwaying, _playMusic, _toggleSound as they were) ...

  void _startBouncing() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 800));
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
      await Future.delayed(Duration(milliseconds: 2500));
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
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/card.mp3'));
  }

  void _toggleSound() {
    setState(() {
      if (_isPlaying) {
        _audioPlayer.pause();
        _isPlaying = false;
      } else {
        _audioPlayer.resume();
        _isPlaying = true;
      }
    });
  }

  void _navigateToGames() async {
    if (_isPlaying) _audioPlayer.pause();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamesMenu()),
    );
    if (_isPlaying) _audioPlayer.resume();
  }

  void _navigateToStorybooks() async {
    if (_isPlaying) _audioPlayer.pause();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryBooksPage()),
    );
    if (_isPlaying) _audioPlayer.resume();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _sfxPlayer.dispose(); // Don't forget to dispose the SFX player too!
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

          // Logo (NEWT WITH POP SOUND)
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            child: Center(
              child: ZoomTapAnimation(
                begin: 1.0,
                end: 0.90, // Shrink slightly when tapped
                onTap: () {
                  // Play the pop sound using the separate SFX player
                  // Assuming pop.mp3 is in assets/sounds/
                  _sfxPlayer.play(AssetSource('sounds/pop.mp3'));
                },
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
              duration: Duration(milliseconds: 800),
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
              duration: Duration(milliseconds: 2500),
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
