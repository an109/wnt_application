import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/auth_guard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../../../core/utils/storage/shared_preference.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../auth/presentation/screen/apple_verify_contact_screen.dart';
import '../../auth/presentation/sdk/apple_sign_in_service.dart';
import '../../auth/presentation/sdk/google_sign_in_service.dart';
import '../../login/presentation/screen/loginsuccess.dart';
import 'auth_scaffold.dart';

/// The "Or … with" Google / Apple row, together with the sign-in calls and
/// the listener that moves on once the bloc reports a session.
///
/// Both the login screen and the verify screen show this row, so the listener
/// only acts when its own route is on top — otherwise one successful sign-in
/// would be handled twice.
class SocialAuthSection extends StatefulWidget {
  const SocialAuthSection({super.key, this.isGate = false});

  final bool isGate;

  @override
  State<SocialAuthSection> createState() => _SocialAuthSectionState();
}

class _SocialAuthSectionState extends State<SocialAuthSection> {
  late final GoogleSignInService _googleSignInService;
  late final AppleSignInService _appleSignInService;

  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignInService = di.sl<GoogleSignInService>();
    _appleSignInService = di.sl<AppleSignInService>();
  }

  bool get _isTopRoute => ModalRoute.of(context)?.isCurrent ?? false;

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await _googleSignInService.signOut();
      final String? idToken = await _googleSignInService.signIn();

      if (idToken == null) {
        if (mounted) _snack('Sign-in cancelled', Colors.orange);
        return;
      }
      if (mounted) context.read<AuthBloc>().add(GoogleLoginRequested(idToken));
    } catch (e) {
      debugPrint('SocialAuth: Google Sign-In error: $e');
      if (mounted) _snack('Google sign-in failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isAppleLoading) return;

    // Native Sign in with Apple is only available on Apple platforms; on
    // Android it needs a web redirect flow, so guard against a crash.
    if (!Platform.isIOS && !Platform.isMacOS) {
      _snack('Apple Sign-In is available on iOS devices only', Colors.orange);
      return;
    }

    setState(() => _isAppleLoading = true);

    try {
      final available = await _appleSignInService.isAvailable();
      if (!available) {
        if (mounted) {
          _snack('Apple Sign-In is not available on this device', Colors.orange);
        }
        return;
      }

      final result = await _appleSignInService.signIn();
      if (result == null) {
        if (mounted) _snack('Sign-in cancelled', Colors.orange);
        return;
      }

      if (mounted) {
        Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider<SendOtpBloc>(create: (_) => di.sl<SendOtpBloc>()),
              ],
              child: AppleVerifyContactScreen(appleResult: result),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('SocialAuth: Apple Sign-In error: $e');
      if (mounted) _snack('Apple sign-in failed. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  void _onAuthenticated(AuthAuthenticated state) {
    // AuthBloc._persistAndEmit already saved token, refreshToken, and userData.
    // Only save the separately-keyed userId/userEmail that payment screens read,
    // using the DI singleton to avoid racing with the bloc's writes.
    final prefs = di.sl<PreferencesManager>();
    final parsedId = int.tryParse(state.user.id.toString());
    if (parsedId != null) {
      prefs.saveUserId(parsedId);
    }
    final email = state.user.email.trim();
    if (email.isNotEmpty) {
      prefs.saveUserEmail(email);
    }
    final name = (state.user.name ?? '').toString().trim();
    if (name.isNotEmpty) {
      prefs.saveUserName(name);
    }

    if (AuthReturn.tryReturn()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginSuccessScreen(isGate: widget.isGate),
      ),
    );
  }

  void _snack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!_isTopRoute) return;
        if (state is AuthAuthenticated) {
          _onAuthenticated(state);
        } else if (state is AuthError) {
          _snack(state.message, Colors.red);
        }
      },
      child: AuthSocialRow(
        onGoogle: _handleGoogleSignIn,
        onApple: _handleAppleSignIn,
        isGoogleLoading: _isGoogleLoading,
        isAppleLoading: _isAppleLoading,
        showApple: Platform.isIOS || Platform.isMacOS,
      ),
    );
  }
}
