//puzzle_game
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class PuzzleGame extends StatefulWidget {
  final String imagePath;
  final AudioPlayer bgMusicPlayer; // **ADDED: Accepts the existing player**

  const PuzzleGame({
    super.key,
    required this.imagePath,
    required this.bgMusicPlayer, // **ADDED to constructor**
  });

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> with TickerProviderStateMixin {
  ui.Image? _fullImage;
  List<PuzzlePiece> pieces = [];
  int gridSize = 3;
  bool isLoading = true;
  int piecesPlaced = 0;

  final String backgroundImagePath = 'assets/images/picnic_new.png';

  // --- NEW: Audio & Effects ---
  // REMOVED: late AudioPlayer _bgMusicPlayer; (now accessed via widget.bgMusicPlayer)
  late ConfettiController _bgConfettiController;
  late ConfettiController _dialogConfettiController;

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

    // REMOVED music initialization and play call
    _loadAndSliceImage();
  }

  @override
  void dispose() {
    // IMPORTANT: DO NOT dispose the music player here. It is owned by PuzzleMenu.
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    super.dispose();
  }

  // REMOVED: _playBackgroundMusic method is no longer needed here.
  /*
  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/dots.mp3'));
  }
  */

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

  Future<void> _loadAndSliceImage() async {
    setState(() {
      isLoading = true;
      // Stop confetti when resetting
      _bgConfettiController.stop();
      _dialogConfettiController.stop();
    });

    final ByteData data = await rootBundle.load(widget.imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    _fullImage = frameInfo.image;
    _createPuzzlePieces();

    setState(() {
      isLoading = false;
    });
  }

  void _createPuzzlePieces() {
    pieces.clear();
    piecesPlaced = 0;

    final double pieceWidth = _fullImage!.width / gridSize;
    final double pieceHeight = _fullImage!.height / gridSize;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final int index = row * gridSize + col;
        pieces.add(
          PuzzlePiece(
            id: index,
            correctRow: row,
            correctCol: col,
            currentRow: row,
            currentCol: col,
            sourceRect: Rect.fromLTWH(
              col * pieceWidth,
              row * pieceHeight,
              pieceWidth,
              pieceHeight,
            ),
            isPlaced: false,
          ),
        );
      }
    }

    pieces.shuffle(Random());
  }

  void _checkPiecePlacement(int pieceId, int targetRow, int targetCol) {
    final piece = pieces.firstWhere((p) => p.id == pieceId);

    if (piece.correctRow == targetRow && piece.correctCol == targetCol) {
      setState(() {
        piece.isPlaced = true;
        piece.currentRow = targetRow;
        piece.currentCol = targetCol;
        piecesPlaced++;
      });

      if (piecesPlaced == gridSize * gridSize) {
        _showCompletionDialog();
      }
    }
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

  void _showCompletionDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🧩 Puzzle Solved!',
        'Fantastic! You completed the image.',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAndSliceImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Play Again', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // --- NAVIGATION SAFETY ---
  Future<void> _onBackButtonPressed() async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🚪 Leaving already?',
        'Your current puzzle progress will be lost!',
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

  void _initializeForNewGame() {
    setState(() {
      _loadAndSliceImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with PopScope for navigation safety
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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImagePath),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.28),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              children: [
                                // Left: draggable pieces area
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10.0,
                                        right: 1.0,
                                        top: 3.0,
                                        bottom: 8.0,
                                      ),
                                      child: PuzzlePiecesArea(
                                        image: _fullImage!,
                                        pieces: pieces
                                            .where((piece) => !piece.isPlaced)
                                            .toList(),
                                        gridSize: gridSize,
                                      ),
                                    ),
                                  ),
                                ),

                                // Middle: puzzle board
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double maxSide = min(
                                            constraints.maxWidth,
                                            constraints.maxHeight,
                                          );
                                          final double boardSize =
                                              maxSide * 0.96;
                                          return SizedBox(
                                            width: boardSize,
                                            height: boardSize,
                                            child: PuzzleBoard(
                                              image: _fullImage!,
                                              pieces: pieces,
                                              gridSize: gridSize,
                                              onPiecePlaced:
                                                  _checkPiecePlacement,
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
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: _initializeForNewGame,
                                          icon: const Icon(Icons.refresh),
                                          color: Colors.green.shade700,
                                          tooltip: 'New Puzzle',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: _onBackButtonPressed,
                                          icon: const Icon(
                                            Icons.exit_to_app_rounded,
                                          ),
                                          color: Colors.red.shade700,
                                          tooltip: 'Exit Game',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
              ),
            ),

            // --- CONFETTI OVERLAYS (Unchanged) ---
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
          ],
        ),
      ),
    );
  }
}

