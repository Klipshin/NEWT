import 'package:flutter/material.dart';
import 'the_red_ball.dart';
import 'the_busy_ant.dart';
import 'landing_page.dart'; // 👈 ensure this exists

class StoryBooksPage extends StatelessWidget {
  const StoryBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> stories = [
      'assets/images/story1.png',
      'assets/images/story2.png',
      'assets/images/story3.png',
      'assets/images/story4.png',
      'assets/images/story5.png',
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
                      onTap: () {
                        if (index == 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const StoryBookPage1(),
                            ),
                          );
                        } else if (index == 1) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const StoryBookPage2(),
                            ),
                          );
                        }
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
