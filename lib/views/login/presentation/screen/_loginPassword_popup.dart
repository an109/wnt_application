import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart'; // ← PreferencesManager
import '../../../../injection_container.dart' as di; // ← GetIt
import '../../../home/presentation/screens/home_screen.dart';
import '../bloc/login_bloc.dart'; // ← LoginBloc
import '../bloc/login_event.dart'; // ← LoginEvent
import '../bloc/login_state.dart'; // ← LoginState
import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../Send_otp/presentation/bloc/send_otp_state.dart';
import '../../../Verify_otp/presentation/bloc/verify_otp_bloc.dart';
import '../../../Verify_otp/presentation/bloc/verify_otp_event.dart';
import '../../../Verify_otp/presentation/bloc/verify_otp_state.dart';
import '../../../ResetPassword/presentation/bloc/reset_password_bloc.dart';
import '../../../ResetPassword/presentation/bloc/reset_password_event.dart';
import '../../../ResetPassword/presentation/bloc/reset_password_state.dart';
import '../../../../main.dart'; // ← HomeScreen import (adjust path if needed)

enum _ForgotStage { none, email, otp, newPassword }

class LoginPasswordPopup extends StatefulWidget {
  final String contact;
  final ContactType contactType;

  const LoginPasswordPopup({
    super.key,
    required this.contact,
    required this.contactType,
  });

  @override
  State<LoginPasswordPopup> createState() => _LoginPasswordPopupState();
}

