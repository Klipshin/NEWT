import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StoryBookPage5 extends StatefulWidget {
  const StoryBookPage5({super.key});

  @override
  State<StoryBookPage5> createState() => _StoryBookPage5State();
}

class _StoryBookPage5State extends State<StoryBookPage5> {
  // --- AUDIO SETUP ---
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;

  // Audio files mapped to pages.
  final List<String> _audioPaths = [
    '', // Index 0: Title Page (No Audio)
    'sounds/deep.m4a',
    'sounds/hello_world.m4a',
    'sounds/then_thesun.m4a',
    'sounds/sprouts_grew.m4a',
    'sounds/young_tree.m4a',
    'sounds/children.m4a',
  ];

  final List<String> _pages = [
    'assets/images/5-TheLittleSeedsJourney-5Title.png',
    'assets/images/5-TheLittleSeedsJourney-P1.png',
    'assets/images/5-TheLittleSeedsJourney-P2.png',
    'assets/images/5-TheLittleSeedsJourney-P3.png',
    'assets/images/5-TheLittleSeedsJourney-P4.png',
    'assets/images/5-TheLittleSeedsJourney-P5.png',
    'assets/images/5-TheLittleSeedsJourney-P6.png',
  ];

  int _currentPage = 0;
  bool _showQuiz = false;

  // --- QUIZ VARIABLES ---
  String? q1Answer;
  String? q2Answer;
  String? q3Answer;

  final String correctQ1 = 'assets/images/5-1B.png';
  final String correctQ2 = 'assets/images/5-2B.png';
  final String correctQ3 = 'assets/images/5-3B.png';

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
            'assets/images/5-TheLittleSeedsJourney-P7Quiz.png',
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
                  _answerImageButton(1, 'assets/images/5-1A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(1, 'assets/images/5-1B.png'),
                ],
              ),
              const SizedBox(height: 75),
              // Question 2 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(2, 'assets/images/5-2A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(2, 'assets/images/5-2B.png'),
                ],
              ),
              const SizedBox(height: 60),
              // Question 3 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(3, 'assets/images/5-3A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(3, 'assets/images/5-3B.png'),
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

                // --- VOICE OVER BUTTON (Top Left) ---
                if (!isTitlePage)
                  Positioned(
                    top: 20,
                    left: 20, // Moved to Left
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

                  Positioned(
                    top: 30, // Adjust for status bar/notch
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
