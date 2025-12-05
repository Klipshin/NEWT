import 'package:flutter/material.dart';
import 'package:newt_2/pages/puzzle_menu.dart';
import 'card_game.dart';
import 'fruit_game.dart';
import 'connect_dots.dart';
import 'animal_sounds.dart';
import 'landing_page.dart';
import "guess_animal.dart";
import 'color_game.dart';
import 'background_music_manager.dart'; // <--- NEW IMPORT

class GamesMenu extends StatefulWidget {
  const GamesMenu({super.key});

  @override
  State<GamesMenu> createState() => _GamesMenuState();
}

class _GamesMenuState extends State<GamesMenu> {
  late PageController _pageController;
  double currentPage = 0;
  final BackgroundMusicManager _musicManager =
      BackgroundMusicManager(); // <--- MANAGER INSTANCE

  // 1. Define a large number for "infinite" feeling
  final int _infinitePageCount = 100000;
  late int _initialPage;

  final List<String> gameImages = const [
    'assets/images/fruits_basket.png',
    'assets/images/guess_the_animal.png',
    'assets/images/animal_sounds.png',
    'assets/images/puzzle_piece.png',
    'assets/images/flip_a_card.png',
    'assets/images/color_fill.png',
    'assets/images/connect_the_dots.png',
  ];

  @override
  void initState() {
    super.initState();

    // 2. Calculate the middle index
    _initialPage = (_infinitePageCount / 2).round();
    final int remainder = _initialPage % gameImages.length;
    if (remainder != 0) {
      _initialPage -= remainder;
    }

    // 3. Initialize controller starting at that middle index
    _pageController = PageController(
      viewportFraction: 0.55,
      initialPage: _initialPage,
    );

    // Initialize currentPage to match the initialPage so scaling works immediately
    currentPage = _initialPage.toDouble();

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

  void _handleGameTap(String image) async {
    // <--- MADE ASYNC
    // 1. Define the page to navigate to
    Widget page;
    if (image.contains('flip_a_card')) {
      page = const CardGame();
    } else if (image.contains('fruits_basket')) {
      page = const FruitGame();
    } else if (image.contains('connect_the_dots')) {
      page = const ConnectDotsGame();
    } else if (image.contains('guess_the_animal')) {
      page = const GuessAnimalGame();
    } else if (image.contains('animal_sounds')) {
      page = const AnimalSoundsQuiz();
    } else if (image.contains('color_fill')) {
      page = const ColorFloodGame();
    } else if (image.contains('puzzle_piece')) {
      page = const PuzzleMenu();
    } else {
      return; // Safety break
    }

    // 2. Pause music before pushing the game page (optional, but standard for focused gameplay)
    _musicManager.pauseMusic();

    // 3. Navigate and WAIT for the game page to be popped
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    // 4. Resume music when returning to GamesMenu
    _musicManager.resumeMusic();
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

          // 🎠 Carousel
          Positioned.fill(
            child: Center(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _infinitePageCount, // Uses the large number
                itemBuilder: (context, index) {
                  // 4. Use Modulo (%) to loop through the 8 images repeatedly
                  final realIndex = index % gameImages.length;

                  final double distance = (currentPage - index).abs();
                  final double scale = 1 - distance * 0.25;
                  final double opacity = 1 - distance * 0.4;

                  return Transform.scale(
                    scale: scale.clamp(0.8, 1.0),
                    child: Opacity(
                      opacity: opacity.clamp(0.5, 1.0),
                      child: GestureDetector(
                        onTap: () => _handleGameTap(gameImages[realIndex]),
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
                              gameImages[realIndex],
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

          // 🔙 Back button
          Positioned(
            top: 40,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  // Uses pushReplacement to return to LandingPage and dispose of GamesMenu
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
