import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

//animal quiz game - guess the animal name from the image
class GuessAnimalGame extends StatefulWidget {
  const GuessAnimalGame({super.key});

  @override
  State<GuessAnimalGame> createState() => _GuessAnimalGameState();
}

class _GuessAnimalGameState extends State<GuessAnimalGame> {
  final List<Animal> allAnimals = [
    Animal(name: 'cat', cardPath: 'assets/images/cat_card2.png'),
    Animal(name: 'cow', cardPath: 'assets/images/cow_card2.png'),
    Animal(name: 'dog', cardPath: 'assets/images/dog_card2.png'),
    Animal(name: 'rooster', cardPath: 'assets/images/rooster_card2.png'),
    Animal(name: 'duck', cardPath: 'assets/images/duck_card2.png'),
    Animal(name: 'lion', cardPath: 'assets/images/lion_card2.png'),
    Animal(name: 'horse', cardPath: 'assets/images/horse_card2.png'),
    Animal(name: 'sheep', cardPath: 'assets/images/sheep_card2.png'),
    Animal(name: 'pig', cardPath: 'assets/images/pig_card2.png'),
    Animal(name: 'owl', cardPath: 'assets/images/owl_card2.png'),
    Animal(name: 'elephant', cardPath: 'assets/images/elephant_card2.png'),
    Animal(name: 'crow', cardPath: 'assets/images/crow_card2.png'),
    Animal(name: 'monkey', cardPath: 'assets/images/monkey_card2.png'),
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
        return AlertDialog(
          backgroundColor: isPerfect ? Colors.amber[50] : Colors.blue[50],
          title: Text(
            isPerfect ? '🎉 Perfect Score!' : '✅ Game Complete!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Score',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                '$score / $totalQuestions',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isPerfect
                      ? Colors.amber.shade700
                      : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 12),
              if (isPerfect)
                const Text(
                  'Outstanding! You got them all right!',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Great job! Keep practicing!',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: const Text('Play Again', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Menu', style: TextStyle(fontSize: 16)),
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

class Animal {
  final String name;
  final String cardPath;

  Animal({required this.name, required this.cardPath});
}
