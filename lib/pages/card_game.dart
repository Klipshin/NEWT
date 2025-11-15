import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CardGame extends StatefulWidget {
  const CardGame({super.key});

  @override
  State<CardGame> createState() => _CardGameState();
}

class _CardGameState extends State<CardGame> with TickerProviderStateMixin {
  List<GameCard> cards = [];
  List<int> flippedCards = [];
  bool canFlip = true;
  int matches = 0;
  int setsCompleted = 0;
  int timeRemaining = 30; // Start with 30 seconds
  Timer? _gameTimer;
  late AnimationController _flipController;
  late AnimationController _matchController;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  int _frogFrame = 0; // 0 = eyeopen, 1 = close, 2 = mouth
  Timer? _mascotTimer;

  final List<String> cardImages = [
    'assets/images/hedge.png',
    'assets/images/ray.png',
    'assets/images/star.png',
    'assets/images/owl.png',
  ];

  final List<String> extraCardImages = [
    'assets/images/sloth.png',
    'assets/images/redpanda.png',
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _matchController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initializeGame();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();

    _startMascotAnimation();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _matchController.dispose();
    _mascotTimer?.cancel();
    _gameTimer?.cancel();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  void _startMascotAnimation() {
    // Cycle frog images every 1 second
    _mascotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _frogFrame = (_frogFrame + 1) % 3; // 0 → 1 → 2 → 0
        });
      }
    });
  }

  void _initializeGame() {
    cards.clear();
    flippedCards.clear();
    matches = 0;
    setsCompleted = 0;
    canFlip = true;
    timeRemaining = 30;

    _gameTimer?.cancel();
    _startGameTimer();

    _setupCards();
  }

  void _setupCards() {
    cards.clear();

    if (setsCompleted < 3) {
      // 3x3 grid with one unpaired card
      List<String> gameImages = [...cardImages, ...cardImages];
      gameImages.add('assets/images/pad.png'); // 9th unpaired card
      gameImages.shuffle();

      for (int i = 0; i < 9; i++) {
        cards.add(GameCard(id: i, imagePath: gameImages[i]));
      }
    } else {
      // 4x3 grid (12 cards) - all paired, no unpaired card
      List<String> allImages = [...cardImages, ...extraCardImages];
      List<String> gameImages = [...allImages, ...allImages];
      gameImages.shuffle();

      for (int i = 0; i < 12; i++) {
        cards.add(GameCard(id: i, imagePath: gameImages[i]));
      }
    }

    setState(() {});
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          timeRemaining--;
        });

        if (timeRemaining <= 0) {
          timer.cancel();
          _showGameOverDialog();
        }
      }
    });
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/card.mp3'));
  }

  void _flipCard(int index) {
    if (!canFlip ||
        cards[index].isFlipped ||
        cards[index].isMatched ||
        flippedCards.length >= 2) {
      return;
    }

    setState(() {
      cards[index].isFlipped = true;
      flippedCards.add(index);
    });

    if (flippedCards.length == 2) {
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    canFlip = false;

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (cards[flippedCards[0]].imagePath ==
              cards[flippedCards[1]].imagePath &&
          cards[flippedCards[0]].imagePath != 'assets/images/pad.png') {
        setState(() {
          cards[flippedCards[0]].isMatched = true;
          cards[flippedCards[1]].isMatched = true;
          matches++;
          timeRemaining += 5; // Add 5 seconds for each match
        });

        _matchController.forward().then((_) => _matchController.reset());

        int requiredMatches = setsCompleted < 3 ? 4 : 6;
        if (matches == requiredMatches) {
          _onSetCompleted();
        }
      } else {
        setState(() {
          cards[flippedCards[0]].isFlipped = false;
          cards[flippedCards[1]].isFlipped = false;
        });
      }

      flippedCards.clear();
      canFlip = true;
    });
  }

  void _onSetCompleted() {
    setsCompleted++;

    if (setsCompleted == 3) {
      // Completed 3 sets of 3x3, now move to 4x3
      _gameTimer?.cancel();
      _showLevelUpDialog();
    } else {
      // Continue with another 3x3 set
      _gameTimer?.cancel();
      _showNextSetDialog();
    }
  }

  void _showNextSetDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'ALL PAIRED UP! 🌟',
          titleColor: Colors.cyan.shade300, // A new celebratory color
          mascotImagePath:
              'assets/images/mouthfrog.png', // Assuming a happy frog image
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You found every creature pair! Get ready for a bigger swamp challenge.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade50,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Start Next Round!',
              onPressed: () {
                Navigator.of(context).pop();
                matches = 0;
                _setupCards(); // Setup the next, larger card grid
                _startGameTimer();
              },
              color: Colors.green.shade700,
            ),
            _buildThemedButton(
              context,
              text: 'Go to Menu',
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to the previous screen (menu)
                Navigator.of(context).pop();
              },
              color: Colors.brown.shade700,
            ),
          ],
        );
      },
    );
  }

  void _showLevelUpDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'LEVEL COMPLETE! 🎉',
          titleColor: Colors.yellow.shade300,
          mascotImagePath: 'assets/images/mouthfrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Great job! The swamp gets bigger now.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade50,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Play Next Level!',
              onPressed: () {
                Navigator.of(context).pop();
                matches = 0;
                _setupCards();
                _startGameTimer();
              },
              color: Colors.orange.shade700,
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'GAME OVER 😔',
          titleColor: Colors.red.shade300,
          mascotImagePath: 'assets/images/closefrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Time ran out! Try again!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade200,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Play Again',
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              color: Colors.green.shade600,
            ),
            _buildThemedButton(
              context,
              text: 'Back to Menu',
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to the previous screen (menu)
                Navigator.of(context).pop();
              },
              color: Colors.brown.shade700,
            ),
          ],
        );
      },
    );
  }

  // Helper widget for a thematic button style (inside _CardGameState)
  Widget _buildThemedButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    Color color = Colors.green,
  }) {
    return Expanded(
      // Use Expanded to give buttons equal width
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // Bigger radius
              side: BorderSide(
                color: Colors.yellow.shade200,
                width: 3,
              ), // Stronger border
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 15, // Taller button
            ),
            elevation: 8, // More prominent shadow
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, // Bigger font size
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for stats in game over (inside _CardGameState)
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ), // REDUCED vertical padding (from 3)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/swamp_new.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromARGB(255, 112, 155, 131).withOpacity(0.4),
          child: SafeArea(
            child: Row(
              children: [
                // Left mascot area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return OverflowBox(
                            maxWidth: double.infinity,
                            maxHeight: double.infinity,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              transform: Matrix4.translationValues(
                                setsCompleted >= 3
                                    ? -3
                                    : 50, // Move left when 12 cards
                                20,
                                0,
                              ),
                              child: Image.asset(
                                _frogFrame == 0
                                    ? 'assets/images/eyeopenfrog.png'
                                    : _frogFrame == 1
                                    ? 'assets/images/closefrog.png'
                                    : 'assets/images/mouthfrog.png',
                                width: constraints.maxWidth * 1.5,
                                height: constraints.maxHeight * 1.5,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Game grid
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double spacing = 6;
                        double maxWidth = constraints.maxWidth;
                        double maxHeight = constraints.maxHeight;

                        int crossAxisCount = setsCompleted < 3 ? 3 : 4;
                        int rows = setsCompleted < 3 ? 3 : 3;

                        double cardWidth =
                            (maxWidth - (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;
                        double cardHeight =
                            (maxHeight - (spacing * (rows - 1))) / rows;
                        double cardSize =
                            (cardWidth < cardHeight ? cardWidth : cardHeight) *
                            0.9;
                        cardSize = cardSize.clamp(50, 120);

                        double gridWidth =
                            (cardSize * crossAxisCount) +
                            (spacing * (crossAxisCount - 1));
                        double gridHeight =
                            (cardSize * rows) + (spacing * (rows - 1));

                        return Center(
                          child: SizedBox(
                            width: gridWidth,
                            height: gridHeight,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                  ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                return _buildGameCard(index, cardSize);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Right sidebar - FIXED WITH SINGLECHILDSCROLLVIEW
                Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSideStatItem(
                          'Time',
                          '$timeRemaining',
                          Icons.timer,
                        ),
                        const SizedBox(height: 20),
                        _buildSideStatItem(
                          'Sets',
                          '$setsCompleted/3',
                          Icons.grid_4x4,
                        ),
                        const SizedBox(height: 20),
                        _buildSideStatItem(
                          'Matches',
                          '$matches/${setsCompleted < 3 ? 4 : 6}',
                          Icons.favorite,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            onPressed: _initializeGame,
                            icon: const Icon(Icons.refresh),
                            color: Colors.green.shade700,
                            tooltip: 'Reset Game',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green.shade700, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(int index, double cardSize) {
    final card = cards[index];

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                RotationTransition(turns: animation, child: child),
            child: card.isFlipped || card.isMatched
                ? _buildCardFront(card, cardSize)
                : _buildCardBack(cardSize),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(GameCard card, double cardSize) {
    return Container(
      key: ValueKey('front-${card.id}'),
      decoration: BoxDecoration(
        color: card.isMatched ? Colors.green.shade300 : Colors.white,
        border: Border.all(
          color: card.isMatched ? Colors.green.shade600 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: AnimatedScale(
          scale: card.isMatched ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Image.asset(
            card.imagePath,
            width: cardSize * 0.7,
            height: cardSize * 0.7,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack(double cardSize) {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        border: Border.all(color: Colors.green.shade900, width: 2),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/pad.png',
          width: cardSize * 0.7,
          height: cardSize * 0.7,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class GameCard {
  final int id;
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.id,
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

// --- NEW/UPDATED Themed Game Dialog Widget (Big, Engaging, and Safe) ---
class ThemedGameDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final Color titleColor;
  final String mascotImagePath;

  const ThemedGameDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.titleColor = Colors.white,
    this.mascotImagePath = 'assets/images/eyeopenfrog.png',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Make the dialog very large, but responsive
    final dialogWidth = screenWidth * 0.8;
    final dialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      // Use AlertDialog-like padding to make it truly a popup
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 1. The Main Content Box (Wooden/Mossy Look)
            Container(
              margin: const EdgeInsets.only(
                top: 50,
              ), // Space for the title banner
              decoration: BoxDecoration(
                // Dark, swampy gradient for the body
                gradient: LinearGradient(
                  colors: [Colors.brown.shade800, Colors.green.shade900],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(25), // More rounded corners
                border: Border.all(
                  color: Colors.brown.shade600,
                  width: 8,
                ), // Thicker, wooden border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15, // Deeper shadow
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  25,
                  75,
                  25,
                  25,
                ), // More generous padding
                child: Column(
                  mainAxisSize: MainAxisSize
                      .max, // Take max height allowed by ConstrainedBox
                  children: [
                    // Content Area - Use SingleChildScrollView + Flexible for safety
                    Flexible(child: SingleChildScrollView(child: content)),
                    const SizedBox(height: 20),
                    // Actions Row (buttons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),

            // 2. The Title Header/Banner
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700, // Richer green for the banner
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.yellow.shade700,
                    width: 4,
                  ), // Bright border for pop
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, // Bigger title for kids
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    shadows: const [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 2.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. The Mascot Image (Optional, kept positioned for theme)
            Positioned(
              top: 35, // Adjust vertical position to overlap banner slightly
              right: 15,
              child: Image.asset(
                mascotImagePath,
                width: 70, // Slightly bigger mascot
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
