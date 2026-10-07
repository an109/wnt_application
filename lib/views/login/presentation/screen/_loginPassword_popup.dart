import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart'; // ← PreferencesManager
import '../../../../injection_container.dart' as di; // ← GetIt
import '../../../splash/widgets/auth_scaffold.dart';
import 'loginsuccess.dart';
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
        child: _buildStage(context),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
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

  /// Heading pair shared by the forgot-password steps.
  List<Widget> _stageHeading(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return [
      SizedBox(height: context.w(28)),
      Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: authDisplayStyle(context, size: 26),
        ),
      ),
      SizedBox(height: context.w(10)),
      Center(
        child: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.fs(13.5),
            color: AppColors.authSubtle,
            height: 1.4,
          ),
        ),
      ),
      SizedBox(height: context.w(34)),
    ];
  }

  PinTheme _forgotPinTheme(BuildContext context, {Color? border, double width = 1}) {
    return PinTheme(
      width: context.w(52),
      height: context.w(58),
      textStyle: TextStyle(
        fontSize: context.fs(20),
        fontWeight: FontWeight.w600,
        color: AppColors.authInk,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(10)),
        border: Border.all(
          color: border ?? AppColors.authFieldBorder,
          width: width,
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN STAGE
  // ============================================================
  Widget _buildLoginStage(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthScaffold(
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
        children: [
          SizedBox(height: context.w(28)),
          Center(
            child: Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: authDisplayStyle(context, size: 26),
            ),
          ),
          SizedBox(height: context.w(10)),
          Center(
            child: Text(
              'Enter your password for\n${widget.contact}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(12),
                color: AppColors.authSubtle,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: context.w(34)),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            cursorColor: AppColors.AppBlue,
            style: TextStyle(
              fontSize: context.fs(14.5),
              fontWeight: FontWeight.w500,
              color: AppColors.authInk,
            ),
            decoration: authFieldDecoration(
              context,
              label: 'PASSWORD',
              hintText: '••••••••',
              suffix: Padding(
                padding: EdgeInsets.only(right: context.w(6)),
                child: IconButton(
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  splashRadius: context.w(20),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: context.w(20),
                    color: AppColors.authSubtle,
                  ),
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          SizedBox(height: context.w(6)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.w(4),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w500,
                  color: AppColors.AppBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: context.w(26)),
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return AuthPrimaryButton(
                label: 'LOGIN',
                isLoading: state is LoginLoading,
                onPressed: _login,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 1: ENTER EMAIL / PHONE
  // ============================================================
  Widget _buildForgotEmailStage(BuildContext context) {
    final isPhone = widget.contactType == ContactType.phone;
    return AuthScaffold(
      onBack: () => setState(() => _forgotStage = _ForgotStage.none),
      children: [
        ..._stageHeading(
          context,
          title: 'Forgot Password',
          subtitle: isPhone
              ? 'Please enter your mobile number to reset the password'
              : 'Please enter your email to reset the password',
        ),
        TextField(
          controller: _forgotEmailController,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
          cursorColor: AppColors.AppBlue,
          onChanged: (_) {
            if (_forgotEmailError != null) {
              setState(() => _forgotEmailError = null);
            }
          },
          style: TextStyle(
            fontSize: context.fs(14.5),
            fontWeight: FontWeight.w500,
            color: AppColors.authInk,
          ),
          decoration: authFieldDecoration(
            context,
            label: isPhone ? 'MOBILE NUMBER' : 'EMAIL ADDRESS',
            hintText: isPhone ? '+1 234 567 8900' : 'you@example.com',
            icon: isPhone ? Icons.phone : Icons.mail,
            hasError: _forgotEmailError != null,
          ),
        ),
        if (_forgotEmailError != null) ...[
          SizedBox(height: context.w(10)),
          _ForgotError(message: _forgotEmailError!),
        ],
        SizedBox(height: context.w(26)),
        BlocBuilder<SendOtpBloc, SendOtpState>(
          builder: (context, state) {
            return AuthPrimaryButton(
              label: 'RESET PASSWORD',
              isLoading: state is SendOtpLoading,
              onPressed: _sendForgotOtp,
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 2: ENTER CODE
  // ============================================================
  Widget _buildForgotOtpStage(BuildContext context) {
    return AuthScaffold(
      onBack: () => setState(() => _forgotStage = _ForgotStage.email),
      children: [
        ..._stageHeading(
          context,
          title: 'Forgot Password',
          subtitle: 'Please enter your email to reset the password',
        ),
        Center(
          child: Pinput(
            length: 6,
            defaultPinTheme: _forgotPinTheme(context),
            focusedPinTheme:
                _forgotPinTheme(context, border: AppColors.AppBlue, width: 1.6),
            submittedPinTheme:
                _forgotPinTheme(context, border: AppColors.AppBlue, width: 1.6),
            errorPinTheme:
                _forgotPinTheme(context, border: AppColors.OrangeColor),
            mainAxisAlignment: MainAxisAlignment.center,
            separatorBuilder: (_) => SizedBox(width: context.w(8)),
            onChanged: (value) => setState(() => _otpCode = value),
            onCompleted: (pin) {
              setState(() => _otpCode = pin);
              _verifyForgotOtp();
            },
          ),
        ),
        SizedBox(height: context.w(30)),
        BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
          builder: (context, state) {
            return AuthPrimaryButton(
              label: 'VERIFY CODE',
              isLoading: state is VerifyOtpLoading,
              onPressed: _verifyForgotOtp,
            );
          },
        ),
        SizedBox(height: context.w(18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Haven't got the email yet? ",
              style: TextStyle(
                fontSize: context.fs(13),
                color: AppColors.authSubtle,
              ),
            ),
            GestureDetector(
              onTap: _sendForgotOtp,
              child: Text(
                'Resend email',
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.AppBlue,
                  color: AppColors.AppBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FORGOT PASSWORD — STEP 3: SET A NEW PASSWORD
  // ============================================================
  Widget _buildForgotNewPasswordStage(BuildContext context) {
    return AuthScaffold(
      onBack: () => setState(() => _forgotStage = _ForgotStage.otp),
      children: [
        ..._stageHeading(
          context,
          title: 'Set a new password',
          subtitle: 'Create new password. Ensure it differs from previous '
              'ones for security',
        ),
        _buildForgotPasswordField(
          label: 'PASSWORD',
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onToggle: () =>
              setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        SizedBox(height: context.w(18)),
        _buildForgotPasswordField(
          label: 'CONFIRM PASSWORD',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onToggle: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
        if (_newPasswordFieldError != null) ...[
          SizedBox(height: context.w(10)),
          _ForgotError(message: _newPasswordFieldError!),
        ],
        SizedBox(height: context.w(30)),
        BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
          builder: (context, state) {
            return AuthPrimaryButton(
              label: 'UPDATE PASSWORD',
              isLoading: state is ResetPasswordLoading,
              onPressed: _submitNewPassword,
            );
          },
        ),
      ],
    );
  }

  Widget _buildForgotPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: AppColors.AppBlue,
      onChanged: (_) {
        if (_newPasswordFieldError != null) {
          setState(() => _newPasswordFieldError = null);
        }
      },
      style: TextStyle(
        fontSize: context.fs(14.5),
        fontWeight: FontWeight.w500,
        color: AppColors.authInk,
      ),
      decoration: authFieldDecoration(
        context,
        label: label,
        hintText: '••••••••',
        hasError: _newPasswordFieldError != null,
        suffix: Padding(
          padding: EdgeInsets.only(right: context.w(6)),
          child: IconButton(
            onPressed: onToggle,
            splashRadius: context.w(20),
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: context.w(20),
              color: AppColors.authSubtle,
            ),
          ),
        ),
      ),
    );
  }

  void _openForgotPassword() {
    if (widget.contactType == ContactType.email) {
      _forgotEmailController.text = widget.contact;
    }
    setState(() => _forgotStage = _ForgotStage.email);
  }

  void _sendForgotOtp() {
    final contact = _forgotEmailController.text.trim();
    final isPhone = widget.contactType == ContactType.phone;

    if (isPhone) {
      if (contact.isEmpty) {
        setState(() => _forgotEmailError = 'Please enter your mobile number');
        return;
      }
    } else {
      if (contact.isEmpty || !_emailRegex.hasMatch(contact)) {
        setState(() => _forgotEmailError = 'Please enter a valid email address');
        return;
      }
    }
    setState(() => _forgotEmailError = null);

    _sendOtpBloc.add(
      SendOtpRequested(
        contact: contact,
        type: isPhone ? ContactType.phone : ContactType.email,
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
    // The login stage is a Form now, so honour its validator before firing.
    if (_formKey.currentState?.validate() == false) return;

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

    if (mounted) {
      // Clear the whole auth stack rather than popping a fixed number of
      // routes: this popup is reached both from the splash gate (where the
      // login screen is the only route) and from overlays elsewhere in the
      // app, so the depth below it varies.
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginSuccessScreen(
            message: 'Congratulations! You are signed in. '
                'Click continue to book',
          ),
        ),
        (route) => false,
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

/// Inline validation message used by the forgot-password steps.
class _ForgotError extends StatelessWidget {
  const _ForgotError({required this.message});

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
