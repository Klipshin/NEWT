import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class FruitGame extends StatefulWidget {
  const FruitGame({super.key});

  @override
  State<FruitGame> createState() => _FruitGameState();
}

class _FruitGameState extends State<FruitGame> {
  int cherryCount = 0;
  int blueberryCount = 0;
  int totalScore = 0;
  int timeLeft = 60;
  bool gameActive = false;
  Timer? _timer;
  Timer? _peacockTimer;

  FruitType? currentFruit;
  Offset fruitPosition = Offset.zero;
  bool isDragging = false;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  // Peacock animation states
  int _peacockState = 0; // 0 = downP, 1 = halfP, 2 = upP
  final List<String> _peacockImages = [
    'assets/images/downP.png',
    'assets/images/halfP.png',
    'assets/images/upP.png',
    'assets/images/halfP.png', // Add halfP again for the sequence
  ];
  final List<int> _peacockDurations = [4500, 4500, 4500, 4500];

  final GlobalKey cherryBasketKey = GlobalKey();
  final GlobalKey blueberryBasketKey = GlobalKey();
  Rect? cherryBasketRect;
  Rect? blueberryBasketRect;

  Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startPeacockAnimation();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _peacockTimer?.cancel();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  void _startPeacockAnimation() {
    _updatePeacockState();
  }

  void _updatePeacockState() {
    setState(() {
      _peacockState = (_peacockState + 1) % 4; // Changed to 4 for the sequence
    });

    // Schedule next state change
    _peacockTimer = Timer(
      Duration(milliseconds: _peacockDurations[_peacockState]),
      _updatePeacockState,
    );
  }

  void _initializeGame() {
    setState(() {
      cherryCount = 0;
      blueberryCount = 0;
      totalScore = 0;
      timeLeft = 60;
      gameActive = false;
      currentFruit = null;
      isDragging = false;
    });
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/basket.mp3'));
  }

