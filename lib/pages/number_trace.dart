import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

class NumberPathGame extends StatefulWidget {
  const NumberPathGame({super.key});

  @override
  State<NumberPathGame> createState() => _NumberPathGameState();
}

class _NumberPathGameState extends State<NumberPathGame>
    with TickerProviderStateMixin {
  int gridSize = 3; // Start with 3x3
  int level = 1;
  int puzzlesSolved = 0;

  late List<List<int?>> grid;
  List<Offset> currentPath = [];
  Offset? startPos;
  Offset? endPos;
  bool gameComplete = false;

  int _mascotFrame = 0;
  Timer? _mascotTimer;

  late AnimationController _winController;
  late AudioPlayer _bgMusicPlayer;
  bool _isMuted = false;

  // Number range for each level
  int maxNumber = 5;

  // Timer variables
  Timer? _gameTimer;
  int _timeRemaining = 30;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
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
    _gameTimer?.cancel();
    _winController.dispose();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  void _startMascotAnimation() {
    _mascotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _mascotFrame = (_mascotFrame + 1) % 3;
        });
      }
    });
  }

  void _updateDifficultyForLevel() {
    if (level == 1) {
      gridSize = 3;
      maxNumber = 5;
    } else if (level == 2) {
      gridSize = 3;
      maxNumber = 9;
    } else if (level == 3) {
      gridSize = 4;
      maxNumber = 9;
    } else if (level == 4) {
      gridSize = 4;
      maxNumber = 12;
    } else if (level == 5) {
      gridSize = 4;
      maxNumber = 15;
    } else {
      gridSize = 4;
      maxNumber = 20;
    }
  }

  String _getLevelDescription() {
    switch (level) {
      case 1:
        return "3×3 Grid - Numbers 1-5";
      case 2:
        return "3×3 Grid - Numbers 1-9";
      case 3:
        return "4×4 Grid - Numbers 1-9";
      case 4:
        return "4×4 Grid - Numbers 1-12";
      case 5:
        return "4×4 Grid - Numbers 1-15";
      default:
        return "4×4 Grid - Numbers 1-20";
    }
  }

  void _initializeGame() {
    gameComplete = false;
    currentPath.clear();
    _updateDifficultyForLevel();
    _generatePuzzle();
    _startTimer();

    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _timeRemaining = 30;
    _isTimerRunning = true;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeRemaining > 0 && !gameComplete) {
          _timeRemaining--;
        } else if (_timeRemaining == 0 && !gameComplete) {
          _onTimeUp();
        }
      });
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    _isTimerRunning = false;
  }

  void _onTimeUp() {
    _stopTimer();
    gameComplete = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.orange[50],
          title: const Text(
            '⏰ Time\'s Up!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Try again!',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Try Again'),
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

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
  }

  void _generatePuzzle() {
    final rand = Random();

    // Simplified puzzle generation - much faster!
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));

    // Place START at random position
    int startX = rand.nextInt(gridSize);
    int startY = rand.nextInt(gridSize);
    startPos = Offset(startX.toDouble(), startY.toDouble());

    // Place END at opposite corner or far away
    int endX = gridSize - 1 - startX;
    int endY = gridSize - 1 - startY;
    endPos = Offset(endX.toDouble(), endY.toDouble());

    // Create a simple guaranteed solvable path
    List<Offset> solutionPath = _createSimplePath(startPos!, endPos!);

    // Assign ascending numbers to the path
    for (int i = 0; i < solutionPath.length; i++) {
      Offset pos = solutionPath[i];
      grid[pos.dy.toInt()][pos.dx.toInt()] = i + 1;
    }

    // Fill remaining cells with random numbers
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] == null) {
          // Random number that could be part of alternate paths
          grid[y][x] = 1 + rand.nextInt(maxNumber);
        }
      }
    }
  }

  List<Offset> _createSimplePath(Offset start, Offset end) {
    List<Offset> path = [start];
    Offset current = start;

    // Move horizontally first
    while (current.dx != end.dx) {
      if (current.dx < end.dx) {
        current = Offset(current.dx + 1, current.dy);
      } else {
        current = Offset(current.dx - 1, current.dy);
      }
      path.add(current);
    }

    // Then move vertically
    while (current.dy != end.dy) {
      if (current.dy < end.dy) {
        current = Offset(current.dx, current.dy + 1);
      } else {
        current = Offset(current.dx, current.dy - 1);
      }
      path.add(current);
    }

    return path;
  }

  void _handleCellTouch(Offset cellPos) {
    if (gameComplete) return;

    int x = cellPos.dx.toInt();
    int y = cellPos.dy.toInt();

    // Starting a new path
    if (currentPath.isEmpty) {
      if (cellPos == startPos) {
        currentPath.add(cellPos);
        setState(() {});
      }
      return;
    }

    // Check if this is the same cell (ignore)
    if (currentPath.last == cellPos) return;

    // Check if move is adjacent
    final last = currentPath.last;
    bool isAdjacent =
        (cellPos.dx - last.dx).abs() + (cellPos.dy - last.dy).abs() == 1;

    if (!isAdjacent) return;

    // Check if backtracking
    if (currentPath.length > 1 &&
        currentPath[currentPath.length - 2] == cellPos) {
      currentPath.removeLast();
      setState(() {});
      return;
    }

    // Check if we can move to this cell
    if (_canMoveToCell(cellPos)) {
      currentPath.add(cellPos);

      // Check if we reached the end
      if (cellPos == endPos) {
        _onPuzzleComplete();
      }

      setState(() {});
    }
  }

  void _handleDragEnd() {
    if (gameComplete) return;

    // If path doesn't reach the end, clear it
    if (currentPath.isEmpty || currentPath.last != endPos) {
      currentPath.clear();
      setState(() {});
    }
  }

  bool _canMoveToCell(Offset pos) {
    int x = pos.dx.toInt();
    int y = pos.dy.toInt();

    // Can't move to a cell already in path (except backtracking)
    if (currentPath.contains(pos)) return false;

    // Get current cell value
    int? currentValue =
        grid[currentPath.last.dy.toInt()][currentPath.last.dx.toInt()];
    int? nextValue = grid[y][x];

    if (currentValue == null || nextValue == null) return false;

    // Can always move to the END position
    if (pos == endPos) return true;

    // Must move to equal or greater number (ascending rule)
    return nextValue >= currentValue;
  }

  void _onPuzzleComplete() {
    if (gameComplete) return;
    gameComplete = true;
    puzzlesSolved++;

    bool shouldLevelUp = false;
    String levelUpMessage = '';

    if (puzzlesSolved >= 2 && level < 6) {
      int oldGridSize = gridSize;
      level++;
      shouldLevelUp = true;
      levelUpMessage = 'Level $level: ${_getLevelDescription()}';
      puzzlesSolved = 0;
      _updateDifficultyForLevel();

      if (oldGridSize != gridSize) {
        _showLevelUpDialog(levelUpMessage);
        return;
      }
    }

    if (shouldLevelUp) {
      _showLevelUpDialog(levelUpMessage);
    } else {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: const Text(
            '🎉 Excellent!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You found the path!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                'Level $level - Puzzle $puzzlesSolved/2',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Next Puzzle'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Amazing work!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGame();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _resetProgress() {
    setState(() {
      level = 1;
      puzzlesSolved = 0;
      _updateDifficultyForLevel();
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
                                gridSize >= 6 ? -1 : (gridSize >= 5 ? 10 : 50),
                                20,
                                0,
                              ),
                              child: Image.asset(
                                _mascotFrame == 0
                                    ? 'assets/images/eyeopenfrog.png'
                                    : _mascotFrame == 1
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
                            child: NumberGameGrid(
                              key: ValueKey(
                                'grid-$gridSize-$level-$puzzlesSolved',
                              ),
                              grid: grid,
                              gridSize: gridSize,
                              cellSize: cellSize,
                              currentPath: currentPath,
                              startPos: startPos!,
                              endPos: endPos!,
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
                          "Steps",
                          "${currentPath.length}",
                          Icons.timeline,
                        ),
                        const SizedBox(height: 15),
                        _buildStatItem(
                          "Time",
                          "${_timeRemaining}s",
                          Icons.timer,
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
    // Special styling for timer when low
    Color valueColor = Colors.green;
    if (label == "Time" && _timeRemaining <= 10) {
      valueColor = Colors.red;
    } else if (label == "Time" && _timeRemaining <= 20) {
      valueColor = Colors.orange;
    }

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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NumberGameGrid extends StatefulWidget {
  final List<List<int?>> grid;
  final int gridSize;
  final double cellSize;
  final List<Offset> currentPath;
  final Offset startPos;
  final Offset endPos;
  final Function(Offset) onCellTouch;
  final Function() onDragEnd;

  const NumberGameGrid({
    super.key,
    required this.grid,
    required this.gridSize,
    required this.cellSize,
    required this.currentPath,
    required this.startPos,
    required this.endPos,
    required this.onCellTouch,
    required this.onDragEnd,
  });

  @override
  State<NumberGameGrid> createState() => _NumberGameGridState();
}

class _NumberGameGridState extends State<NumberGameGrid> {
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
            // Path line layer
            if (widget.currentPath.length > 1)
              CustomPaint(
                size: Size(
                  widget.cellSize * widget.gridSize,
                  widget.cellSize * widget.gridSize,
                ),
                painter: NumberPathPainter(widget.currentPath, widget.cellSize),
              ),
            // Grid cells
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
                Offset cellPos = Offset(x.toDouble(), y.toDouble());
                int? value = widget.grid[y][x];

                bool isInPath = widget.currentPath.contains(cellPos);
                bool isStart = cellPos == widget.startPos;
                bool isEnd = cellPos == widget.endPos;

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isInPath
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isStart
                          ? Colors.green
                          : isEnd
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: isStart || isEnd ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isInPath)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                    ],
                  ),
                  child: Center(
                    child: isStart
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.green.shade700,
                                size: widget.cellSize * 0.4,
                              ),
                              Text(
                                'START',
                                style: TextStyle(
                                  fontSize: widget.cellSize * 0.12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          )
                        : isEnd
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag,
                                color: Colors.red.shade700,
                                size: widget.cellSize * 0.4,
                              ),
                              Text(
                                'END',
                                style: TextStyle(
                                  fontSize: widget.cellSize * 0.12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '$value',
                            style: TextStyle(
                              fontSize: widget.cellSize * 0.35,
                              fontWeight: FontWeight.bold,
                              color: isInPath
                                  ? Colors.blue.shade800
                                  : Colors.black87,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NumberPathPainter extends CustomPainter {
  final List<Offset> path;
  final double cellSize;

  NumberPathPainter(this.path, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathToDraw = Path();
    pathToDraw.moveTo(
      path[0].dx * cellSize + cellSize / 2,
      path[0].dy * cellSize + cellSize / 2,
    );

    for (int i = 1; i < path.length; i++) {
      pathToDraw.lineTo(
        path[i].dx * cellSize + cellSize / 2,
        path[i].dy * cellSize + cellSize / 2,
      );
    }

    canvas.drawPath(pathToDraw, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Transition Video Player Widget
class TransitionVideoPlayer extends StatefulWidget {
  final VoidCallback onComplete;

  const TransitionVideoPlayer({super.key, required this.onComplete});

  @override
  State<TransitionVideoPlayer> createState() => _TransitionVideoPlayerState();
}

class _TransitionVideoPlayerState extends State<TransitionVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    print('Initializing transition video...');

    _controller =
        VideoPlayerController.asset('assets/videos/test_transition.mp4')
          ..setLooping(false)
          ..initialize()
              .then((_) {
                if (mounted) {
                  print('Video initialized successfully');
                  setState(() {
                    _isInitialized = true;
                  });
                  _controller.play();
                }
              })
              .catchError((error) {
                print('Error initializing video: $error');
                // If video fails to load, just continue to next level
                if (!_hasCompleted) {
                  _hasCompleted = true;
                  widget.onComplete();
                }
              });

    _controller.addListener(_checkVideoProgress);
  }

  void _checkVideoProgress() {
    if (!mounted || _hasCompleted) return;

    // Check if video has finished playing
    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration) {
      print('Video completed');
      _hasCompleted = true;
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Loading transition...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }
}
