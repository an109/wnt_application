import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../../UI_helper/responsive_layout.dart';
import '../../core/utils/storage/shared_preference.dart';
import '../home/presentation/screens/home_screen.dart';
import '../login/presentation/screen/login.dart';
import 'screen/choose_country_screen.dart';
import 'widgets/wander_logo.dart';

/// Cross-fade between the screens of the splash flow.
PageRouteBuilder<void> fadeRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, animation, __) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: page,
    ),
  );
}

/// Where the splash flow can send the user.
enum SplashDestination { home, country, login }

/// True when a signed-in session is already on the device.
///
/// This reads storage rather than [AuthBloc], deliberately. The bloc is a
/// factory behind a lazy provider, so the first `read` of it is also what
/// constructs it — its own startup check has not been handled yet at that
/// point, the state is still [AuthInitial], and a signed-in user would be
/// sent to the login screen. The condition here is the same one
/// `AuthCheckStatusRequested` applies.
bool hasStoredSession() {
  final prefs = di.sl<PreferencesManager>();
  return prefs.isLoggedIn() &&
      prefs.getUserData() != null &&
      prefs.getToken() != null;
}

/// Decides where the splash hands off to. Signed-in users go straight to the
/// home screen — the country step is first-run onboarding, not a gate.
SplashDestination splashDestination() {
  if (hasStoredSession()) return SplashDestination.home;
  if (di.sl<PreferencesManager>().getSelectedCountry() == null) {
    return SplashDestination.country;
  }
  return SplashDestination.login;
}

/// Where the app goes once the splash flow is done: straight to the home
/// screen for a session we already have, otherwise the login gate, which is
/// the only way through.
void continuePastSplash(BuildContext context) {
  Navigator.of(context).pushReplacement(
    fadeRoute(
      hasStoredSession()
          ? const HomeScreen()
          : const LoginSignupScreen(isGate: true),
    ),
  );
}

/// Entry screen. Builds the Wander Nova mark a stroke at a time, then hands
/// off: straight to the home screen for a user we already have a session for,
/// otherwise to the login/signup gate, which is the only way through.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _buildDuration = Duration(milliseconds: 2000);
  static const _hold = Duration(milliseconds: 380);

  late final AnimationController _controller;
  bool _started = false;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _buildDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    // Decode the logo slices before the first frame of the build, but never
    // let a slow decode hold the splash hostage.
    await Future.any([
      WanderLogoLayers.precache(context),
      Future<void>.delayed(const Duration(milliseconds: 800)),
    ]);
    if (!mounted) return;

    // The splash is idle for a couple of seconds — spend it pulling the home
    // screen's hero photo into the decoded-image cache.
    HomeHeroBanner.warmUp(context);

    await _controller.forward();
    await Future<void>.delayed(_hold);
    if (!mounted) return;
    _routeOnward();
  }

  void _routeOnward() {
    if (_routed) return;
    _routed = true;

    switch (splashDestination()) {
      case SplashDestination.home:
      case SplashDestination.login:
        continuePastSplash(context);
      case SplashDestination.country:
        Navigator.of(context).pushReplacement(
          fadeRoute(ChooseCountryScreen(onContinue: continuePastSplash)),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Center(
          child: Hero(
            tag: WanderLogo.heroTag,
            child: WanderLogo(
              width: context.w(190),
              progress: _controller,
            ),
          ),
        ),
      ),
    );
  }
}
