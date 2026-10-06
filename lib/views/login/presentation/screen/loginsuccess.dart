import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../UI_helper/navigation_queue.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../newUIWidgets/FooterImage.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../splash/widgets/auth_scaffold.dart';

/// Confirmation played after a login or a signup lands.
///
/// The sequence follows the design: the brand blue floods the screen, draws
/// itself back down into the badge, the tick appears in place, then a sheen
/// sweeps across the copy as it rises.
class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({
    super.key,
    this.isGate = false,
    this.title = 'Successful !',
    this.message =
        'Congratulations! Your password has been created. Click continue to book',
  });

  /// True when the auth flow started at the splash gate: there is nothing
  /// behind this screen to go back to, so it opens the home screen itself.
  final bool isGate;

  final String title;
  final String message;

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // flood → collapse → tick → sheen + copy → button
  late final Animation<double> _flood;
  late final Animation<double> _collapse;
  late final Animation<double> _tick;
  late final Animation<double> _copy;
  late final Animation<double> _sheen;
  late final Animation<double> _action;

  bool _resumed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    Animation<double> at(double begin, double end, Curve curve) {
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );
    }

    _flood = at(0.00, 0.26, Curves.easeOutCubic);
    _collapse = at(0.26, 0.54, Curves.easeInOutCubic);
    _tick = at(0.50, 0.66, Curves.easeOut);
    _copy = at(0.62, 0.84, Curves.easeOutQuint);
    _sheen = at(0.66, 0.96, Curves.easeInOut);
    _action = at(0.82, 1.00, Curves.easeOutQuint);

    _controller.addStatusListener(_onDone);
  }

  /// Something was waiting on this sign-in (a booking, a visa form, …).
  /// Resume it rather than making the user tap through to the home screen.
  void _onDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || _resumed) return;
    if (!NavigationQueueService().hasPendingNavigation) return;

    _resumed = true;
    NavigationQueueService().executePendingNavigation(context);
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
  }

  void _goHome() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onDone);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = context.w(132);
    final media = MediaQuery.of(context).size;
    // How far the flood has to grow to clear the furthest corner.
    final coverScale =
        math.sqrt(media.width * media.width + media.height * media.height) /
            badge;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                const Spacer(flex: 4),
                _buildBadge(badge, coverScale),
                SizedBox(height: context.w(34)),
                _buildCopy(),
                SizedBox(height: context.w(34)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                  child: _rise(
                    _action,
                    AuthPrimaryButton(
                      label: 'GO TO HOME',
                      onPressed: _goHome,
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                _rise(_action, const AuthFooterBadge()),
                SizedBox(height: context.w(16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The disc that floods the screen and then draws back down into the ring.
  Widget _buildBadge(double size, double coverScale) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final grow = _flood.value;
        final shrink = _collapse.value;

        // Full-screen at the peak, badge-sized once it has drawn back in.
        final scale = grow * (coverScale - (coverScale - 1) * shrink);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      AppColors.AppBlue,
                      const Color(0xFFEAF7FE),
                      shrink,
                    ),
                    border: Border.all(
                      color: AppColors.AppBlue.withOpacity(shrink),
                      width: 3 * shrink,
                    ),
                  ),
                ),
              ),
              // The tick never scales — it fades in where it belongs.
              Opacity(
                opacity: _tick.value.clamp(0.0, 1.0),
                child: child,
              ),
            ],
          ),
        );
      },
      child: Image.asset(
        'assets/NewIcons/tick.png',
        width: size * 0.46,
        height: size * 0.46,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildCopy() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(28)),
      child: _rise(
        _copy,
        _Sheen(
          progress: _sheen,
          child: Column(
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: authDisplayStyle(context, size: 24),
              ),
              SizedBox(height: context.w(10)),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: AppColors.authSubtle,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rise(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, context.w(16) * (1 - t)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}

/// Sweeps a soft highlight across its child, once.
///
/// Painted over the child rather than masked into it: a mask with transparent
/// stops would rub out whatever sits outside the band.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.progress, required this.child});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final t = progress.value;
                if (t <= 0 || t >= 1) return const SizedBox.shrink();

                // Band travels from off the left edge to off the right.
                final centre = (t * 1.6) - 0.3;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.72),
                        Colors.white.withOpacity(0),
                      ],
                      stops: [
                        (centre - 0.16).clamp(0.0, 1.0),
                        centre.clamp(0.0, 1.0),
                        (centre + 0.16).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
