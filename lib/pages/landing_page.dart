import 'package:flutter/material.dart';
import '../animated_button.dart';
import 'card_game.dart';
import 'fruit_game.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Define a base width (Pixel 9a width is around 412)
            final baseWidth = 412.0;
            final scaleFactor = constraints.maxWidth / baseWidth;

            // Clamp the scale factor to prevent buttons from getting too large
            final clampedScale = scaleFactor.clamp(0.8, 1.5);

            // Calculate responsive offsets for larger screens
            final isLargeScreen = constraints.maxWidth > 600;
            final horizontalSpacing = isLargeScreen ? 1.2 : 1.0;
            final verticalSpacing = isLargeScreen ? 1.1 : 1.0;

            return Stack(
              children: [
                // Treasure Chest - Left side (pushed more to the left on large screens)
                Positioned(
                  left: constraints.maxWidth * (0.06 / horizontalSpacing),
                  top: constraints.maxHeight * (0.46 / verticalSpacing),
                  child: AnimatedButton(
                    imagePath: "assets/images/chest.png",
                    width: 190 * clampedScale,
                    height: 130 * clampedScale,
                    onTap: () => _navigateToPage(context, "Treasure"),
                  ),
                ),

                // Basket - Right side (pushed more to the right on large screens)
                Positioned(
                  right: constraints.maxWidth * (0.024 / horizontalSpacing),
                  top: constraints.maxHeight * (0.45 / verticalSpacing),
                  child: AnimatedButton(
                    imagePath: "assets/images/basket.png",
                    width: 180 * clampedScale,
                    height: 100 * clampedScale,
                    onTap: () => _navigateToFruitGame(context),
                  ),
                ),

                // Rocks - Center-right (adjusted spacing)
                Positioned(
                  right: constraints.maxWidth * (0.235 * horizontalSpacing),
                  top: constraints.maxHeight * (0.445 / verticalSpacing),
                  child: AnimatedButton(
                    imagePath: "assets/images/rocks.png",
                    width: 150 * clampedScale,
                    height: 80 * clampedScale,
                    onTap: () => _navigateToPage(context, "Rocks"),
                  ),
                ),

                // Lily Flower - Center (adjusted spacing)
                Positioned(
                  left: constraints.maxWidth * (0.48 * horizontalSpacing),
                  top: constraints.maxHeight * (0.580 * verticalSpacing),
                  child: AnimatedButton(
                    imagePath: "assets/images/lilyflower.png",
                    width: 110 * clampedScale,
                    height: 110 * clampedScale,
                    onTap: () => _navigateToCardGame(context),
                  ),
                ),

                // Frog (adjusted spacing)
                Positioned(
                  left: constraints.maxWidth * (0.285 * horizontalSpacing),
                  top: constraints.maxHeight * (0.651 * verticalSpacing),
                  child: AnimatedButton(
                    imagePath: "assets/images/frog.png",
                    width: 100 * clampedScale,
                    height: 64 * clampedScale,
                    onTap: () => _navigateToPage(context, "Frog"),
                  ),
                ),

                // Welcome text at the top
                Positioned(
                  top: constraints.maxHeight * 0.1,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * clampedScale,
                        vertical: 10 * clampedScale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "NEWT",
                        style: TextStyle(
                          fontSize: 24 * clampedScale,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: const [
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
            );
          },
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

  void _navigateToCardGame(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CardGame()));
  }

  void _navigateToFruitGame(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FruitGame()));
  }
}
