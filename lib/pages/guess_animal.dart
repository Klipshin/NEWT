import 'dart:async';
import 'dart:math' as math; // Alias math to avoid conflicts
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

// Simple data class for the quiz
class Animal {
  final String name;
  final String cardPath;
  Animal({required this.name, required this.cardPath});
}

class GuessAnimalGame extends StatefulWidget {
  const GuessAnimalGame({super.key});

  @override
  State<GuessAnimalGame> createState() => _GuessAnimalGameState();
}

class _GuessAnimalGameState extends State<GuessAnimalGame> {
  final List<Animal> allAnimals = [
    Animal(name: 'cat', cardPath: 'assets/images/cat_card.png'),
    Animal(name: 'cow', cardPath: 'assets/images/cow_card.png'),
    Animal(name: 'dog', cardPath: 'assets/images/dog_card.png'),
    Animal(name: 'rooster', cardPath: 'assets/images/rooster_card.png'),
    Animal(name: 'duck', cardPath: 'assets/images/duck_card.png'),
    Animal(name: 'lion', cardPath: 'assets/images/lion_card.png'),
    Animal(name: 'horse', cardPath: 'assets/images/horse_card.png'),
    Animal(name: 'sheep', cardPath: 'assets/images/sheep_card.png'),
    Animal(name: 'pig', cardPath: 'assets/images/pig_card.png'),
    Animal(name: 'owl', cardPath: 'assets/images/owl_card.png'),
    Animal(name: 'elephant', cardPath: 'assets/images/elephant_card.png'),
    Animal(name: 'crow', cardPath: 'assets/images/crow_card.png'),
    Animal(name: 'monkey', cardPath: 'assets/images/monkey_card.png'),
  ];

  static const int choicesCount = 3;
  static const int totalQuestions = 10;

  List<Animal> gameQuestions = [];
  int currentQuestionIndex = 0;
  Animal? currentAnimal;
  List<Animal> currentChoices = [];
  int score = 0;
  bool hasAnswered = false;
  String? selectedName;

  // Audio and Effects
  late AudioPlayer _bgMusicPlayer;
  late ConfettiController _bgConfettiController; // Background celebrations
  late ConfettiController _dialogConfettiController; // Popups celebrations

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

    _initializeGame();
  }

  @override
  void dispose() {
    _bgMusicPlayer.dispose();
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/card.mp3'));
  }

  Path drawStar(Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;
    double outerRadius = size.width / 2;
    double innerRadius = size.width / 5;

    Path path = Path();
    double rot = math.pi / 2 * 3;
    double step = math.pi / 5;

    path.moveTo(cx, cy - outerRadius);
    for (int i = 0; i < 5; i++) {
      double x = cx + math.cos(rot) * outerRadius;
      double y = cy + math.sin(rot) * outerRadius;
      path.lineTo(x, y);
      rot += step;

      x = cx + math.cos(rot) * innerRadius;
      y = cy + math.sin(rot) * innerRadius;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    return path;
  }

  void _initializeGame() {
    setState(() {
      score = 0;
      currentQuestionIndex = 0;
      hasAnswered = false;
      selectedName = null;
      _bgConfettiController.stop();
      _dialogConfettiController.stop();

      List<Animal> shuffled = List.from(allAnimals);
      shuffled.shuffle();
      gameQuestions = shuffled.take(totalQuestions).toList();
    });
    _loadQuestion();
  }

  void _loadQuestion() {
    // NOTE: The Game Over check has been moved to _select
    // to prevent the UI from rendering "11/10" briefly.

    setState(() {
      hasAnswered = false;
      selectedName = null;
      currentAnimal = gameQuestions[currentQuestionIndex];
      currentChoices = [currentAnimal!];

      List<Animal> others = allAnimals
          .where((a) => a.name != currentAnimal!.name)
          .toList();
      others.shuffle();

      final toTake = math.min(choicesCount - 1, others.length);
      currentChoices.addAll(others.take(toTake));
      currentChoices.shuffle();
    });
  }

  void _select(String name) {
    if (hasAnswered) return;

    setState(() {
      hasAnswered = true;
      selectedName = name;
    });

    final correct = name == currentAnimal!.name;
    if (correct) {
      score++;
    }

    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        // --- FIXED LOGIC HERE ---
        // Check if we just answered the last question (index 9 if total is 10)
        if (currentQuestionIndex >= totalQuestions - 1) {
          // Do NOT increment index. Just show results.
          _showGameCompleteDialog();
        } else {
          // Move to next question
          setState(() {
            currentQuestionIndex++;
          });
          _loadQuestion();
        }
      }
    });
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
          // Confetti for the dialog itself
          ConfettiWidget(
            confettiController: _dialogConfettiController,
            blastDirection: math.pi / 2, // Downwards
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

  // --- POPUPS USING THE SHARED BUILDER ---

  Future<void> _onBackButtonPressed() async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🚪 Leaving already?',
        'Your current quiz progress will be lost!',
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
            child: const Text('Exit Quiz', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showGameCompleteDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        bool isPerfect = score == totalQuestions;
        String title = isPerfect ? '🏆 Perfect Score!' : '🎉 Quiz Complete!';
        String msg = isPerfect
            ? 'Amazing! You got $score/$totalQuestions correct.'
            : 'Great job! You scored $score/$totalQuestions.';

        return _buildDialogContent(title, msg, [
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
              _initializeGame();
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
        ]);
      },
    );
  }

  // --- WIDGET BUILDING ---

  Widget _choiceCard(Animal a) {
    final bool isSelected = selectedName == a.name;
    final bool isCorrect = a.name == currentAnimal?.name;
    Color? backgroundColor;
    Color? borderColor;

    if (hasAnswered && isSelected) {
      backgroundColor = isCorrect
          ? Colors.green.withOpacity(0.2)
          : Colors.red.withOpacity(0.2);
      borderColor = isCorrect ? Colors.green : Colors.red;
    } else if (hasAnswered && isCorrect) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: () => _select(a.name),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: hasAnswered && (isSelected || isCorrect) ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                a.name[0].toUpperCase() + a.name.substring(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasAnswered && (isSelected || isCorrect)
                      ? (isCorrect
                            ? Colors.green.shade700
                            : Colors.red.shade700)
                      : Colors.black87,
                ),
              ),
            ),
            if (hasAnswered && (isSelected || isCorrect))
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 28,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideStatItem(String label, String value, IconData icon) {
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
        mainAxisSize: MainAxisSize.min,
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
            // Background & Game Content
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/picnic_new.png"),
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
                  child:
                      currentAnimal == null ||
                          currentChoices.length < choicesCount
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            // Left: Animal card image
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'What animal is this?',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.8,
                                            ),
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Image.asset(
                                              currentAnimal!.cardPath,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Center: Text choices
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 20.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Choose the correct answer:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.8,
                                            ),
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ...currentChoices.map(
                                      (a) => _choiceCard(a),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right sidebar with stats
                            Container(
                              width: 90,
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSideStatItem(
                                      'Score',
                                      '$score/$totalQuestions',
                                      Icons.star,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSideStatItem(
                                      'Question',
                                      // Display 1-based index
                                      '${currentQuestionIndex + 1}/$totalQuestions',
                                      Icons.quiz,
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
                                        tooltip: 'Reset Game',
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
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // --- CONFETTI OVERLAY (Background) ---
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                blastDirection: math.pi / 2,
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
                blastDirection: math.pi / 3,
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
                blastDirection: 2 * math.pi / 3,
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
                blastDirection: math.pi,
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
                blastDirection: -math.pi / 4,
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
                blastDirection: -3 * math.pi / 4,
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
