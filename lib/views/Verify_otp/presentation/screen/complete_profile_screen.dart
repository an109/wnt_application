import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../signup/domain/entity/signup_entity.dart';
import '../../../signup/presentation/bloc/signup_bloc.dart';
import '../../../signup/presentation/bloc/signup_event.dart';
import '../../../signup/presentation/bloc/signup_state.dart';


class CompleteProfilePopup extends StatefulWidget {
  final String contact;
  final ContactType contactType;
  final bool isVerified;

  const CompleteProfilePopup({
    super.key,
    required this.contact,
    required this.contactType,
    required this.isVerified,
  });

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

  @override
  void initState() {
    super.initState();
    // Pre-fill contact field based on type
    if (widget.contactType == ContactType.phone) {
      // Phone is already handled via phone/phoneCode fields in API
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SignupBloc>(),
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

            // Popup content
            SafeArea(
              child: Center(
                child: Container(
                  width: context.wp(90),
                  constraints: BoxConstraints(
                    maxHeight: context.hp(80),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                child: Image.asset('assets/images/wander_nova_logo.jpg'),
                              ),
                              SizedBox(width: context.wp(3)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "WANDER NOVA",
                                      style: TextStyle(
                                        fontSize: context.sp(17),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: context.hp(0.2)),
                                    Text(
                                      "Your Reliable Travel Partner.",
                                      style: TextStyle(
                                        fontSize: context.sp(11),
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

                          SizedBox(height: context.hp(2)),

                          // Title
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: context.sp(20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          SizedBox(height: context.hp(0.5)),

                          // Subtitle
                          Text(
                            'Set up your account for ${widget.contact}',
                            style: TextStyle(
                              fontSize: context.sp(12),
                              color: Colors.grey.shade600,
                            ),
                          ),

                          SizedBox(height: context.hp(2)),

                          // Verified badge
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: context.hp(1.2),
                              horizontal: context.wp(3),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: context.iconSmall,
                                ),
                                SizedBox(width: context.wp(2)),
                                Text(
                                  '${widget.contactType == ContactType.email ? "Email" : "Mobile number"} verified',
                                  style: TextStyle(
                                    fontSize: context.sp(11),
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.hp(2.5)),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // First Name and Last Name
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'First Name',
                                            style: TextStyle(
                                              fontSize: context.sp(13),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: context.hp(1)),
                                          _buildTextField(
                                            controller: _firstNameController,
                                            hintText: 'John',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: context.wp(3)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Last Name',
                                            style: TextStyle(
                                              fontSize: context.sp(13),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: context.hp(1)),
                                          _buildTextField(
                                            controller: _lastNameController,
                                            hintText: 'Doe',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.hp(2)),

                                // Password
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: context.sp(13),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: context.hp(1)),
                                _buildPasswordField(
                                  controller: _passwordController,
                                  hintText: 'Create a strong password (min 8 chars)',
                                  obscureText: _obscurePassword,
                                  onToggle: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),

                                SizedBox(height: context.hp(2)),

                                // Confirm Password
                                Text(
                                  'Confirm Password',
                                  style: TextStyle(
                                    fontSize: context.sp(13),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: context.hp(1)),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  hintText: 'Re-enter your password',
                                  obscureText: _obscureConfirmPassword,
                                  onToggle: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),

                                SizedBox(height: context.hp(3)),

                                // Create Account Button
                                BlocListener<SignupBloc, SignupState>(
                                  listener: (context, state) {
                                    if (state is SignupSuccess) {
                                      _handleSignupSuccess(state.signupEntity);
                                    } else if (state is SignupFailed) {
                                      _showError(state.errorMessage);
                                    }
                                  },
                                  child: BlocBuilder<SignupBloc, SignupState>(
                                    builder: (context, state) {
                                      final isLoading = state is SignupLoading;
                                      return SizedBox(
                                        width: double.infinity,
                                        height: context.hp(6),
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : _createAccount,
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
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: context.sp(15),
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }

  // void _handleSignupSuccess(SignupEntity entity) {
  //   // Save tokens using your PreferencesManager
  //   final prefs = sl<PreferencesManager>();
  //   prefs.saveToken(entity.tokens.access);
  //   prefs.saveRefreshToken(entity.tokens.refresh);
  //
  //   // Save user data if needed
  //   prefs.saveUserId(entity.user.id);
  //   prefs.saveUserEmail(entity.user.email ?? '');
  //   prefs.saveUserName('${entity.user.firstname} ${entity.user.lastname}');
  //
  //   // Show success message
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(entity.message),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  //
  //   Navigator.of(context).popUntil((route) => route.isFirst);
  //   Navigator.pushReplacementNamed(context, '/home');
  //
  // }
  void _handleSignupSuccess(SignupEntity entity) async {
    try {
      // 1. Save tokens and user data
      final prefs = sl<PreferencesManager>();
      await prefs.saveToken(entity.tokens.access);
      await prefs.saveRefreshToken(entity.tokens.refresh);
      await prefs.saveUserId(entity.user.id);
      await prefs.saveUserEmail(entity.user.email ?? '');
      await prefs.saveUserName('${entity.user.firstname} ${entity.user.lastname}');

      // 2. Show success message (check mounted first)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(entity.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 3. Small delay so user sees the message
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Navigate using ROOT navigator (main app navigator, not dialog overlay)
      if (mounted) {
        // Get the root navigator that controls the main app routes
        final rootNavigator = Navigator.of(context, rootNavigator: true);

        // First, close this dialog popup
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close dialog using dialog's context
        }

        // Then navigate to home, removing all previous auth routes
        rootNavigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false, // Remove ALL previous routes
        );
      }

    } catch (e, stack) {
      print('>>>>>>>>>>>>> Navigation error in _handleSignupSuccess: $e');
      print('Stack trace: $stack');

      // Fallback: try direct navigation if named route fails
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  void _createAccount() {
    if (_formKey.currentState!.validate()) {
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

      // Trigger signup via SignupBloc
      context.read<SignupBloc>().add(
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: context.hp(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: context.sp(13)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: context.hp(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: context.sp(13)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(2),
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500,
              size: context.iconSmall,
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
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}