import 'package:flutter/material.dart';

class NavigationQueueService {
  static final NavigationQueueService _instance = NavigationQueueService._internal();
  factory NavigationQueueService() => _instance;
  NavigationQueueService._internal();

  // Store the pending navigation action
  VoidCallback? _pendingNavigation;

  // Store if we're waiting for login
  bool _isWaitingForLogin = false;

  // Call this before showing login
  void setPendingNavigation(VoidCallback navigationAction) {
    _pendingNavigation = navigationAction;
    _isWaitingForLogin = true;
  }

  // Call this after successful login
  void executePendingNavigation(BuildContext context) {
    if (_isWaitingForLogin && _pendingNavigation != null) {
      // Clear the queue first to prevent re-execution
      final navigationAction = _pendingNavigation;
      _clear();

      // Small delay to ensure login screen is closed
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          navigationAction!();
        }
      });
    }
  }

  // Clear the queue (e.g., when login is cancelled)
  void clear() {
    _clear();
  }

  void _clear() {
    _pendingNavigation = null;
    _isWaitingForLogin = false;
  }

  // Check if there's a pending navigation
  bool get hasPendingNavigation => _isWaitingForLogin;
}