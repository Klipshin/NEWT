import 'package:flutter/material.dart';
import 'the_red_ball.dart';
import 'the_busy_ant.dart';

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
          // 🖼 Background Image (Full Screen)
          Positioned.fill(
            child: Image.asset('assets/images/stories.png', fit: BoxFit.cover),
          ),

          // 🔙 Previous Button
          Positioned(
            top: 40,
            left: 15,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/images/previous.png',
                width: 35,
                height: 35,
              ),
            ),
          ),

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
        ],
      ),
    );
  }
}
