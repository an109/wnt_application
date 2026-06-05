// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_animate/flutter_animate.dart';
//
// import '../../UI_helper/navigation_queue.dart';
// import '../home/presentation/screens/home_screen.dart';
// import '../login/presentation/screen/login.dart';
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
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 3800),
//     );
//
//     _controller.forward();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _coordinateAppRouting();
//     });
//   }
//
//   void _coordinateAppRouting() async {
//     // wait slightly BEFORE navigation starts (sync with animation peak)
//     await Future.delayed(const Duration(milliseconds: 3000));
//
//     if (!mounted) return;
//
//     final authState = context.read<AuthBloc>().state;
//
//     final Widget nextScreen = authState is AuthAuthenticated
//         ? const HomeScreen()
//         : const HomeScreenWrapper();
//
//     Navigator.pushReplacement(
//       context,
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 900),
//         reverseTransitionDuration: const Duration(milliseconds: 500),
//         pageBuilder: (_, animation, __) {
//           return FadeTransition(
//             opacity: CurvedAnimation(
//               parent: animation,
//               curve: Curves.easeOut,
//             ),
//             child: nextScreen,
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _controller,
//           builder: (context, child) {
//             final t = Curves.easeInOutCubic.transform(_controller.value);
//
//             // smooth zoom progression
//             final scale = 0.6 + (t * 2.5);
//
//             return Transform.scale(
//               scale: scale,
//               child: Opacity(
//                 opacity: (1.0 - (_controller.value * 0.6)).clamp(0.0, 1.0),
//                 child: Image.asset(
//                   'assets/images/wander_nova_logo.jpg',
//                   height: 180,
//                   fit: BoxFit.contain,
//                   filterQuality: FilterQuality.high,
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// // === PERSISTENT WRAPPER PANELS WITH SECURE POPUPS ===
//
// class HomeScreenWrapper extends StatefulWidget {
//   const HomeScreenWrapper({super.key});
//
//   @override
//   State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
// }
//
// class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final authState = context.read<AuthBloc>().state;
//
//       if (authState is! AuthAuthenticated) {
//         NavigationQueueService().setPendingNavigation(() {
//           if (context.mounted) {
//             debugPrint('User logged in successfully');
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
//       barrierDismissible: false,
//       barrierLabel: "Login",
//       barrierColor: Colors.black.withOpacity(0.4),
//       transitionDuration: const Duration(milliseconds: 350),
//       pageBuilder: (_, __, ___) => const LoginSignupScreen(),
//       transitionBuilder: (_, animation, __, child) {
//         return FadeTransition(
//           opacity: animation,
//           child: ScaleTransition(
//             scale: Tween<double>(
//               begin: 0.95,
//               end: 1.0,
//             ).animate(
//               CurvedAnimation(
//                 parent: animation,
//                 curve: Curves.easeOutBack,
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
//     return const HomeScreen();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../UI_helper/navigation_queue.dart';
import '../../UI_helper/responsive_layout.dart';
import '../home/presentation/screens/home_screen.dart';
import '../login/presentation/screen/login.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coordinateAppRouting();
    });
  }

  void _coordinateAppRouting() async {
    // wait slightly BEFORE navigation starts (sync with animation peak)
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;

    final Widget nextScreen = authState is AuthAuthenticated
        ? const HomeScreen()
        : const HomeScreenWrapper();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: nextScreen,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOutCubic.transform(_controller.value);

            // smooth zoom progression
            final scale = 0.6 + (t * 2.5);

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: (1.0 - (_controller.value * 0.6)).clamp(0.0, 1.0),
                child: Image.asset(
                  'assets/images/wander_nova_logo.jpg',
                  height: context.h(180), // 180px on design
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            );
          },
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
