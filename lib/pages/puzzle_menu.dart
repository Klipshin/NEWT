import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'games_menu.dart';
import 'puzzle_game.dart';

class PuzzleMenu extends StatefulWidget {
  const PuzzleMenu({super.key});

  @override
  State<PuzzleMenu> createState() => _PuzzleMenuState();
}

class _PuzzleMenuState extends State<PuzzleMenu> {
  bool _showDCardOverlay = true;
  late AudioPlayer _bgMusicPlayer;

  @override
  void initState() {
    super.initState();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  // IMPORTANT: We REMOVE the dispose call here, as the player needs to stay alive
  // when navigating to PuzzleGame. We dispose when explicitly leaving the flow (to GamesMenu).
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    // Only play if the music is not already playing (e.g., when returning from PuzzleGame)
    if (_bgMusicPlayer.state != PlayerState.playing) {
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer.play(AssetSource('sounds/intro.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> stories = [
      'assets/images/pond.png',
      'assets/images/birb.png',
      'assets/images/panda.png',
      'assets/images/wolf.png',
      'assets/images/capy.png',
      'assets/images/redi.png',
      'assets/images/bear_puzzle.png',
      'assets/images/cat_puzzle.png',
      'assets/images/wizard_puzzle.png',
    ];

    return Scaffold(
      body: Stack(
        children: [
          // bg
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/landingv2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // carousel
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 80, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(stories.length, (index) {
                  final path = stories[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GestureDetector(
                      onTap: () {
                        // **CHANGE: Pass the existing AudioPlayer instance to PuzzleGame**
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PuzzleGame(
                              imagePath: path,
                              bgMusicPlayer: _bgMusicPlayer,
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        path,
                        width: 280,
                        height: 380,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // back button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // **CHANGE: Dispose the player only when navigating away from the puzzle flow**
                _bgMusicPlayer.dispose();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesMenu()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 28),
              ),
            ),
          ),

          // dialogue
          if (_showDCardOverlay)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDCardOverlay = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/dpuzz.png',
                    width: MediaQuery.of(context).size.width * 1.0,
                    height: MediaQuery.of(context).size.height * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
