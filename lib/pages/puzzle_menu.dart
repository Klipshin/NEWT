import 'package:flutter/material.dart';
import 'games_menu.dart';

class PuzzleMenu extends StatelessWidget {
  const PuzzleMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> stories = [
      'assets/images/cat_puzzle.png',
      'assets/images/bear_puzzle.png',
      'assets/images/wizard_puzzle.png',
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 🖼 Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.8, // 👈 80% visible
              child: Image.asset(
                'assets/images/landingv2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 📚 Storybook Carousel
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
                      onTap: () {},
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

          // 🔙 Clickable Back Button — on top of everything
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque, // ✅ ensures tap always registers
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
        ],
      ),
    );
  }
}
