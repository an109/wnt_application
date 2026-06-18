import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../UI_helper/navigation_queue.dart';

class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for animation to play, then handle navigation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Check if there's pending navigation
      if (NavigationQueueService().hasPendingNavigation) {
        // Execute pending navigation (this will navigate to the intended screen)
        NavigationQueueService().executePendingNavigation(context);

        // After executing pending navigation, remove this success screen
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        });
      } else {
        // No pending navigation, just close the success screen
        // This will reveal the login/signup screen underneath
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.asset(
                'assets/animation/successful.json',
                repeat: false,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Login Successful!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Welcome back to Wander Nova",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}