import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// --- Supporting Classes from Reference (Themed Dialog) ---

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
                  mainAxisSize:
                      MainAxisSize.max, // Ensures the column stretches
                  children: [
                    // Content Area: Wrapped in Expanded to take remaining vertical space
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

            // 3. The Mascot Image (Placeholder image path used)
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

class Animal {
  final String name;
  final String cardPath;

  Animal({required this.name, required this.cardPath});
}

// --- GuessAnimalGame Implementation ---

//animal quiz game - guess the animal name from the image
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

  List<Animal> gameQuestions = []; // The 10 unique animals for this game
  int currentQuestionIndex = 0;

  Animal? currentAnimal;
  List<Animal> currentChoices = [];

  int score = 0;
  bool hasAnswered = false;
  String? selectedName;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

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

  void _initializeGame() {
    setState(() {
      score = 0;
      currentQuestionIndex = 0;
      hasAnswered = false;
      selectedName = null;

      // Select 10 random unique animals for this game
      List<Animal> shuffled = List.from(allAnimals);
      shuffled.shuffle();
      gameQuestions = shuffled.take(totalQuestions).toList();
    });

    _loadQuestion();
  }

  void _loadQuestion() {
    if (currentQuestionIndex >= totalQuestions) {
      _showGameCompleteDialog();
      return;
    }

    setState(() {
      hasAnswered = false;
      selectedName = null;

      // Current animal is from the pre-selected list
      currentAnimal = gameQuestions[currentQuestionIndex];

      // Build choices: correct answer + 2 random wrong answers
      currentChoices = [currentAnimal!];

      List<Animal> others = allAnimals
          .where((a) => a.name != currentAnimal!.name)
          .toList();
      others.shuffle();

      final toTake = min(choicesCount - 1, others.length);
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
    if (correct) score++;

    // Move to next question after delay
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          currentQuestionIndex++;
        });
        _loadQuestion();
      }
    });
  }

  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isPerfect = score == totalQuestions;
        String title = isPerfect ? 'PERFECT! 🏆' : 'QUIZ COMPLETE! ✅';
        Color titleColor = isPerfect
            ? Colors.yellow.shade300
            : Colors.cyan.shade300;

        return ThemedGameDialog(
          title: title,
          titleColor: titleColor,
          mascotImagePath: isPerfect
              ? 'assets/images/mouthfrog.png'
              : 'assets/images/eyeopenfrog.png',

          // --- FIX: CONTENT IS NOW THE SCORE TEXT ---
          content: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 40.0,
            ), // Increased padding for height
            child: Text(
              '$score / $totalQuestions',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: isPerfect
                    ? Colors.amber.shade200
                    : Colors.lightGreen.shade200,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // --- END FIXED CONTENT ---
          actions: [
            _buildThemedButton(
              context,
              text: 'Play Again',
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/picnic_new.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromARGB(255, 112, 155, 131).withOpacity(0.4),
          child: SafeArea(
            child: currentAnimal == null || currentChoices.length < choicesCount
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
                                      color: Colors.black.withOpacity(0.8),
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
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Choose the correct answer:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ...currentChoices
                                  .map((a) => _choiceCard(a))
                                  .toList(),
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
}