  void _startGame() {
    if (gameActive) return;

    setState(() {
      gameActive = true;
      timeLeft = 60;
      cherryCount = 0;
      blueberryCount = 0;
      totalScore = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          gameActive = false;
          timer.cancel();
          _showGameOver();
        }
      });
    });

    _generateNewFruit();
  }

  void _generateNewFruit() {
    if (!gameActive) return;

    setState(() {
      currentFruit = random.nextBool() ? FruitType.cherry : FruitType.blueberry;
      final randomX = 0.2 + random.nextDouble() * 0.6;
      final randomY = 0.2 + random.nextDouble() * 0.5;
      fruitPosition = Offset(randomX, randomY);
      isDragging = false;
    });
  }

  void _onDragStart(DragStartDetails details) {
    if (!gameActive || currentFruit == null) return;
    setState(() => isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!gameActive || currentFruit == null) return;
    setState(() {
      final gameSize = _getGameAreaSize();
      final newX = (fruitPosition.dx + details.delta.dx / gameSize.width).clamp(
        0.0,
        1.0,
      );
      final newY = (fruitPosition.dy + details.delta.dy / gameSize.height)
          .clamp(0.0, 1.0);
      fruitPosition = Offset(newX, newY);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!gameActive || currentFruit == null) return;

    final fruitCenter = _getFruitCenter();
    bool scored = false;

    if (currentFruit == FruitType.cherry &&
        cherryBasketRect != null &&
        cherryBasketRect!.contains(fruitCenter)) {
      setState(() {
        cherryCount++;
        totalScore += 10;
        scored = true;
      });
    } else if (currentFruit == FruitType.blueberry &&
        blueberryBasketRect != null &&
        blueberryBasketRect!.contains(fruitCenter)) {
      setState(() {
        blueberryCount++;
        totalScore += 10;
        scored = true;
      });
    }

    if (scored) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && gameActive) _generateNewFruit();
      });
    } else {
      setState(() => isDragging = false);
    }
  }

  void _updateBasketPositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cherryContext = cherryBasketKey.currentContext;
      final blueberryContext = blueberryBasketKey.currentContext;
      if (cherryContext != null) {
        final box = cherryContext.findRenderObject() as RenderBox;
        cherryBasketRect = box.localToGlobal(Offset.zero) & box.size;
      }
      if (blueberryContext != null) {
        final box = blueberryContext.findRenderObject() as RenderBox;
        blueberryBasketRect = box.localToGlobal(Offset.zero) & box.size;
      }
    });
  }

  Size _getGameAreaSize() {
    final mediaQuery = MediaQuery.of(context);
    return Size(mediaQuery.size.width, mediaQuery.size.height - 120);
  }

  Offset _getFruitCenter() {
    final gameSize = _getGameAreaSize();
    return Offset(
      fruitPosition.dx * gameSize.width,
      fruitPosition.dy * gameSize.height + 80,
    );
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Game Over! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $totalScore',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE94B3C),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResult("🍒", cherryCount),
                _buildResult("🫐", blueberryCount),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _initializeGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94B3C),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(String emoji, int count) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 5),
      Text('$count', style: const TextStyle(fontSize: 24)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    _updateBasketPositions();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final basketSize = isTablet ? 210.0 : 130.0;
    final baseFruitSize = isTablet ? 70.0 : 50.0; // Reduced fruit size
    final draggingFruitSize = isTablet ? 100.0 : 80.0; // Reduced dragging size
    final peacockSize = isTablet ? 390.0 : 290.0;
    final headerHeight = isTablet ? 100.0 : 80.0;
    final fontSize = isTablet ? 20.0 : 12.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/picnic_new.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromARGB(
            255,
            130,
            138,
            115,
          ).withOpacity(0.4), // Same method as card game
          child: SafeArea(
            left: false,
            bottom: false,
            child: Stack(
              children: [
                // Header with score, timer, and counters in one row
                Positioned(
                  top: 0.03,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score
                      _buildScoreDisplay(fontSize),

                      // Fruit counters in the middle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModernCounter("🍒", cherryCount, fontSize),
                          const SizedBox(width: 8),
                          _buildModernCounter("🫐", blueberryCount, fontSize),
                        ],
                      ),
                      // Timer
                      _buildTimerDisplay(fontSize),
                    ],
                  ),
                ),

                // Peacock mascot with animation
                Positioned(
                  left: isTablet ? 0 : 0,
                  bottom: isTablet ? 2.5 : 1.5,
                  child: Image.asset(
                    _peacockImages[_peacockState],
                    width: peacockSize,
                    height: peacockSize,
                    fit: BoxFit.contain,
                  ),
                ),

                // Cherry basket
                Positioned(
                  left: screenWidth * 0.47,
                  bottom: isTablet ? 15 : 5,
                  child: _buildBasket(
                    key: cherryBasketKey,
                    image: 'assets/images/cherrybasket.png',
                    size: basketSize,
                  ),
                ),

                // Blueberry basket
                Positioned(
                  right: screenWidth * 0.05,
                  bottom: isTablet ? 15 : 5,
                  child: _buildBasket(
                    key: blueberryBasketKey,
                    image: 'assets/images/blueberrybasket.png',
                    size: basketSize,
                  ),
                ),

                // Draggable fruit - with reduced size
                if (currentFruit != null)
                  Positioned(
                    left:
                        fruitPosition.dx * _getGameAreaSize().width -
                        (isDragging ? draggingFruitSize : baseFruitSize) / 2,
                    top:
                        fruitPosition.dy * _getGameAreaSize().height -
                        (isDragging ? draggingFruitSize : baseFruitSize) / 2 +
                        headerHeight,
                    child: GestureDetector(
                      onPanStart: _onDragStart,
                      onPanUpdate: _onDragUpdate,
                      onPanEnd: _onDragEnd,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isDragging ? draggingFruitSize : baseFruitSize,
                        height: isDragging ? draggingFruitSize : baseFruitSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Subtle glow effect behind the fruit
                            if (isDragging)
                              Container(
                                width: isDragging
                                    ? draggingFruitSize * 1.1
                                    : baseFruitSize,
                                height: isDragging
                                    ? draggingFruitSize * 1.1
                                    : baseFruitSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getFruitGlowColor().withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),

                            // Main fruit - this is what actually scales
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                currentFruit == FruitType.cherry
                                    ? 'assets/images/cherry.png'
                                    : 'assets/images/blueberry.png',
                                width: isDragging
                                    ? draggingFruitSize
                                    : baseFruitSize,
                                height: isDragging
                                    ? draggingFruitSize
                                    : baseFruitSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Start button
                if (!gameActive && currentFruit == null)
                  Center(
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 15 : 5,
                          vertical: isTablet ? 5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'START GAME',
                        style: TextStyle(
                          fontSize: isTablet ? 10 : 5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  Widget _buildModernCounter(String emoji, int count, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: fontSize - 2)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFruitGlowColor() {
    switch (currentFruit) {
      case FruitType.cherry:
        return Colors.red;
      case FruitType.blueberry:
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }

  Widget _buildBasket({
    required GlobalKey key,
    required String image,
    required double size,
  }) {
    return Container(
      key: key,
      child: Image.asset(image, width: size, height: size, fit: BoxFit.contain),
    );
  }

  Widget _buildScoreDisplay(double fontSize) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          '$totalScore',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );

  Widget _buildTimerDisplay(double fontSize) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Text(
          '00:${timeLeft.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

enum FruitType { cherry, blueberry }
