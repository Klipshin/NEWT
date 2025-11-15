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

class _FruitGameState extends State<FruitGame> with TickerProviderStateMixin {
  int cherryCount = 0;
  int blueberryCount = 0;
  int totalScore = 0;
  int timeLeft = 60;
  bool gameActive = false;
  Timer? _timer;
  Timer? _mascotTimer;

  FruitType? currentFruit;
  Offset fruitPosition = Offset.zero;
  bool isDragging = false;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  // Poof animation controller
  late AnimationController _poofController;
  late Animation<double> _poofScale;
  late Animation<double> _poofOpacity;
  bool showPoof = false;

  // Frog mascot animation states (same as card game)
  int _frogFrame = 0; // 0 = eyeopen, 1 = close, 2 = mouth

  final GlobalKey cherryBasketKey = GlobalKey();
  final GlobalKey blueberryBasketKey = GlobalKey();
  Rect? cherryBasketRect;
  Rect? blueberryBasketRect;

  Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startMascotAnimation();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();
    _setupPoofAnimation();
  }

  void _setupPoofAnimation() {
    _poofController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _poofScale = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _poofController, curve: Curves.easeOut));

    _poofOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _poofController, curve: Curves.easeIn));

    _poofController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          showPoof = false;
        });
        _poofController.reset();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mascotTimer?.cancel();
    _bgMusicPlayer.dispose();
    _poofController.dispose();
    super.dispose();
  }

  void _startMascotAnimation() {
    // Cycle frog images every 1 second (same as card game)
    _mascotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _frogFrame = (_frogFrame + 1) % 3; // 0 → 1 → 2 → 0
        });
      }
    });
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
      // Fixed position at the mascot location (left side)
      fruitPosition = const Offset(0.31, 0.6); // Fixed position near the frog
      isDragging = false;
      showPoof = true;
    });

    // Trigger poof animation
    _poofController.forward();
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

    final basketSize = isTablet ? 220.0 : 130.0;
    final baseFruitSize = isTablet ? 70.0 : 50.0;
    final draggingFruitSize = isTablet ? 100.0 : 80.0;
    final frogSize = isTablet ? 240.0 : 140.0;
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
          color: const Color.fromARGB(255, 130, 138, 115).withOpacity(0.4),
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

                // Frog mascot with animation (same as card game)
                Positioned(
                  left: isTablet ? 40 : 20,
                  bottom: isTablet ? 20 : 17,
                  child: Image.asset(
                    _frogFrame == 0
                        ? 'assets/images/open_no_pad.png'
                        : _frogFrame == 1
                        ? 'assets/images/close_no_pad.png'
                        : 'assets/images/eyes_no_pad.png',
                    width: frogSize,
                    height: frogSize,
                    fit: BoxFit.contain,
                  ),
                ),

                // Cherry basket
                Positioned(
                  left: screenWidth * 0.35,
                  bottom: isTablet ? 15 : 5,
                  child: _buildBasket(
                    key: cherryBasketKey,
                    image: 'assets/images/cherrybasket.png',
                    size: basketSize,
                  ),
                ),

                // Blueberry basket
                Positioned(
                  right: screenWidth * 0.11,
                  bottom: isTablet ? 15 : 5,
                  child: _buildBasket(
                    key: blueberryBasketKey,
                    image: 'assets/images/blueberrybasket.png',
                    size: basketSize,
                  ),
                ),

                // Poof animation
                if (showPoof && currentFruit != null)
                  Positioned(
                    left: fruitPosition.dx * _getGameAreaSize().width - 75,
                    top:
                        fruitPosition.dy * _getGameAreaSize().height -
                        75 +
                        headerHeight,
                    child: AnimatedBuilder(
                      animation: _poofController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _poofOpacity.value,
                          child: Transform.scale(
                            scale: _poofScale.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              child: CustomPaint(
                                painter: PoofPainter(
                                  color: _getFruitGlowColor(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Draggable fruit
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

                            // Main fruit
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
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
          Text(emoji, style: TextStyle(fontSize: fontSize + 8)),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: fontSize + 8,
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

// Custom painter for the poof effect
class PoofPainter extends CustomPainter {
  final Color color;

  PoofPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw multiple cloud-like circles to create poof effect
    final random = Random(42); // Fixed seed for consistent appearance
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final radius = size.width * 0.15;
      final distance = size.width * 0.25;

      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(offset, radius, paint);
    }

    // Draw center circle
    canvas.drawCircle(center, size.width * 0.2, paint);

    // Add sparkles
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6 + math.pi / 6;
      final distance = size.width * 0.35;
      final sparkleOffset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Draw star shape
      _drawStar(canvas, sparkleOffset, 4, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 2;
      final x = center.dx + math.cos(angle) * size;
      final y = center.dy + math.sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum FruitType { cherry, blueberry }
