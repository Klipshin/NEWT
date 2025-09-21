import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}

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
              left: MediaQuery.of(context).size.width * 0.07,
              top: MediaQuery.of(context).size.height * 0.2,
              child: AnimatedButton(
                imagePath: "assets/images/chest.png",
                width: 400,
                height: 350,
                onTap: () => _navigateToPage(context, "Treasure"),
              ),
            ),

            // Basket - Right side
            Positioned(
              right: MediaQuery.of(context).size.width * 0.04,
              top: MediaQuery.of(context).size.height * 0.3,
              child: AnimatedButton(
                imagePath: "assets/images/basket.png",
                width: 280,
                height: 280,
                onTap: () => _navigateToPage(context, "Basket"),
              ),
            ),

            // Rocks - Center-right
            Positioned(
              right: MediaQuery.of(context).size.width * 0.22,
              top: MediaQuery.of(context).size.height * 0.35,
              child: AnimatedButton(
                imagePath: "assets/images/rocks.png",
                width: 280,
                height: 180,
                onTap: () => _navigateToPage(context, "Rocks"),
              ),
            ),

            // Lily Flower - Center
            Positioned(
              left: MediaQuery.of(context).size.width * 0.4,
              top: MediaQuery.of(context).size.height * 0.37,
              child: AnimatedButton(
                imagePath: "assets/images/lilyflower.png",
                width: 400,
                height: 300,
                onTap: () => _navigateToPage(context, "Lily Flower"),
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
                  "assets/images/bushtree.png",
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

class AnimatedButton extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final VoidCallback onTap;

  const AnimatedButton({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensures whole box is clickable
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: widget.width * 0.3,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
