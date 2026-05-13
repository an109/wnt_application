import 'package:flutter/material.dart';
import 'dart:async';


class ProfessionalLoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;
  final Map<String, dynamic>? searchParams;

  const ProfessionalLoadingScreen({
    super.key,
    required this.onLoadingComplete,
    this.searchParams,
  });

  @override
  State<ProfessionalLoadingScreen> createState() => _ProfessionalLoadingScreenState();
}

class _ProfessionalLoadingScreenState extends State<ProfessionalLoadingScreen> {
  double _progress = 0.0;
  Timer? _progressTimer;
  String _currentMessage = "Finding best flight options...";
  int currentIndex = 0;

  final List<String> _loadingMessages = [
    "Finding best flight options...",
    "Checking availability across airlines...",
    "Comparing prices for best deals...",
    "Applying exclusive discounts...",
    "Almost there! Preparing your results...",
    "You're all set! Redirecting...",
  ];

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_progress < 1.0) {
            _progress += 0.01;

            // Update message based on progress
            int messageIndex = (_progress * _loadingMessages.length).floor();
            if (messageIndex < _loadingMessages.length && messageIndex >= 0) {
              _currentMessage = _loadingMessages[messageIndex];
            }

            if (_progress >= 1.0) {
              timer.cancel();
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  widget.onLoadingComplete();
                }
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top progress indicator (Blue color)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 3,
          ),

          // Main content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GIF Animation
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.asset(
                      'assets/images/flight-loader.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.flight_takeoff,
                          size: 80,
                          color: Colors.blue,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dynamic message below GIF
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _currentMessage,
                      key: ValueKey(_currentMessage),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Bottom Progress Indicator (Red color)
                  Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0054A0)),
                        minHeight: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),

        ],
      ),

    );
  }
}