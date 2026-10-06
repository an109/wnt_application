import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/contact_type.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../login/presentation/screen/loginsuccess.dart';
import '../../../signup/domain/entity/signup_entity.dart';
import '../../../signup/presentation/bloc/signup_bloc.dart';
import '../../../signup/presentation/bloc/signup_event.dart';
import '../../../signup/presentation/bloc/signup_state.dart';
import '../../../splash/widgets/auth_scaffold.dart';

/// Last step of signup: name and password, once the code has been verified.
///
/// The design for this screen shows only the two password fields. The signup
/// call takes a first and last name as well, so those are kept here in the
/// same field style — without them the request goes out with blank names and
/// the profile has nothing to show.
class CompleteProfilePopup extends StatefulWidget {
  const CompleteProfilePopup({
    super.key,
    required this.contact,
    required this.contactType,
    required this.isVerified,
  });

  final String contact;
  final ContactType contactType;
  final bool isVerified;

  @override
  State<CompleteProfilePopup> createState() => _CompleteProfilePopupState();
}

class _CompleteProfilePopupState extends State<CompleteProfilePopup> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final SignupBloc _signupBloc;

  @override
  void initState() {
    super.initState();
    _signupBloc = sl<SignupBloc>();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _signupBloc.close();
    super.dispose();
  }

  // ----------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _signupBloc,
      child: BlocListener<SignupBloc, SignupState>(
        listener: (context, state) {
          if (state is SignupSuccess) {
            _handleSignupSuccess(state.signupEntity);
          } else if (state is SignupFailed) {
            _showError(state.errorMessage);
          }
        },
        child: Form(
          key: _formKey,
          child: AuthScaffold(
            // onBack: Navigator.of(context).canPop()
            //     ? () => Navigator.of(context).pop()
            //     : null,
            children: [
              // SizedBox(height: context.w(10)),
              Center(
                child: Text(
                  'Set a new password',
                  textAlign: TextAlign.center,
                  style: authDisplayStyle(context, size: 26),
                ),
              ),
              SizedBox(height: context.w(10)),
              Center(
                child: Text(
                  'Create new password. Ensure it differs from previous '
                  'ones for security',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    color: AppColors.authSubtle,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: context.w(34)),
              _buildNameField(
                label: 'FIRST NAME',
                hintText: 'First name',
                controller: _firstNameController,
              ),
              SizedBox(height: context.w(18)),
              _buildNameField(
                label: 'LAST NAME',
                hintText: 'Last name',
                controller: _lastNameController,
              ),
              SizedBox(height: context.w(18)),
              _buildPasswordField(
                label: 'PASSWORD',
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              SizedBox(height: context.w(18)),
              _buildPasswordField(
                label: 'CONFIRM PASSWORD',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onToggle: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              SizedBox(height: context.w(30)),
              BlocBuilder<SignupBloc, SignupState>(
                builder: (context, state) {
                  return AuthPrimaryButton(
                    label: 'DONE',
                    isLoading: state is SignupLoading,
                    onPressed: _createAccount,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField({
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      cursorColor: AppColors.AppBlue,
      style: TextStyle(
        fontSize: context.fs(14.5),
        fontWeight: FontWeight.w500,
        color: AppColors.authInk,
      ),
      decoration: authFieldDecoration(
        context,
        label: label,
        hintText: hintText,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: AppColors.AppBlue,
      style: TextStyle(
        fontSize: context.fs(14.5),
        fontWeight: FontWeight.w500,
        color: AppColors.authInk,
      ),
      decoration: authFieldDecoration(
        context,
        label: label,
        hintText: '••••••••',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  // ------------------------------------------------------------- behaviour

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    // Build signup payload depending on whether the user registered with an
    // email or a phone number. Backend accepts email OR phone (never the
    // email value stuffed into the phone field).
    String? email;
    String? phoneNumber;
    String? phoneCode;

    if (widget.contactType == ContactType.email) {
      email = widget.contact.trim();
    } else {
      // Phone signup — split country code and number, e.g. "+918595557189"
      phoneCode = '+91';
      phoneNumber = widget.contact;
      final match = RegExp(r'^(\+\d+)(\d+)$').firstMatch(widget.contact);
      if (match != null) {
        phoneCode = match.group(1) ?? '+91';
        phoneNumber = match.group(2) ?? widget.contact;
      }
    }

    _signupBloc.add(
      SignupSubmitted(
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        password: _passwordController.text,
        email: email,
        phone: phoneNumber,
        phoneCode: phoneCode,
      ),
    );
  }

  void _handleSignupSuccess(SignupEntity entity) async {
    try {
      // 1. Save tokens and user data, and mark the user as logged in
      // (same fields/shape as the regular login flow) so the rest of the
      // app treats this as an authenticated session immediately.
      final prefs = sl<PreferencesManager>();
      await prefs.saveToken(entity.tokens.access);
      await prefs.saveRefreshToken(entity.tokens.refresh);

      final userData = {
        'id': entity.user.id,
        'firstname': entity.user.firstname,
        'lastname': entity.user.lastname,
        'email': entity.user.email,
        'phone_code': entity.user.phoneCode,
        'phone_number': entity.user.phoneNumber,
        'platform': entity.user.platform,
      };
      await prefs.saveUserData(userData); // also flips isLoggedIn() to true
      await prefs.saveIsSocialLogin(false);
      await prefs.saveUserPassword(_passwordController.text);

      await prefs.saveUserId(entity.user.id);
      await prefs.saveUserEmail(entity.user.email ?? '');
      await prefs.saveUserName(
        '${entity.user.firstname} ${entity.user.lastname}',
      );

      // 2. Hand over to the confirmation screen, which owns the move to home.
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginSuccessScreen(
              message: entity.message.isNotEmpty
                  ? entity.message
                  : 'Congratulations! Your account has been created. '
                      'Click continue to book',
            ),
          ),
          (route) => false, // Remove ALL previous routes
        );
      }
    } catch (e, stack) {
      debugPrint('Navigation error in _handleSignupSuccess: $e');
      debugPrint('Stack trace: $stack');

      // Fallback: still get the user through to the confirmation screen.
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginSuccessScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
