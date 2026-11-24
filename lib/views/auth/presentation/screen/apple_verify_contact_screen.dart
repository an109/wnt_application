import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../Send_otp/presentation/bloc/send_otp_state.dart';
import '../../../Verify_otp/presentation/bloc/verify_otp_bloc.dart';
import '../../../splash/widgets/auth_scaffold.dart';
import '../../../splash/widgets/wander_logo.dart';
import '../bloc/auth_bloc.dart';
import '../sdk/apple_sign_in_service.dart';
import 'apple_otp_screen.dart';

/// Shown after the native Apple sign-in sheet to collect the user's real
/// email or phone number (Apple often returns a private relay address).
/// After validation it sends an OTP and navigates to [AppleOtpScreen].
class AppleVerifyContactScreen extends StatefulWidget {
  const AppleVerifyContactScreen({super.key, required this.appleResult});

  final AppleSignInResult appleResult;

  @override
  State<AppleVerifyContactScreen> createState() =>
      _AppleVerifyContactScreenState();
}

class _AppleVerifyContactScreenState extends State<AppleVerifyContactScreen> {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;
  bool _triedLogin = false;

  String _contact = '';
  ContactType _contactType = ContactType.email;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() => _error = 'Please enter your email or phone number');
      return;
    }

    final isEmail = value.contains('@');
    if (isEmail && !_emailRegex.hasMatch(value)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    if (!isEmail && !_phoneRegex.hasMatch(value)) {
      setState(() => _error = 'Please enter a valid email or 10-digit phone number');
      return;
    }

    _contact = value;
    _contactType = isEmail ? ContactType.email : ContactType.phone;

    setState(() {
      _error = null;
      _sending = true;
      _triedLogin = false;
    });

    context.read<SendOtpBloc>().add(SendOtpRequested(
          contact: _contact,
          type: _contactType,
          purpose: 'login',
        ));
  }

  void _onOtpSent() {
    setState(() => _sending = false);
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AuthBloc>()),
            BlocProvider.value(value: context.read<SendOtpBloc>()),
            BlocProvider<VerifyOtpBloc>(create: (_) => di.sl<VerifyOtpBloc>()),
          ],
          child: AppleOtpScreen(
            appleResult: widget.appleResult,
            contact: _contact,
            contactType: _contactType,
          ),
        ),
      ),
    ).then((authenticated) {
      if (authenticated == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendOtpBloc, SendOtpState>(
      listener: (context, state) {
        if (!_sending) return;
        if (state is SendOtpSuccess) {
          _onOtpSent();
        } else if (state is SendOtpFailed) {
          if (!_triedLogin) {
            _triedLogin = true;
            context.read<SendOtpBloc>().add(SendOtpRequested(
                  contact: _contact,
                  type: _contactType,
                  purpose: 'signup',
                ));
            return;
          }
          setState(() => _sending = false);
          _snack('Failed to send code. Please try again.', Colors.red);
        }
      },
      child: AuthScaffold(
        onBack: () => Navigator.of(context).pop(false),
        children: [
          SizedBox(height: context.w(10)),
          Center(child: WanderLogo.still(width: context.w(130))),
          SizedBox(height: context.w(38)),
          Center(
            child: Text(
              'Almost there!',
              style: authDisplayStyle(context, size: 20),
            ),
          ),
          SizedBox(height: context.w(8)),
          Center(
            child: Text(
              'Enter your email or phone number to\ncomplete sign-in',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(12),
                color: AppColors.authSubtle,
              ),
            ),
          ),
          SizedBox(height: context.w(32)),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            cursorColor: AppColors.AppBlue,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w600,
              color: AppColors.authInk,
            ),
            decoration: authFieldDecoration(
              context,
              label: 'EMAIL OR PHONE',
              hintText: 'you@example.com or 9876543210',
              icon: Icons.person_outline,
              hasError: _error != null,
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: context.w(8)),
            Text(
              _error!,
              style: TextStyle(fontSize: context.fs(11), color: Colors.red),
            ),
          ],
          SizedBox(height: context.w(32)),
          AuthPrimaryButton(
            label: 'SEND CODE',
            isLoading: _sending,
            onPressed: _sending ? null : _submit,
          ),
        ],
      ),
    );
  }
}
