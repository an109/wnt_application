import 'dart:async';
import 'package:flutter/material.dart';

import '../views/home/presentation/screens/home_screen.dart';
import '../views/login/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // KEEPING YOUR ORIGINAL EFFECT
    _animation = Tween<double>(
      begin: 0.5,
      end: 3.5,
    ).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 3), () {

      // OPEN HOME SCREEN FIRST
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreenWrapper(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/images/wander_nova_logo.jpg',
            height: 140,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// HOME SCREEN + LOGIN POPUP
class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {

  @override
  void initState() {
    super.initState();

    // SHOW POPUP AFTER HOME SCREEN LOADS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginPopup();
    });
  }

  void _showLoginPopup() {

    showGeneralDialog(
      context: context,

      barrierDismissible: true,
      barrierLabel: "Login",

      // DARK BLUR EFFECT
      barrierColor: Colors.black.withOpacity(0.15),

      transitionDuration: const Duration(milliseconds: 300),

      pageBuilder: (_, __, ___) {
        return const LoginSignupScreen();
      },

      transitionBuilder: (_, animation, __, child) {

        return FadeTransition(
          opacity: animation,

          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),

            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    // THIS IS BACKGROUND SCREEN
    return const HomeScreen();
  }
}