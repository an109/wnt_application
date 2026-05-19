// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../UI_helper/navigation_queue.dart';
// import '../home/flight/flight_screen.dart';
// import '../home/presentation/screens/home_screen.dart';
// import '../login/login.dart';
// import '../auth/presentation/bloc/auth_bloc.dart';
// import '../auth/presentation/bloc/auth_state.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//
//     _animation = Tween<double>(
//       begin: 0.5,
//       end: 3.5,
//     ).animate(_controller);
//
//     _controller.forward();
//
//     Timer(const Duration(seconds: 3), () {
//       // OPEN HOME SCREEN FIRST
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(
//       //     builder: (_) => const HomeScreenWrapper(),
//       //   ),
//       // );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const HomeScreen(),
//         ),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ScaleTransition(
//           scale: _animation,
//           child: Image.asset(
//             'assets/images/wander_nova_logo.jpg',
//             height: 140,
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
//
// // HOME SCREEN + LOGIN POPUP
// class HomeScreenWrapper extends StatefulWidget {
//   const HomeScreenWrapper({super.key});
//
//   @override
//   State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
// }
//
// class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
//
//   @override
//   void initState() {
//     super.initState();
//
//     // CHECK IF USER IS ALREADY LOGGED IN
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final authState = context.read<AuthBloc>().state;
//
//       if (authState is! AuthAuthenticated) {
//         // User not logged in, set pending navigation to home (or whatever)
//         NavigationQueueService().setPendingNavigation(() {
//           if (context.mounted) {
//             // Optional: Show welcome back message or just do nothing
//             print('User logged in successfully');
//           }
//         });
//
//         _showLoginPopup();
//       }
//     });
//   }
//
//   void _showLoginPopup() {
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: "Login",
//       barrierColor: Colors.black.withOpacity(0.15),
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (_, __, ___) {
//         return const LoginSignupScreen();
//       },
//       transitionBuilder: (_, animation, __, child) {
//         return FadeTransition(
//           opacity: animation,
//           child: ScaleTransition(
//             scale: Tween<double>(
//               begin: 0.95,
//               end: 1,
//             ).animate(
//               CurvedAnimation(
//                 parent: animation,
//                 curve: Curves.easeOut,
//               ),
//             ),
//             child: child,
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const FlightScreen();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../UI_helper/navigation_queue.dart';
import '../home/presentation/screens/home_screen.dart';
import '../login/login.dart';
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

    // Smooth, deterministic routing hooked directly to the native frame pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coordinateAppRouting();
    });
  }

  void _coordinateAppRouting() {
    // Wait exactly 2.5 seconds for the premium zoom animation to finish its timeline cleanly
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;

      // Smart architectural routing based directly on your login state profile
      if (authState is AuthAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Safe protection layout layer: Send unauthenticated traffic to the popup wrapper
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Guarantees a clean, premium background isolation layout
      body: Center(
        // Cinematic Zoom-In & Fade Animation Segment
        child: Image.asset(
          'assets/images/wander_nova_logo.jpg',
          height: 160, // Increased size slightly to anchor the layout perfectly as a standalone element
          fit: BoxFit.contain,
        )
            .animate()
            .fadeIn(
          duration: 1000.ms,
          curve: Curves.easeOut,
        )
            .scale(
          begin: const Offset(0.2, 0.2), // Starts compressed in 3D distance
          end: const Offset(2.8, 2.8),   // Zooms forward smoothly to its natural dimensions
          duration: 1400.ms,
          curve: Curves.easeOutCubic,    // Silky smooth deceleration curve with zero harsh bounces
        )
        // Elegant light reflection gloss sweep running across the logo asset continuously
            .shimmer(
          delay: 400.ms,
          duration: 1800.ms,
          color: Colors.white.withOpacity(0.55),
          size: 0.35,
          angle: 1.2,
          curve: Curves.easeInOut,
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
      barrierDismissible: false, // Set false for strict login verification walls
      barrierLabel: "Login",
      barrierColor: Colors.black.withOpacity(0.4), // Premium translucent overlay for high visual focus
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const LoginSignupScreen(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack), // Responsive spring pop
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
