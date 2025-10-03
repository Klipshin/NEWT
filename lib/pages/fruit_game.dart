import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class FruitGame extends StatefulWidget {
  const FruitGame({super.key});

  @override
  State<FruitGame> createState() => _FruitGameState();
}

class _FruitGameState extends State<FruitGame> {
  // Game state
  int appleCount = 0;
  int bananaCount = 0;
  int totalScore = 0;
  int timeLeft = 60;
  bool gameActive = false;
  Timer? _timer;

  // Current fruit
  FruitType? currentFruit;
  Offset fruitPosition = Offset.zero;
  bool isDragging = false;

  // Container positions (will be set after layout)
  final GlobalKey appleContainerKey = GlobalKey();
  final GlobalKey bananaContainerKey = GlobalKey();
  Rect? appleContainerRect;
  Rect? bananaContainerRect;

  Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    setState(() {
      appleCount = 0;
      bananaCount = 0;
      totalScore = 0;
      timeLeft = 60;
      gameActive = false;
      currentFruit = null;
      isDragging = false;
    });
  }

  void _startGame() {
    if (gameActive) return;

    setState(() {
      gameActive = true;
      timeLeft = 60;
      appleCount = 0;
      bananaCount = 0;
      totalScore = 0;
    });

    // Start timer
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

    // Generate first fruit
    _generateNewFruit();
  }

  void _generateNewFruit() {
    if (!gameActive) return;

    setState(() {
      currentFruit = random.nextBool() ? FruitType.apple : FruitType.banana;
      // Position fruit in the middle of the screen
      fruitPosition = const Offset(0.5, 0.5);
      isDragging = false;
    });
  }

  void _onDragStart(DragStartDetails details) {
    if (!gameActive || currentFruit == null) return;
    setState(() {
      isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!gameActive || currentFruit == null) return;

    setState(() {
      // Convert to relative position (0-1 range)
      final newX =
          (fruitPosition.dx + details.delta.dx / _getGameAreaSize().width)
              .clamp(0.0, 1.0);
      final newY =
          (fruitPosition.dy + details.delta.dy / _getGameAreaSize().height)
              .clamp(0.0, 1.0);
      fruitPosition = Offset(newX, newY);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!gameActive || currentFruit == null) return;

    // Check if fruit is dropped in correct container
    final fruitCenter = _getFruitCenter();
    bool scored = false;

    if (currentFruit == FruitType.apple &&
        appleContainerRect != null &&
        appleContainerRect!.contains(fruitCenter)) {
      setState(() {
        appleCount++;
        totalScore += 10;
        scored = true;
      });
    } else if (currentFruit == FruitType.banana &&
        bananaContainerRect != null &&
        bananaContainerRect!.contains(fruitCenter)) {
      setState(() {
        bananaCount++;
        totalScore += 10;
        scored = true;
      });
    }

    if (scored) {
      // Success - generate new fruit after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && gameActive) {
          _generateNewFruit();
        }
      });
    } else {
      // Not in container - reset position
      setState(() {
        fruitPosition = const Offset(0.5, 0.5);
        isDragging = false;
      });
    }
  }

  void _updateContainerPositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appleContext = appleContainerKey.currentContext;
      final bananaContext = bananaContainerKey.currentContext;

      if (appleContext != null) {
        final box = appleContext.findRenderObject() as RenderBox;
        appleContainerRect = box.localToGlobal(Offset.zero) & box.size;
      }

      if (bananaContext != null) {
        final box = bananaContext.findRenderObject() as RenderBox;
        bananaContainerRect = box.localToGlobal(Offset.zero) & box.size;
      }
    });
  }

  Size _getGameAreaSize() {
    final mediaQuery = MediaQuery.of(context);
    return Size(
      mediaQuery.size.width,
      mediaQuery.size.height - 200, // Account for header and instructions
    );
  }

  Offset _getFruitCenter() {
    final gameSize = _getGameAreaSize();
    final fruitPixelPosition = Offset(
      fruitPosition.dx * gameSize.width,
      fruitPosition.dy * gameSize.height + 100, // Add header height
    );
    return fruitPixelPosition;
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.orange[50],
        title: const Text(
          'Game Over!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score: $totalScore',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text('Apples Collected: $appleCount'),
            Text('Bananas Collected: $bananaCount'),
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
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update container positions after build
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateContainerPositions(),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
          ),
        ),
        child: Column(
          children: [
            // Header with timer and score
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('TIME', '$timeLeft', Icons.timer),
                  _buildStatItem('SCORE', '$totalScore', Icons.star),
                  _buildStatItem('APPLES', '$appleCount', Icons.apple),
                  _buildStatItem('BANANAS', '$bananaCount', Icons.celebration),
                ],
              ),
            ),

            // Game area
            Expanded(
              child: Stack(
                children: [
                  // Containers
                  Positioned(
                    left: 20,
                    top: 20,
                    child: _buildContainer(
                      key: appleContainerKey,
                      label: 'APPLE BASKET',
                      count: appleCount,
                      color: Colors.red,
                      icon: Icons.apple,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: _buildContainer(
                      key: bananaContainerKey,
                      label: 'BANANA BASKET',
                      count: bananaCount,
                      color: Colors.yellow,
                      icon: Icons.celebration,
                    ),
                  ),

                  // Current fruit (if any)
                  if (currentFruit != null)
                    Positioned(
                      left: fruitPosition.dx * _getGameAreaSize().width - 30,
                      top: fruitPosition.dy * _getGameAreaSize().height - 30,
                      child: GestureDetector(
                        onPanStart: _onDragStart,
                        onPanUpdate: _onDragUpdate,
                        onPanEnd: _onDragEnd,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDragging
                                ? Colors.white.withOpacity(0.8)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              currentFruit == FruitType.apple ? '🍎' : '🍌',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Start button (centered when game not active)
                  if (!gameActive && currentFruit == null)
                    Center(
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 24),
                        ),
                        child: const Text('START GAME'),
                      ),
                    ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.1),
              child: const Column(
                children: [
                  Text(
                    'Drag the fruit to the correct basket!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '🍎 → Red Basket | 🍌 → Yellow Basket',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContainer({
    required GlobalKey key,
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      key: key,
      width: 120,
      height: 150,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum FruitType { apple, banana }
