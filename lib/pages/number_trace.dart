import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Required for PathMetric
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart';

// --- 1. NUMBER PATH DEFINITIONS (Optimized for Bezier Smoothing) ---
class NumberTraceDefinition {
  final int number;
  final List<List<Offset>> segments; // Segments 0-1000

  NumberTraceDefinition(this.number, this.segments);

  static final Map<int, NumberTraceDefinition> definitions = {
    // 0: Oval - Points define the perimeter
    0: NumberTraceDefinition(0, [
      [
        const Offset(500, 100), // Top Center
        const Offset(200, 100), // Top Left Corner (Control)
        const Offset(200, 500), // Left Middle
        const Offset(200, 900), // Bottom Left Corner (Control)
        const Offset(500, 900), // Bottom Center
        const Offset(800, 900), // Bottom Right Corner (Control)
        const Offset(800, 500), // Right Middle
        const Offset(800, 100), // Top Right Corner (Control)
        const Offset(500, 100), // Close Loop
      ],
    ]),
    // 1: Nose then Vertical
    1: NumberTraceDefinition(1, [
      [
        const Offset(300, 300),
        const Offset(500, 100),
      ], // Stroke 1: Nose (Straight)
      [
        const Offset(500, 100),
        const Offset(500, 900),
      ], // Stroke 2: Vertical (Straight)
    ]),
    // 2: Curve + Diagonal + Base
    2: NumberTraceDefinition(2, [
      [
        const Offset(250, 300), // Start Hook
        const Offset(300, 100), // Top Arch
        const Offset(700, 100), // Top Arch Right
        const Offset(750, 350), // Shoulder
        const Offset(250, 900), // Diagonal Target
      ],
      [const Offset(250, 900), const Offset(800, 900)], // Base (Straight)
    ]),
    // 3: Two stacked curves
    3: NumberTraceDefinition(3, [
      [
        const Offset(280, 220),
        const Offset(750, 200), // Top Arch
        const Offset(550, 480), // Middle In
        const Offset(500, 500), // Center Point
      ],
      [
        const Offset(500, 500),
        const Offset(750, 550), // Bottom Arch Out
        const Offset(750, 850), // Bottom Arch Down
        const Offset(280, 850), // Bottom Hook
      ],
    ]),
    // 4: Open 4 style
    4: NumberTraceDefinition(4, [
      [const Offset(650, 100), const Offset(200, 650)], // Diagonal
      [const Offset(200, 650), const Offset(850, 650)], // Horizontal
      [const Offset(650, 350), const Offset(650, 900)], // Vertical Cross
    ]),
    // 5: Vertical -> Belly -> Top
    5: NumberTraceDefinition(5, [
      [const Offset(280, 180), const Offset(280, 450)], // Vertical Down
      [
        const Offset(280, 450), // Belly Start
        const Offset(750, 450), // Belly Out
        const Offset(750, 880), // Belly Down
        const Offset(300, 880), // Belly Hook
      ],
      [const Offset(280, 180), const Offset(800, 180)], // Top Hat
    ]),
    // 6: C curve -> Loop
    6: NumberTraceDefinition(6, [
      [
        const Offset(650, 100), // Top Start
        const Offset(200, 500), // Back curve
        const Offset(200, 900), // Bottom curve
        const Offset(650, 900), // Bottom Right
        const Offset(650, 550), // Loop Top
        const Offset(200, 600), // Loop Tuck
      ],
    ]),
    // 7: Horizontal -> Diagonal
    7: NumberTraceDefinition(7, [
      [const Offset(200, 100), const Offset(800, 100)],
      [const Offset(800, 100), const Offset(400, 900)],
    ]),
    // 8: S-Curve Snake
    8: NumberTraceDefinition(8, [
      [
        const Offset(500, 100), // Start Top
        const Offset(200, 250), // Top Left
        const Offset(500, 500), // Cross
        const Offset(800, 750), // Bottom Right
        const Offset(500, 900), // Bottom
        const Offset(200, 750), // Bottom Left
        const Offset(500, 500), // Cross
        const Offset(800, 250), // Top Right
        const Offset(500, 100), // Close
      ],
    ]),
    // 9: Circle -> Vertical Tail
    9: NumberTraceDefinition(9, [
      [
        const Offset(750, 400), // Start Side
        const Offset(500, 100), // Top
        const Offset(250, 400), // Left
        const Offset(500, 650), // Bottom
        const Offset(750, 400), // Close
      ],
      [const Offset(750, 400), const Offset(500, 900)], // Tail
    ]),
  };
}

