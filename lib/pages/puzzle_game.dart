import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Helper Widget for Themed Dialog Buttons ---
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

// --- Themed Game Dialog Widget ---
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
                    // Content Area
                    Expanded(child: Center(child: content)),
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

class PuzzleGame extends StatefulWidget {
  final String imagePath;

  const PuzzleGame({super.key, required this.imagePath});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  ui.Image? _fullImage;
  List<PuzzlePiece> pieces = [];
  int gridSize = 3;
  bool isLoading = true;
  int piecesPlaced = 0;

  final String backgroundImagePath = 'assets/images/picnic_new.png';

  @override
  void initState() {
    super.initState();
    _loadAndSliceImage();
  }

  Future<void> _loadAndSliceImage() async {
    setState(() {
      isLoading = true;
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

  // --- UPDATED DIALOG METHOD ---
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ThemedGameDialog(
          title: 'PUZZLE SOLVED! 🧩',
          titleColor: Colors.yellow.shade300,
          mascotImagePath: 'assets/images/mouthfrog.png',
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 25.0),
            child: Text(
              'Fantastic! You completed the image.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 230, 255, 230),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            _buildThemedButton(
              context,
              text: 'Play Again',
              onPressed: () {
                Navigator.of(context).pop();
                _loadAndSliceImage();
              },
              color: Colors.green.shade700,
            ),
            _buildThemedButton(
              context,
              text: 'Back to Menu',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              color: Colors.brown.shade700,
            ),
          ],
        );
      },
    );
  }
  // --- END UPDATED DIALOG METHOD ---

  void _resetPuzzle() {
    _loadAndSliceImage();
  }

  // helper used by right sidebar buttons
  void _initializeForNewGame() {
    setState(() {
      gridSize = gridSize; // keep same grid size
      _loadAndSliceImage();
    });
  }

  void _resetProgress() {
    setState(() {
      gridSize = 3;
      piecesPlaced = 0;
      _loadAndSliceImage();
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    // kept for compatibility though not used in UI now
    Color valueColor = Colors.green;
    if (label == "Time" && value == "--") {
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

  @override
  Widget build(BuildContext context) {
    // Use Scaffold and full background — cleaned top area per request.
    return Scaffold(
      body: Container(
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
                    // Small spacer instead of top bar (keeps top area clean)
                    const SizedBox(height: 8),

                    // Main content - moved slightly up by aligning to top
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

                          // Middle: puzzle board (bigger) - aligned to top to move up
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment:
                                  Alignment.topCenter, // push board slightly up
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Make the puzzle occupy as much space as possible but remain square.
                                    final double maxSide = min(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    );
                                    // slightly bigger ratio so board sits a bit higher
                                    final double boardSize = maxSide * 0.96;
                                    return SizedBox(
                                      width: boardSize,
                                      height: boardSize,
                                      child: PuzzleBoard(
                                        image: _fullImage!,
                                        pieces: pieces,
                                        gridSize: gridSize,
                                        onPiecePlaced: _checkPiecePlacement,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Right sidebar: only keep retry and back (cleaned)
                          Container(
                            width: 90,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
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
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    color: Colors.orange.shade700,
                                    tooltip: 'Back',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // small bottom spacer
                    const SizedBox(height: 8),
                  ],
                ),
        ),
      ),
    );
  }
}

// PuzzlePiecesArea (unchanged except sizing tweaks)
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

// Updated PuzzleBoard — fixed alignment & ghost image
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
    // Outer container already forces width/height via parent SizedBox.
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
                // Ghost image painted exactly into the square board area
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25, // adjust for stronger/softer guide
                    child: CustomPaint(
                      painter: ImagePainter(image: image),
                      size: Size(boardSize, boardSize),
                    ),
                  ),
                ),

                // Grid with ZERO spacing/padding so tiles align perfectly with ghost
                Positioned.fill(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      childAspectRatio: 1.0, // force square cells
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

// Data classes & painters
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
    // Draw the whole image stretched to the square board area.
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
