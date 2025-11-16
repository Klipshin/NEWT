import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ConnectDotsGame extends StatefulWidget {
  const ConnectDotsGame({super.key});

  @override
  State<ConnectDotsGame> createState() => _ConnectDotsGameState();
}

class _ConnectDotsGameState extends State<ConnectDotsGame>
    with TickerProviderStateMixin {
  int gridSize = 4; // Start with 4x4
  int level = 1;
  int puzzlesSolved = 0;

  late List<List<String?>> grid;
  String? currentColor;
  Map<String, List<Offset>> paths = {};
  int _frogFrame = 0;
  Timer? _mascotTimer;

  late AnimationController _winController;
  bool gameComplete = false;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  // Extended color styles with more colors for higher levels
  int currentStyle = 0;
  final List<Map<String, Color>> colorStyles = [
    {
      "red": Colors.red,
      "blue": Colors.blue,
      "yellow": Colors.yellow,
      "pink": Colors.pinkAccent,
      "green": Colors.green,
      "orange": Colors.orange,
    },
    {
      "red": Colors.orange,
      "blue": const Color.fromARGB(255, 56, 45, 199),
      "yellow": Colors.lime,
      "pink": const Color.fromARGB(255, 202, 85, 202),
      "green": Colors.teal,
      "orange": Colors.deepOrange,
    },
    {
      "red": Color(0xFFFF6B6B),
      "blue": Color.fromARGB(255, 76, 87, 252),
      "yellow": Color(0xFFFFE66D),
      "pink": Color.fromARGB(255, 202, 84, 226),
      "green": Color(0xFF95E1D3),
      "orange": Color(0xFFFFAA5A),
    },
  ];

  late Map<String, Color> colorMap;
  late List<String> colors;

  @override
  void initState() {
    super.initState();
    colorMap = colorStyles[currentStyle];
    _updateColorsForLevel();
    _initializeGame();
    _startMascotAnimation();
    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _mascotTimer?.cancel();
    _winController.dispose();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  void _updateColorsForLevel() {
    // Progressive difficulty with more colors and bigger grids
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
    } else if (level == 5) {
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green"];
    } else if (level == 6) {
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green", "orange"];
    } else {
      // Level 7+: Keep 6x6 with 6 colors but increase complexity
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green", "orange"];
    }
  }

  String _getLevelDescription() {
    switch (level) {
      case 1:
        return "4×4 Grid - 3 Colors";
      case 2:
        return "4×4 Grid - 4 Colors";
      case 3:
        return "5×5 Grid - 4 Colors";
      case 4:
        return "5×5 Grid - 5 Colors";
      case 5:
        return "6×6 Grid - 5 Colors";
      case 6:
        return "6×6 Grid - 6 Colors";
      default:
        return "6×6 Grid - Expert Mode";
    }
  }

  void _startMascotAnimation() {
    _mascotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _frogFrame = (_frogFrame + 1) % 3;
        });
      }
    });
  }

  void _initializeGame() {
    // Clear everything first
    gameComplete = false;
    currentColor = null;
    paths.clear();

    // Change style on each new game
    currentStyle = (currentStyle + 1) % colorStyles.length;
    colorMap = colorStyles[currentStyle];

    // Generate a solvable puzzle
    _generateSolvablePuzzle();

    // Force rebuild after state is fully updated
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
  }

  void _generateSolvablePuzzle({int recursionDepth = 0}) {
    // Prevent infinite recursion
    if (recursionDepth > 10) {
      // Fallback: create a simpler puzzle
      _generateSimplePuzzle();
      return;
    }

    // ALWAYS create a fresh empty grid at the start
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));

    // Generate paths - each color appears EXACTLY twice (one pair of dots)
    // IMPORTANT: occupiedCells must be reset here too
    Set<Offset> occupiedCells = {};
    final rand = Random();

    // Track successfully placed colors to detect if we need to restart
    Set<String> placedColors = {};

    // Keep track of which colors have been placed
    List<String> shuffledColors = List.from(colors)..shuffle();

    for (var color in shuffledColors) {
      bool pathCreated = false;
      int attempts = 0;

      // Before placing this color, verify grid doesn't already have it
      bool colorAlreadyOnGrid = false;
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (grid[y][x] == color) {
            colorAlreadyOnGrid = true;
            break;
          }
        }
        if (colorAlreadyOnGrid) break;
      }

      if (colorAlreadyOnGrid) {
        // Grid is corrupted, restart completely
        _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
        return;
      }

      while (!pathCreated && attempts < 100) {
        attempts++;

        // Pick random start position
        int startX = rand.nextInt(gridSize);
        int startY = rand.nextInt(gridSize);
        Offset start = Offset(startX.toDouble(), startY.toDouble());

        if (occupiedCells.contains(start)) continue;

        // Try to create a path using random walk
        List<Offset> path = [start];
        Set<Offset> pathSet = {start};
        Offset current = start;

        // Path length increases with level
        int minLength = 2 + (level ~/ 2);
        int maxLength = 4 + level;
        int targetLength = minLength + rand.nextInt(maxLength - minLength + 1);

        for (int i = 0; i < targetLength; i++) {
          List<Offset> possibleMoves = _getPossibleMoves(
            current,
            pathSet,
            occupiedCells,
          );

          if (possibleMoves.isEmpty) break;

          // Pick a random valid move
          Offset next = possibleMoves[rand.nextInt(possibleMoves.length)];
          path.add(next);
          pathSet.add(next);
          current = next;
        }

        // Path must be at least 2 cells long
        if (path.length >= 2) {
          occupiedCells.addAll(pathSet);

          // Place ONLY the two endpoints on the grid (start and end)
          // This ensures each color appears exactly twice
          int startYPos = path.first.dy.toInt();
          int startXPos = path.first.dx.toInt();
          int endYPos = path.last.dy.toInt();
          int endXPos = path.last.dx.toInt();

          // Double-check these cells are actually empty before placing
          if (grid[startYPos][startXPos] == null &&
              grid[endYPos][endXPos] == null) {
            grid[startYPos][startXPos] = color;
            grid[endYPos][endXPos] = color;
            placedColors.add(color);
            pathCreated = true;
          }
        }
      }

      // If we couldn't create a path after many attempts, start over completely
      if (!pathCreated) {
        _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
        return;
      }
    }

    // Final validation: count dots for each color
    Map<String, int> colorCounts = {};
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        String? cellColor = grid[y][x];
        if (cellColor != null) {
          colorCounts[cellColor] = (colorCounts[cellColor] ?? 0) + 1;
        }
      }
    }

    // Check if any color has more or less than 2 dots
    for (var color in colors) {
      int count = colorCounts[color] ?? 0;
      if (count != 2) {
        // Invalid puzzle detected! Regenerate completely
        print('Invalid puzzle detected: $color has $count dots instead of 2');
        _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
        return;
      }
    }

    // Also verify no extra colors on grid
    for (var entry in colorCounts.entries) {
      if (!colors.contains(entry.key)) {
        print('Extra color detected on grid: ${entry.key}');
        _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
        return;
      }
    }
  }

  void _generateSimplePuzzle() {
    // Fallback simple puzzle generator
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    final rand = Random();

    for (var color in colors) {
      // Place first dot
      int x1, y1, x2, y2;
      do {
        x1 = rand.nextInt(gridSize);
        y1 = rand.nextInt(gridSize);
      } while (grid[y1][x1] != null);
      grid[y1][x1] = color;

      // Place second dot
      do {
        x2 = rand.nextInt(gridSize);
        y2 = rand.nextInt(gridSize);
      } while (grid[y2][x2] != null);
      grid[y2][x2] = color;
    }
  }

  List<Offset> _getPossibleMoves(
    Offset current,
    Set<Offset> currentPath,
    Set<Offset> occupied,
  ) {
    List<Offset> moves = [];
    final directions = [
      Offset(0, -1), // up
      Offset(0, 1), // down
      Offset(-1, 0), // left
      Offset(1, 0), // right
    ];

    for (var dir in directions) {
      Offset next = Offset(current.dx + dir.dx, current.dy + dir.dy);

      // Check bounds
      if (next.dx < 0 ||
          next.dx >= gridSize ||
          next.dy < 0 ||
          next.dy >= gridSize) {
        continue;
      }

      // Check if already in current path
      if (currentPath.contains(next)) continue;

      // Check if occupied by another path
      if (occupied.contains(next)) continue;

      moves.add(next);
    }

    return moves;
  }

  void _handleCellTouch(Offset cellPos) {
    if (gameComplete) return;

    int x = cellPos.dx.toInt();
    int y = cellPos.dy.toInt();

    if (currentColor == null) {
      // Starting a new path
      if (grid[y][x] != null) {
        currentColor = grid[y][x];
        paths[currentColor!] = [cellPos];
        setState(() {});
      }
    } else {
      // Continuing or ending a path
      final currentPath = paths[currentColor!]!;
      final last = currentPath.last;

      // Check if move is adjacent
      bool isAdjacent =
          (cellPos.dx - last.dx).abs() + (cellPos.dy - last.dy).abs() == 1;

      if (!isAdjacent) return;

      // Check if this is backtracking
      bool isBacktracking =
          currentPath.length > 1 &&
          currentPath[currentPath.length - 2] == cellPos;

      if (isBacktracking) {
        // Allow backtracking
        currentPath.removeLast();
        setState(() {});
      } else {
        // Check if we can move to this cell
        bool canMoveTo = _canMoveToCell(cellPos, currentColor!);

        if (canMoveTo) {
          currentPath.add(cellPos);

          // Check if we completed this connection
          if (grid[y][x] == currentColor && cellPos != currentPath.first) {
            // Completed connection
            currentColor = null;

            if (_checkComplete()) {
              _onPuzzleComplete();
            }
          }

          setState(() {});
        }
      }
    }
  }

  void _handleDragEnd() {
    if (currentColor == null || gameComplete) return;

    final path = paths[currentColor!]!;

    // Check if this is a valid complete connection
    if (!_isValidConnection(currentColor!)) {
      // Remove incomplete paths
      paths.remove(currentColor!);
    }

    currentColor = null;

    if (_checkComplete()) {
      _onPuzzleComplete();
    }
    setState(() {});
  }

  bool _canMoveToCell(Offset pos, String color) {
    int x = pos.dx.toInt();
    int y = pos.dy.toInt();

    // Can't move to a cell that's already in our current path (except backtracking)
    if (paths[color]!.contains(pos)) return false;

    // Can move to the target endpoint of the same color
    String? cellColor = grid[y][x];
    if (cellColor == color) return true;

    // Can't move to cells occupied by other color endpoints
    if (cellColor != null && cellColor != color) return false;

    // Can't move to cells occupied by other paths
    for (var entry in paths.entries) {
      if (entry.key == color) continue;
      if (entry.value.contains(pos)) return false;
    }

    return true;
  }

  bool _isValidConnection(String color) {
    final path = paths[color];
    if (path == null || path.length < 2) return false;

    // Check if path connects two dots of the same color
    final start = path.first;
    final end = path.last;

    return grid[start.dy.toInt()][start.dx.toInt()] == color &&
        grid[end.dy.toInt()][end.dx.toInt()] == color &&
        start != end;
  }

  bool _checkComplete() {
    // Check if all colors have valid connections
    for (var color in colors) {
      if (!paths.containsKey(color) || !_isValidConnection(color)) {
        return false;
      }
    }

    // Check for overlapping paths (no cell should be in multiple paths except endpoints)
    Set<Offset> allCells = {};
    for (var entry in paths.entries) {
      for (var cell in entry.value) {
        // Skip endpoints in overlap check
        String? cellColor = grid[cell.dy.toInt()][cell.dx.toInt()];
        if (cellColor != null) continue;

        if (allCells.contains(cell)) {
          return false; // Overlap found
        }
        allCells.add(cell);
      }
    }

    return true;
  }

  void _onPuzzleComplete() {
    if (gameComplete) return;
    gameComplete = true;
    puzzlesSolved++;

    // Check for level up (2 puzzles per level)
    bool shouldLevelUp = false;
    String levelUpMessage = '';
    bool gridSizeChanged = false;

    if (puzzlesSolved >= 2 && level < 7) {
      int oldGridSize = gridSize;
      level++;
      shouldLevelUp = true;
      levelUpMessage = 'Level $level: ${_getLevelDescription()}';
      puzzlesSolved = 0;
      _updateColorsForLevel();

      // Check if grid size changed
      if (oldGridSize != gridSize) {
        gridSizeChanged = true;
      }
    }

    if (shouldLevelUp) {
      _showLevelUpDialog(levelUpMessage, gridSizeChanged);
    } else {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'GREAT JOB! 🎉',
          titleColor: Colors.cyan.shade300,
          mascotImagePath: 'assets/images/mouthfrog.png',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You connected all the colors!',
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
            _buildThemedButton(
              context,
              text: 'Back to Menu',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              color: Colors.brown.shade700,
            ),
          ],
        );
      },
    );
  }

  void _showLevelUpDialog(String message, bool gridSizeChanged) {
    // If grid changed, generate new puzzle immediately before showing dialog
    if (gridSizeChanged) {
      // Clear game state and generate new grid
      gameComplete = false;
      currentColor = null;
      paths.clear();
      _generateSolvablePuzzle();

      // Force UI update
      setState(() {});
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
                'Amazing work!',
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
            ],
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Start Level!',
              onPressed: () {
                Navigator.pop(context);
                if (!gridSizeChanged) {
                  // Only generate new puzzle if grid size didn't change
                  _initializeGame();
                }
                // Grid is already ready to play
              },
              color: Colors.orange.shade700,
            ),
          ],
        );
      },
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

  void _resetProgress() {
    setState(() {
      level = 1;
      puzzlesSolved = 0;
      _updateColorsForLevel();
      _initializeGame();
    });
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
                // Left mascot - moves based on grid size
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
                                gridSize >= 6 ? -1 : (gridSize >= 5 ? 10 : 50),
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
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSize = constraints.maxWidth / gridSize;

                          return Container(
                            padding: EdgeInsets.all(
                              constraints.maxWidth * 0.02,
                            ),
                            child: GameGrid(
                              key: ValueKey(
                                'grid-$gridSize-$level-$puzzlesSolved',
                              ),
                              grid: grid,
                              gridSize: gridSize,
                              cellSize: cellSize,
                              paths: paths,
                              colorMap: colorMap,
                              colors: colors,
                              onCellTouch: _handleCellTouch,
                              onDragEnd: _handleDragEnd,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Right sidebar
                Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem("Level", "$level", Icons.star),
                        const SizedBox(height: 15),
                        _buildStatItem(
                          "Puzzle",
                          "$puzzlesSolved/2",
                          Icons.extension,
                        ),
                        const SizedBox(height: 15),
                        _buildStatItem(
                          "Colors",
                          "${paths.keys.where((color) => _isValidConnection(color)).length}/${colors.length}",
                          Icons.palette,
                        ),
                        const SizedBox(height: 15),
                        _buildStatItem(
                          "Grid",
                          "${gridSize}×$gridSize",
                          Icons.grid_4x4,
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
                            onPressed: _resetProgress,
                            icon: const Icon(Icons.restart_alt),
                            color: Colors.orange.shade700,
                            tooltip: 'Reset Progress',
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

  Widget _buildStatItem(String label, String value, IconData icon) {
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
}

// Separate widget for the game grid with its own gesture handling
class GameGrid extends StatefulWidget {
  final List<List<String?>> grid;
  final int gridSize;
  final double cellSize;
  final Map<String, List<Offset>> paths;
  final Map<String, Color> colorMap;
  final List<String> colors;
  final Function(Offset) onCellTouch;
  final Function() onDragEnd;

  const GameGrid({
    super.key,
    required this.grid,
    required this.gridSize,
    required this.cellSize,
    required this.paths,
    required this.colorMap,
    required this.colors,
    required this.onCellTouch,
    required this.onDragEnd,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  Offset? lastProcessedCell;

  void _handlePointerEvent(Offset localPosition) {
    final x = (localPosition.dx / widget.cellSize).floor();
    final y = (localPosition.dy / widget.cellSize).floor();

    if (x >= 0 && x < widget.gridSize && y >= 0 && y < widget.gridSize) {
      final cellPos = Offset(x.toDouble(), y.toDouble());

      // Only process if we moved to a different cell
      if (lastProcessedCell != cellPos) {
        lastProcessedCell = cellPos;
        widget.onCellTouch(cellPos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        lastProcessedCell = null;
        _handlePointerEvent(event.localPosition);
      },
      onPointerMove: (event) {
        _handlePointerEvent(event.localPosition);
      },
      onPointerUp: (event) {
        lastProcessedCell = null;
        widget.onDragEnd();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Lines layer
            CustomPaint(
              size: Size(
                widget.cellSize * widget.gridSize,
                widget.cellSize * widget.gridSize,
              ),
              painter: PathPainter(
                widget.paths,
                widget.colorMap,
                widget.cellSize,
                widget.colors,
              ),
            ),
            // Dots layer
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.gridSize,
                childAspectRatio: 1,
              ),
              itemCount: widget.gridSize * widget.gridSize,
              itemBuilder: (context, index) {
                int x = index % widget.gridSize;
                int y = index ~/ widget.gridSize;
                String? color = widget.grid[y][x];

                if (color != null && widget.colors.contains(color)) {
                  bool isConnected =
                      widget.paths.containsKey(color) &&
                      (widget.paths[color]!.first ==
                              Offset(x.toDouble(), y.toDouble()) ||
                          widget.paths[color]!.last ==
                              Offset(x.toDouble(), y.toDouble())) &&
                      _isValidConnection(color);

                  return Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.colorMap[color]!.withOpacity(0.9),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      width: widget.cellSize * 0.6,
                      height: widget.cellSize * 0.6,
                      child: isConnected
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: widget.cellSize * 0.35,
                            )
                          : null,
                    ),
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidConnection(String color) {
    final path = widget.paths[color];
    if (path == null || path.length < 2) return false;

    final start = path.first;
    final end = path.last;

    return widget.grid[start.dy.toInt()][start.dx.toInt()] == color &&
        widget.grid[end.dy.toInt()][end.dx.toInt()] == color &&
        start != end;
  }
}

class PathPainter extends CustomPainter {
  final Map<String, List<Offset>> paths;
  final Map<String, Color> colorMap;
  final double cellSize;
  final List<String> colors;

  PathPainter(this.paths, this.colorMap, this.cellSize, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    paths.forEach((color, points) {
      if (points.length > 1 && colors.contains(color)) {
        paint.color = colorMap[color]!.withOpacity(0.8);
        final path = Path();
        path.moveTo(
          points[0].dx * cellSize + cellSize / 2,
          points[0].dy * cellSize + cellSize / 2,
        );
        for (int i = 1; i < points.length; i++) {
          path.lineTo(
            points[i].dx * cellSize + cellSize / 2,
            points[i].dy * cellSize + cellSize / 2,
          );
        }
        canvas.drawPath(path, paint);
      }
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// --- Themed Game Dialog Widget (Matching Card Game Style) ---
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
