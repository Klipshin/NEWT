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

  // Number of choices to display (now 3)
  static const int choicesCount = 3;

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

      final random = Random();
      List<Animal> availableAnimals = allAnimals
          .where((a) => a.name != previousAnimal?.name)
          .toList();

      // If availableAnimals is too small (unlikely), fall back to allAnimals
      if (availableAnimals.isEmpty) {
        availableAnimals = List.from(allAnimals);
      }

      currentAnimal = availableAnimals[random.nextInt(availableAnimals.length)];
      previousAnimal = currentAnimal;

      // Build choicesCount choices: the correct animal + (choicesCount - 1) random others
      currentChoices = [currentAnimal!];
      List<Animal> otherAnimals = allAnimals
          .where((a) => a.name != currentAnimal!.name)
          .toList();
      otherAnimals.shuffle();
      final toTake = min(choicesCount - 1, otherAnimals.length);
      currentChoices.addAll(otherAnimals.take(toTake));
      currentChoices.shuffle();
    });

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
      timeRemaining += 3;
      _correctController.forward().then((_) => _correctController.reset());
    } else {
      _wrongController.forward().then((_) => _wrongController.reset());
    }

    questionsAnswered++;

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
          child: Column(
            children: [
              // Top bar with play button and question
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    // Sound player button
                    GestureDetector(
                      onTap: _playCurrentSound,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPlaying ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.volume_up : Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Question text
                    Text(
                      'Which animal makes this sound?',
                      style: TextStyle(
                        fontSize: 20,
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
                    ),
                  ],
                ),
              ),

              // Animal choices row - 3 cards in one row (no scroll)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                  child: currentChoices.length < choicesCount
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: List.generate(
                            choicesCount,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 8,
                                  right: index == choicesCount - 1 ? 0 : 8,
                                ),
                                child: _buildAnimalChoice(
                                  currentChoices[index],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Bottom stats bar
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.timer, '$timeRemaining s'),
                    _buildStatItem(Icons.star, '$currentScore'),
                    _buildStatItem(
                      Icons.quiz,
                      '${questionsAnswered + 1}/$totalQuestions',
                    ),
                    IconButton(
                      onPressed: _initializeGame,
                      icon: const Icon(Icons.refresh),
                      color: Colors.white,
                      tooltip: 'Reset Game',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Small wrapper in case other code expects `_buildStatText`
  Widget _buildStatText(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade300,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalChoice(Animal animal) {
    bool isSelected = selectedAnswer == animal.name;
    bool isCorrect = animal.name == currentAnimal?.name;

    Color? overlayColor;
    if (hasAnswered && isSelected) {
      overlayColor = isCorrect
          ? Colors.green.withOpacity(0.7)
          : Colors.red.withOpacity(0.7);
    } else if (hasAnswered && isCorrect) {
      overlayColor = Colors.green.withOpacity(0.7);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(animal.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // BoxFit.contain ensures the whole image is visible
              Image.asset(animal.cardPath, fit: BoxFit.contain),
              if (overlayColor != null)
                Container(
                  color: overlayColor,
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
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
