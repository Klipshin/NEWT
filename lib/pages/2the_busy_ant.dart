import 'package:flutter/material.dart';
import '3the_rainbow_bridge.dart';

class StoryBookPage2 extends StatefulWidget {
  const StoryBookPage2({super.key});

  @override
  State<StoryBookPage2> createState() => _StoryBookPage1State();
}

class _StoryBookPage1State extends State<StoryBookPage2> {
  final List<String> _pages = [
    'assets/images/2-TheBusyAnt-2Title.png',
    'assets/images/2-TheBusyAnt-P1.png',
    'assets/images/2-TheBusyAnt-P2.png',
    'assets/images/2-TheBusyAnt-P3.png',
    'assets/images/2-TheBusyAnt-P4.png',
    'assets/images/2-TheBusyAnt-P5.png',
  ];

  int _currentPage = 0;
  bool _showQuiz = false;

  // --- QUIZ VARIABLES ---
  String? q1Answer;
  String? q2Answer;
  String? q3Answer;

  final String correctQ1 = 'assets/images/2-1B.png';
  final String correctQ2 = 'assets/images/2-2B.png';
  final String correctQ3 = 'assets/images/2-3A.png';

  void _selectAnswer(int question, String imagePath) {
    setState(() {
      if (question == 1) q1Answer = imagePath;
      if (question == 2) q2Answer = imagePath;
      if (question == 3) q3Answer = imagePath;
    });

    if (q1Answer == correctQ1 &&
        q2Answer == correctQ2 &&
        q3Answer == correctQ3) {
      _showResultDialog();
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
                MaterialPageRoute(builder: (context) => const StoryBookPage3()),
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

  // --- FIXED QUIZ UI ---
  Widget _buildQuiz() {
    return Stack(
      children: [
        // Background fills the screen
        Positioned.fill(
          child: Image.asset(
            'assets/images/2-TheBusyAnt-P6Quiz.png',
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

        // Answer buttons with better spacing
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
                  _answerImageButton(1, 'assets/images/2-1A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(1, 'assets/images/2-1B.png'),
                ],
              ),
              const SizedBox(height: 75),
              // Question 2 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(2, 'assets/images/2-2A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(2, 'assets/images/2-2B.png'),
                ],
              ),
              const SizedBox(height: 60),
              // Question 3 answers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _answerImageButton(3, 'assets/images/2-3A.png'),
                  const SizedBox(width: 20),
                  _answerImageButton(3, 'assets/images/2-3B.png'),
                ],
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
            print('ERROR loading: $imagePath');
            print('Error details: $error');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                Text(
                  imagePath.split('/').last,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ],
            );
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

                if (isTitlePage)
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
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }
}
