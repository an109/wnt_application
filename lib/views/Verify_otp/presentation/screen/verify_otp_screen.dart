import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../UI_helper/contact_type.dart';
import '../../../../core/resources/app_colours.dart';
import '../bloc/verify_otp_bloc.dart';
import '../bloc/verify_otp_event.dart';
import '../bloc/verify_otp_state.dart';
import 'complete_profile_screen.dart' hide ContactType;


class VerifyOtpScreen extends StatefulWidget {
  final String contact;
  final ContactType contactType;

  const VerifyOtpScreen({
    super.key,
    required this.contact,
    required this.contactType,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _otpCode = '';

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyOtpBloc, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          // Close this popup, then show Complete Profile popup
          Navigator.of(context).pop();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => BlocProvider.value(
              value: context.read<VerifyOtpBloc>(),
              child: CompleteProfilePopup(
                contact: widget.contact,
                contactType: widget.contactType,
                isVerified: true,
              ),
            ),
          );
        } else if (state is VerifyOtpFailed) {
          String errorMessage = 'Invalid OTP. Please try again.';
          final error = state.dataState.error;
          if (error?.response?.data != null) {
            errorMessage = error!.response!.data['error'] ?? errorMessage;
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Full screen blur
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: context.wp(3),
                sigmaY: context.wp(3),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.08),
              ),
            ),

            // Popup content - matches your LoginSignupScreen style
            SafeArea(
              child: Center(
                child: Container(
                  width: context.wp(90),
                  constraints: BoxConstraints(maxHeight: context.hp(70)),
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
                          // TOP ROW (same as LoginSignupScreen)
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

                          // Title
                          Text(
                            'Verify Your ${widget.contactType == ContactType.email ? "Email" : "Phone"}',
                            style: TextStyle(
                              fontSize: context.sp(24),
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: context.hp(0.8)),

                          // Subtitle
                          Text(
                            'Enter the 6-digit code sent to\n${widget.contact}',
                            style: TextStyle(
                              fontSize: context.sp(15),
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: context.hp(3)),

                          // OTP Input using pinput
                          Form(
                            key: _formKey,
                            child: Pinput(
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
                              onChanged: (value) {
                                setState(() => _otpCode = value);
                              },
                              onCompleted: (pin) {
                                setState(() => _otpCode = pin);
                                _verifyOtp();
                              },
                            ),
                          ),

                          SizedBox(height: context.hp(2)),

                          // Resend OTP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive code? ",
                                style: TextStyle(
                                  fontSize: context.sp(15),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: _resendOtp,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    fontSize: context.sp(15),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.hp(3)),

                          // Verify Button
                          BlocBuilder<VerifyOtpBloc, VerifyOtpState>(
                            builder: (context, state) {
                              final isLoading = state is VerifyOtpLoading;
                              return SizedBox(
                                width: double.infinity,
                                height: context.hp(6),
                                child: ElevatedButton(
                                  onPressed: isLoading || _otpCode.length != 6 ? null : _verifyOtp,
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
                                    'Verify & Continue',
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
    );
  }

  void _verifyOtp() {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.orange,
        ),
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent again'),
        backgroundColor: Colors.green,
      ),
    );
  }
}