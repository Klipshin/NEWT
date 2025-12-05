import 'package:flutter/material.dart';
import 'games_menu.dart';
import 'puzzle_game.dart';

class PuzzleMenu extends StatefulWidget {
  const PuzzleMenu({super.key});

  @override
  State<PuzzleMenu> createState() => _PuzzleMenuState();
}

class _PuzzleMenuState extends State<PuzzleMenu> {
  bool _showDCardOverlay = true;

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PuzzleGame(imagePath: path),
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
