import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// NOTE: The AudioPlayer imports are still commented out
// as they were in your original 'ColorFloodGame' to avoid
// external package/asset issues.

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

  // Game state variables for Color Flood
  late List<List<String>> grid;
  late int movesLimit; // Max moves allowed for the current level
  late int movesMade;
  late int timeLimit; // Seconds
  late int timeLeft;
  Timer? _gameTimer;

  // Colors available for the current level
  late List<String> colors;
  late Map<String, Color> colorMap;

  // Extended color styles
  int currentStyle = 0;
  final List<Map<String, Color>> colorStyles = [
    {
      "red": const Color(0xFFFF6B6B), // Light Red
      "blue": const Color(0xFF4C57FC), // Vibrant Blue
      "yellow": const Color(0xFFFFE66D), // Soft Yellow
      "pink": const Color.fromARGB(255, 208, 110, 228), // Purple Pink
      "green": const Color(0xFF95E1D3), // Seafoam Green
      "orange": const Color(0xFFFFAA5A), // Bright Orange
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
    colorMap = colorStyles[currentStyle];
    _updateLevelConfig();
    _initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  // --- Level Progression and Configuration ---

  void _updateLevelConfig() {
    // Set grid size and number of colors based on level
    if (level == 1) {
      gridSize = 4;
      colors = ["red", "blue", "yellow"]; // 3 Colors
    } else if (level == 2) {
      gridSize = 4;
      colors = ["red", "blue", "yellow", "pink"]; // 4 Colors
    } else if (level == 3) {
      gridSize = 5;
      colors = ["red", "blue", "yellow", "pink"]; // 4 Colors
    } else if (level == 4) {
      gridSize = 5;
      colors = ["red", "blue", "yellow", "pink", "green"]; // 5 Colors
    } else if (level >= 5) {
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green", "orange"]; // 6 Colors
    }

    // Progressive difficulty: Moves Limit
    if (level <= 3) {
      // Levels 1-3: No move limit, focus on speed (timer)
      movesLimit = 999;
      timeLimit = 45 - (level - 1) * 5; // Start at 45s, decrease by 5s
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
    _gameTimer?.cancel(); // Stop any existing timer

    movesMade = 0;
    timeLeft = timeLimit;

    // Change style for variation
    currentStyle = (currentStyle + 1) % colorStyles.length;
    colorMap = colorStyles[currentStyle];

    _generateRandomBoard();
    _startGameTimer();

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

    // Check if game is already over
    if (timeLeft <= 0 || (level >= 4 && movesMade >= movesLimit)) return;

    // Don't waste a move if the color is already the current color
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

    // 4-way connectivity
    _applyFloodFill(row + 1, col, targetColor, replacementColor); // Down
    _applyFloodFill(row - 1, col, targetColor, replacementColor); // Up
    _applyFloodFill(row, col + 1, targetColor, replacementColor); // Right
    _applyFloodFill(row, col - 1, targetColor, replacementColor); // Left
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

  // --- Game State Management and Dialogs ---

  void _onPuzzleComplete() {
    puzzlesSolved++;

    bool shouldLevelUp = false;
    String levelUpMessage = '';
    int oldGridSize = gridSize;

    if (puzzlesSolved >= 2 && level < 7) {
      level++;
      puzzlesSolved = 0;
      shouldLevelUp = true;
      _updateLevelConfig(); // Update config before showing dialog
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

  // Themed Dialog Functions (Copied/Adapted from ConnectDotsGame)

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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'PERFECT! 🎉',
          titleColor: Colors.cyan.shade300,
          mascotImagePath: 'assets/images/mouthfrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Board flooded in $movesMade moves!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade50,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Level $level - Puzzle $puzzlesSolved/2',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.yellow.shade200,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Next Puzzle',
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              color: Colors.green.shade700,
            ),
            // Example of Back to Menu button (requires navigation logic to work)
            // _buildThemedButton(
            //   context,
            //   text: 'Back to Menu',
            //   onPressed: () => Navigator.pop(context),
            //   color: Colors.brown.shade700,
            // ),
          ],
        );
      },
    );
  }

  void _showLevelUpDialog(String message, bool gridSizeChanged) {
    // If grid changed, generate new puzzle immediately before showing dialog
    if (gridSizeChanged) {
      _initializeGame(); // Re-initializes with the new grid size and generates new board
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'LEVEL UP! ⭐',
          titleColor: Colors.yellow.shade300,
          mascotImagePath: 'assets/images/mouthfrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Challenge Awaits!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade50,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade200,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Grid: ${gridSize}x$gridSize',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.yellow.shade200,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Start Level!',
              onPressed: () {
                Navigator.pop(context);
                if (!gridSizeChanged) {
                  _initializeGame(); // Only re-initialize game if the grid size wasn't changed
                }
                // If grid size changed, it was already initialized above
              },
              color: Colors.orange.shade700,
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'GAME OVER! 😥',
          titleColor: Colors.red.shade300,
          mascotImagePath: 'assets/images/closefrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reason,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade50,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Current Level: $level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.yellow.shade200,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Try Again',
              onPressed: () {
                Navigator.pop(context);
                // Restart current level
                _updateLevelConfig();
                _initializeGame();
              },
              color: Colors.red.shade700,
            ),
          ],
        );
      },
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final currentMovesLeft = level >= 4 ? movesLimit - movesMade : movesLimit;
    final movesDisplay = level >= 4
        ? '$currentMovesLeft/$movesLimit'
        : '$movesMade';
    final movesLabel = level >= 4 ? "Moves Left" : "Moves Made";

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
                // Left Sidebar: Stats and Reset
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    // Added to prevent overflow
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
                          timeLeft <= 10 ? Colors.red : Colors.green.shade700,
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
                        // Refresh Button
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
                          // Key change ensures full grid rebuild on size change
                          key: ValueKey('grid-$gridSize-$level'),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10),
                            ],
                            color: Colors.white.withOpacity(
                              0.7,
                            ), // Background for the grid
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
                              Color color = colorMap[colorName] ?? Colors.grey;

                              return Container(color: color);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right Sidebar: Color Palette (Fixed Overflow)
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    // FIX: Added SingleChildScrollView here
                    child: _buildColorPalette(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Themed Game Dialog Widget (from ConnectDotsGame) ---
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
    // FIX: Removed SingleChildScrollView wrapper from here, as it's now around the Column in build()
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

// --- Themed Game Dialog Widget (Matching Card Game Style) ---
// This class is copied directly from your ConnectDotsGame for consistent styling.
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

            // 3. The Mascot Image
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
