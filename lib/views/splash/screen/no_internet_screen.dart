import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key, required this.onConnected});

  final VoidCallback onConnected;

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  Timer? _poller;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty && mounted) {
        _poller?.cancel();
        widget.onConnected();
      }
    } catch (_) {}
    _checking = false;
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(74)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/no_internet.png',
                width: context.w(229),
                height: context.w(162),
                fit: BoxFit.contain,
              ),
              SizedBox(height: context.w(24)),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: context.w(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: context.w(4)),
              Text(
                'It looks like you\'re offline. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.w(12),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns true when the device can reach the internet.
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
