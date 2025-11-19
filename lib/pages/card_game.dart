import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flip_card/flip_card.dart'; // Import the package

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
  int timeRemaining = 30;
  Timer? _gameTimer;

  // Removed _flipController (handled by package)
  late AnimationController _matchController;
  late AudioPlayer _bgMusicPlayer;

  // Master confetti controller for background effects
  late ConfettiController _confettiController;
  // Specific controller for confetti that originates from the dialog itself
  late ConfettiController _dialogConfettiController;

  int _frogFrame = 0;
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

    _matchController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Initialize dialog confetti controller as well
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _initializeGame();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();

    _startMascotAnimation();
  }

  @override
  void dispose() {
    _matchController.dispose();
    _mascotTimer?.cancel();
    _gameTimer?.cancel();
    _bgMusicPlayer.dispose();
    _confettiController.dispose();
    _dialogConfettiController.dispose(); // Dispose dialog controller
    super.dispose();
  }

  void _startMascotAnimation() {
    _mascotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _frogFrame = (_frogFrame + 1) % 3;
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

    _confettiController.stop();
    _dialogConfettiController.stop(); // Stop dialog confetti on restart

    _gameTimer?.cancel();
    _startGameTimer();

    _setupCards();
  }

  void _setupCards() {
    cards.clear();

    if (setsCompleted < 3) {
      List<String> gameImages = [...cardImages, ...cardImages];
      gameImages.add('assets/images/pad.png');
      gameImages.shuffle();
      for (int i = 0; i < 9; i++) {
        cards.add(GameCard(id: i, imagePath: gameImages[i]));
      }
    } else {
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

    // Trigger the package animation using the key
    cards[index].cardKey.currentState?.toggleCard();

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
          timeRemaining += 5;
        });

        _matchController.forward().then((_) => _matchController.reset());

        int requiredMatches = setsCompleted < 3 ? 4 : 6;
        if (matches == requiredMatches) {
          _onSetCompleted();
        }
      } else {
        // No match: Flip them back using the keys
        cards[flippedCards[0]].cardKey.currentState?.toggleCard();
        cards[flippedCards[1]].cardKey.currentState?.toggleCard();

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
      _gameTimer?.cancel();
      _showLevelUpDialog();
    } else {
      _gameTimer?.cancel();
      _showNextSetDialog();
    }
  }

  Future<void> _onBackButtonPressed() async {
    _gameTimer?.cancel();

    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🚪 Leaving already?',
        'Your current game progress will be lost!',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              _startGameTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Stay & Play', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit Game', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // --- DIALOG BUILDER WITH INTERNAL CONFETTI ---
  Widget _buildDialogContent(
    String title,
    String message,
    List<Widget> actions,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        // Use Stack to layer confetti over the dialog
        alignment: Alignment.topCenter, // Confetti from the top of the dialog
        children: [
          Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade800, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actions,
                ),
              ],
            ),
          ),
          // Confetti for the dialog itself
          ConfettiWidget(
            confettiController: _dialogConfettiController,
            blastDirection: pi / 2, // Downwards
            maxBlastForce: 20, // Stronger blast for a pop
            minBlastForce: 10,
            emissionFrequency: 0.2, // Frequent bursts
            numberOfParticles: 15, // A good amount
            gravity: 0.5, // Fall a bit faster
            shouldLoop: false,
            colors: const [
              Colors.yellow,
              Colors.lightGreen,
              Colors.lightBlue,
            ], // Brighter colors for dialog
            createParticlePath: drawStar,
          ),
        ],
      ),
    );
  }

  void _showNextSetDialog() {
    _confettiController.play();
    _dialogConfettiController.play(); // Play dialog confetti
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialogContent(
        '🎉 Good Job!',
        'You found all the pairs! Ready for the next round?',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              matches = 0;
              _setupCards();
              _startGameTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Next Round',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog() {
    _confettiController.play();
    _dialogConfettiController.play(); // Play dialog confetti
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialogContent(
        '🎉 Level Complete!',
        'Great work! The swamp is getting bigger now.',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              matches = 0;
              _setupCards();
              _startGameTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Play Next Level',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialogContent(
        '⏳ Time\'s Up!',
        'You ran out of time. Don\'t give up!',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Play Again', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;
    double outerRadius = size.width / 2;
    double innerRadius = size.width / 5;

    Path path = Path();
    double rot = pi / 2 * 3;
    double step = pi / 5;

    path.moveTo(cx, cy - outerRadius);
    for (int i = 0; i < 5; i++) {
      double x = cx + cos(rot) * outerRadius;
      double y = cy + sin(rot) * outerRadius;
      path.lineTo(x, y);
      rot += step;

      x = cx + cos(rot) * innerRadius;
      y = cy + sin(rot) * innerRadius;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackButtonPressed();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/swamp_new.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: const Color.fromARGB(
                  255,
                  112,
                  155,
                  131,
                ).withOpacity(0.4),
                child: SafeArea(
                  child: Row(
                    children: [
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
                                      setsCompleted >= 3 ? -3 : 50,
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
                                  (maxWidth -
                                      (spacing * (crossAxisCount - 1))) /
                                  crossAxisCount;
                              double cardHeight =
                                  (maxHeight - (spacing * (rows - 1))) / rows;
                              double cardSize =
                                  (cardWidth < cardHeight
                                      ? cardWidth
                                      : cardHeight) *
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                              const SizedBox(height: 10),

                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  onPressed: _onBackButtonPressed,
                                  icon: const Icon(Icons.exit_to_app_rounded),
                                  color: Colors.red.shade700,
                                  tooltip: 'Exit Game',
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

            // --- ALL CONFETTI CANNONS (Background) ---

            // 1. Top Center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 30,
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                  Colors.red,
                ],
                createParticlePath: drawStar,
              ),
            ),

            // 2. Top Left
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 3,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.1, // Increased
                numberOfParticles: 25, // Increased
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                ],
                createParticlePath: drawStar,
              ),
            ),

            // 3. Top Right
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 2 * pi / 3,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.1, // Increased
                numberOfParticles: 25, // Increased
                gravity: 0.2,
                colors: const [
                  Colors.purple,
                  Colors.amber,
                  Colors.red,
                  Colors.cyan,
                ],
                createParticlePath: drawStar,
              ),
            ),

            // 4. Center Left (Shooting Right)
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 0,
                maxBlastForce: 15,
                minBlastForce: 5,
                emissionFrequency: 0.08, // Increased
                numberOfParticles: 20, // Increased
                gravity: 0.4,
                colors: const [Colors.yellow, Colors.orange, Colors.red],
                createParticlePath: drawStar,
              ),
            ),

            // 5. Center Right (Shooting Left)
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi,
                maxBlastForce: 15,
                minBlastForce: 5,
                emissionFrequency: 0.08, // Increased
                numberOfParticles: 20, // Increased
                gravity: 0.4,
                colors: const [Colors.blue, Colors.cyan, Colors.purple],
                createParticlePath: drawStar,
              ),
            ),

            // 6. NEW: Bottom Left (Shooting Up)
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 4, // Up-Right diagonal
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [Colors.teal, Colors.lime, Colors.indigo],
                createParticlePath: drawStar,
              ),
            ),

            // 7. NEW: Bottom Right (Shooting Up)
            Align(
              alignment: Alignment.bottomRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -3 * pi / 4, // Up-Left diagonal
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [
                  Colors.pinkAccent,
                  Colors.deepOrange,
                  Colors.lightBlueAccent,
                ],
                createParticlePath: drawStar,
              ),
            ),
          ],
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
    // Replaced Manual animation with FlipCard
    return GestureDetector(
      onTap: () => _flipCard(index),
      child: FlipCard(
        key: card.cardKey, // Use key for programmatic control
        flipOnTouch: false, // We handle the flip via _flipCard
        direction: FlipDirection.HORIZONTAL,
        side: CardSide.FRONT,
        front: _buildCardBack(cardSize), // "Front" is the Pad (hidden state)
        back: _buildCardFront(
          card,
          cardSize,
        ), // "Back" is the Animal (revealed state)
      ),
    );
  }

  Widget _buildCardFront(GameCard card, double cardSize) {
    return Container(
      key: ValueKey('front-${card.id}'),
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: card.isMatched ? Colors.green.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: card.isMatched ? Colors.green.shade600 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
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
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade900, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
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

  // Added key for flip control
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  GameCard({
    required this.id,
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
