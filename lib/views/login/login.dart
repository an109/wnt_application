import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';
import '../auth/presentation/sdk/google_sign_in_service.dart';
import '../home/presentation/screens/home_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;
  bool _isGoogleLoading = false;

  final TextEditingController _emailController = TextEditingController();
  late final GoogleSignInService _googleSignInService;

  @override
  void initState() {
    super.initState();
    _googleSignInService = di.sl<GoogleSignInService>();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('LoginScreen: Starting Google Sign-In...');

      // Force account picker by signing out first
      await _googleSignInService.signOut();

      final String? idToken = await _googleSignInService.signIn();

      if (idToken == null) {
        print('LoginScreen: User cancelled or failed to get token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('LoginScreen: ID token received, authenticating...');

      if (mounted) {
        context.read<AuthBloc>().add(GoogleLoginRequested(idToken));
      }
    } catch (e) {
      print('LoginScreen: Google Sign-In error: $e');
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Error: ${e.toString()}'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // BlocListener wraps the ENTIRE body content
      body: Stack(
          children: [
            // FULL SCREEN BLUR
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withOpacity(0.08),
              ),
            ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              print('LoginScreen: Auth successful, navigating...');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login successful'),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate based on user type
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!mounted) return;
                final userType = state.user.userType;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              });
            } else if (state is AuthError) {
              print('LoginScreen: Auth error: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          // This is the single 'body' for the Scaffold
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: SafeArea(
              child: Center(
                child: Container(
                  width: context.wp(90),
                  constraints: BoxConstraints(
                    maxHeight: context.hp(72),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: SingleChildScrollView(
                    physics: context.scrollPhysics,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.wp(5),
                            vertical: context.hp(2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOP ROW
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
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

                              SizedBox(height: context.hp(2.3)),

                              // TAB BAR
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isLogin = true;
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: context.sp(18),
                                              fontWeight: FontWeight.w700,
                                              color: _isLogin
                                                  ? const Color(0xffFF3B42)
                                                  : Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: context.hp(1)),
                                          Container(
                                            height: 3,
                                            color: _isLogin
                                                ? const Color(0xffFF3B42)
                                                : Colors.grey.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isLogin = false;
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            "Sign Up",
                                            style: TextStyle(
                                              fontSize: context.sp(18),
                                              fontWeight: FontWeight.w700,
                                              color: !_isLogin
                                                  ? const Color(0xffFF3B42)
                                                  : Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: context.hp(1)),
                                          Container(
                                            height: 3,
                                            color: !_isLogin
                                                ? const Color(0xffFF3B42)
                                                : Colors.grey.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.hp(2.8)),

                              // TITLE
                              Text(
                                _isLogin ? "Welcome Back" : "Create Account",
                                style: TextStyle(
                                  fontSize: context.sp(24),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: context.hp(0.8)),
                              Text(
                                _isLogin
                                    ? "Enter your email or mobile number to login."
                                    : "Enter your email or mobile number to get started.",
                                style: TextStyle(
                                  fontSize: context.sp(15),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: context.hp(2.8)),
                              Text(
                                "Email ID / Mobile Number",
                                style: TextStyle(
                                  fontSize: context.sp(16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: context.hp(1.2)),

                              // TEXTFIELD
                              Container(
                                height: context.hp(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  style: TextStyle(
                                    fontSize: context.sp(15),
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                    "you@example.com or mobile number",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: context.wp(4),
                                      vertical: context.hp(2),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.hp(2)),

                              // BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: context.hp(6),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Your existing email/mobile login logic
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? "Continue" : "Send OTP",
                                    style: TextStyle(
                                      fontSize: context.sp(18),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.hp(2)),

                              Center(
                                child: Text(
                                  "Or continue with",
                                  style: TextStyle(
                                    fontSize: context.sp(15),
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              SizedBox(height: context.hp(1.8)),

                              // SOCIAL BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: _socialButton(
                                      title: "Google",
                                      image: "assets/images/google_icon.png",
                                      onPressed: _isGoogleLoading
                                          ? null
                                          : _handleGoogleSignIn,
                                      isLoading: _isGoogleLoading,
                                    ),
                                  ),
                                  SizedBox(width: context.wp(3)),
                                  Expanded(
                                    child: _appleButton(),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.hp(2.3)),

                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: context.sp(13),
                                    color: Colors.grey.shade600,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "By proceeding, you agree with our ",
                                    ),
                                    TextSpan(
                                      text: "Terms of service",
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    TextSpan(text: ", "),
                                    TextSpan(
                                      text: "privacy policy",
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    TextSpan(text: " & "),
                                    TextSpan(
                                      text: "Master User Agreement.",
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.hp(1.8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ]
      ),
    );
  }

  Widget _socialButton({
    required String title,
    required String image,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: context.hp(6.5),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade600,
                  ),
                ),
              )
            else ...[
              Image.asset(
                image,
                height: 24,
              ),
              SizedBox(width: context.wp(2)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _appleButton() {
    return Container(
      height: context.hp(6.5),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apple,
            size: context.iconLarge,
          ),
          SizedBox(width: context.wp(2)),
          Text(
            "Apple",
            style: TextStyle(
              fontSize: context.sp(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}