import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Enabled
import 'package:confetti/confetti.dart'; // Added

class ColorFloodGame extends StatefulWidget {
  const ColorFloodGame({super.key});

  @override
  State<ColorFloodGame> createState() => _ColorFloodGameState();
}

class _ColorFloodGameState extends State<ColorFloodGame>
    with TickerProviderStateMixin {
  int gridSize = 4; // Starts 4x4
  int level = 1;
  int puzzlesSolved = 0;
  bool _showDCardOverlay = true;

  // Game state variables for Color Flood
  late List<List<String>> grid;
  late int movesLimit;
  late int movesMade;
  late int timeLimit;
  late int timeLeft;
  Timer? _gameTimer;

  // Colors available for the current level
  late List<String> colors;
  late Map<String, Color> colorMap;

  // --- NEW: Audio & Effects ---
  late AudioPlayer _bgMusicPlayer;
  late ConfettiController _bgConfettiController;
  late ConfettiController _dialogConfettiController;

  // Extended color styles
  int currentStyle = 0;
  final List<Map<String, Color>> colorStyles = [
    {
      "red": const Color(0xFFFF6B6B),
      "blue": const Color(0xFF4C57FC),
      "yellow": const Color(0xFFFFE66D),
      "pink": const Color.fromARGB(255, 208, 110, 228),
      "green": const Color(0xFF95E1D3),
      "orange": const Color(0xFFFFAA5A),
    },
    {
      "red": const Color.fromARGB(255, 224, 41, 41),
      "blue": const Color.fromARGB(255, 66, 88, 226),
      "yellow": const Color.fromARGB(255, 228, 184, 54),
      "pink": const Color.fromARGB(255, 238, 108, 151),
      "green": const Color.fromARGB(255, 108, 189, 38),
      "orange": const Color.fromARGB(255, 236, 99, 57),
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Confetti
    _bgConfettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // Initialize Audio
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();

    colorMap = colorStyles[currentStyle];
    _updateLevelConfig();
    _initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _bgMusicPlayer.dispose();
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    // Using a calm track for logic puzzles
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
  }

  // --- STAR PATH FOR CONFETTI ---
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

  // --- Level Progression and Configuration ---

  void _updateLevelConfig() {
    if (level == 1) {
      gridSize = 4;
      colors = ["red", "blue", "yellow"];
    } else if (level == 2) {
      gridSize = 4;
      colors = ["red", "blue", "yellow", "pink"];
    } else if (level == 3) {
      gridSize = 5;
      colors = ["red", "blue", "yellow", "pink"];
    } else if (level == 4) {
      gridSize = 5;
      colors = ["red", "blue", "yellow", "pink", "green"];
    } else if (level >= 5) {
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green", "orange"];
    }

    if (level <= 3) {
      movesLimit = 999;
      timeLimit = 45 - (level - 1) * 5;
    } else if (level == 4) {
      movesLimit = 25;
      timeLimit = 40;
    } else if (level == 5) {
      movesLimit = 20;
      timeLimit = 50;
    } else if (level == 6) {
      movesLimit = 25;
      timeLimit = 60;
    } else if (level >= 7) {
      movesLimit = 20;
      timeLimit = 55;
    }
  }

  // --- Game Initialization and Reset ---

  void _initializeGame() {
    _gameTimer?.cancel();

    // Stop effects
    _bgConfettiController.stop();
    _dialogConfettiController.stop();

    movesMade = 0;
    timeLeft = timeLimit;

    currentStyle = (currentStyle + 1) % colorStyles.length;
    colorMap = colorStyles[currentStyle];

    _generateRandomBoard();
    _gameTimer?.cancel();
    // Only start timer if overlay is not showing
    if (!_showDCardOverlay) {
      _startGameTimer();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _generateRandomBoard() {
    final rand = Random();
    grid = List.generate(
      gridSize,
      (_) =>
          List.generate(gridSize, (_) => colors[rand.nextInt(colors.length)]),
    );
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _gameTimer?.cancel();
            _showGameOverDialog("Time's Up! ⏳");
          }
        });
      }
    });
  }

  // --- Core Flood-Fill Logic ---

  void _handleColorSelection(String newColor) {
    final targetColor = grid[0][0];

    if (timeLeft <= 0 || (level >= 4 && movesMade >= movesLimit)) return;
    if (newColor == targetColor) return;

    movesMade++;
    _applyFloodFill(0, 0, targetColor, newColor);

    if (_checkComplete()) {
      _gameTimer?.cancel();
      _onPuzzleComplete();
    } else if (level >= 4 && movesMade >= movesLimit) {
      _gameTimer?.cancel();
      _showGameOverDialog("Out of Moves! 🚫");
    }

    setState(() {});
  }

  void _applyFloodFill(
    int row,
    int col,
    String targetColor,
    String replacementColor,
  ) {
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return;
    }

    if (grid[row][col] != targetColor) {
      return;
    }

    grid[row][col] = replacementColor;

    _applyFloodFill(row + 1, col, targetColor, replacementColor);
    _applyFloodFill(row - 1, col, targetColor, replacementColor);
    _applyFloodFill(row, col + 1, targetColor, replacementColor);
    _applyFloodFill(row, col - 1, targetColor, replacementColor);
  }

  bool _checkComplete() {
    final targetColor = grid[0][0];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] != targetColor) {
          return false;
        }
      }
    }
    return true;
  }

  void _onPuzzleComplete() {
    puzzlesSolved++;

    bool shouldLevelUp = false;
    String levelUpMessage = '';
    int oldGridSize = gridSize;

    if (puzzlesSolved >= 2 && level < 7) {
      level++;
      puzzlesSolved = 0;
      shouldLevelUp = true;
      _updateLevelConfig();
      levelUpMessage = 'Level $level: ${_getLevelDescription()}';
    }

    if (shouldLevelUp) {
      _showLevelUpDialog(levelUpMessage, oldGridSize != gridSize);
    } else {
      _showWinDialog();
    }
  }

  String _getLevelDescription() {
    if (level <= 3) {
      return "Moves UNLIMITED, Focus on Speed!";
    }
    return "Moves LIMITED: $movesLimit";
  }

  // --- SHARED DIALOG BUILDER (Standard Style) ---
  Widget _buildDialogContent(
    String title,
    String message,
    List<Widget> actions,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
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
          ConfettiWidget(
            confettiController: _dialogConfettiController,
            blastDirection: pi / 2,
            maxBlastForce: 20,
            minBlastForce: 10,
            emissionFrequency: 0.2,
            numberOfParticles: 15,
            gravity: 0.5,
            shouldLoop: false,
            colors: const [Colors.yellow, Colors.lightGreen, Colors.lightBlue],
            createParticlePath: drawStar,
          ),
        ],
      ),
    );
  }

  // --- UPDATED DIALOGS ---

  void _showWinDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🎉 Perfect!',
        'Board flooded in $movesMade moves! Puzzle $puzzlesSolved/2',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Next Puzzle', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(String message, bool gridSizeChanged) {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    if (gridSizeChanged) {
      _initializeGame();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _buildDialogContent('⭐ Level Up!', 'New Challenge: $message', [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!gridSizeChanged) {
                  _initializeGame();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Level', style: TextStyle(fontSize: 16)),
            ),
          ]),
    );
  }

  void _showGameOverDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _buildDialogContent('😥 Game Over!', '$reason Try again.', [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateLevelConfig();
                _initializeGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ]),
    );
  }

  // --- NAVIGATION SAFETY ---
  Future<void> _onBackButtonPressed() async {
    _gameTimer?.cancel(); // Pause timer

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
              if (!_showDCardOverlay) {
                _startGameTimer();
              }
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

  @override
  Widget build(BuildContext context) {
    final currentMovesLeft = level >= 4 ? movesLimit - movesMade : movesLimit;
    final movesDisplay = level >= 4
        ? '$currentMovesLeft/$movesLimit'
        : '$movesMade';
    final movesLabel = level >= 4 ? "Moves Left" : "Moves Made";

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
                      // Left Sidebar: Stats and Reset
                      Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildStatItem(
                                "Level",
                                "$level",
                                Icons.star,
                                Colors.blue.shade700,
                              ),
                              const SizedBox(height: 15),
                              _buildStatItem(
                                "Time",
                                "$timeLeft s",
                                Icons.timer,
                                timeLeft <= 10
                                    ? Colors.red
                                    : Colors.green.shade700,
                              ),
                              const SizedBox(height: 15),
                              _buildStatItem(
                                movesLabel,
                                movesDisplay,
                                Icons.change_circle,
                                level >= 4 && currentMovesLeft <= 5
                                    ? Colors.red
                                    : Colors.orange.shade700,
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
                                  color: Colors.purple.shade700,
                                  tooltip: 'New Puzzle',
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

                      // Game grid
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                key: ValueKey('grid-$gridSize-$level'),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                    ),
                                  ],
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridSize,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 1.0,
                                        mainAxisSpacing: 1.0,
                                      ),
                                  itemCount: gridSize * gridSize,
                                  itemBuilder: (context, index) {
                                    int x = index % gridSize;
                                    int y = index ~/ gridSize;
                                    String colorName = grid[y][x];
                                    Color color =
                                        colorMap[colorName] ?? Colors.grey;

                                    return Container(color: color);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right Sidebar: Color Palette
                      Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: _buildColorPalette(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- CONFETTI OVERLAYS ---
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: pi / 2,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 30,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                ],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: pi / 3,
                emissionFrequency: 0.1,
                numberOfParticles: 25,
                colors: const [Colors.green, Colors.blue, Colors.pink],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: 2 * pi / 3,
                emissionFrequency: 0.1,
                numberOfParticles: 25,
                colors: const [Colors.purple, Colors.amber, Colors.red],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: 0,
                maxBlastForce: 15,
                emissionFrequency: 0.08,
                numberOfParticles: 20,
                colors: const [Colors.yellow, Colors.orange, Colors.red],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: pi,
                maxBlastForce: 15,
                emissionFrequency: 0.08,
                numberOfParticles: 20,
                colors: const [Colors.blue, Colors.cyan, Colors.purple],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: -pi / 4,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                colors: const [Colors.teal, Colors.lime, Colors.indigo],
                createParticlePath: drawStar,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: -3 * pi / 4,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                colors: const [Colors.pinkAccent, Colors.deepOrange],
                createParticlePath: drawStar,
              ),
            ),
            // DColors Overlay - stuck to bottom
            if (_showDCardOverlay)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDCardOverlay = false;
                  });
                  _startGameTimer();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/dcolor.png',
                      width: MediaQuery.of(context).size.width * 1.0,
                      height: MediaQuery.of(context).size.height * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final bool isCritical =
        (label == "Time" && timeLeft <= 10) ||
        (label == "Moves Left" && level >= 4 && movesLimit - movesMade <= 5);
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : color,
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((colorName) {
        final color = colorMap[colorName]!;
        final bool isCurrentColor = grid[0][0] == colorName;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GestureDetector(
            onTap: () => _handleColorSelection(colorName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentColor ? Colors.white : Colors.black26,
                  width: isCurrentColor ? 4 : 2,
                ),
                boxShadow: isCurrentColor
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
