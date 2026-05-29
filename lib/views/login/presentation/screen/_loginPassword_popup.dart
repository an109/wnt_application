import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart'; // ← PreferencesManager
import '../../../../injection_container.dart' as di; // ← GetIt
import '../../../home/presentation/screens/home_screen.dart';
import '../bloc/login_bloc.dart'; // ← LoginBloc
import '../bloc/login_event.dart'; // ← LoginEvent
import '../bloc/login_state.dart'; // ← LoginState
import '../../../../main.dart'; // ← HomeScreen import (adjust path if needed)

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

  @override
  void initState() {
    super.initState();
    // ← Initialize LoginBloc with dependency injection
    _loginBloc = di.sl<LoginBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginBloc, // ← Provide LoginBloc locally
      child: BlocListener<LoginBloc, LoginState>( // ← Listen to LoginState (not AuthState)
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
                    constraints: BoxConstraints(maxHeight: context.hp(60)),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TOP ROW (unchanged)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: context.hp(4.5),
                                  width: context.hp(4.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFFEAEA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.flight_takeoff_rounded,
                                    color: const Color(0xffFF3B42),
                                    size: context.iconMedium,
                                  ),
                                ),
                                SizedBox(width: context.wp(3)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "WANDER NOVA",
                                        style: TextStyle(
                                          fontSize: context.sp(20),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: context.hp(0.2)),
                                      Text(
                                        "Your Reliable Travel Partner.",
                                        style: TextStyle(
                                          fontSize: context.sp(12),
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
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
                            ),

                            SizedBox(height: context.hp(2.5)),

                            // Title (unchanged)
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: context.sp(24),
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: context.hp(0.8)),

                            // Subtitle (unchanged)
                            Text(
                              'Enter your password for\n${widget.contact}',
                              style: TextStyle(
                                fontSize: context.sp(15),
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
                                      onPressed: () {
                                        print('Forgot password tapped');
                                      },
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
                        ),
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

  // ← NEW: Handle login API call
  void _login() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ← Trigger LoginBloc event with contact + password
    _loginBloc.add(
      LoginSubmitted(
        contactValue: widget.contact,
        password: _passwordController.text,
        contactType: widget.contactType.fieldName, // Uses your ContactType extension
      ),
    );
  }

  // ← NEW: Save user data and navigate to HomeScreen
  Future<void> _saveUserDataAndNavigate(loginEntity) async {
    final prefs = di.sl<PreferencesManager>();

    // Save tokens
    if (loginEntity.tokens.access != null) {
      await prefs.saveToken(loginEntity.tokens.access!);
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
    _loginBloc.close(); // ← Close Bloc to free resources
    super.dispose();
  }
}