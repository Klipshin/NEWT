import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class AnimalSoundsQuiz extends StatefulWidget {
  const AnimalSoundsQuiz({super.key});

  @override
  State<AnimalSoundsQuiz> createState() => _AnimalSoundsQuizState();
}

class _AnimalSoundsQuizState extends State<AnimalSoundsQuiz>
    with TickerProviderStateMixin {
  late AudioPlayer _soundPlayer;
  late AudioPlayer _bgMusicPlayer;
  bool _showDCardOverlay = true;

  // --- Confetti Controllers ---
  late ConfettiController _bgConfettiController;
  late ConfettiController _dialogConfettiController;
  late ConfettiController _correctBurstController;

  // --- ADDED: Define sizes for bigger confetti ---
  final Size confettiMinSize = const Size(20, 20);
  final Size confettiMaxSize = const Size(35, 35);

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

  static const int choicesCount = 3;

  @override
  void initState() {
    super.initState();

    _bgConfettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _dialogConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _correctBurstController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );

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
    _bgConfettiController.dispose();
    _dialogConfettiController.dispose();
    _correctBurstController.dispose();

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

  void _initializeGame() {
    currentScore = 0;
    questionsAnswered = 0;
    timeRemaining = 60;
    hasAnswered = false;
    selectedAnswer = null;

    _bgConfettiController.stop();
    _dialogConfettiController.stop();
    _correctBurstController.stop();

    _gameTimer?.cancel();
    // Only start timer if overlay is not showing
    if (!_showDCardOverlay) {
      _startGameTimer();
    }
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

      if (availableAnimals.isEmpty) {
        availableAnimals = List.from(allAnimals);
      }

      currentAnimal = availableAnimals[random.nextInt(availableAnimals.length)];
      previousAnimal = currentAnimal;

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

      _correctBurstController.play();

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
          ConfettiWidget(
            confettiController: _dialogConfettiController,
            // --- ADDED SIZES HERE ---
            minimumSize: confettiMinSize,
            maximumSize: confettiMaxSize,
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

  // --- DIALOG LOGIC ---
  void _showVictoryDialog() {
    _bgConfettiController.play();
    _dialogConfettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🎉 Congratulations!',
        'You finished! Score: $currentScore',
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
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '⏰ Time\'s Up!',
        'Score: $currentScore. Try again!',
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
        ],
      ),
    );
  }

  Future<void> _onBackButtonPressed() async {
    _gameTimer?.cancel();

    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialogContent(
        '🚪 Leaving already?',
        'Your progress will be lost!',
        [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              if (!_showDCardOverlay) {
                _startGameTimer();
              }
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
            // Layer 1: Background Image and Game Content
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
                ).withOpacity(0.3),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
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
                                        right: index == choicesCount - 1
                                            ? 0
                                            : 8,
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

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                      ),
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
                            onPressed: _onBackButtonPressed,
                            icon: const Icon(Icons.exit_to_app_rounded),
                            color: Colors.red.shade300,
                            tooltip: 'Exit Game',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Specific Center Burst Confetti ---
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _correctBurstController,
                // --- ADDED SIZES HERE ---
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
                createParticlePath: drawStar,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.3,
              ),
            ),

            // Layer 2: Background Confetti System (Victory Confetti)
            // --- ADDED SIZES TO ALL BACKGROUND WIDGETS BELOW ---
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _bgConfettiController,
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
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
                minimumSize: confettiMinSize,
                maximumSize: confettiMaxSize,
                blastDirection: -3 * pi / 4,
                emissionFrequency: 0.08,
                numberOfParticles: 15,
                colors: const [Colors.pinkAccent, Colors.deepOrange],
                createParticlePath: drawStar,
              ),
            ),
            // DAnimal Overlay - stuck to bottom
            if (_showDCardOverlay)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDCardOverlay = false;
                  });
                  _startGameTimer();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/dsounds.png',
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
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
