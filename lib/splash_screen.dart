import 'dart:async';

import 'package:flutter/material.dart';

import 'home/home_controller.dart';
import 'home/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.controller, this.preload = true, this.autoNavigate = true});

  final HomeController? controller;
  final bool preload;
  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.autoNavigate) {
      _preloadAndGo();
    }
  }

  Future<void> _preloadAndGo() async {
    final controller = widget.controller ?? HomeController();
    if (widget.preload) {
      await controller.init();
    }
    if (!mounted) return;
    _navTimer = Timer(const Duration(milliseconds: 400), () {
      _goNext(controller);
    });
  }

  void _goNext(HomeController controller) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: HomePage(controller: controller, initController: false),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00E5FF);
    const secondary = Color(0xFF1DE9B6);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3300E5FF),
                          blurRadius: 22,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 86,
                      width: 86,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ESP Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 160,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.25 + (0.65 * _controller.value),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [primary, secondary],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Getting your devices ready',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
