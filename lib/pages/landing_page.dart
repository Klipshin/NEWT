import 'package:flutter/material.dart';
import 'package:newt_2/pages/storybooks.dart';
import 'games_menu.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/landingv2.png',
              fit: BoxFit.cover,
            ),
          ),

          //Frog mascot
          Positioned(
            left: -100,
            bottom: -50,
            child: Image.asset('assets/images/frogmascot.png', width: 430),
          ),

          //Play
          Positioned(
            top:
                MediaQuery.of(context).size.height *
                0.58, // lowered 2x from center
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesMenu()),
                );
              },
              child: Center(
                child: Image.asset('assets/images/play.png', width: 250),
              ),
            ),
          ),

          //Story Time
          Positioned(
            top: MediaQuery.of(context).size.height * 0.27,
            right: MediaQuery.of(context).size.width * 0.05,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoryBooksPage(),
                  ),
                );
              },
              child: Image.asset('assets/images/storytime.png', width: 210),
            ),
          ),

          //Close
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // TODO: Exit or close
              },
              child: Image.asset('assets/images/close.png', width: 40),
            ),
          ),

          //Sound
          Positioned(
            bottom: 25,
            right: 90,
            child: GestureDetector(
              onTap: () {
                // TODO: Toggle sound
              },
              child: Image.asset('assets/images/volume.png', width: 55),
            ),
          ),

          //Settings
          Positioned(
            bottom: 25,
            right: 25,
            child: GestureDetector(
              onTap: () {
                // TODO: Open settings
              },
              child: Image.asset('assets/images/settings.png', width: 55),
            ),
          ),
        ],
      ),
    );
  }
}
