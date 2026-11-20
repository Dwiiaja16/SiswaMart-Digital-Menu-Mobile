import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  Timer? _initSafetyTimer;
  Timer? _endSafetyTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Pengaman hanya jika video gagal/macet saat proses inisialisasi awal (4 detik)
    _initSafetyTimer = Timer(const Duration(seconds: 4), () {
      if (_controller == null || !_controller!.value.isInitialized) {
        _navigateToMain();
      }
    });

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/splash.mp4');
      _controller = controller;

      await controller.initialize();
      _initSafetyTimer?.cancel();

      await controller.setLooping(false);

      if (!mounted) return;

      // Cadangan otomatis sesuai durasi asli video (10 detik) + toleransi 800ms
      final videoDuration = controller.value.duration;
      if (videoDuration > Duration.zero) {
        _endSafetyTimer = Timer(
          videoDuration + const Duration(milliseconds: 800),
          _navigateToMain,
        );
      }

      controller.addListener(_checkVideoProgress);
      await controller.play();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Jika video gagal dimuat di perangkat tertentu, langsung lanjut ke MainNavigation
      _navigateToMain();
    }
  }

  void _checkVideoProgress() {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration <= Duration.zero) return;

    final isFinished =
        value.isCompleted ||
        (!value.isPlaying &&
            value.position >=
                value.duration - const Duration(milliseconds: 150));

    if (isFinished) {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _initSafetyTimer?.cancel();
    _endSafetyTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _initSafetyTimer?.cancel();
    _endSafetyTimer?.cancel();
    _controller?.removeListener(_checkVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: isReady
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
