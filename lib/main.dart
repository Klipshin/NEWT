import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
// Make sure this file exists in your project structure
import 'pages/landing_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hide the status bars (Battery, Time, WiFi, etc.)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 2. Lock orientation to landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEWT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const IntroVideoPage(),
    );
  }
}

class IntroVideoPage extends StatefulWidget {
  const IntroVideoPage({super.key});

  @override
  State<IntroVideoPage> createState() => _IntroVideoPageState();
}

class _IntroVideoPageState extends State<IntroVideoPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  // Flag to prevent multiple navigation attempts
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Load video from assets
    // Ensure the asset path 'assets/videos/new_intro.mp4' is correct
    _controller = VideoPlayerController.asset('assets/videos/new_intro.mp4');

    await _controller.initialize();
    setState(() {
      _isVideoInitialized = true;
    });

    // Play the video
    _controller.play();

    // Listen for video completion
    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToLandingPage();
      }
    });
  }

  void _navigateToLandingPage() {
    // Only navigate if we are not already navigating
    if (_isNavigating) return;

    _isNavigating = true;
    _controller.pause();

    // Use pushReplacement to navigate and remove the video page from the stack
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LandingPage()),
    );
  }

  @override
  void dispose() {
    // Always dispose of the controller to free up resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // The GestureDetector has been removed from the body!
      body: SizedBox.expand(
        child: FittedBox(
          // BoxFit.cover ensures the video fills the screen
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
