import 'package:flutter/material.dart';

import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart' as di;
import '../views/login/presentation/screen/login.dart';
import 'navigation_queue.dart';

/// Browsing is open to guests (App Store 5.1.1(v)); only booking, payment and
/// account features ask for a sign-in, via [requireLogin].
bool isUserLoggedIn() {
  final prefs = di.sl<PreferencesManager>();
  return prefs.isLoggedIn() && prefs.getToken() != null;
}

/// Runs [action] straight away for a signed-in user. Otherwise opens login and
/// runs [action] once the user is back on this screen, signed in.
void requireLogin(BuildContext context, VoidCallback action) {
  if (isUserLoggedIn()) {
    action();
    return;
  }
  NavigationQueueService().setPendingNavigation(action);
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const LoginSignupScreen()))
      .then((_) => NavigationQueueService().clear());
}

/// Opens login and reports whether the user came back signed in. For "Log-In
/// to Book" buttons: the screen just rebuilds and the button turns into pay.
Future<bool> openLogin(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
  );
  return isUserLoggedIn();
}

/// Tracks a login screen opened from inside the app (not the splash gate), so
/// a finished sign-in can return there instead of resetting to home.
class AuthReturn {
  AuthReturn._();

  static Route<dynamic>? _loginRoute;

  static void register(Route<dynamic>? route) => _loginRoute = route;

  static void unregister(Route<dynamic>? route) {
    if (identical(_loginRoute, route)) _loginRoute = null;
  }

  /// Closes the in-app login flow and resumes whatever was waiting on it.
  /// Returns false when login was not opened in-app (e.g. the splash gate) —
  /// the caller then keeps its own post-login navigation.
  static bool tryReturn() {
    final route = _loginRoute;
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return false;
    _loginRoute = null;

    final pending = NavigationQueueService().takePending();
    navigator.popUntil((r) => r == route);
    navigator.pop();

    ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
      const SnackBar(
        content: Text('Logged in successfully'),
        backgroundColor: Colors.green,
      ),
    );
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pending());
    }
    return true;
  }
}
