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
      builder: (context) {
        return ThemedGameDialog(
          title: 'GAME OVER! 🎉',
          titleColor: totalScore > 0
              ? Colors.yellow.shade300
              : Colors.red.shade300,
          mascotImagePath: totalScore > 0
              ? 'assets/images/eyes_no_pad.png'
              : 'assets/images/close_no_pad.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalScore > 0
                    ? 'Great job collecting fruits!'
                    : 'Time ran out! Try again!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade50,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Final Score: $totalScore',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber.shade300,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultColumn("🍒", cherryCount),
                  _buildResultColumn("🫐", blueberryCount),
                ],
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
                _startGame();
              },
              color: Colors.green.shade600,
            ),
            _buildThemedButton(
              context,
              text: 'Back to Menu',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              color: Colors.brown.shade700,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultColumn(String emoji, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    Color color = Colors.green,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.yellow.shade200, width: 3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            elevation: 8,
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

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
                      _buildScoreDisplay(fontSize),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModernCounter("🍒", cherryCount, fontSize),
                          const SizedBox(width: 8),
                          _buildModernCounter("🫐", blueberryCount, fontSize),
                        ],
                      ),
                      _buildTimerDisplay(fontSize),
                    ],
                  ),
                ),

                // Frog mascot with animation
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

    final random = Random(42);
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

    canvas.drawCircle(center, size.width * 0.2, paint);

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

// --- Themed Game Dialog Widget (Same as CardGame) ---
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
    this.mascotImagePath = 'assets/images/open_no_pad.png',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final dialogWidth = screenWidth * 0.8;
    final dialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Main Content Box
            Container(
              margin: const EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade800, Colors.green.shade900],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.brown.shade600, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 75, 25, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(child: SingleChildScrollView(child: content)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),

            // Title Header/Banner
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.yellow.shade700, width: 4),
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
                    fontSize: 28,
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

            // Mascot Image
            Positioned(
              top: 35,
              right: 15,
              child: Image.asset(
                mascotImagePath,
                width: 70,
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
