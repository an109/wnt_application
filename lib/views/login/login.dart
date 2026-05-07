import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;

  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      // BACKGROUND BLUR
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),

        child: SafeArea(
          child: Center(
            child: Container(
              width: context.wp(94),
              height: context.hp(84),
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

                          SizedBox(height: context.hp(1.8)),

                          Text(
                            "Take a chill and enjoy your travel with WANDER NOVA",
                            style: TextStyle(
                              fontSize: context.sp(18),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: context.hp(1.8)),

                          _buildPoint("Easy booking"),
                          _buildPoint("Lowest price"),
                          _buildPoint("1 Million+ app downloads"),
                          _buildPoint("4.1 App rating"),

                          SizedBox(height: context.hp(1.8)),

                          // IMAGE
                          Container(
                            height: context.hp(18),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xffF5F7FA),
                                  Color(0xffE4ECF7),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -20,
                                  right: -20,
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: -30,
                                  left: -20,
                                  child: Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.flight_takeoff_rounded,
                                          color: Color(0xffFF3B42),
                                          size: 42,
                                        ),
                                      ),

                                      SizedBox(height: context.hp(1.3)),

                                      Text(
                                        "Travel Smart With Wander Nova",
                                        style: TextStyle(
                                          fontSize: context.sp(17),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                            _isLogin
                                ? "Welcome Back"
                                : "Create Account",
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
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                 AppColors.accent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
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
                                  image:
                                  "assets/images/google_icon.png",
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
                                  text:
                                  "By proceeding, you agree with our ",
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
    );
  }

  Widget _buildPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check,
            color: Color(0xff2962FF),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: context.sp(15),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required String title,
    required String image,
  }) {
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