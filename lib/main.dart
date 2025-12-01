import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Load video from assets
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
    // Ensure we don't navigate multiple times
    _controller.pause();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LandingPage()),
    );
  }

  @override
  void dispose() {
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
      // GestureDetector allows user to tap anywhere to skip video
      body: GestureDetector(
        onTap: _navigateToLandingPage,
        child: SizedBox.expand(
          child: FittedBox(
            // BoxFit.cover ensures the video fills the screen
            // (cropping edges if aspect ratio differs)
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );
  }
}
