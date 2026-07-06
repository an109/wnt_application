import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TransportLoadingIndicator extends StatefulWidget {
  const TransportLoadingIndicator({super.key});

  @override
  State<TransportLoadingIndicator> createState() => _TransportLoadingIndicatorState();
}

class _TransportLoadingIndicatorState extends State<TransportLoadingIndicator> {
  int _messageIndex = 0;
  Timer? _timer;

  static const _messages = [
    'Finding best hotels for you...',
    'Checking room availability...',
    'Comparing prices for best deals...',
    'Fetching exclusive offers...',
    'Almost there! Preparing your results...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: Lottie.asset(
              'assets/animation/transport.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              _messages[_messageIndex],
              key: ValueKey(_messageIndex),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1769F6),
                ),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
