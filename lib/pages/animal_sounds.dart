import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AnimalSoundsQuiz extends StatefulWidget {
  const AnimalSoundsQuiz({super.key});

  @override
  State<AnimalSoundsQuiz> createState() => _AnimalSoundsQuizState();
}

class _AnimalSoundsQuizState extends State<AnimalSoundsQuiz>
    with TickerProviderStateMixin {
  late AudioPlayer _soundPlayer;
  late AudioPlayer _bgMusicPlayer;

  int currentScore = 0;
  int questionsAnswered = 0;
  int totalQuestions = 10;
  int timeRemaining = 60;
  Timer? _gameTimer;

  bool isPlaying = false;
  bool hasAnswered = false;
  String? selectedAnswer;

  late AnimationController _correctController;
  late AnimationController _wrongController;

  final List<Animal> allAnimals = [
    Animal(
      name: 'cat',
      soundPath: 'assets/sounds/cat.mp3',
      cardPath: 'assets/images/cat_card2.png',
    ),
    Animal(
      name: 'cow',
      soundPath: 'assets/sounds/cow.mp3',
      cardPath: 'assets/images/cow_card2.png',
    ),
    Animal(
      name: 'dog',
      soundPath: 'assets/sounds/dog.mp3',
      cardPath: 'assets/images/dog_card2.png',
    ),
    Animal(
      name: 'rooster',
      soundPath: 'assets/sounds/rooster.mp3',
      cardPath: 'assets/images/rooster_card2.png',
    ),
    Animal(
      name: 'duck',
      soundPath: 'assets/sounds/duck.mp3',
      cardPath: 'assets/images/duck_card2.png',
    ),
    Animal(
      name: 'lion',
      soundPath: 'assets/sounds/lion.mp3',
      cardPath: 'assets/images/lion_card2.png',
    ),
    Animal(
      name: 'horse',
      soundPath: 'assets/sounds/horse.mp3',
      cardPath: 'assets/images/horse_card2.png',
    ),
    Animal(
      name: 'sheep',
      soundPath: 'assets/sounds/sheep.mp3',
      cardPath: 'assets/images/sheep_card2.png',
    ),
    Animal(
      name: 'pig',
      soundPath: 'assets/sounds/pig.mp3',
      cardPath: 'assets/images/pig_card2.png',
    ),
    Animal(
      name: 'owl',
      soundPath: 'assets/sounds/owl.mp3',
      cardPath: 'assets/images/owl_card2.png',
    ),
    Animal(
      name: 'elephant',
      soundPath: 'assets/sounds/elephant.mp3',
      cardPath: 'assets/images/elephant_card2.png',
    ),
    Animal(
      name: 'crow',
      soundPath: 'assets/sounds/crow.mp3',
      cardPath: 'assets/images/crow_card2.png',
    ),
    Animal(
      name: 'monkey',
      soundPath: 'assets/sounds/monkey.mp3',
      cardPath: 'assets/images/monkey_card2.png',
    ),
  ];

  Animal? currentAnimal;
  Animal? previousAnimal;
  List<Animal> currentChoices = [];

  @override
  void initState() {
    super.initState();
    _soundPlayer = AudioPlayer();
    _bgMusicPlayer = AudioPlayer();

    _correctController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _wrongController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _playBackgroundMusic();
    _initializeGame();
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    _bgMusicPlayer.dispose();
    _gameTimer?.cancel();
    _correctController.dispose();
    _wrongController.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgMusicPlayer.play(AssetSource('sounds/card.mp3'));
  }

  void _initializeGame() {
    currentScore = 0;
    questionsAnswered = 0;
    timeRemaining = 60;
    hasAnswered = false;
    selectedAnswer = null;

    _gameTimer?.cancel();
    _startGameTimer();
    _loadNextQuestion();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          timeRemaining--;
        });

        if (timeRemaining <= 0) {
          timer.cancel();
          _showGameOverDialog();
        }
      }
    });
  }

  void _loadNextQuestion() {
    if (questionsAnswered >= totalQuestions) {
      _gameTimer?.cancel();
      _showVictoryDialog();
      return;
    }

    setState(() {
      hasAnswered = false;
      selectedAnswer = null;

      // Pick random animal for the question (avoid repeating previous animal)
      final random = Random();
      List<Animal> availableAnimals = allAnimals
          .where((a) => a.name != previousAnimal?.name)
          .toList();

      currentAnimal = availableAnimals[random.nextInt(availableAnimals.length)];
      previousAnimal = currentAnimal;

      // Create choices (correct answer + 3 random wrong answers)
      currentChoices = [currentAnimal!];
      List<Animal> otherAnimals = allAnimals
          .where((a) => a.name != currentAnimal!.name)
          .toList();
      otherAnimals.shuffle();
      currentChoices.addAll(otherAnimals.take(3));
      currentChoices.shuffle();
    });

    // Auto-play sound
    _playCurrentSound();
  }

  Future<void> _playCurrentSound() async {
    if (currentAnimal == null) return;

    setState(() {
      isPlaying = true;
    });

    await _soundPlayer.stop();
    await _soundPlayer.play(
      AssetSource(
        currentAnimal!.soundPath.replaceAll('assets/sounds/', 'sounds/'),
      ),
    );

    // Reset playing state after sound completes (estimate 2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  void _selectAnswer(String animalName) {
    if (hasAnswered) return;

    setState(() {
      hasAnswered = true;
      selectedAnswer = animalName;
    });

    bool isCorrect = animalName == currentAnimal!.name;

    if (isCorrect) {
      currentScore += 10;
      timeRemaining += 3; // Bonus time
      _correctController.forward().then((_) => _correctController.reset());
    } else {
      _wrongController.forward().then((_) => _wrongController.reset());
    }

    questionsAnswered++;

    // Move to next question after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _loadNextQuestion();
      }
    });
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.amber[50],
          title: const Text(
            '🎉 Congratulations!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You completed all questions!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Final Score: $currentScore',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'Time Left: $timeRemaining seconds',
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
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: const Text(
            '⏰ Time\'s Up!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                'Score: $currentScore',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Questions: $questionsAnswered/$totalQuestions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
            image: AssetImage("assets/images/swamp_new.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromARGB(255, 112, 155, 131).withOpacity(0.3),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top bar with stats - combined into one
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatText('⏱️', '$timeRemaining s'),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatText('⭐', '$currentScore'),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatText(
                          '📝',
                          '${questionsAnswered + 1}/$totalQuestions',
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        IconButton(
                          onPressed: _initializeGame,
                          icon: const Icon(Icons.refresh, size: 20),
                          color: Colors.green.shade700,
                          tooltip: 'Reset Game',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sound player section - more compact
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎵 Listen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _playCurrentSound,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPlaying ? Colors.orange : Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.volume_up : Icons.play_arrow,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Question text
                  const Text(
                    'Which animal makes this sound?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Animal choices - taking remaining space
                  Expanded(
                    child: Row(
                      children: currentChoices.asMap().entries.map((entry) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: entry.key == 0 ? 0 : 8,
                              right: entry.key == currentChoices.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: _buildAnimalChoice(entry.value),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatText(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalChoice(Animal animal) {
    bool isSelected = selectedAnswer == animal.name;
    bool isCorrect = animal.name == currentAnimal?.name;

    Color? borderColor;
    Color? backgroundColor;

    if (hasAnswered && isSelected) {
      if (isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.shade100;
      } else {
        borderColor = Colors.red;
        backgroundColor = Colors.red.shade100;
      }
    } else if (hasAnswered && isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.shade100;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(animal.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? Colors.grey.shade300,
            width: hasAnswered && (isSelected || isCorrect) ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(animal.cardPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class Animal {
  final String name;
  final String soundPath;
  final String cardPath;

  Animal({required this.name, required this.soundPath, required this.cardPath});
}
