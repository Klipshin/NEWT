import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const KidsLearningApp());
}

class KidsLearningApp extends StatelessWidget {
  const KidsLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Learning Adventure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Comic Sans MS',
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;
  late Animation<double> _floatAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF98FB98), // Pale green
              Color(0xFF90EE90), // Light green
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background elements
            _buildBackgroundElements(),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Header with title
                    _buildHeader(),

                    Expanded(
                      child: Row(
                        children: [
                          // Left side - Character and welcome
                          Expanded(flex: 2, child: _buildWelcomeSection()),

                          // Right side - Menu options
                          Expanded(flex: 3, child: _buildMenuSection()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings button
            Positioned(top: 40, right: 20, child: _buildSettingsButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating clouds
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: 50 + _floatAnimation.value,
              left: 100,
              child: _buildCloud(),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: 80 - _floatAnimation.value,
              right: 150,
              child: _buildCloud(),
            );
          },
        ),

        // Decorative trees
        Positioned(bottom: 0, left: 0, child: _buildTree()),
        Positioned(bottom: 0, right: 0, child: _buildTree()),
      ],
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildTree() {
    return Container(
      width: 100,
      height: 150,
      decoration: const BoxDecoration(color: Colors.brown),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 25,
            child: Container(
              width: 50,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B6B),
                  Color(0xFFFFE66D),
                  Color(0xFF4ECDC4),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              '🌟 Kids Learning Adventure 🌟',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated character
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome, Little Explorer!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ready for fun learning?',
          style: TextStyle(fontSize: 18, color: Color(0xFF388E3C)),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _buildMenuCard(
          title: 'Mini Games',
          subtitle: 'Fun & Learning',
          icon: Icons.games,
          colors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
          onTap: () => _navigateToSection('Mini Games'),
        ),
        _buildMenuCard(
          title: 'Storybooks',
          subtitle: 'Read & Discover',
          icon: Icons.menu_book,
          colors: [const Color(0xFFFFB74D), const Color(0xFFFF8A65)],
          onTap: () => _navigateToSection('Storybooks'),
        ),
        _buildMenuCard(
          title: 'Learn ABC',
          subtitle: 'Letters & Words',
          icon: Icons.abc,
          colors: [const Color(0xFFE57373), const Color(0xFFEF5350)],
          onTap: () => _navigateToSection('Learn ABC'),
        ),
        _buildMenuCard(
          title: 'Numbers',
          subtitle: 'Count & Calculate',
          icon: Icons.calculate,
          colors: [const Color(0xFF9575CD), const Color(0xFF7E57C2)],
          onTap: () => _navigateToSection('Numbers'),
        ),
        _buildMenuCard(
          title: 'Colors & Shapes',
          subtitle: 'Art & Creativity',
          icon: Icons.palette,
          colors: [const Color(0xFF4DB6AC), const Color(0xFF26A69A)],
          onTap: () => _navigateToSection('Colors & Shapes'),
        ),
        _buildMenuCard(
          title: 'Achievements',
          subtitle: 'Your Progress',
          icon: Icons.emoji_events,
          colors: [const Color(0xFFFFD54F), const Color(0xFFFFCA28)],
          onTap: () => _navigateToSection('Achievements'),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _showSettingsDialog(),
        icon: const Icon(Icons.settings, color: Color(0xFF2E7D32), size: 28),
      ),
    );
  }

  void _navigateToSection(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $section...'),
        backgroundColor: const Color(0xFF4ECDC4),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.volume_up, color: Color(0xFF4ECDC4)),
                title: Text('Sound Effects'),
                trailing: Icon(Icons.toggle_on, color: Color(0xFF4ECDC4)),
              ),
              ListTile(
                leading: Icon(Icons.music_note, color: Color(0xFF4ECDC4)),
                title: Text('Background Music'),
                trailing: Icon(Icons.toggle_on, color: Color(0xFF4ECDC4)),
              ),
              ListTile(
                leading: Icon(Icons.child_care, color: Color(0xFF4ECDC4)),
                title: Text('Parental Controls'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ),
          ],
        );
      },
    );
  }
}
