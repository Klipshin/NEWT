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
  static const int gridSize = 5;

  late List<List<String?>> grid;
  String? currentColor;
  Map<String, List<Offset>> paths = {};
  int _frogFrame = 0;
  Timer? _mascotTimer;

  late AnimationController _winController;
  bool gameComplete = false;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  // Style variations
  int currentStyle = 0;
  final List<Map<String, Color>> colorStyles = [
    {
      "red": Colors.red,
      "blue": Colors.blue,
      "yellow": Colors.yellow,
      "pink": Colors.pinkAccent,
    },
    {
      "red": Colors.orange,
      "blue": Colors.purple,
      "yellow": Colors.lime,
      "pink": Colors.cyan,
    },
    {
      "red": Color(0xFFFF6B6B),
      "blue": Color(0xFF4ECDC4),
      "yellow": Color(0xFFFFE66D),
      "pink": Color(0xFFA8E6CF),
    },
  ];

  late Map<String, Color> colorMap;
  late List<String> colors;

  @override
  void initState() {
    super.initState();
    colors = ["red", "blue", "yellow", "pink"];
    colorMap = colorStyles[currentStyle];
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
    gameComplete = false;
    currentColor = null;
    paths.clear();

    // Change style on each new game
    currentStyle = (currentStyle + 1) % colorStyles.length;
    colorMap = colorStyles[currentStyle];

    // Generate a solvable puzzle
    _generateSolvablePuzzle();

    setState(() {});
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
  }

  void _generateSolvablePuzzle() {
    // Create empty grid
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));

    // Generate paths first, then place endpoints
    Map<String, List<Offset>> generatedPaths = {};
    Set<Offset> occupiedCells = {};

    final rand = Random();

    for (var color in colors) {
      bool pathCreated = false;
      int attempts = 0;

      while (!pathCreated && attempts < 50) {
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

        // Random walk for 3-8 steps
        int targetLength = 3 + rand.nextInt(6);

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
          generatedPaths[color] = path;
          occupiedCells.addAll(pathSet);

          // Place the endpoints on the grid
          grid[path.first.dy.toInt()][path.first.dx.toInt()] = color;
          grid[path.last.dy.toInt()][path.last.dx.toInt()] = color;

          pathCreated = true;
        }
      }

      // If we couldn't create a path, reset and try again
      if (!pathCreated) {
        _generateSolvablePuzzle();
        return;
      }
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
              _showWinDialog();
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
      _showWinDialog();
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

  void _showWinDialog() {
    if (gameComplete) return;
    gameComplete = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text(
            '🎉 Great job!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You connected all the colors!',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
                // Left mascot
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Image.asset(
                        _frogFrame == 0
                            ? 'assets/images/eyeopenfrog.png'
                            : _frogFrame == 1
                            ? 'assets/images/closefrog.png'
                            : 'assets/images/mouthfrog.png',
                        fit: BoxFit.contain,
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
                              grid: grid,
                              gridSize: gridSize,
                              cellSize: cellSize,
                              paths: paths,
                              colorMap: colorMap,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        "Colors",
                        "${paths.keys.where((color) => _isValidConnection(color)).length}/${colors.length}",
                        Icons.palette,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
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
  final Function(Offset) onCellTouch;
  final Function() onDragEnd;

  const GameGrid({
    super.key,
    required this.grid,
    required this.gridSize,
    required this.cellSize,
    required this.paths,
    required this.colorMap,
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

                if (color != null) {
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

  PathPainter(this.paths, this.colorMap, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    paths.forEach((color, points) {
      if (points.length > 1) {
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
