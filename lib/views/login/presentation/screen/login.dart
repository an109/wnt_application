// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
// import 'package:wander_nova/injection_container.dart' as di;
//
// import '../../../../UI_helper/contact_type.dart';
// import '../../../../UI_helper/navigation_queue.dart';
// import '../../../../core/utils/storage/shared_preference.dart';
// import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
// import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
// import '../../../Send_otp/presentation/bloc/send_otp_state.dart';
// import '_loginPassword_popup.dart';
// import '../../../Verify_otp/presentation/screen/verify_otp_screen.dart';
// import '../../../auth/presentation/bloc/auth_bloc.dart';
// import '../../../auth/presentation/bloc/auth_event.dart';
// import '../../../auth/presentation/bloc/auth_state.dart';
// import '../../../auth/presentation/sdk/google_sign_in_service.dart';
//
// class LoginSignupScreen extends StatefulWidget {
//   const LoginSignupScreen({super.key});
//
//   @override
//   State<LoginSignupScreen> createState() => _LoginSignupScreenState();
// }
//
// class _LoginSignupScreenState extends State<LoginSignupScreen> {
//   bool _isLogin = true;
//   bool _isGoogleLoading = false;
//
//   final TextEditingController _emailController = TextEditingController();
//   late final GoogleSignInService _googleSignInService;
//
//   @override
//   void initState() {
//     super.initState();
//     _googleSignInService = di.sl<GoogleSignInService>();
//   }
//
//   Future<void> _handleGoogleSignIn() async {
//     if (_isGoogleLoading) return;
//
//     setState(() {
//       _isGoogleLoading = true;
//     });
//
//     try {
//       print('LoginScreen: Starting Google Sign-In...');
//
//       // Force account picker by signing out first
//       await _googleSignInService.signOut();
//
//       final String? idToken = await _googleSignInService.signIn();
//
//       if (idToken == null) {
//         print('LoginScreen: User cancelled or failed to get token');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Sign-in cancelled'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         return;
//       }
//
//       print('LoginScreen: ID token received, authenticating...');
//
//       if (mounted) {
//         context.read<AuthBloc>().add(GoogleLoginRequested(idToken));
//       }
//     } catch (e) {
//       print('LoginScreen: Google Sign-In error: $e');
//       if (mounted) {
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   SnackBar(
//         //     content: Text('Error: ${e.toString()}'),
//         //     backgroundColor: Colors.red,
//         //   ),
//         // );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isGoogleLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       // BlocListener wraps the ENTIRE body content
//       body: Stack(
//         children: [
//           // FULL SCREEN BLUR
//           BackdropFilter(
//             filter: ImageFilter.blur(
//               sigmaX: context.wp(3),
//               sigmaY: context.wp(3),
//             ),
//             child: Container(color: Colors.black.withOpacity(0.08)),
//           ),
//           BlocListener<SendOtpBloc, SendOtpState>(
//             listener: (context, state) {
//               if (state is SendOtpSuccess) {
//                 final input = _emailController.text.trim();
//                 final isEmail = RegExp(
//                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                 ).hasMatch(input);
//                 final contactType = isEmail
//                     ? ContactType.email
//                     : ContactType.phone;
//
//                 // Navigate to Verify OTP screen
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (context) => VerifyOtpScreen(
//                       contact: input,
//                       contactType: contactType,
//                     ),
//                   ),
//                 );
//               } else if (state is SendOtpFailed) {
//                 String errorMessage = 'Failed to send OTP';
//                 final error = state.dataState.error;
//                 if (error?.response?.data != null) {
//                   errorMessage =
//                       error!.response!.data['message'] ?? errorMessage;
//                 }
//
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(errorMessage),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: BlocListener<AuthBloc, AuthState>(
//               listener: (context, state) {
//                 if (state is AuthAuthenticated) {
//                   final accessToken = state.user?.accessToken;
//                   final refreshToken = state.user?.refreshToken;
//                   final userId = state.user?.id;
//
//                   if (accessToken != null && accessToken.isNotEmpty) {
//                     SharedPreferences.getInstance().then((prefs) async {
//                       final prefManager = await PreferencesManager.create(
//                         prefs,
//                       );
//                       await prefManager.saveToken(accessToken);
//
//                       if (refreshToken != null && refreshToken.isNotEmpty) {
//                         await prefManager.saveRefreshToken(refreshToken);
//                       }
//
//                       if (userId != null) {
//                         await prefManager.saveUserId(int.parse(userId.toString()));
//                         print(' User ID saved: ${prefManager.getUserId()}');
//                       }
//
//                       print(' Token saved: ${prefManager.getToken()}');
//                     });
//                   } else {
//                     print(' No access token in AuthAuthenticated state');
//                     print('State user: ${state.user}');
//                   }
//                   print('LoginScreen: Auth successful, navigating...');
//
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Login successful'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//
//                   // Navigator.of(context).pop();
//                   //
//                   // // Then execute any pending navigation from queue
//                   // NavigationQueueService().executePendingNavigation(context);
//                   Future.delayed(const Duration(milliseconds: 200), () {
//                     // Execute pending navigation
//                     NavigationQueueService().executePendingNavigation(context);
//
//                     // Close dialog
//                     if (mounted) {
//                       Navigator.of(context).pop();
//                     }
//                   });
//                 } else if (state is AuthError) {
//                   print('LoginScreen: Auth error: ${state.message}');
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(state.message),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               // This is the single 'body' for the Scaffold
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                 child: SafeArea(
//                   child: Center(
//                     child: Container(
//                       width: context.wp(90),
//                       constraints: BoxConstraints(maxHeight: context.hp(72)),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           context.borderRadiusLarge + 6,
//                         ),
//                       ),
//                       child: SingleChildScrollView(
//                         physics: context.scrollPhysics,
//                         child: Column(
//                           children: [
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: context.wp(5),
//                                 vertical: context.hp(2),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   // TOP ROW
//                                   Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Container(
//                                         height: context.hp(4.5),
//                                         width: context.hp(4.5),
//                                         decoration: BoxDecoration(
//                                           color: const Color(0xffFFEAEA),
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Icon(
//                                           Icons.flight_takeoff_rounded,
//                                           color: const Color(0xffFF3B42),
//                                           size: context.iconMedium,
//                                         ),
//                                       ),
//                                       SizedBox(width: context.wp(3)),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "WANDER NOVA",
//                                               style: TextStyle(
//                                                 fontSize: context.sp(20),
//                                                 fontWeight: FontWeight.w800,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                             SizedBox(height: context.hp(0.2)),
//                                             Text(
//                                               "Your Reliable Travel Partner.",
//                                               style: TextStyle(
//                                                 fontSize: context.sp(12),
//                                                 color: Colors.grey.shade600,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       GestureDetector(
//                                         onTap: () => Navigator.pop(context),
//                                         child: Container(
//                                           height: context.hp(4.5),
//                                           width: context.hp(4.5),
//                                           decoration: BoxDecoration(
//                                             color: Colors.grey.shade100,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: Icon(
//                                             Icons.close,
//                                             size: context.iconMedium,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//
//                                   SizedBox(height: context.hp(2.3)),
//
//                                   // TAB BAR
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               _isLogin = true;
//                                             });
//                                           },
//                                           child: Column(
//                                             children: [
//                                               Text(
//                                                 "Login",
//                                                 style: TextStyle(
//                                                   fontSize: context.sp(18),
//                                                   fontWeight: FontWeight.w700,
//                                                   color: _isLogin
//                                                       ? const Color(0xffFF3B42)
//                                                       : Colors.grey,
//                                                 ),
//                                               ),
//                                               SizedBox(height: context.hp(1)),
//                                               Container(
//                                                 height: context.dividerMedium,
//                                                 color: _isLogin
//                                                     ? const Color(0xffFF3B42)
//                                                     : Colors.grey.shade300,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Expanded(
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             setState(() {
//                                               _isLogin = false;
//                                             });
//                                           },
//                                           child: Column(
//                                             children: [
//                                               Text(
//                                                 "Sign Up",
//                                                 style: TextStyle(
//                                                   fontSize: context.sp(18),
//                                                   fontWeight: FontWeight.w700,
//                                                   color: !_isLogin
//                                                       ? const Color(0xffFF3B42)
//                                                       : Colors.grey,
//                                                 ),
//                                               ),
//                                               SizedBox(height: context.hp(1)),
//                                               Container(
//                                                 height: context.dividerMedium,
//                                                 color: !_isLogin
//                                                     ? const Color(0xffFF3B42)
//                                                     : Colors.grey.shade300,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(height: context.hp(2.8)),
//
//                                   // TITLE
//                                   Text(
//                                     _isLogin
//                                         ? "Welcome Back"
//                                         : "Create Account",
//                                     style: TextStyle(
//                                       fontSize: context.sp(24),
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(0.8)),
//                                   Text(
//                                     _isLogin
//                                         ? "Enter your email or mobile number to login."
//                                         : "Enter your email or mobile number to get started.",
//                                     style: TextStyle(
//                                       fontSize: context.sp(15),
//                                       color: Colors.grey.shade600,
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(2.8)),
//                                   Text(
//                                     "Email ID / Mobile Number",
//                                     style: TextStyle(
//                                       fontSize: context.sp(16),
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(1.2)),
//
//                                   // TEXTFIELD
//                                   Container(
//                                     height: context.hp(6),
//                                     decoration: BoxDecoration(
//                                       border: Border.all(
//                                         color: Colors.grey.shade300,
//                                       ),
//                                       borderRadius: BorderRadius.circular(
//                                         context.borderRadiusMedium,
//                                       ),
//                                     ),
//                                     child: TextField(
//                                       controller: _emailController,
//                                       style: TextStyle(
//                                         fontSize: context.sp(15),
//                                       ),
//                                       decoration: InputDecoration(
//                                         hintText:
//                                             "you@example.com or mobile number",
//                                         hintStyle: TextStyle(
//                                           color: Colors.grey.shade400,
//                                         ),
//                                         border: InputBorder.none,
//                                         contentPadding: EdgeInsets.symmetric(
//                                           horizontal: context.wp(4),
//                                           vertical: context.hp(2),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(2)),
//
//                                   // BUTTON
//                                   SizedBox(
//                                     width: double.infinity,
//                                     height: context.hp(6),
//                                     child: ElevatedButton(
//                                       onPressed: () {
//                                         final input = _emailController.text
//                                             .trim();
//                                         if (input.isEmpty) {
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 'Please enter email or phone number',
//                                               ),
//                                             ),
//                                           );
//                                           return;
//                                         }
//
//                                         final isEmail = RegExp(
//                                           r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                                         ).hasMatch(input);
//                                         final contactType = isEmail
//                                             ? ContactType.email
//                                             : ContactType.phone;
//
//                                         // KEY CHANGE: Check if Login or Signup
//                                         if (_isLogin) {
//                                           // LOGIN FLOW: Show password popup with contact data
//                                           showDialog(
//                                             context: context,
//                                             barrierDismissible: true,
//                                             builder: (dialogContext) =>
//                                                 LoginPasswordPopup(
//                                                   contact: input,
//                                                   contactType: contactType,
//                                                 ),
//                                           );
//                                         } else {
//                                           // SIGNUP FLOW: Send OTP
//                                           context.read<SendOtpBloc>().add(
//                                             SendOtpRequested(
//                                               contact: input,
//                                               type: contactType,
//                                               purpose: 'signup',
//                                             ),
//                                           );
//                                         }
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: AppColors.accent,
//                                         elevation: 0,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             context.borderRadiusMedium,
//                                           ),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         _isLogin ? "Continue" : "Send OTP",
//                                         style: TextStyle(
//                                           fontSize: context.sp(18),
//                                           fontWeight: FontWeight.w700,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(2)),
//
//                                   Center(
//                                     child: Text(
//                                       "Or continue with",
//                                       style: TextStyle(
//                                         fontSize: context.sp(15),
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(1.8)),
//
//                                   // SOCIAL BUTTONS
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: _socialButton(
//                                           title: "Google",
//                                           image:
//                                               "assets/images/google_icon.png",
//                                           onPressed: _isGoogleLoading
//                                               ? null
//                                               : _handleGoogleSignIn,
//                                           isLoading: _isGoogleLoading,
//                                         ),
//                                       ),
//                                       SizedBox(width: context.wp(3)),
//                                       Expanded(child: _appleButton()),
//                                     ],
//                                   ),
//                                   SizedBox(height: context.hp(2.3)),
//
//                                   RichText(
//                                     text: TextSpan(
//                                       style: TextStyle(
//                                         fontSize: context.sp(13),
//                                         color: Colors.grey.shade600,
//                                       ),
//                                       children: const [
//                                         TextSpan(
//                                           text:
//                                               "By proceeding, you agree with our ",
//                                         ),
//                                         TextSpan(
//                                           text: "Terms of service",
//                                           style: TextStyle(color: Colors.blue),
//                                         ),
//                                         TextSpan(text: ", "),
//                                         TextSpan(
//                                           text: "privacy policy",
//                                           style: TextStyle(color: Colors.blue),
//                                         ),
//                                         TextSpan(text: " & "),
//                                         TextSpan(
//                                           text: "Master User Agreement.",
//                                           style: TextStyle(color: Colors.blue),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   SizedBox(height: context.hp(1.8)),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _socialButton({
//     required String title,
//     required String image,
//     VoidCallback? onPressed,
//     bool isLoading = false,
//   }) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Container(
//         height: context.hp(6.5),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(context.borderRadiusMedium),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (isLoading)
//               SizedBox(
//                 height: context.hp(2.5),
//                 width: context.hp(2.5),
//                 child: CircularProgressIndicator(
//                   strokeWidth: context.dividerThin,
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     Colors.grey.shade600,
//                   ),
//                 ),
//               )
//             else ...[
//               Image.asset(image, height: context.iconMedium),
//               SizedBox(width: context.wp(2)),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: context.sp(16),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _appleButton() {
//     return Container(
//       height: context.hp(6.5),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(context.borderRadiusMedium),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.apple, size: context.iconLarge),
//           SizedBox(width: context.wp(2)),
//           Text(
//             "Apple",
//             style: TextStyle(
//               fontSize: context.sp(16),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }
// }


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/injection_container.dart' as di;

import '../../../../UI_helper/contact_type.dart';
import '../../../../UI_helper/navigation_queue.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../Send_otp/presentation/bloc/send_otp_bloc.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../Send_otp/presentation/bloc/send_otp_state.dart';
import '_loginPassword_popup.dart';
import '../../../Verify_otp/presentation/screen/verify_otp_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/sdk/google_sign_in_service.dart';

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
            filter: ImageFilter.blur(
              sigmaX: context.w(12), // 12px on design
              sigmaY: context.w(12), // 12px on design
            ),
            child: Container(color: Colors.black.withOpacity(0.08)),
          ),
          BlocListener<SendOtpBloc, SendOtpState>(
            listener: (context, state) {
              if (state is SendOtpSuccess) {
                final input = _emailController.text.trim();
                final isEmail = RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(input);
                final contactType = isEmail
                    ? ContactType.email
                    : ContactType.phone;

                // Navigate to Verify OTP screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VerifyOtpScreen(
                      contact: input,
                      contactType: contactType,
                    ),
                  ),
                );
              } else if (state is SendOtpFailed) {
                String errorMessage = 'Failed to send OTP';
                final error = state.dataState.error;
                if (error?.response?.data != null) {
                  errorMessage =
                      error!.response!.data['message'] ?? errorMessage;
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  final accessToken = state.user?.accessToken;
                  final refreshToken = state.user?.refreshToken;
                  final userId = state.user?.id;

                  if (accessToken != null && accessToken.isNotEmpty) {
                    SharedPreferences.getInstance().then((prefs) async {
                      final prefManager = await PreferencesManager.create(
                        prefs,
                      );
                      await prefManager.saveToken(accessToken);

                      if (refreshToken != null && refreshToken.isNotEmpty) {
                        await prefManager.saveRefreshToken(refreshToken);
                      }

                      if (userId != null) {
                        await prefManager.saveUserId(int.parse(userId.toString()));
                        print(' User ID saved: ${prefManager.getUserId()}');
                      }

                      print(' Token saved: ${prefManager.getToken()}');
                    });
                  } else {
                    print(' No access token in AuthAuthenticated state');
                    print('State user: ${state.user}');
                  }
                  print('LoginScreen: Auth successful, navigating...');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login successful'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Future.delayed(const Duration(milliseconds: 200), () {
                    // Execute pending navigation
                    NavigationQueueService().executePendingNavigation(context);

                    // Close dialog
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
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
                filter: ImageFilter.blur(sigmaX: context.w(32), sigmaY: context.w(32)),
                child: SafeArea(
                  child: Center(
                    child: Container(
                      width: context.w(360),
                      constraints: BoxConstraints(maxHeight: context.h(576)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.borderRadiusLarge + context.w(6),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: context.scrollPhysics,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(20),
                                vertical: context.h(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TOP ROW
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: context.h(36),
                                        width: context.h(36),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFFEAEA),
                                          borderRadius: BorderRadius.circular(
                                            context.r(12),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.flight_takeoff_rounded,
                                          color: const Color(0xffFF3B42),
                                          size: context.iconMedium,
                                        ),
                                      ),
                                      SizedBox(width: context.w(12)), // 12px on design
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "WANDER NOVA",
                                              style: TextStyle(
                                                fontSize: context.fs(20),
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: context.h(2)),
                                            Text(
                                              "Your Reliable Travel Partner.",
                                              style: TextStyle(
                                                fontSize: context.fs(12),
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          height: context.h(36), // 36px on design
                                          width: context.h(36), // 36px on design
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

                                  SizedBox(height: context.h(18)), // 18px on design (2.3% of 800)

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
                                                  fontSize: context.fs(18),
                                                  fontWeight: FontWeight.w700,
                                                  color: _isLogin
                                                      ? const Color(0xffFF3B42)
                                                      : Colors.grey,
                                                ),
                                              ),
                                              SizedBox(height: context.h(8)),
                                              Container(
                                                height: context.dividerMedium,
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
                                                  fontSize: context.fs(18),
                                                  fontWeight: FontWeight.w700,
                                                  color: !_isLogin
                                                      ? const Color(0xffFF3B42)
                                                      : Colors.grey,
                                                ),
                                              ),
                                              SizedBox(height: context.h(8)), // 8px on design
                                              Container(
                                                height: context.dividerMedium,
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
                                  SizedBox(height: context.h(22)), // 22px on design (2.8% of 800)

                                  // TITLE
                                  Text(
                                    _isLogin
                                        ? "Welcome Back"
                                        : "Create Account",
                                    style: TextStyle(
                                      fontSize: context.fs(24),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: context.h(6)), // 6px on design
                                  Text(
                                    _isLogin
                                        ? "Enter your email or mobile number to login."
                                        : "Enter your email or mobile number to get started.",
                                    style: TextStyle(
                                      fontSize: context.fs(15),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: context.h(22)), // 22px on design

                                  Text(
                                    "Email ID / Mobile Number",
                                    style: TextStyle(
                                      fontSize: context.fs(16),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: context.h(10)), // 10px on design

                                  // TEXTFIELD
                                  Container(
                                    height: context.h(48), // 48px on design
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        context.borderRadiusMedium,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _emailController,
                                      style: TextStyle(
                                        fontSize: context.fs(15),
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                        "you@example.com or mobile number",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: context.w(16), // 16px on design
                                          vertical: context.h(16), // 16px on design
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.h(16)), // 16px on design

                                  // BUTTON
                                  SizedBox(
                                    width: double.infinity,
                                    height: context.h(48), // 48px on design
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final input = _emailController.text
                                            .trim();
                                        if (input.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter email or phone number',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final isEmail = RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(input);
                                        final contactType = isEmail
                                            ? ContactType.email
                                            : ContactType.phone;

                                        // KEY CHANGE: Check if Login or Signup
                                        if (_isLogin) {
                                          // LOGIN FLOW: Show password popup with contact data
                                          showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (dialogContext) =>
                                                LoginPasswordPopup(
                                                  contact: input,
                                                  contactType: contactType,
                                                ),
                                          );
                                        } else {
                                          // SIGNUP FLOW: Send OTP
                                          context.read<SendOtpBloc>().add(
                                            SendOtpRequested(
                                              contact: input,
                                              type: contactType,
                                              purpose: 'signup',
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            context.borderRadiusMedium,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _isLogin ? "Continue" : "Send OTP",
                                        style: TextStyle(
                                          fontSize: context.fs(18),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.h(16)),

                                  Center(
                                    child: Text(
                                      "Or continue with",
                                      style: TextStyle(
                                        fontSize: context.fs(15),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.h(14)),

                                  // SOCIAL BUTTONS
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _socialButton(
                                          title: "Google",
                                          image:
                                          "assets/images/google_icon.png",
                                          onPressed: _isGoogleLoading
                                              ? null
                                              : _handleGoogleSignIn,
                                          isLoading: _isGoogleLoading,
                                        ),
                                      ),
                                      SizedBox(width: context.w(12)),
                                      Expanded(child: _appleButton()),
                                    ],
                                  ),
                                  SizedBox(height: context.h(18)),

                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: context.fs(13),
                                        color: Colors.grey.shade600,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text:
                                          "By proceeding, you agree with our ",
                                        ),
                                        TextSpan(
                                          text: "Terms of service",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        TextSpan(text: ", "),
                                        TextSpan(
                                          text: "privacy policy",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        TextSpan(text: " & "),
                                        TextSpan(
                                          text: "Master User Agreement.",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: context.h(14)),
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
          ),
        ],
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
        height: context.h(52),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: context.h(20),
                width: context.h(20),
                child: CircularProgressIndicator(
                  strokeWidth: context.dividerThin,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade600,
                  ),
                ),
              )
            else ...[
              Image.asset(image, height: context.iconMedium),
              SizedBox(width: context.w(8)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.fs(16),
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
      height: context.h(52),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apple, size: context.iconLarge),
          SizedBox(width: context.w(8)),
          Text(
            "Apple",
            style: TextStyle(
              fontSize: context.fs(16),
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