// --- UNCHANGED PUZZLE LOGIC CLASSES ---
// (PuzzlePiecesArea, PuzzleBoard, PuzzlePiece, PuzzlePiecePainter, ImagePainter remain the same)

class PuzzlePiecesArea extends StatelessWidget {
  final ui.Image image;
  final List<PuzzlePiece> pieces;
  final int gridSize;

  const PuzzlePiecesArea({
    super.key,
    required this.image,
    required this.pieces,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (gridSize * gridSize > 9) ? 4 : 3;
        final double pieceSize =
            (constraints.maxWidth - (crossAxisCount - 1) * 6) / crossAxisCount;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white70, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: pieces.map((piece) {
                return Draggable<int>(
                  data: piece.id,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.9,
                      child: Container(
                        width: pieceSize,
                        height: pieceSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.yellowAccent,
                            width: 3,
                          ),
                        ),
                        child: CustomPaint(
                          painter: PuzzlePiecePainter(
                            image: image,
                            sourceRect: piece.sourceRect,
                          ),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: pieceSize,
                    height: pieceSize,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: Container(
                    width: pieceSize,
                    height: pieceSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: PuzzlePiecePainter(
                        image: image,
                        sourceRect: piece.sourceRect,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class PuzzleBoard extends StatelessWidget {
  final ui.Image image;
  final List<PuzzlePiece> pieces;
  final int gridSize;
  final Function(int, int, int) onPiecePlaced;

  const PuzzleBoard({
    super.key,
    required this.image,
    required this.pieces,
    required this.gridSize,
    required this.onPiecePlaced,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: Colors.brown.shade200.withOpacity(0.38),
              border: Border.all(color: Colors.brown.shade700, width: 5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: CustomPaint(
                      painter: ImagePainter(image: image),
                      size: Size(boardSize, boardSize),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridSize;
                      final col = index % gridSize;

                      final placedPiece = pieces.firstWhere(
                        (p) =>
                            p.isPlaced &&
                            p.currentRow == row &&
                            p.currentCol == col,
                        orElse: () => PuzzlePiece.empty(),
                      );

                      return DragTarget<int>(
                        onWillAcceptWithDetails: (details) {
                          final pieceToPlace = pieces.firstWhere(
                            (p) => p.id == details.data,
                          );
                          return placedPiece.id == -1 &&
                              pieceToPlace.correctRow == row &&
                              pieceToPlace.correctCol == col;
                        },
                        onAcceptWithDetails: (details) {
                          onPiecePlaced(details.data, row, col);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final bool isCandidate = candidateData.isNotEmpty;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isCandidate
                                    ? Colors.lightGreenAccent
                                    : Colors.black26,
                                width: isCandidate ? 3 : 1,
                              ),
                            ),
                            child: placedPiece.id != -1
                                ? CustomPaint(
                                    painter: PuzzlePiecePainter(
                                      image: image,
                                      sourceRect: placedPiece.sourceRect,
                                    ),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  int currentRow;
  int currentCol;
  final Rect sourceRect;
  bool isPlaced;

  PuzzlePiece({
    required this.id,
    required this.correctRow,
    required this.correctCol,
    required this.currentRow,
    required this.currentCol,
    required this.sourceRect,
    required this.isPlaced,
  });

  factory PuzzlePiece.empty() {
    return PuzzlePiece(
      id: -1,
      correctRow: -1,
      correctCol: -1,
      currentRow: -1,
      currentCol: -1,
      sourceRect: Rect.zero,
      isPlaced: false,
    );
  }
}

class PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;

  PuzzlePiecePainter({required this.image, required this.sourceRect});

  @override
  void paint(Canvas canvas, Size size) {
    final dest = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, sourceRect, dest, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final dest = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dest, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
