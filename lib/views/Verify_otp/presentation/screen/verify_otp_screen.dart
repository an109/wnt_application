import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/contact_type.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../splash/widgets/auth_scaffold.dart';
import '../../../splash/widgets/social_auth.dart';
import '../../../splash/widgets/wander_logo.dart';
import '../bloc/verify_otp_bloc.dart';
import '../bloc/verify_otp_event.dart';
import '../bloc/verify_otp_state.dart';
import 'complete_profile_screen.dart';

/// The code step of the signup flow.
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.contact,
    required this.contactType,
  });

  final String contact;
  final ContactType contactType;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  /// Length the API issues. The design draws five boxes, but the backend
  /// sends six digits, so six it is.
  static const _otpLength = 6;
  static const _resendCooldown = 30;

  final _formKey = GlobalKey<FormState>();
  String _otpCode = '';

  Timer? _timer;
  int _secondsLeft = _resendCooldown;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _countdown {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isEmail => widget.contactType == ContactType.email;

  void _verifyOtp() {
    if (_otpCode.length != _otpLength) {
      _snack('Please enter the complete code', Colors.orange);
      return;
    }

    context.read<VerifyOtpBloc>().add(
          VerifyOtpRequested(
            contact: widget.contact,
            type: widget.contactType,
            otp: _otpCode,
          ),
        );
  }

  void _resendOtp() {
    if (_secondsLeft > 0) return;

    context.read<SendOtpBloc>().add(
          SendOtpRequested(
            contact: widget.contact,
            type: widget.contactType,
            purpose: 'signup',
          ),
        );
    _startCooldown();
    _snack('Code sent again', Colors.green);
  }

  void _snack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  PinTheme _pinTheme({Color? border, double width = 1}) {
    return PinTheme(
      width: context.w(44),
      height: context.w(44),
      textStyle: TextStyle(
        fontSize: context.fs(20),
        fontWeight: FontWeight.w600,
        color: AppColors.authInk,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.w(8)),
        border: Border.all(
          color: border ?? AppColors.authFieldBorder,
          width: width,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyOtpBloc, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          // Hand over to the profile step, which is a full page of its own.
          final verifyBloc = context.read<VerifyOtpBloc>();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: verifyBloc,
                child: CompleteProfilePopup(
                  contact: widget.contact,
                  contactType: widget.contactType,
                  isVerified: true,
                ),
              ),
            ),
          );
        } else if (state is VerifyOtpFailed) {
          var message = 'Invalid code. Please try again.';
          final error = state.dataState.error;
          if (error?.response?.data != null) {
            message = error!.response!.data['error'] ?? message;
          }
          if (mounted) _snack(message, Colors.red);
        }
      },
      child: AuthScaffold(
        // onBack: () => Navigator.of(context).pop(),
        children: [
          SizedBox(height: context.w(10)),
          Center(child: WanderLogo.still(width: context.w(130))),
          SizedBox(height: context.w(38)),
          Center(
            child: Text(
              'Enter your code',
              style: authDisplayStyle(context, size: 20),
            ),
          ),
          SizedBox(height: context.w(8)),
          Center(
            child: Text(
              'A $_otpLength digit code has been sent to '
              '${_isEmail ? 'your mail' : 'your phone'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w400,
                color: AppColors.authSubtle,
              ),
            ),
          ),
          SizedBox(height: context.w(4)),
          Center(
            child: Text(
              widget.contact,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w400,
                color: AppColors.AppBlue,
              ),
            ),
          ),
          SizedBox(height: context.w(30)),
          Form(
            key: _formKey,
            child: Center(
              child: Pinput(
                length: _otpLength,
                defaultPinTheme: _pinTheme(),
                focusedPinTheme: _pinTheme(border: AppColors.AppBlue, width: 1),
                submittedPinTheme: _pinTheme(border: AppColors.AppBlue, width: 1),
                errorPinTheme: _pinTheme(border: AppColors.OrangeColor),
                mainAxisAlignment: MainAxisAlignment.center,
                separatorBuilder: (_) => SizedBox(width: context.w(8)),
                onChanged: (value) => setState(() => _otpCode = value),
                onCompleted: (pin) {
                  setState(() => _otpCode = pin);
                  _verifyOtp();
                },
              ),
            ),
          ),
          SizedBox(height: context.w(18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _countdown,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.AppBlue,
                ),
              ),
              GestureDetector(
                onTap: _resendOtp,
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: _secondsLeft > 0
                        ? AppColors.authHint
                        : AppColors.AppBlue,
                    color: _secondsLeft > 0
                        ? AppColors.authHint
                        : AppColors.AppBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.w(34)),
          BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
            builder: (context, state) {
              return AuthPrimaryButton(
                label: 'VERIFY CODE',
                isLoading: state is VerifyOtpLoading,
                onPressed: _otpCode.length == _otpLength ? _verifyOtp : null,
              );
            },
          ),
          SizedBox(height: context.w(28)),
          const AuthDivider(label: 'Or'),
          SizedBox(height: context.w(18)),
          const SocialAuthSection(),
        ],
      ),
    );
  }
}
