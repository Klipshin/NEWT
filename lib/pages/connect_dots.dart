import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

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
  bool _showDCardOverlay = true;

  late List<List<String?>> grid;
  String? currentColor;
  Map<String, List<Offset>> paths = {};
  int _frogFrame = 0;
  Timer? _mascotTimer;

  // --- Audio & Effects ---
  late AudioPlayer _bgMusicPlayer;
  late ConfettiController _bgConfettiController;
  late ConfettiController _dialogConfettiController;

  // --- ADDED: Bigger Confetti Settings ---
  final Size confettiMinSize = const Size(20, 20);
  final Size confettiMaxSize = const Size(35, 35);

  bool gameComplete = false;

  // Extended color styles
  int currentStyle = 0;
  final List<Map<String, Color>> colorStyles = [
    {
      "red": const Color(0xFFFF5252),
      "blue": const Color(0xFF448AFF),
      "yellow": const Color(0xFFFFD740),
      "pink": const Color(0xFFFF4081),
      "green": const Color(0xFF69F0AE),
      "orange": const Color(0xFFFFAB40),
    },
    {
      "red": Colors.deepOrange,
      "blue": Colors.indigoAccent,
      "yellow": Colors.limeAccent,
      "pink": Colors.purpleAccent,
      "green": Colors.tealAccent,
      "orange": Colors.amber,
    },
  ];

  late Map<String, Color> colorMap;
  late List<String> colors;

  @override
  void initState() {
    super.initState();

    _bgConfettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _bgMusicPlayer = AudioPlayer();
    _playBackgroundMusic();

    colorMap = colorStyles[currentStyle];
    _updateColorsForLevel();
    _initializeGame();
    _startMascotAnimation();
  }

  @override
  void dispose() {
    _mascotTimer?.cancel();
    _bgMusicPlayer.dispose();
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
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

  void _updateColorsForLevel() {
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
    } else {
      gridSize = 6;
      colors = ["red", "blue", "yellow", "pink", "green", "orange"];
    }
  }

  String _getLevelDescription() {
    return "${gridSize}x$gridSize Grid - ${colors.length} Colors";
  }

  void _initializeGame() {
    gameComplete = false;
    currentColor = null;
    paths.clear();

    _bgConfettiController.stop();
    _dialogConfettiController.stop();

    currentStyle = (currentStyle + 1) % colorStyles.length;
    colorMap = colorStyles[currentStyle];

    _generateSolvablePuzzle();

    if (mounted) {
      setState(() {});
    }
  }

  void _generateSolvablePuzzle({int recursionDepth = 0}) {
    if (recursionDepth > 10) {
      _generateSimplePuzzle();
      return;
    }

    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    Set<Offset> occupiedCells = {};
    final rand = Random();
    List<String> shuffledColors = List.from(colors)..shuffle();

    for (var color in shuffledColors) {
      bool pathCreated = false;
      int attempts = 0;

      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (grid[y][x] == color) {
            _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
            return;
          }
        }
      }

      while (!pathCreated && attempts < 100) {
        attempts++;
        int startX = rand.nextInt(gridSize);
        int startY = rand.nextInt(gridSize);
        Offset start = Offset(startX.toDouble(), startY.toDouble());

        if (occupiedCells.contains(start)) continue;

        List<Offset> path = [start];
        Set<Offset> pathSet = {start};
        Offset current = start;

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
          Offset next = possibleMoves[rand.nextInt(possibleMoves.length)];
          path.add(next);
          pathSet.add(next);
          current = next;
        }

        if (path.length >= 2) {
          occupiedCells.addAll(pathSet);
          int startYPos = path.first.dy.toInt();
          int startXPos = path.first.dx.toInt();
          int endYPos = path.last.dy.toInt();
          int endXPos = path.last.dx.toInt();

          if (grid[startYPos][startXPos] == null &&
              grid[endYPos][endXPos] == null) {
            grid[startYPos][startXPos] = color;
            grid[endYPos][endXPos] = color;
            pathCreated = true;
          }
        }
      }

      if (!pathCreated) {
        _generateSolvablePuzzle(recursionDepth: recursionDepth + 1);
        return;
      }
    }
  }

  void _generateSimplePuzzle() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    final rand = Random();

    for (var color in colors) {
      int x1, y1, x2, y2;
      do {
        x1 = rand.nextInt(gridSize);
        y1 = rand.nextInt(gridSize);
      } while (grid[y1][x1] != null);
      grid[y1][x1] = color;

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
      Offset(0, -1),
      Offset(0, 1),
      Offset(-1, 0),
      Offset(1, 0),
    ];

    for (var dir in directions) {
      Offset next = Offset(current.dx + dir.dx, current.dy + dir.dy);
      if (next.dx < 0 ||
          next.dx >= gridSize ||
          next.dy < 0 ||
          next.dy >= gridSize) {
        continue;
      }
      if (currentPath.contains(next)) continue;
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
      if (grid[y][x] != null) {
        currentColor = grid[y][x];
        paths[currentColor!] = [cellPos];
        setState(() {});
      }
    } else {
      final currentPath = paths[currentColor!]!;
      final last = currentPath.last;
      bool isAdjacent =
          (cellPos.dx - last.dx).abs() + (cellPos.dy - last.dy).abs() == 1;

      if (!isAdjacent) return;

      bool isBacktracking =
          currentPath.length > 1 &&
          currentPath[currentPath.length - 2] == cellPos;

      if (isBacktracking) {
        currentPath.removeLast();
        setState(() {});
      } else {
        bool canMoveTo = _canMoveToCell(cellPos, currentColor!);
        if (canMoveTo) {
          currentPath.add(cellPos);
          if (grid[y][x] == currentColor && cellPos != currentPath.first) {
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

    if (!_isValidConnection(currentColor!)) {
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

    if (paths[color]!.contains(pos)) return false;
    String? cellColor = grid[y][x];
    if (cellColor == color) return true;
    if (cellColor != null && cellColor != color) return false;

    for (var entry in paths.entries) {
      if (entry.key == color) continue;
      if (entry.value.contains(pos)) return false;
    }
    return true;
  }

  bool _isValidConnection(String color) {
    final path = paths[color];
    if (path == null || path.length < 2) return false;
    final start = path.first;
    final end = path.last;
    return grid[start.dy.toInt()][start.dx.toInt()] == color &&
        grid[end.dy.toInt()][end.dx.toInt()] == color &&
        start != end;
  }

  bool _checkComplete() {
    for (var color in colors) {
      if (!paths.containsKey(color) || !_isValidConnection(color)) {
        return false;
      }
    }
    return true;
  }

  void _onPuzzleComplete() {
    if (gameComplete) return;
    gameComplete = true;
    puzzlesSolved++;

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

  // --- SHARED DIALOG BUILDER ---
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
            // --- Bigger Confetti ---
            minimumSize: confettiMinSize,
            maximumSize: confettiMaxSize,
            colors: const [Colors.yellow, Colors.lightGreen, Colors.lightBlue],
            createParticlePath: drawStar,
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    // --- MODIFIED: Dynamic Label ---
    String statusMsg = level >= 7
        ? 'Endless Score: $puzzlesSolved'
        : 'Puzzle $puzzlesSolved/2';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🎉 Excellent!',
        'You connected all dots! $statusMsg',
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

  Future<void> _onBackButtonPressed() async {
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
                      // Left mascot
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
                                      gridSize >= 6
                                          ? -1
                                          : (gridSize >= 5 ? 10 : 50),
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

                      // --- MODIFIED: Grid Alignment Fix ---
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // 1. Account for padding in math
                                final double paddingValue =
                                    constraints.maxWidth * 0.02;
                                // 2. Account for border width (2px * 2)
                                final double borderWidth = 4.0;
                                // 3. Calculate actual available width for dots
                                final double availableWidth =
                                    constraints.maxWidth -
                                    (paddingValue * 2) -
                                    borderWidth;
                                final cellSize = availableWidth / gridSize;

                                return Container(
                                  padding: EdgeInsets.all(paddingValue),
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

                              // --- MODIFIED: Endless Score Logic ---
                              _buildStatItem(
                                level >= 7 ? "Score" : "Puzzle",
                                level >= 7
                                    ? "$puzzlesSolved"
                                    : "$puzzlesSolved/2",
                                level >= 7
                                    ? Icons.emoji_events
                                    : Icons.extension,
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
                    ],
                  ),
                ),
              ),
            ),

            // --- CONFETTI OVERLAYS (Bigger sizes applied) ---
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: pi / 2,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.08,
                numberOfParticles: 30,
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
                colors: const [Colors.pinkAccent, Colors.deepOrange],
                createParticlePath: drawStar,
              ),
            ),
            // DDots Overlay - stuck to bottom
            if (_showDCardOverlay)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDCardOverlay = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/ddots.png',
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
      if (lastProcessedCell != cellPos) {
        lastProcessedCell = cellPos;
        widget.onCellTouch(cellPos);
      }
    }
  }

  Widget _buildDot(String colorName, bool isConnected) {
    Color baseColor = widget.colorMap[colorName]!;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.cellSize * 0.7,
        height: widget.cellSize * 0.7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [baseColor.withOpacity(0.7), baseColor],
            center: const Alignment(-0.3, -0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isConnected ? baseColor.withOpacity(0.8) : Colors.black26,
              blurRadius: isConnected ? 12 : 4,
              spreadRadius: isConnected ? 2 : 0,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white, width: isConnected ? 3 : 1.5),
        ),
        child: isConnected
            ? Icon(
                Icons.check_rounded,
                color: Colors.white.withOpacity(0.9),
                size: widget.cellSize * 0.4,
              )
            : null,
      ),
    );
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Grid Lines
            CustomPaint(
              size: Size(
                widget.cellSize * widget.gridSize,
                widget.cellSize * widget.gridSize,
              ),
              painter: GridLinesPainter(widget.gridSize, widget.cellSize),
            ),

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
              // --- MODIFIED: Ensure dots align perfectly with grid ---
              padding: EdgeInsets.zero,
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
                  bool isConnected = false;
                  if (widget.paths.containsKey(color)) {
                    final path = widget.paths[color]!;
                    final dotPos = Offset(x.toDouble(), y.toDouble());
                    isConnected =
                        (path.first == dotPos || path.last == dotPos) &&
                        _isValidConnection(color, path);
                  }

                  return _buildDot(color, isConnected);
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidConnection(String color, List<Offset> path) {
    if (path.length < 2) return false;
    final start = path.first;
    final end = path.last;
    return widget.grid[start.dy.toInt()][start.dx.toInt()] == color &&
        widget.grid[end.dy.toInt()][end.dx.toInt()] == color &&
        start != end;
  }
}

class GridLinesPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  GridLinesPainter(this.gridSize, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 1; i < gridSize; i++) {
      // Vertical
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
      // Horizontal
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..strokeWidth = cellSize * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.3);

    final shadowPaint = Paint()
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    paths.forEach((color, points) {
      if (points.length > 1 && colors.contains(color)) {
        final baseColor = colorMap[color]!;

        paint.color = baseColor.withOpacity(0.8);
        shadowPaint.color = baseColor.withOpacity(0.4);

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

        canvas.drawPath(path, shadowPaint);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, highlightPaint);
      }
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
