import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '4the_helpful_wind.dart';

class StoryBookPage3 extends StatefulWidget {
  const StoryBookPage3({super.key});

  @override
  State<StoryBookPage3> createState() => _StoryBookPage3State();
}

class _StoryBookPage3State extends State<StoryBookPage3> {
  // --- AUDIO SETUP ---
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;

  // Audio files mapped to pages.
  final List<String> _audioPaths = [
    '', // Index 0: Title Page (No Audio)
    'sounds/after_the_rain.m4a',
    'sounds/lil_bird.m4a',
    'sounds/why_cant.m4a',
    'sounds/so_lil_bird.m4a',
    'sounds/when_she_flew.m4a',
  ];

  final List<String> _pages = [
    'assets/images/3-TheRainbowBridge-3Title.png',
    'assets/images/3-TheRainbowBridge-P1.png',
    'assets/images/3-TheRainbowBridge-P2.png',
    'assets/images/3-TheRainbowBridge-P3.png',
    'assets/images/3-TheRainbowBridge-P4.png',
    'assets/images/3-TheRainbowBridge-P5.png',
  ];

  int _currentPage = 0;
  bool _showQuiz = false;

  // --- QUIZ VARIABLES ---
  String? q1Answer;
  String? q2Answer;
  String? q3Answer;

  final String correctQ1 = 'assets/images/3-1B.png';
  final String correctQ2 = 'assets/images/3-2A.png';
  final String correctQ3 = 'assets/images/3-3B.png';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.audioCache.prefix = 'assets/';

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- AUDIO LOGIC ---
  Future<void> _toggleAudio() async {
    if (_currentPage == 0 || _audioPaths[_currentPage].isEmpty) return;

    if (_isAudioPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isAudioPlaying = false;
      });
    } else {
      if (_currentPage < _audioPaths.length) {
        String path = _audioPaths[_currentPage];
        try {
          await _audioPlayer.play(AssetSource(path));
          setState(() {
            _isAudioPlaying = true;
          });
        } catch (e) {
          print('Error playing audio: $e');
        }
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isAudioPlaying = false;
    });
  }

  void _selectAnswer(int question, String imagePath) {
    setState(() {
      if (question == 1) q1Answer = imagePath;
      if (question == 2) q2Answer = imagePath;
      if (question == 3) q3Answer = imagePath;
    });
  }

  void _submitQuiz() {
    // Check if all questions are answered
    if (q1Answer == null || q2Answer == null || q3Answer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions first!')),
      );
      return;
    }

    if (q1Answer == correctQ1 &&
        q2Answer == correctQ2 &&
        q3Answer == correctQ3) {
      _showResultDialog();
    } else {
      _showTryAgainDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🎉 Excellent!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You got all answers correct!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to storybooks.dart
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StoryBookPage4()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Proceed to Next Story'),
          ),
        ],
      ),
    );
  }

  void _showTryAgainDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Oops!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: const Text(
          'Some answers are not correct yet.\nDo you want to try again?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  // --- FIXED QUIZ UI ---
  Widget _buildQuiz() {
    return Stack(
      children: [
        // Background fills the screen
        Positioned.fill(
          child: Image.asset(
            'assets/images/3-TheRainbowBridge-P6Quiz.png',
            fit: BoxFit.cover,
          ),
        ),

        // Back button in top left corner
        Positioned(
          top: 50,
          left: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showQuiz = false;
              });
            },
            child: Image.asset('assets/images/back.png', width: 120),
          ),
        ),

        // Answer buttons with consistent spacing
        Padding(
          padding: const EdgeInsets.only(left: 300, right: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Question 1 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(1, 'assets/images/3-1A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(1, 'assets/images/3-1B.png'),
                ],
              ),
              const SizedBox(height: 75),
              // Question 2 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(2, 'assets/images/3-2A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(2, 'assets/images/3-2B.png'),
                ],
              ),
              const SizedBox(height: 60),
              // Question 3 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(3, 'assets/images/3-3A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(3, 'assets/images/3-3B.png'),
                ],
              ),

              // Small gap
              const SizedBox(height: 10),

              // --- SUBMIT BUTTON ---
              GestureDetector(
                onTap: _submitQuiz,
                child: Image.asset(
                  'assets/images/submit.png',
                  width: 130, // Slim width
                  errorBuilder: (context, error, stack) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _answerImageButton(int question, String imagePath) {
    final String? selectedAnswer = question == 1
        ? q1Answer
        : question == 2
        ? q2Answer
        : q3Answer;

    final bool isSelected = selectedAnswer == imagePath;

    return GestureDetector(
      onTap: () => _selectAnswer(question, imagePath),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          imagePath,
          width: 130,
          errorBuilder: (context, error, stack) {
            return const Icon(Icons.error, color: Colors.red);
          },
        ),
      ),
    );
  }

  // --- MAIN STORY UI ---
  @override
  Widget build(BuildContext context) {
    final bool isTitlePage = _currentPage == 0;
    final bool isLastPage = _currentPage == _pages.length - 1;

    const double startBtnW = 180;
    const double navBtnW = 150;
    const double bottomOffset = 24;
    const double sidePadding = 40;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _showQuiz
          ? _buildQuiz()
          : Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _pages[_currentPage],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          '⚠️ Image not found. Check asset path.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),

                // --- VOICE OVER BUTTON (KEPT ON RIGHT AS REQUESTED) ---
                if (!isTitlePage)
                  Positioned(
                    top: 20,
                    right: 20, // REMAINS ON RIGHT
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 40,
                        color: Colors.blueAccent,
                        icon: Icon(
                          _isAudioPlaying
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                        ),
                        onPressed: _toggleAudio,
                      ),
                    ),
                  ),

                if (isTitlePage) ...[
                  // ... your existing Start button ...
                  Positioned(
                    bottom: 36,
                    right: sidePadding,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Image.asset(
                        'assets/images/start.png',
                        width: startBtnW,
                      ),
                    ),
                  ),

                  // NEW: Normal Back/Exit Button (Top Left)
                  Positioned(
                    top: 50, // Adjust for status bar/notch
                    left: sidePadding,
                    child: IconButton(
                      icon: const Icon(
                        Icons
                            .arrow_back_rounded, // You can also use Icons.close_rounded
                        size: 40,
                        color: Colors
                            .black, // Change to Colors.black if background is light
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],

                if (!isTitlePage)
                  Positioned(
                    bottom: bottomOffset,
                    left: sidePadding,
                    child: GestureDetector(
                      onTap: _previousPage,
                      child: Image.asset(
                        'assets/images/back.png',
                        width: navBtnW,
                      ),
                    ),
                  ),

                if (!isLastPage && !isTitlePage)
                  Positioned(
                    bottom: bottomOffset,
                    right: sidePadding,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Image.asset(
                        'assets/images/next.png',
                        width: navBtnW,
                      ),
                    ),
                  ),

                if (isLastPage)
                  Positioned(
                    bottom: bottomOffset,
                    right: sidePadding + 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showQuiz = true;
                        });
                      },
                      child: Image.asset(
                        'assets/images/finish.png',
                        width: navBtnW,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _nextPage() {
    _stopAudio();
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    _stopAudio();
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }
}
