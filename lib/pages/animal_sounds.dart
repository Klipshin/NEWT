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

  int _frogFrame = 0;
  Timer? _mascotTimer;

  late AnimationController _correctController;
  late AnimationController _wrongController;

  final List<Animal> allAnimals = [
    Animal(
      name: 'cat',
      soundPath: 'assets/sounds/cat.mp3',
      cardPath: 'assets/images/cat_card.png',
    ),
    Animal(
      name: 'cow',
      soundPath: 'assets/sounds/cow.mp3',
      cardPath: 'assets/images/cow_card.png',
    ),
    Animal(
      name: 'dog',
      soundPath: 'assets/sounds/dog.mp3',
      cardPath: 'assets/images/dog_card.png',
    ),
    Animal(
      name: 'rooster',
      soundPath: 'assets/sounds/rooster.mp3',
      cardPath: 'assets/images/rooster_card.png',
    ),
    Animal(
      name: 'duck',
      soundPath: 'assets/sounds/duck.mp3',
      cardPath: 'assets/images/duck_card.png',
    ),
    Animal(
      name: 'lion',
      soundPath: 'assets/sounds/lion.mp3',
      cardPath: 'assets/images/lion_card.png',
    ),
    Animal(
      name: 'horse',
      soundPath: 'assets/sounds/horse.mp3',
      cardPath: 'assets/images/horse_card.png',
    ),
    Animal(
      name: 'sheep',
      soundPath: 'assets/sounds/sheep.mp3',
      cardPath: 'assets/images/sheep_card.png',
    ),
    Animal(
      name: 'pig',
      soundPath: 'assets/sounds/pig.mp3',
      cardPath: 'assets/images/pig_card.png',
    ),
    Animal(
      name: 'owl',
      soundPath: 'assets/sounds/owl.mp3',
      cardPath: 'assets/images/owl_card.png',
    ),
    Animal(
      name: 'elephant',
      soundPath: 'assets/sounds/elephant.mp3',
      cardPath: 'assets/images/elephant_card.png',
    ),
    Animal(
      name: 'crow',
      soundPath: 'assets/sounds/crow.mp3',
      cardPath: 'assets/images/crow_card.png',
    ),
    Animal(
      name: 'monkey',
      soundPath: 'assets/sounds/monkey.mp3',
      cardPath: 'assets/images/monkey_card.png',
    ),
  ];

  Animal? currentAnimal;
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
    _startMascotAnimation();
    _initializeGame();
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    _bgMusicPlayer.dispose();
    _gameTimer?.cancel();
    _mascotTimer?.cancel();
    _correctController.dispose();
    _wrongController.dispose();
    super.dispose();
  }

  void _startMascotAnimation() {
    _mascotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _frogFrame = (_frogFrame + 1) % 3;
        });
      }
    });
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

      // Pick random animal for the question
      final random = Random();
      currentAnimal = allAnimals[random.nextInt(allAnimals.length)];

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
          color: const Color.fromARGB(255, 112, 155, 131).withOpacity(0.4),
          child: SafeArea(
            child: Row(
              children: [
                // Left mascot area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Image.asset(
                            _frogFrame == 0
                                ? 'assets/images/eyeopenfrog.png'
                                : _frogFrame == 1
                                ? 'assets/images/closefrog.png'
                                : 'assets/images/mouthfrog.png',
                            width: constraints.maxWidth * 1.2,
                            height: constraints.maxHeight * 1.2,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Game area
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sound player button
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🎵 Listen to the sound!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 15),
                              GestureDetector(
                                onTap: _playCurrentSound,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? Colors.orange
                                        : Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.volume_up
                                        : Icons.play_arrow,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Question ${questionsAnswered + 1}/$totalQuestions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Answer choices
                        const Text(
                          'Which animal makes this sound?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: currentChoices.length,
                            itemBuilder: (context, index) {
                              return _buildAnimalChoice(currentChoices[index]);
                            },
                          ),
                        ),
                      ],
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
                        _buildSideStatItem(
                          'Time',
                          '$timeRemaining',
                          Icons.timer,
                        ),
                        const SizedBox(height: 20),
                        _buildSideStatItem(
                          'Score',
                          '$currentScore',
                          Icons.star,
                        ),
                        const SizedBox(height: 20),
                        _buildSideStatItem(
                          'Q',
                          '${questionsAnswered + 1}/$totalQuestions',
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
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: borderColor ?? Colors.grey.shade400,
            width: hasAnswered && (isSelected || isCorrect) ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(animal.cardPath, fit: BoxFit.contain),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                animal.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: borderColor ?? Colors.green.shade800,
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
}

class Animal {
  final String name;
  final String soundPath;
  final String cardPath;

  Animal({required this.name, required this.soundPath, required this.cardPath});
}