class _LoginPasswordPopupState extends State<LoginPasswordPopup> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final LoginBloc _loginBloc; // ← Local LoginBloc instance

  // ← Forgot password flow
  late final SendOtpBloc _sendOtpBloc;
  late final VerifyOtpBloc _verifyOtpBloc;
  late final ResetPasswordBloc _resetPasswordBloc;

  _ForgotStage _forgotStage = _ForgotStage.none;
  final _forgotEmailController = TextEditingController();
  String? _forgotEmailError;
  String _otpCode = '';
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _newPasswordFieldError;

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    // ← Initialize LoginBloc with dependency injection
    _loginBloc = di.sl<LoginBloc>();
    _sendOtpBloc = di.sl<SendOtpBloc>();
    _verifyOtpBloc = di.sl<VerifyOtpBloc>();
    _resetPasswordBloc = di.sl<ResetPasswordBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _loginBloc),
        BlocProvider.value(value: _sendOtpBloc),
        BlocProvider.value(value: _verifyOtpBloc),
        BlocProvider.value(value: _resetPasswordBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<LoginBloc, LoginState>( // ← Listen to LoginState (not AuthState)
            listener: (context, state) {
              if (state is LoginSuccess) {
                // ← Save tokens and user data using PreferencesManager
                _saveUserDataAndNavigate(state.loginEntity);
              } else if (state is LoginFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is LoginValidationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.field}: ${state.message}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          BlocListener<SendOtpBloc, SendOtpState>(
            listener: (context, state) {
              if (state is SendOtpSuccess) {
                setState(() => _forgotStage = _ForgotStage.otp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.sendOtpEntity.message.isNotEmpty
                          ? state.sendOtpEntity.message
                          : 'Verification code sent to your email',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is SendOtpFailed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_extractError(state.dataState, 'Failed to send verification code. Please try again.')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<VerifyOtpBloc, VerifyOtpState>(
            listener: (context, state) {
              if (state is VerifyOtpSuccess) {
                setState(() => _forgotStage = _ForgotStage.newPassword);
              } else if (state is VerifyOtpFailed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_extractError(state.dataState, 'Invalid verification code. Please try again.')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<ResetPasswordBloc, ResetPasswordState>(
            listener: (context, state) {
              if (state is ResetPasswordSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.resetPasswordEntity.message.isNotEmpty
                          ? state.resetPasswordEntity.message
                          : 'Password reset successful. Please login with your new password.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _resetForgotFlow();
              } else if (state is ResetPasswordFailed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_extractError(state.dataState, 'Failed to reset password. Please try again.')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Full screen blur (unchanged)
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: context.wp(3),
                  sigmaY: context.wp(3),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                ),
              ),

              // Popup content (unchanged UI)
              SafeArea(
                child: Center(
                  child: Container(
                    width: context.wp(90),
                    constraints: BoxConstraints(
                      maxHeight: context.hp(_forgotStage == _ForgotStage.none ? 60 : 78),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.borderRadiusLarge + 6),
                    ),
                    child: SingleChildScrollView(
                      physics: context.scrollPhysics,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.wp(5),
                          vertical: context.hp(2),
                        ),
                        child: _buildStageContent(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(BuildContext context) {
    switch (_forgotStage) {
      case _ForgotStage.none:
        return _buildLoginStage(context);
      case _ForgotStage.email:
        return _buildForgotEmailStage(context);
      case _ForgotStage.otp:
        return _buildForgotOtpStage(context);
      case _ForgotStage.newPassword:
        return _buildForgotNewPasswordStage(context);
    }
  }

  // ============================================================
  // LOGIN STAGE (unchanged UI)
  // ============================================================
  Widget _buildLoginStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TOP ROW (unchanged)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: context.wp(70)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: context.hp(4.5),
                width: context.hp(4.5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: context.iconMedium,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: context.hp(2.5)),

        // Title (unchanged)
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: context.sp(22),
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(0.8)),

        // Subtitle (unchanged)
        Text(
          'Enter your password for\n${widget.contact}',
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(3)),

        // Password Field (unchanged)
        Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: context.hp(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: context.sp(15)),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.wp(4),
                      vertical: context.hp(2),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade500,
                        size: context.iconSmall,
                      ),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.hp(2)),

              // Login Button (UPDATED)
              BlocBuilder<LoginBloc, LoginState>( // ← Use LoginBloc
                builder: (context, state) {
                  final isLoading = state is LoginLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: context.hp(6),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                        height: context.hp(3),
                        width: context.hp(3),
                        child: CircularProgressIndicator(
                          strokeWidth: context.dividerThin,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Login',
                        style: TextStyle(
                          fontSize: context.sp(18),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        SizedBox(height: context.hp(2)),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 1: ENTER EMAIL
  // ============================================================
  Widget _buildForgotEmailStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStageTopRow(context, onBack: () => setState(() => _forgotStage = _ForgotStage.none)),

        SizedBox(height: context.hp(2.5)),

        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: context.sp(22),
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(0.8)),

        Text(
          'Enter your registered email to receive\na verification code',
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(3)),

        Container(
          height: context.hp(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          ),
          child: TextField(
            controller: _forgotEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: context.sp(15)),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(2),
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.grey.shade500,
                size: context.iconSmall,
              ),
            ),
          ),
        ),

        if (_forgotEmailError != null) ...[
          SizedBox(height: context.hp(0.8)),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _forgotEmailError!,
              style: TextStyle(
                color: Colors.red,
                fontSize: context.sp(11),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        SizedBox(height: context.hp(2.5)),

        BlocBuilder<SendOtpBloc, SendOtpState>(
          builder: (context, state) {
            final isLoading = state is SendOtpLoading;
            return SizedBox(
              width: double.infinity,
              height: context.hp(6),
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendForgotOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                  height: context.hp(3),
                  width: context.hp(3),
                  child: CircularProgressIndicator(
                    strokeWidth: context.dividerThin,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Send Verification Code',
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: context.hp(2)),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 2: VERIFY OTP (pinput)
  // ============================================================
  Widget _buildForgotOtpStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStageTopRow(context, onBack: () => setState(() => _forgotStage = _ForgotStage.email)),

        SizedBox(height: context.hp(2.5)),

        Text(
          'Verify Your Email',
          style: TextStyle(
            fontSize: context.sp(22),
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(0.8)),

        Text(
          'Enter the 6-digit code sent to\n${_forgotEmailController.text.trim()}',
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(3)),

        Pinput(
          length: 6,
          defaultPinTheme: PinTheme(
            width: context.wp(11),
            height: context.hp(7),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            textStyle: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
          focusedPinTheme: PinTheme(
            width: context.wp(11),
            height: context.hp(7),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            textStyle: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
          submittedPinTheme: PinTheme(
            width: context.wp(11),
            height: context.hp(7),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
            textStyle: TextStyle(
              fontSize: context.titleMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
          errorPinTheme: PinTheme(
            width: context.wp(11),
            height: context.hp(7),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(context.borderRadiusMedium),
            ),
          ),
          onChanged: (value) => setState(() => _otpCode = value),
          onCompleted: (pin) {
            setState(() => _otpCode = pin);
            _verifyForgotOtp();
          },
        ),

        SizedBox(height: context.hp(2)),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(
                fontSize: context.sp(13),
                color: Colors.grey.shade600,
              ),
            ),
            BlocBuilder<SendOtpBloc, SendOtpState>(
              builder: (context, state) {
                final isResending = state is SendOtpLoading;
                return TextButton(
                  onPressed: isResending ? null : _sendForgotOtp,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Resend',
                    style: TextStyle(
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        SizedBox(height: context.hp(2)),

        BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
          builder: (context, state) {
            final isLoading = state is VerifyOtpLoading;
            return SizedBox(
              width: double.infinity,
              height: context.hp(6),
              child: ElevatedButton(
                onPressed: (isLoading || _otpCode.length != 6) ? null : _verifyForgotOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                  height: context.hp(3),
                  width: context.hp(3),
                  child: CircularProgressIndicator(
                    strokeWidth: context.dividerThin,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Verify Code',
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: context.hp(2)),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 3: NEW PASSWORD + CONFIRM
  // ============================================================
  Widget _buildForgotNewPasswordStage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStageTopRow(context, onBack: () => setState(() => _forgotStage = _ForgotStage.otp)),

        SizedBox(height: context.hp(2.5)),

        Text(
          'Set New Password',
          style: TextStyle(
            fontSize: context.sp(22),
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(0.8)),

        Text(
          'Create a new password for\n${_forgotEmailController.text.trim()}',
          style: TextStyle(
            fontSize: context.sp(12),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.hp(3)),

        Container(
          height: context.hp(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          ),
          child: TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: TextStyle(fontSize: context.sp(15)),
            decoration: InputDecoration(
              hintText: 'New password',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(2),
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade500,
                  size: context.iconSmall,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: context.hp(1.5)),

        Container(
          height: context.hp(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(context.borderRadiusMedium),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(fontSize: context.sp(15)),
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(2),
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade500,
                  size: context.iconSmall,
                ),
              ),
            ),
          ),
        ),

        if (_newPasswordFieldError != null) ...[
          SizedBox(height: context.hp(0.8)),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _newPasswordFieldError!,
              style: TextStyle(
                color: Colors.red,
                fontSize: context.sp(11),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        SizedBox(height: context.hp(2.5)),

        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
          builder: (context, state) {
            final isLoading = state is ResetPasswordLoading;
            return SizedBox(
              width: double.infinity,
              height: context.hp(6),
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                  height: context.hp(3),
                  width: context.hp(3),
                  child: CircularProgressIndicator(
                    strokeWidth: context.dividerThin,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: context.hp(2)),
      ],
    );
  }

  // Shared top row for every forgot-password step: back arrow + close button.
  Widget _buildStageTopRow(BuildContext context, {required VoidCallback onBack}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            height: context.hp(4.5),
            width: context.hp(4.5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              size: context.iconMedium,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: context.hp(4.5),
            width: context.hp(4.5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: context.iconMedium,
            ),
          ),
        ),
      ],
    );
  }

  void _openForgotPassword() {
    if (widget.contactType == ContactType.email) {
      _forgotEmailController.text = widget.contact;
    }
    setState(() => _forgotStage = _ForgotStage.email);
  }

  void _sendForgotOtp() {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _forgotEmailError = 'Please enter a valid email address');
      return;
    }
    setState(() => _forgotEmailError = null);

    _sendOtpBloc.add(
      SendOtpRequested(
        contact: email,
        type: ContactType.email,
        purpose: 'login',
      ),
    );
  }

  void _verifyForgotOtp() {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete verification code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _verifyOtpBloc.add(
      VerifyOtpRequested(
        contact: _forgotEmailController.text.trim(),
        type: ContactType.email,
        otp: _otpCode,
      ),
    );
  }

  void _submitNewPassword() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _newPasswordFieldError = 'Password must be at least 6 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _newPasswordFieldError = 'Passwords do not match');
      return;
    }
    setState(() => _newPasswordFieldError = null);

    _resetPasswordBloc.add(
      ResetPasswordRequested(
        email: _forgotEmailController.text.trim(),
        otp: _otpCode,
        newPassword: newPassword,
      ),
    );
  }

  void _resetForgotFlow() {
    setState(() {
      _forgotStage = _ForgotStage.none;
      _forgotEmailError = null;
      _otpCode = '';
      _newPasswordFieldError = null;
      _forgotEmailController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _passwordController.clear();
    });
    _sendOtpBloc.add(const SendOtpReset());
    _verifyOtpBloc.add(const VerifyOtpReset());
    _resetPasswordBloc.add(const ResetPasswordReset());
  }

  String _extractError(DataState<dynamic> dataState, String fallback) {
    final data = dataState.error?.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }

  // ← NEW: Handle login API call
  void _login() {
    final password = _passwordController.text.trim();

    // ← Trigger LoginBloc event with contact + password
    _loginBloc.add(
      LoginSubmitted(
        contactValue: widget.contact,
        password: password,
        contactType: widget.contactType.fieldName, // Uses your ContactType extension
      ),
    );
  }

  // ← NEW: Save user data and navigate to HomeScreen
  Future<void> _saveUserDataAndNavigate(loginEntity) async {
    final prefs = di.sl<PreferencesManager>();

    print('LOGIN DEBUG: access token = ${loginEntity.tokens.access?.isNotEmpty == true ? 'EXISTS' : 'NULL/EMPTY'}');

    // Save tokens
    if (loginEntity.tokens.access != null) {
      await prefs.saveToken(loginEntity.tokens.access!);
      print('LOGIN DEBUG: Token saved successfully');
    }
    if (loginEntity.tokens.refresh != null) {
      await prefs.saveRefreshToken(loginEntity.tokens.refresh!);
    }

    // Save user data
    final userData = {
      'id': loginEntity.user.id,
      'firstname': loginEntity.user.firstname,
      'lastname': loginEntity.user.lastname,
      'email': loginEntity.user.email,
      'phone_code': loginEntity.user.phoneCode,
      'phone_number': loginEntity.user.phoneNumber,
      'platform': loginEntity.user.platform,
    };
    await prefs.saveUserData(userData);
    await prefs.saveIsSocialLogin(false);
    await prefs.saveUserPassword(_passwordController.text);

    // Save additional fields if needed
    if (loginEntity.user.id != null) {
      await prefs.saveUserId(loginEntity.user.id!);
    }
    if (loginEntity.user.email != null) {
      await prefs.saveUserEmail(loginEntity.user.email!);
    }
    final fullName = '${loginEntity.user.firstname ?? ''} ${loginEntity.user.lastname ?? ''}'.trim();
    if (fullName.isNotEmpty) {
      await prefs.saveUserName(fullName);
    }

    print('Login successful: User data saved');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Login Successful',
          style: TextStyle(fontSize: context.bodyMedium),
        ),
        backgroundColor: Colors.red,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop(); // Close popup
      Navigator.of(context).pop(); // Close LoginSignupScreen dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _loginBloc.close(); // ← Close Bloc to free resources
    _sendOtpBloc.close();
    _verifyOtpBloc.close();
    _resetPasswordBloc.close();
    super.dispose();
  }
}
