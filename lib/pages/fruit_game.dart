import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class FruitGame extends StatefulWidget {
  const FruitGame({super.key});

  @override
  State<FruitGame> createState() => _FruitGameState();
}

class _FruitGameState extends State<FruitGame> with TickerProviderStateMixin {
  int cherryCount = 0;
  int blueberryCount = 0;
  int totalScore = 0;
  int timeLeft = 30;
  bool gameActive = false;
  Timer? _timer;
  Timer? _mascotTimer;

  FruitType? currentFruit;
  Offset fruitPosition = Offset.zero;
  bool isDragging = false;
  late AudioPlayer _bgMusicPlayer;

  // Poof animation controller
  late AnimationController _poofController;
  late Animation<double> _poofScale;
  late Animation<double> _poofOpacity;
  bool showPoof = false;

  // Frog mascot animation states
  int _frogFrame = 0;

  // CONFETTI CONTROLLERS
  late ConfettiController _confettiController;
  late ConfettiController _dialogConfettiController;

  final GlobalKey cherryBasketKey = GlobalKey();
  final GlobalKey blueberryBasketKey = GlobalKey();
  Rect? cherryBasketRect;
  Rect? blueberryBasketRect;

  Random random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

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
    _confettiController.dispose();
    _dialogConfettiController.dispose();
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
    setState(() {
      cherryCount = 0;
      blueberryCount = 0;
      totalScore = 0;
      timeLeft = 30;
      gameActive = false;
      currentFruit = null;
      isDragging = false;
    });
    _confettiController.stop();
    _dialogConfettiController.stop();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/basket.mp3'));
  }

  void _startGame() {
    if (gameActive) return;

    setState(() {
      gameActive = true;
      timeLeft = 30;
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
      // Start slightly lower to account for top bar
      fruitPosition = const Offset(0.31, 0.6);
      isDragging = false;
      showPoof = true;
    });

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
    // Adjusted calculation to account for safe area
    return Size(mediaQuery.size.width, mediaQuery.size.height - 120);
  }

  Offset _getFruitCenter() {
    final gameSize = _getGameAreaSize();
    // Adjusted offset calculation
    return Offset(
      fruitPosition.dx * gameSize.width,
      fruitPosition.dy * gameSize.height + 80,
    );
  }

  Future<void> _onBackButtonPressed() async {
    _timer?.cancel();

    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        title: '🚪 Leaving already?',
        content: const Text(
          'Your current game progress will be lost!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false); // Stay
              if (gameActive) {
                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  setState(() {
                    if (timeLeft > 0)
                      timeLeft--;
                    else {
                      gameActive = false;
                      timer.cancel();
                      _showGameOver();
                    }
                  });
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Stay & Play'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Leave
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit Game'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildDialogContent({
    required String title,
    required Widget content,
    required List<Widget> actions,
    bool showConfetti = false,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 350,
            padding: const EdgeInsets.all(20),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                content,
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actions,
                ),
              ],
            ),
          ),
          if (showConfetti)
            ConfettiWidget(
              confettiController: _dialogConfettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.2,
              numberOfParticles: 15,
              gravity: 0.5,
              shouldLoop: false,
              colors: const [
                Colors.yellow,
                Colors.lightGreen,
                Colors.lightBlue,
              ],
              createParticlePath: _drawStar,
            ),
        ],
      ),
    );
  }

  void _showGameOver() {
    if (totalScore > 0) {
      _confettiController.play();
      _dialogConfettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _buildDialogContent(
          title: 'WELL DONE! 🎉',
          showConfetti: totalScore > 0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('🍒', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        '$cherryCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('🫐', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        '$blueberryCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
                _startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Play Again'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  Path _drawStar(Size size) {
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

  @override
  Widget build(BuildContext context) {
    _updateBasketPositions();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final basketSize = isTablet ? 220.0 : 130.0;
    final baseFruitSize = isTablet ? 70.0 : 50.0;
    final draggingFruitSize = isTablet ? 100.0 : 80.0;
    final frogSize = isTablet ? 240.0 : 140.0;

    // Use SafeArea top padding if available, otherwise default to a reasonable margin
    final safeTopPadding = MediaQuery.of(context).padding.top;
    final topMargin = safeTopPadding > 0 ? safeTopPadding + 10 : 30.0;

    // Adjust header height based on screen size + margin
    final headerHeight = isTablet ? 100.0 + topMargin : 80.0 + topMargin;
    final fontSize = isTablet ? 20.0 : 12.0;

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
                ).withOpacity(0.4),
                child: SafeArea(
                  // Using SafeArea to respect device notches/cutouts
                  left: false,
                  bottom: false,
                  // IMPORTANT: Top is TRUE by default, keeping it TRUE ensures we respect the notch
                  top: true,
                  child: Stack(
                    children: [
                      // --- UPDATED HEADER (SPLIT) ---

                      // 1. CENTER: Counters
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0, // Stretch to allow centering
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModernCounter("🍒", cherryCount, fontSize),
                            const SizedBox(width: 8),
                            _buildModernCounter("🫐", blueberryCount, fontSize),
                          ],
                        ),
                      ),

                      // 2. RIGHT: Timer and Exit Button
                      Positioned(
                        top: 10,
                        right: 20,
                        child: Row(
                          children: [
                            _buildTimerDisplay(fontSize),
                            const SizedBox(width: 8),
                            // EXIT BUTTON
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: _onBackButtonPressed,
                                child: const Icon(
                                  Icons.exit_to_app_rounded,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Frog mascot
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
                          left:
                              fruitPosition.dx * _getGameAreaSize().width - 75,
                          top:
                              fruitPosition.dy * _getGameAreaSize().height -
                              75 +
                              headerHeight, // Adjusted for new header height
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
                              (isDragging ? draggingFruitSize : baseFruitSize) /
                                  2,
                          top:
                              fruitPosition.dy * _getGameAreaSize().height -
                              (isDragging ? draggingFruitSize : baseFruitSize) /
                                  2 +
                              headerHeight, // Adjusted for new header height
                          child: GestureDetector(
                            onPanStart: _onDragStart,
                            onPanUpdate: _onDragUpdate,
                            onPanEnd: _onDragEnd,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isDragging
                                  ? draggingFruitSize
                                  : baseFruitSize,
                              height: isDragging
                                  ? draggingFruitSize
                                  : baseFruitSize,
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
                                            color: _getFruitGlowColor()
                                                .withOpacity(0.4),
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
                                horizontal: isTablet ? 30 : 20,
                                vertical: isTablet ? 15 : 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'START GAME',
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 18,
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

            // --- CONFETTI CANNONS (7 Sources) ---
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
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 3,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.1,
                numberOfParticles: 25,
                gravity: 0.2,
                colors: const [Colors.green, Colors.blue, Colors.pink],
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 2 * pi / 3,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.1,
                numberOfParticles: 25,
                gravity: 0.2,
                colors: const [Colors.purple, Colors.amber, Colors.red],
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 0,
                maxBlastForce: 15,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 20,
                gravity: 0.4,
                colors: const [Colors.yellow, Colors.orange, Colors.red],
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi,
                maxBlastForce: 15,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 20,
                gravity: 0.4,
                colors: const [Colors.blue, Colors.cyan, Colors.purple],
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 4,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [Colors.teal, Colors.lime, Colors.indigo],
                createParticlePath: _drawStar,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -3 * pi / 4,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                gravity: 0.3,
                colors: const [Colors.pinkAccent, Colors.deepOrange],
                createParticlePath: _drawStar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PoofPainter extends CustomPainter {
  final Color color;

  PoofPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

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
