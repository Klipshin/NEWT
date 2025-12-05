import 'package:flutter/material.dart';
import '1the_red_ball.dart';
import '2the_busy_ant.dart';
import '3the_rainbow_bridge.dart';
import '4the_helpful_wind.dart';
import '5the_little_seeds_journey.dart';
import 'landing_page.dart';
import 'background_music_manager.dart';

// Changed to Stateful to allow for async navigation logic
class StoryBooksPage extends StatefulWidget {
  const StoryBooksPage({super.key});

  @override
  State<StoryBooksPage> createState() => _StoryBooksPageState();
}

class _StoryBooksPageState extends State<StoryBooksPage> {
  final BackgroundMusicManager _musicManager =
      BackgroundMusicManager(); // <--- MANAGER INSTANCE

  final List<String> stories = const [
    'assets/images/story1.png',
    'assets/images/story2.png',
    'assets/images/story3.png',
    'assets/images/story4.png',
    'assets/images/story5.png',
  ];

  // New asynchronous handler for navigation
  void _navigateToStory(int index) async {
    Widget? page;

    if (index == 0) {
      page = const StoryBookPage1();
    } else if (index == 1) {
      page = const StoryBookPage2();
    } else if (index == 2) {
      page = const StoryBookPage3();
    } else if (index == 3) {
      page = const StoryBookPage4();
    } else if (index == 4) {
      page = const StoryBookPage5();
    }

    if (page != null) {
      // 1. Pause music before pushing the story page
      _musicManager.pauseMusic();

      // 2. Navigate and WAIT for the story page to be popped
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => page!));

      // 3. Resume music when returning to StoryBooksPage
      _musicManager.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🖼 Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
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
                      // Use the new handler
                      onTap: () => _navigateToStory(index),
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
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
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
