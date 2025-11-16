import 'package:flutter/material.dart';
import 'package:newt_2/pages/storybooks.dart';
import 'games_menu.dart';
import 'package:audioplayers/audioplayers.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  // --- NEW FUNCTION TO HANDLE NAVIGATION & SOUND ---
  void _navigateToGames() async {
    if (_isPlaying) _audioPlayer.pause(); // Pause music

    // Go to the Games page and wait until we come back
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamesMenu()),
    );

    // When we come back, resume music (if it was on)
    if (_isPlaying) _audioPlayer.resume();
  }

  // --- NEW FUNCTION TO HANDLE NAVIGATION & SOUND ---
  void _navigateToStorybooks() async {
    if (_isPlaying) _audioPlayer.pause(); // Pause music

    // Go to the Storybooks page and wait until we come back
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryBooksPage()),
    );

    // When we come back, resume music (if it was on)
    if (_isPlaying) _audioPlayer.resume();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //Background
          Positioned.fill(
            child: Opacity(
              // <--- WRAP WITH THIS WIDGET
              opacity: 0.82, // <--- SET TO 80%
              child: Image.asset(
                'assets/images/landingv00.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo (NEW)
          Positioned(
            top: 5, // At the top
            left: 0, // Centered
            right: 0, // Centered
            child: Center(
              child: Image.asset('assets/images/newt3.png', width: 350),
            ),
          ),

          //Play
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

          //Story Time (MOVED & ENLARGED)
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
          //Sound
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
