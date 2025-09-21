import 'package:flutter/material.dart';
import '../animated_button.dart'; // Import from parent directory

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/swamp.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Treasure Chest - Left side
            Positioned(
              left: MediaQuery.of(context).size.width * 0.1,
              top: MediaQuery.of(context).size.height * 0.46,
              child: AnimatedButton(
                imagePath: "assets/images/chest.png",
                width: 250,
                height: 180,
                onTap: () => _navigateToPage(context, "Treasure"),
              ),
            ),

            // Basket - Right side
            Positioned(
              right: MediaQuery.of(context).size.width * 0.065,
              top: MediaQuery.of(context).size.height * 0.46,
              child: AnimatedButton(
                imagePath: "assets/images/basket.png",
                width: 195,
                height: 135,
                onTap: () => _navigateToPage(context, "Basket"),
              ),
            ),

            // Rocks - Center-right
            Positioned(
              right: MediaQuery.of(context).size.width * 0.268,
              top: MediaQuery.of(context).size.height * 0.445,
              child: AnimatedButton(
                imagePath: "assets/images/rocks.png",
                width: 200,
                height: 97,
                onTap: () => _navigateToPage(context, "Rocks"),
              ),
            ),

            // Lily Flower - Center
            Positioned(
              left: MediaQuery.of(context).size.width * 0.53,
              top: MediaQuery.of(context).size.height * 0.687,
              child: AnimatedButton(
                imagePath: "assets/images/lilyflower.png",
                width: 160,
                height: 115,
                onTap: () => _navigateToPage(context, "Lily Flower"),
              ),
            ),

            Positioned(
              left: MediaQuery.of(context).size.width * 0.376,
              top: MediaQuery.of(context).size.height * 0.726,
              child: AnimatedButton(
                imagePath: "assets/images/frog.png",
                width: 115,
                height: 85,
                onTap: () => _navigateToPage(context, "Frog"),
              ),
            ),

            // Welcome text at the top
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    "NEWT",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bush Tree Border (Foreground Overlay)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  "assets/images/foreground.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $pageName page...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
