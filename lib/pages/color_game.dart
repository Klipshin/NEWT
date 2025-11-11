import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// NOTE: For simplicity, I've commented out the AudioPlayer imports
// as they require external packages/assets and are not strictly needed
// for the core game logic demonstration.

// import 'package:audioplayers/audioplayers.dart';

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
      "pink": const Color(0xFFCA54E2), // Purple Pink
      "green": const Color(0xFF95E1D3), // Seafoam Green
      "orange": const Color(0xFFFFAA5A), // Bright Orange
    },
    // Add more color styles here for variation
  ];

  @override
  void initState() {
    super.initState();
    colorMap = colorStyles[currentStyle];
    _updateLevelConfig();
    _initializeGame();
    // _bgMusicPlayer = AudioPlayer();
    // _playBackgroundMusic();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    // _bgMusicPlayer.dispose();
    super.dispose();
  }

  // --- Level Progression and Configuration ---

  void _updateLevelConfig() {
    // Progressive difficulty: Grid Size, Number of Colors, Moves Limit
    if (level <= 3) {
      // Levels 1-3: No move limit, focus on speed (timer) and learning
      movesLimit = 999;
      timeLimit = 45 - (level - 1) * 5; // Start at 45s, decrease by 5s
    } else if (level == 4) {
      // Level 4: Introduce Move Limit
      movesLimit = 25;
      timeLimit = 40;
    } else if (level == 5) {
      // Level 5: Bigger grid, fewer moves
      gridSize = 5;
      movesLimit = 20;
      timeLimit = 50;
    } else if (level == 6) {
      // Level 6: Even bigger grid, tighter limit
      gridSize = 6;
      movesLimit = 25;
      timeLimit = 60;
    } else if (level >= 7) {
      // Level 7+: Max difficulty, max colors/grid, tight limits
      gridSize = 6;
      movesLimit = 20;
      timeLimit = 55;
    }

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
    // Ensure the starting block is a valid color (it always is with this method)
    // and that the board isn't already flooded (highly unlikely with random gen)
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            _gameTimer?.cancel();
            _showGameOverDialog("Time's Up!");
          }
        });
      }
    });
  }

  // --- Core Flood-Fill Logic ---

  void _handleColorSelection(String newColor) {
    // Game over checks
    if (movesMade >= movesLimit && level >= 4) return;
    if (timeLeft <= 0) return;

    final startColor = grid[0][0];

    // Don't waste a move if the color is already the current color
    if (newColor == startColor) return;

    movesMade++;
    _applyFloodFill(0, 0, startColor, newColor);

    if (_checkComplete()) {
      _gameTimer?.cancel();
      _onPuzzleComplete();
    } else if (level >= 4 && movesMade >= movesLimit) {
      _gameTimer?.cancel();
      _showGameOverDialog("Out of Moves!");
    }

    setState(() {});
  }

  // Recursive Flood Fill Algorithm (Depth-First Search)
  void _applyFloodFill(
    int row,
    int col,
    String targetColor,
    String replacementColor,
  ) {
    // 1. Boundary Check
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return;
    }

    // 2. Color Check - Only fill blocks matching the starting color
    if (grid[row][col] != targetColor) {
      return;
    }

    // 3. Apply the fill
    grid[row][col] = replacementColor;

    // 4. Recurse to connected neighbors (4-way connectivity)
    _applyFloodFill(row + 1, col, targetColor, replacementColor); // Down
    _applyFloodFill(row - 1, col, targetColor, replacementColor); // Up
    _applyFloodFill(row, col + 1, targetColor, replacementColor); // Right
    _applyFloodFill(row, col - 1, targetColor, replacementColor); // Left
  }

  bool _checkComplete() {
    // Check if the entire board is the same color as the top-left cell
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

    if (puzzlesSolved >= 2 && level < 7) {
      level++;
      puzzlesSolved = 0;
      shouldLevelUp = true;
      _updateLevelConfig(); // Update config before showing dialog
      levelUpMessage = 'Level $level: ${_getLevelDescription()}';
    }

    if (shouldLevelUp) {
      _showLevelUpDialog(levelUpMessage);
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text(
            '🎉 You Did It!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Flooded the board in $movesMade moves with $timeLeft seconds left!',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Next Puzzle'),
            ),
          ],
        );
      },
    );
  }

  void _showLevelUpDialog(String message) {
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
          content: Text(
            'New Challenge!\n$message\nGrid: ${gridSize}x$gridSize',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Start Level'),
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
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: const Text(
            'Game Over! 😥',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            reason,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Restart current level
                _updateLevelConfig();
                _initializeGame();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  // --- UI Building Blocks (Adapted from your reference) ---

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

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final currentMovesLeft = level >= 4 ? movesLimit - movesMade : movesLimit;
    final movesDisplay = level >= 4 ? '$currentMovesLeft/$movesLimit' : '∞';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Use a simple color or placeholder if you don't have the assets
          color: Color.fromARGB(255, 180, 230, 180),
        ),
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
                        timeLeft <= 10 ? Colors.red : Colors.green.shade700,
                      ),
                      const SizedBox(height: 15),
                      _buildStatItem(
                        level >= 4 ? "Moves Left" : "Moves",
                        level >= 4 ? movesDisplay : '$movesMade',
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
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
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
              // Right Sidebar: Color Palette
              Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                child: _buildColorPalette(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
