import 'package:flutter/material.dart';

class StoryBookPage4 extends StatefulWidget {
  const StoryBookPage4({super.key});

  @override
  State<StoryBookPage4> createState() => _StoryBookPage4State();
}

class _StoryBookPage4State extends State<StoryBookPage4> {
  final List<String> _pages = [
    'assets/images/4-TheHelpfulWind-4Title.png',
    'assets/images/4-TheHelpfulWind-P1.png',
    'assets/images/4-TheHelpfulWind-P2.png',
    'assets/images/4-TheHelpfulWind-P3.png',
    'assets/images/4-TheHelpfulWind-P4.png',
    'assets/images/4-TheHelpfulWind-P5.png',
  ];

  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTitlePage = _currentPage == 0;
    final bool isLastPage = _currentPage == _pages.length - 1;

    // Button sizes and spacing (adjust these numbers if you want different sizing/position)
    const double startBtnW = 180;
    const double navBtnW = 150;
    const double bottomOffset = 24; // how far from bottom the nav buttons sit
    const double sidePadding = 40; // distance from left/right edges

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen story image
          Positioned.fill(
            child: Image.asset(
              _pages[_currentPage],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    '⚠️ Image not found. Check asset path.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),

          // START button on title page (placed lower)
          if (isTitlePage)
            Positioned(
              bottom: 36, // moved lower
              right: sidePadding,
              child: GestureDetector(
                onTap: _nextPage,
                child: Image.asset('assets/images/start.png', width: startBtnW),
              ),
            ),

          // BACK button - visible on pages > 0 (including last)
          if (!isTitlePage)
            Positioned(
              bottom: bottomOffset, // control vertical position here
              left: sidePadding, // move right/left by changing this value
              child: GestureDetector(
                onTap: _previousPage,
                child: Image.asset('assets/images/back.png', width: navBtnW),
              ),
            ),

          // NEXT button - visible on pages that are not last (and not title)
          if (!isLastPage && !isTitlePage)
            Positioned(
              bottom: bottomOffset, // same vertical level as Back
              right: sidePadding,
              child: GestureDetector(
                onTap: _nextPage,
                child: Image.asset('assets/images/next.png', width: navBtnW),
              ),
            ),

          // FINISH button on last page (kept to the right but shifted left a bit)
          if (isLastPage)
            Positioned(
              bottom: bottomOffset,
              right: sidePadding + 40, // shifted left from the edge
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset('assets/images/finish.png', width: navBtnW),
              ),
            ),
        ],
      ),
    );
  }
}
