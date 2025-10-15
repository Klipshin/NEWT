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
  int moves = 0;
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
    moves = 0;
    canFlip = true;

    List<String> gameImages = [...cardImages, ...cardImages];
    gameImages.add('assets/images/pad.png'); // 9th unpaired card
    gameImages.shuffle();

    for (int i = 0; i < 9; i++) {
      cards.add(GameCard(id: i, imagePath: gameImages[i]));
    }
    setState(() {});
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
      moves++;
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
        });

        _matchController.forward().then((_) => _matchController.reset());

        if (matches == 4) {
          _showWinDialog();
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text(
            '🎉 Congratulations!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You matched all the lily pads!',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Moves: $moves',
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
            image: AssetImage("assets/images/swamp.png"),
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
                            child: Transform.translate(
                              offset: const Offset(50, 20),
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
                        double cardWidth = (maxWidth - (spacing * 2)) / 3;
                        double cardHeight = (maxHeight - (spacing * 2)) / 3;
                        double cardSize =
                            (cardWidth < cardHeight ? cardWidth : cardHeight) *
                            0.9;
                        cardSize = cardSize.clamp(50, 120);

                        double gridWidth = (cardSize * 3) + (spacing * 2);
                        double gridHeight = (cardSize * 3) + (spacing * 2);

                        return Center(
                          child: SizedBox(
                            width: gridWidth,
                            height: gridHeight,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
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
                // Right sidebar
                /* const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.green.shade700,
                    ),
                    tooltip: _isMuted ? 'Unmute Music' : 'Mute Music',
                    onPressed: () async {
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) {
                        await _bgMusicPlayer.pause();
                      } else {
                        await _bgMusicPlayer.resume();
                      }
                    },
                  ),
                ), */
                Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSideStatItem(
                        'Moves',
                        moves.toString(),
                        Icons.touch_app,
                      ),
                      const SizedBox(height: 20),
                      _buildSideStatItem(
                        'Matches',
                        '$matches/4',
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
