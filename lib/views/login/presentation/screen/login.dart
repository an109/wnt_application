import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../Send_otp/presentation/bloc/send_otp_state.dart';
import '../../../Verify_otp/presentation/screen/verify_otp_screen.dart';
import '../../../splash/widgets/auth_scaffold.dart';
import '../../../splash/widgets/social_auth.dart';
import '../../../splash/widgets/wander_logo.dart';
import '_loginPassword_popup.dart';

/// Login / signup, as one screen with one action.
///
/// The button sends an OTP; if the API comes back saying the account already
/// exists, we hand straight over to the password popup instead. That keeps
/// both of the app's existing entry paths behind the single button the design
/// asks for.
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key, this.isGate = false});

  /// True when this screen is the app's entry gate (reached from the splash).
  /// A gate has nothing to go back to, so it hides the close affordance and
  /// sends the user to the home screen once they are through.
  final bool isGate;

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  AuthDial _dial = AuthDial.india;
  bool _isSendingOtp = false;
  String? _inlineError;

  /// Which field the current error belongs to. Null while an error applies to
  /// both (nothing filled in at all).
  ContactType? _errorField;

  // The contact the in-flight OTP request was made with.
  String? _submittedContact;
  ContactType? _submittedType;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canClose => !widget.isGate && Navigator.of(context).canPop();

  // ------------------------------------------------------------- behaviour

  bool get _emailHasError =>
      _inlineError != null &&
      (_errorField == null || _errorField == ContactType.email);

  bool get _phoneHasError =>
      _inlineError != null &&
      (_errorField == null || _errorField == ContactType.phone);

  void _clearError() {
    if (_inlineError != null) {
      setState(() {
        _inlineError = null;
        _errorField = null;
      });
    }
  }

  void _fail(String message, ContactType? field) {
    setState(() {
      _inlineError = message;
      _errorField = field;
    });
  }

  /// Either field on its own is enough. When both are filled the email is
  /// used, because the code that follows is worded as going to your mail.
  void _submit() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    String contact;
    ContactType type;

    if (email.isNotEmpty) {
      if (!_emailRegex.hasMatch(email)) {
        _fail('Please enter a valid email address', ContactType.email);
        return;
      }
      contact = email;
      type = ContactType.email;
    } else if (phone.isNotEmpty) {
      final isValid = _dial.code == '+91'
          ? _indianPhoneRegex.hasMatch(phone)
          : RegExp(r'^\d{6,15}$').hasMatch(phone);
      if (!isValid) {
        _fail('Please enter a valid mobile number', ContactType.phone);
        return;
      }
      contact = phone;
      type = ContactType.phone;
    } else {
      _fail('Enter your email address or your mobile number', null);
      return;
    }

    setState(() {
      _inlineError = null;
      _errorField = null;
      _isSendingOtp = true;
      _submittedContact = contact;
      _submittedType = type;
    });

    context.read<SendOtpBloc>().add(
          SendOtpRequested(contact: contact, type: type, purpose: 'signup'),
        );
  }

  void _onOtpSent() {
    setState(() => _isSendingOtp = false);
    final contact = _submittedContact;
    final type = _submittedType;
    if (contact == null || type == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(contact: contact, contactType: type),
      ),
    );
  }

  void _onOtpFailed(SendOtpFailed state) {
    setState(() => _isSendingOtp = false);

    String message = 'Failed to send OTP';
    var userExists = false;

    final data = state.dataState.error?.response?.data;
    if (data is Map) {
      message = (data['error'] ?? data['message'] ?? message).toString();
      userExists = data['user_exists'] == true;
    }

    if (userExists && _submittedContact != null && _submittedType != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPasswordPopup(
            contact: _submittedContact!,
            contactType: _submittedType!,
          ),
        ),
      );
      return;
    }

    _fail(message, _submittedType);
  }

  // ----------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendOtpBloc, SendOtpState>(
          // The OTP bloc is app-wide, and the verify screen resends through it
          // too. Only react while our own request is in flight, so a resend
          // from the screen above does not push a second verify screen.
          listener: (context, state) {
            if (!_isSendingOtp) return;
            if (state is SendOtpSuccess) {
              _onOtpSent();
            } else if (state is SendOtpFailed) {
              _onOtpFailed(state);
            }
          },
          child: Stack(
        children: [
          AuthScaffold(
            children: [
              SizedBox(height: context.w(_canClose ? 12 : 30)),
              Center(child: WanderLogo.still(width: context.w(130))),
              SizedBox(height: context.w(46)),
              Center(
                child: Text(
                  'Hi, Traveller! 👋',
                  style: authDisplayStyle(context, size: 20),
                ),
              ),
              SizedBox(height: context.w(6)),
              Center(
                child: Text(
                  'Login or Signup',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w400,
                    color: AppColors.AppBlue,
                  ),
                ),
              ),
              SizedBox(height: context.w(42)),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.AppBlue,
                onChanged: (_) => _clearError(),
                style: TextStyle(
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w600,
                  color: AppColors.authInk,
                ),
                decoration: authFieldDecoration(
                  context,
                  label: 'EMAIL ADDRESS',
                  hintText: 'you@example.com',
                  icon: Icons.mail,
                  hasError: _emailHasError,
                ),
              ),
              SizedBox(height: context.w(12)),
              Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.authHint,
                  ),
                ),
              ),
              SizedBox(height: context.w(12)),
              AuthPhoneRow(
                dial: _dial,
                controller: _phoneController,
                hasError: _phoneHasError,
                onChanged: (_) => _clearError(),
                onDialTap: () async {
                  final picked = await showAuthDialPicker(context);
                  if (picked != null && mounted) setState(() => _dial = picked);
                },
              ),
              if (_inlineError != null) ...[
                SizedBox(height: context.w(10)),
                _InlineError(message: _inlineError!),
              ],
              SizedBox(height: context.w(36)),
              AuthPrimaryButton(
                label: 'LOGIN OR SIGNUP',
                isLoading: _isSendingOtp,
                onPressed: _submit,
              ),
              SizedBox(height: context.w(26)),
              const AuthDivider(label: 'Or Login/Signup with'),
              SizedBox(height: context.w(12)),
              SocialAuthSection(isGate: widget.isGate),
              SizedBox(height: context.w(20)),
              // const _TermsLine(),
            ],
          ),
          // if (_canClose)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top + context.w(8),
          //     right: context.w(16),
          //     child: GestureDetector(
          //       onTap: () => Navigator.of(context).pop(),
          //       child: Container(
          //         height: context.w(34),
          //         width: context.w(34),
          //         decoration: const BoxDecoration(
          //           color: Color(0xFFF4F4F5),
          //           shape: BoxShape.circle,
          //         ),
          //         child: Icon(
          //           Icons.close,
          //           size: context.w(18),
          //           color: AppColors.authInk,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: context.w(16),
          color: AppColors.OrangeColor,
        ),
        SizedBox(width: context.w(6)),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: context.fs(12.5),
              color: AppColors.OrangeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsLine extends StatelessWidget {
  const _TermsLine();

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(color: AppColors.AppBlue, fontSize: context.fs(11));

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: context.fs(9), color: AppColors.authSubtle),
        children: [
          const TextSpan(text: 'By proceeding, you agree with our '),
          TextSpan(text: 'Terms of service', style: link),
          const TextSpan(text: ', '),
          TextSpan(text: 'privacy policy', style: link),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Master User Agreement.', style: link),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
