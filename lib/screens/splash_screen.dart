import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authService = AuthService();
    final user = authService.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B4B), // Deep navy
              Color(0xFF1A0A3B), // Deep purple
              Color(0xFF0A2440), // Dark teal-blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3D5AFE).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C4DFF).withOpacity(0.12),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated logo container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3D5AFE).withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      size: 64,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        curve: Curves.elasticOut,
                        duration: 900.ms,
                      ),

                  const SizedBox(height: 32),

                  // App name
                  const Text(
                    'FaceAI Pro',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'AI-Powered Face Detection',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 64),

                  // Loading dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3D5AFE).withOpacity(0.8),
                        ),
                      )
                          .animate(
                            delay: Duration(milliseconds: 700 + i * 150),
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scaleXY(
                            begin: 0.5,
                            end: 1.0,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          )
                          .fadeIn(duration: 300.ms);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
