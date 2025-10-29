import 'package:flutter/material.dart';
import 'card_game.dart';
import 'fruit_game.dart';
import 'connect_dots.dart';
import 'animal_sounds.dart';
import 'landing_page.dart';

class GamesMenu extends StatefulWidget {
  const GamesMenu({super.key});

  @override
  State<GamesMenu> createState() => _GamesMenuState();
}

class _GamesMenuState extends State<GamesMenu> {
  final PageController _pageController = PageController(viewportFraction: 0.55);
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

  void _handleGameTap(String image) {
    if (image.contains('flip_a_card')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CardGame()),
      );
    } else if (image.contains('fruits_basket')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FruitGame()),
      );
    } else if (image.contains('connect_the_dots')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ConnectDotsGame()),
      );
    } else if (image.contains('animal_sounds')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnimalSoundsQuiz()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
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

          // 🎠 Carousel (placed below)
          Positioned.fill(
            child: Center(
              child: PageView.builder(
                controller: _pageController,
                itemCount: gameImages.length,
                itemBuilder: (context, index) {
                  final double distance = (currentPage - index).abs();
                  final double scale = 1 - distance * 0.25;
                  final double opacity = 1 - distance * 0.4;

                  return Transform.scale(
                    scale: scale.clamp(0.8, 1.0),
                    child: Opacity(
                      opacity: opacity.clamp(0.5, 1.0),
                      child: GestureDetector(
                        onTap: () => _handleGameTap(gameImages[index]),
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
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🔙 Back button (always on top, clickable)
          Positioned(
            top: 40,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LandingPage(),
                    ),
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
          ),
        ],
      ),
    );
  }
}
