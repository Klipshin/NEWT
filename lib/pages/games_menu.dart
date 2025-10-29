import 'package:flutter/material.dart';
import 'card_game.dart';

class GamesMenu extends StatefulWidget {
  const GamesMenu({super.key});

  @override
  State<GamesMenu> createState() => _GamesMenuState();
}

class _GamesMenuState extends State<GamesMenu> {
  final PageController _pageController = PageController(
    viewportFraction: 0.55,
  ); // 👈 adds side space
  double currentPage = 0;

  final List<String> gameImages = const [
    'assets/images/fruits_basket.png',
    'assets/images/guess_the_animal.png',
    'assets/images/number_tracing.png',
    'assets/images/animal_sounds.png',
    'assets/images/shape_sorter.png',
    'assets/images/flip_a_card.png',
    'assets/images/color_fill.png',
    'assets/images/connect_the_dots.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌿 Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/landingv2.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // 🔙 Back button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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

          // 🎠 Carousel (no shadow)
          Center(
            child: PageView.builder(
              controller: _pageController,
              itemCount: gameImages.length,
              itemBuilder: (context, index) {
                final double distance = (currentPage - index).abs();
                final double scale = 1 - distance * 0.25; // smaller on sides
                final double opacity = 1 - distance * 0.4;

                return Transform.scale(
                  scale: scale.clamp(0.8, 1.0),
                  child: Opacity(
                    opacity: opacity.clamp(0.5, 1.0),
                    child: GestureDetector(
                      onTap: () {
                        if (gameImages[index].contains('flip_a_card')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CardGame(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            gameImages[index],
                            fit: BoxFit.contain, // keep original size
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
