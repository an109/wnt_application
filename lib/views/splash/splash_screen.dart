import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../UI_helper/navigation_queue.dart';
import '../home/presentation/screens/home_screen.dart';
import '../login/presentation/screen/login.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Start routing after first frame renders smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coordinateAppRouting();
    });
  }

  void _coordinateAppRouting() {
    // Sync navigation exactly with cinematic zoom timeline
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;

      if (authState is AuthAuthenticated) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const HomeScreenWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Image.asset(
          'assets/images/wander_nova_logo.jpg',
          height: 180,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        )

        // === PREMIUM CINEMATIC ZOOM EFFECT ===
            .animate()

        // Soft appearance
            .fadeIn(
          duration: 500.ms,
          curve: Curves.easeOut,
        )

        // Feels like logo is continuously coming closer
            .scale(
          begin: const Offset(0.55, 0.55),
          end: const Offset(7.0, 7.0),
          // end: const Offset(5.5, 5.5),
          duration: 3200.ms,
          // duration: 2500.ms,
          curve: Curves.easeInExpo,
          // curve: Curves.easeInCubic,
        )
            .scale(
          begin: const Offset(0.35, 0.35),
          end: const Offset(24.0, 24.0),
          duration: 4000.ms,
          curve: Curves.easeInExpo,
        )
        // // Smooth cinematic dissolve
            .fadeOut(
          begin: 0.92,
          delay: 1850.ms,
          duration: 650.ms,
          curve: Curves.easeOut,
        )

        // Premium moving light sweep
            .shimmer(
          delay: 250.ms,
          duration: 1600.ms,
          color: Colors.white.withOpacity(0.45),
          size: 0.30,
          angle: 1.15,
        ),
      ),
    );
  }
}

// === PERSISTENT WRAPPER PANELS WITH SECURE POPUPS ===

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) {
        NavigationQueueService().setPendingNavigation(() {
          if (context.mounted) {
            debugPrint('User logged in successfully');
          }
        });

        _showLoginPopup();
      }
    });
  }

  void _showLoginPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Login",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const LoginSignupScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
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
    return const HomeScreen();
  }
}