// --- 2. MAIN GAME WIDGET ---
class NumberPathGame extends StatefulWidget {
  const NumberPathGame({super.key});

  @override
  State<NumberPathGame> createState() => _NumberPathGameState();
}

class _NumberPathGameState extends State<NumberPathGame>
    with TickerProviderStateMixin {
  // Game State
  int currentNumber = 0;
  List<Offset> userTracePath = [];
  List<List<Offset>> targetSegments = [];
  int currentSegmentIndex = 0;
  int currentSegmentPointIndex = 0;

  // Validation
  final double validationThreshold = 95.0; // Extremely forgiving
  final double startRadiusNormalized = 180.0; // Huge hit area

  bool isTracing = false;
  bool gameComplete = false;

  // UI State
  int level = 1;
  int puzzlesSolved = 0;
  int _mascotFrame = 0;
  Timer? _mascotTimer;
  late ConfettiController _bgConfettiController;
  late ConfettiController _dialogConfettiController;
  Timer? _gameTimer;
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _bgConfettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _initializeGame();
    _startMascotAnimation();
  }

  @override
  void dispose() {
    _mascotTimer?.cancel();
    _gameTimer?.cancel();
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    super.dispose();
  }

  void _startMascotAnimation() {
    _mascotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _mascotFrame = (_mascotFrame + 1) % 3);
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

  void _updateDifficultyForLevel() {
    currentNumber = (level - 1) % 10;
  }

  void _initializeGame() {
    gameComplete = false;
    userTracePath.clear();
    currentSegmentIndex = 0;
    currentSegmentPointIndex = 0;
    _bgConfettiController.stop();
    _dialogConfettiController.stop();
    _updateDifficultyForLevel();
    _prepareTracingNumber(currentNumber);
    _startTimer();
    if (mounted) setState(() {});
  }

  void _prepareTracingNumber(int number) {
    final definition =
        NumberTraceDefinition.definitions[number] ??
        NumberTraceDefinition.definitions[0]!;
    targetSegments = definition.segments;
    userTracePath.clear();
    currentSegmentIndex = 0;
    currentSegmentPointIndex = 0;
  }

  // --- TOUCH HANDLERS ---

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (gameComplete) return;

    final localPos = details.localPosition;
    final scale = constraints.maxWidth / 1000.0;

    if (targetSegments.isEmpty) return;
    if (currentSegmentIndex >= targetSegments.length) return;

    final startPointNormalized = targetSegments[currentSegmentIndex][0];
    final startPointScaled = Offset(
      startPointNormalized.dx * scale,
      startPointNormalized.dy * scale,
    );

    final distance = (localPos - startPointScaled).distance;

    if (distance < startRadiusNormalized * scale) {
      isTracing = true;
      if (currentSegmentIndex == 0) {
        userTracePath = [localPos];
      } else {
        userTracePath.add(localPos);
      }
      currentSegmentPointIndex = 1;
      HapticFeedback.lightImpact();
      if (mounted) setState(() {});
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!isTracing || gameComplete) return;

    final localPos = details.localPosition;
    userTracePath.add(localPos);

    final scale = constraints.maxWidth / 1000.0;
    final normalizedPos = localPos / scale;

    if (currentSegmentIndex < targetSegments.length) {
      final currentSegment = targetSegments[currentSegmentIndex];

      // For hit testing, we use the raw points, but visually we show curves.
      // Since validationThreshold is high (95.0), this approximation works well for kids.
      if (currentSegmentPointIndex < currentSegment.length) {
        final targetPoint = currentSegment[currentSegmentPointIndex];
        final distance = (normalizedPos - targetPoint).distance;

        if (distance < validationThreshold) {
          currentSegmentPointIndex++;
          // Minimal feedback to keep it smooth
          if (currentSegmentPointIndex % 2 == 0)
            HapticFeedback.selectionClick();

          if (currentSegmentPointIndex >= currentSegment.length) {
            currentSegmentIndex++;
            currentSegmentPointIndex = 0;
            HapticFeedback.mediumImpact();

            if (currentSegmentIndex >= targetSegments.length) {
              _onPuzzleComplete();
            }
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _handlePanEnd(DragEndDetails details, BoxConstraints constraints) {
    isTracing = false;
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _timeRemaining = 30;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0 && !gameComplete)
          _timeRemaining--;
        else if (_timeRemaining == 0 && !gameComplete)
          _onTimeUp();
      });
    });
  }

  void _onPuzzleComplete() {
    if (gameComplete) return;
    gameComplete = true;
    puzzlesSolved++;
    bool levelUp = false;
    String msg = '';

    if (puzzlesSolved >= 1) {
      if (level < 10) {
        level++;
        levelUp = true;
        msg = 'Great job! Moving to Number ${(level - 1) % 10}';
        _updateDifficultyForLevel();
      } else {
        level = 1;
        levelUp = true;
        msg =
            'Excellent! You finished all numbers! Restarting. Want to try again?';
        _updateDifficultyForLevel();
      }
      puzzlesSolved = 0;
    }

    if (levelUp)
      _showLevelUpDialog(msg);
    else
      _showWinDialog();

    setState(() {});
  }

  // --- DIALOGS ---
  void _showWinDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _buildDialog('Awesome!', 'You did it!', 'Next', () {
        Navigator.pop(c);
        _initializeGame();
      }),
    );
  }

  void _showLevelUpDialog(String msg) {
    _bgConfettiController.play();
    _dialogConfettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _buildDialog('Level Up!', msg, 'Start', () {
        Navigator.pop(c);
        _initializeGame();
      }),
    );
  }

  void _onTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _buildDialog('Time Up!', 'Try again?', 'Retry', () {
        Navigator.pop(c);
        _initializeGame();
      }),
    );
  }

  Widget _buildDialog(
    String title,
    String msg,
    String btnText,
    VoidCallback onBtn,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onBtn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: Text(btnText),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _dialogConfettiController,
            blastDirection: -pi / 2,
            emissionFrequency: 0.2,
            numberOfParticles: 10,
            createParticlePath: drawStar,
          ),
        ],
      ),
    );
  }

  Future<void> _onBackButtonPressed() async {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBackButtonPressed();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. BACKGROUND LAYER
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
                      // LEFT MASCOT
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
                                      50,
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
                      // CENTER GAME AREA (BUBBLE NUMBER)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    padding: EdgeInsets.all(
                                      constraints.maxWidth * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: (d) =>
                                          _handlePanStart(d, constraints),
                                      onPanUpdate: (d) =>
                                          _handlePanUpdate(d, constraints),
                                      onPanEnd: (d) =>
                                          _handlePanEnd(d, constraints),
                                      child: CustomPaint(
                                        painter: TracingNumberPainter(
                                          userPath: userTracePath,
                                          targetSegments: targetSegments,
                                          currentSegmentIndex:
                                              currentSegmentIndex,
                                          isComplete: gameComplete,
                                        ),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // RIGHT SIDEBAR
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
                                "Time",
                                "${_timeRemaining}s",
                                Icons.timer,
                              ),
                              const SizedBox(height: 15),
                              _buildStatItem(
                                "Number",
                                "$currentNumber",
                                Icons.looks_one,
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
                                  tooltip: 'New Number',
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

            // 2. CONFETTI OVERLAYS
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
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: 0,
                maxBlastForce: 15,
                emissionFrequency: 0.08,
                numberOfParticles: 20,
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
                createParticlePath: drawStar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    Color valueColor = Colors.green;
    if (label == "Time" && _timeRemaining <= 10) valueColor = Colors.red;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3),
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

// --- 3. CUSTOM PAINTER (BUBBLE STYLE + SMOOTH CURVES) ---
class TracingNumberPainter extends CustomPainter {
  final List<Offset> userPath;
  final List<List<Offset>> targetSegments;
  final int currentSegmentIndex;
  final bool isComplete;

  TracingNumberPainter({
    required this.userPath,
    required this.targetSegments,
    required this.currentSegmentIndex,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1000.0;

    // TRACK STYLE: Huge width, Black Border + White Fill with more rounding
    final double trackWidth = 120.0 * scale;
    final double borderWidth = 10.0 * scale;

    Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = trackWidth + borderWidth;

    Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = trackWidth;

    Paint dashedPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * scale;

    // --- SMOOTH PATH CREATION (Catmull-Rom Spline for rounded curves) ---
    Path createSmoothPath(List<Offset> pts) {
      Path p = Path();
      if (pts.isEmpty) return p;

      // Start
      p.moveTo(pts[0].dx * scale, pts[0].dy * scale);

      // If only 2 points, just straight line
      if (pts.length == 2) {
        p.lineTo(pts[1].dx * scale, pts[1].dy * scale);
        return p;
      }

      // Create smooth curves using quadratic bezier interpolation
      for (int i = 0; i < pts.length - 1; i++) {
        Offset current = pts[i];
        Offset next = pts[i + 1];

        if (i == pts.length - 2) {
          // Last segment - just line to end
          p.lineTo(next.dx * scale, next.dy * scale);
        } else {
          // Create smooth curve using control point
          Offset afterNext = pts[i + 2];

          // Control point is slightly ahead of next point toward afterNext
          double controlX = next.dx * scale;
          double controlY = next.dy * scale;

          // End point is midway to afterNext for smooth connection
          double endX = (next.dx + afterNext.dx) / 2 * scale;
          double endY = (next.dy + afterNext.dy) / 2 * scale;

          p.quadraticBezierTo(controlX, controlY, endX, endY);
        }
      }

      return p;
    }

    // 1. Draw Border (Black)
    for (var seg in targetSegments) {
      canvas.drawPath(createSmoothPath(seg), borderPaint);
    }

    // 2. Draw Fill (White)
    for (var seg in targetSegments) {
      canvas.drawPath(createSmoothPath(seg), fillPaint);
    }

    // 3. Draw Dashed Guide & Arrows
    for (int i = 0; i < targetSegments.length; i++) {
      Path p = createSmoothPath(targetSegments[i]);

      PathMetrics metrics = p.computeMetrics();
      for (PathMetric metric in metrics) {
        double dist = 0;
        while (dist < metric.length) {
          canvas.drawPath(
            metric.extractPath(dist, dist + 15 * scale),
            dashedPaint,
          );
          dist += 30 * scale;
        }

        if (metric.length > 50) {
          Tangent? t = metric.getTangentForOffset(metric.length * 0.5);
          if (t != null) {
            _drawArrowHead(canvas, t.position, t.vector, scale);
          }
        }
      }
    }

    // 4. Draw Start Numbers (1, 2, 3) dots
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < targetSegments.length; i++) {
      if (targetSegments[i].isEmpty) continue;
      Offset start = targetSegments[i][0];
      Offset scaledStart = Offset(start.dx * scale, start.dy * scale);

      bool isActive = (i == currentSegmentIndex);
      Color dotColor = isActive ? Colors.green : Colors.black;

      canvas.drawCircle(scaledStart, 15 * scale, Paint()..color = dotColor);

      tp.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18 * scale,
        ),
      );
      tp.layout();
      tp.paint(canvas, scaledStart - Offset(tp.width / 2, tp.height / 2));
    }

    // 5. Draw User Trace
    Paint userPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = trackWidth * 0.6;

    if (userPath.isNotEmpty) {
      Path uPath = Path();
      uPath.moveTo(userPath[0].dx, userPath[0].dy);
      for (var pt in userPath) uPath.lineTo(pt.dx, pt.dy);
      canvas.drawPath(uPath, userPaint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset pos, Offset dir, double scale) {
    double angle = atan2(dir.dy, dir.dx);
    double wingLen = 15 * scale;

    Offset p1 =
        pos + Offset(cos(angle + 2.5) * wingLen, sin(angle + 2.5) * wingLen);
    Offset p2 =
        pos + Offset(cos(angle - 2.5) * wingLen, sin(angle - 2.5) * wingLen);

    Paint p = Paint()
      ..color = Colors.black
      ..strokeWidth = 3 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawLine(pos, p1, p);
    canvas.drawLine(pos, p2, p);
  }

  @override
  bool shouldRepaint(TracingNumberPainter old) => true;
}
