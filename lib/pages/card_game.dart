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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text(
            '🎉 Set Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set $setsCompleted of 3 completed!',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Time Remaining: $timeRemaining seconds',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                matches = 0;
                _setupCards();
                _startGameTimer();
              },
              child: const Text('Next Set'),
            ),
          ],
        );
      },
    );
  }

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.amber[50],
          title: const Text(
            '⭐ Level Up!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Great job! Now try the harder level!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '4×3 Grid - All cards paired!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Time Remaining: $timeRemaining seconds',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                matches = 0;
                _setupCards();
                _startGameTimer();
              },
              child: const Text('Start Hard Mode'),
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: const Text(
            '⏰ Time\'s Up!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                'Sets Completed: $setsCompleted',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Matches: $matches',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Menu'),
            ),
          ],
        );
      },
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
