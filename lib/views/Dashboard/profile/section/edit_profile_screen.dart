import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../widgets/account_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_bloc.dart';
import 'package:wander_nova/views/Profile/presentation/bloc/profile_event.dart';

import '../../../Profile/domain/entities/ProfileEntity.dart';
import '../../../Profile/presentation/bloc/profile_state.dart';

import '../../../../injection_container.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late ProfileBloc _profileBloc;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController pinController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController emailController; // Added for clean disposal

  bool newsletterSubscribed = true;
  bool smsAlertsEnabled = false;

  String title = "Ms";
  String country = "India";
  String gender = "Female";
  String? _emailError;
  String? _phoneError;

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final isValid = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
    ).hasMatch(value.trim());

    setState(() {
      _emailError = isValid ? null : 'Enter a valid email address';
    });
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        _phoneError = 'Only numbers are allowed';
      } else if (digits.length < 10) {
        _phoneError = 'Minimum 10 digits required';
      } else if (digits.length > 15) {
        _phoneError = 'Maximum 15 digits allowed';
      } else {
        _phoneError = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize BLoC and fetch profile
    _profileBloc = sl<ProfileBloc>();
    _profileBloc.add(const GetProfileEvent());

    // Until the profile API answers, show the names the Profile screen
    // already has (it passes first/last separately; older callers only pass
    // the full name, which is split on the first space).
    final fullName = (widget.userData?['name'] ?? '').toString().trim();
    final splitAt = fullName.indexOf(' ');
    firstNameController = TextEditingController(
      text: widget.userData?['firstName'] ??
          (splitAt < 0 ? fullName : fullName.substring(0, splitAt)),
    );
    lastNameController = TextEditingController(
      text: widget.userData?['lastName'] ??
          (splitAt < 0 ? '' : fullName.substring(splitAt + 1)),
    );
    addressController = TextEditingController(
      text: widget.userData?['address'] ?? '',
    );
    cityController = TextEditingController();
    stateController = TextEditingController();
    pinController = TextEditingController();
    phoneController = TextEditingController(
      text: widget.userData?['phone'] ?? '',
    );
    dobController = TextEditingController();
    emailController = TextEditingController(
      text: widget.userData?['email'] ?? '',
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pinController.dispose();
    phoneController.dispose();
    dobController.dispose();
    emailController.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // Maps API response to UI state
  void _populateProfile(ProfileEntity profile) {
    setState(() {
      title = profile.title.isEmpty ? "Ms" : profile.title;
      firstNameController.text = profile.firstName;
      lastNameController.text = profile.lastName;
      emailController.text = profile.email ?? '';
      phoneController.text = profile.phoneNumber;
      dobController.text = profile.dob ?? '';
      addressController.text = profile.address;
      cityController.text = profile.city;
      stateController.text = profile.state;
      country = profile.country.isEmpty ? "India" : profile.country;
      pinController.text = profile.pinCode;
      newsletterSubscribed = profile.newsletter;
      smsAlertsEnabled = profile.smsAlerts;
    });
  }

  // Constructs entity and dispatches PATCH request
  void _saveProfile() {
    _validateEmail(emailController.text);
    _validatePhone(phoneController.text);

    if (_emailError != null || _phoneError != null) {
      return;
    }
    final profile = ProfileEntity(
      id: _profileBloc.currentProfile?.id ?? 0,
      title: title,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : null,
      phoneCode:
          '+91', // Adjust if your ProfilePhoneField exposes the selected code
      phoneNumber: phoneController.text.trim(),
      dob: dobController.text.trim().isNotEmpty
          ? dobController.text.trim()
          : null,
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: country,
      pinCode: pinController.text.trim(),
      platform: _profileBloc.currentProfile?.platform ?? 'web',
      newsletter: newsletterSubscribed,
      smsAlerts: smsAlertsEnabled,
      created: _profileBloc.currentProfile?.created ?? DateTime.now(),
      updated: DateTime.now(),
    );
    _profileBloc.add(PatchProfileEvent(profile));
  }

  // ---------------------------------------------------------------- password
  // Figma "Edit profile 2": the password row expands into an inline
  // old / new / confirm panel.

  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _passwordOpen = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  /// Same rules the previous change-password dialog enforced.
  String? _passwordRule(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new password';
    if (v.length < 6) return 'Minimum 6 characters required';
    if (v.length > 16) return 'Maximum 16 characters allowed';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include at least 1 lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least 1 number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
      return 'Include at least 1 special character';
    }
    return null;
  }

  void _submitPassword() {
    if (!_passwordFormKey.currentState!.validate()) return;
    // There is no change-password endpoint in the app's API yet (only the
    // OTP-based reset on the login screen), so say so instead of pretending
    // the password changed.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Changing your password here is coming soon. Use "Forgot password" on the login screen for now.',
          ),
        ),
      );
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      listener: (context, state) {
        if (state is ProfileLoaded) {
          _populateProfile(state.profile);
        } else if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: BlocBuilder<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          builder: (context, state) {
            final isUpdating = state is ProfileUpdateLoading;
            return Scaffold(
              backgroundColor: Colors.white,
              bottomNavigationBar: state is ProfileLoading
                  ? null
                  : SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.fx(16),
                          context.fx(8),
                          context.fx(16),
                          context.fx(16),
                        ),
                        child: AccountPrimaryButton(
                          label: 'SAVE',
                          onPressed: _saveProfile,
                          loading: isUpdating,
                        ),
                      ),
                    ),
              body: state is ProfileLoading
                  ? const SafeArea(
                      child: AppLoadingView(message: 'Loading your profile…'),
                    )
                  : ListView(
                      padding: EdgeInsets.only(bottom: context.fx(24)),
                      children: [
                        _buildHeader(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.fx(16)),
                          child: _buildForm(isUpdating),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = '${firstNameController.text} ${lastNameController.text}'.trim();
    final avatar = context.fx(104);
    return SizedBox(
      height: context.statusBarHeight + context.fx(230),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _WavyHeaderPainter()),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.fx(16),
              context.statusBarHeight + context.fx(8),
              context.fx(16),
              0,
            ),
            child: const AccountTopBar(title: 'Edit Profile'),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: context.statusBarHeight + context.fx(84),
            child: Center(
              child: SizedBox(
                width: avatar,
                height: avatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(context.fx(4)),
                      child: AccountAvatar(name: name, size: avatar - context.fx(8)),
                    ),
                    Positioned(
                      right: context.fx(4),
                      bottom: context.fx(6),
                      child: Semantics(
                        button: true,
                        label: 'Change photo',
                        child: GestureDetector(
                          onTap: () => _comingSoon('Profile photo upload'),
                          child: Container(
                            width: context.fx(26),
                            height: context.fx(26),
                            decoration: BoxDecoration(
                              color: kAccountOrange,
                              borderRadius: BorderRadius.circular(context.fx(7)),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.photo_camera_rounded,
                                size: context.fx(14), color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isUpdating) {
    final gap = SizedBox(height: context.fx(16));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: context.fx(8)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: firstNameController,
                enabled: !isUpdating,
                textCapitalization: TextCapitalization.words,
                style: accountValueStyle(context),
                decoration: accountInputDecoration(
                  context,
                  label: 'First Name',
                  icon: Icons.person_rounded,
                ),
              ),
            ),
            SizedBox(width: context.fx(12)),
            Expanded(
              child: TextField(
                controller: lastNameController,
                enabled: !isUpdating,
                textCapitalization: TextCapitalization.words,
                style: accountValueStyle(context),
                decoration: accountInputDecoration(
                  context,
                  label: 'Last Name',
                  icon: Icons.person_rounded,
                ),
              ),
            ),
          ],
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountPhoneCode(code: _profileBloc.currentProfile?.phoneCode ?? '+91'),
            SizedBox(width: context.fx(8)),
            Expanded(
              child: TextField(
                controller: phoneController,
                enabled: !isUpdating,
                keyboardType: TextInputType.phone,
                onChanged: _validatePhone,
                style: accountValueStyle(context),
                decoration: accountInputDecoration(
                  context,
                  label: 'Phone Number',
                  errorText: _phoneError,
                ),
              ),
            ),
          ],
        ),
        gap,
        TextField(
          controller: emailController,
          enabled: !isUpdating,
          keyboardType: TextInputType.emailAddress,
          onChanged: _validateEmail,
          style: accountValueStyle(context),
          decoration: accountInputDecoration(
            context,
            label: 'EMAIL ADDRESS',
            icon: Icons.mail_rounded,
            errorText: _emailError,
          ),
        ),
        gap,
        _passwordOpen ? _buildPasswordPanel() : _buildPasswordRow(),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return InputDecorator(
      decoration: accountInputDecoration(
        context,
        label: 'PASSWORD',
        suffix: Padding(
          padding: EdgeInsets.only(right: context.fx(8)),
          child: TextButton(
            onPressed: () => setState(() => _passwordOpen = true),
            child: Text(
              'Change Password',
              style: TextStyle(
                fontSize: context.ffs(12),
                color: AppColors.AppBlue,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.AppBlue,
              ),
            ),
          ),
        ),
      ),
      child: Text('••••••••••', style: accountValueStyle(context)),
    );
  }

  Widget _buildPasswordPanel() {
    Widget field(
      TextEditingController c,
      String label,
      bool visible,
      VoidCallback toggle,
      String? Function(String?) validator,
    ) {
      return TextFormField(
        controller: c,
        obscureText: !visible,
        style: accountValueStyle(context),
        validator: validator,
        decoration: accountInputDecoration(
          context,
          label: label,
          suffix: IconButton(
            tooltip: visible ? 'Hide password' : 'Show password',
            onPressed: toggle,
            icon: Icon(
              visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: context.fx(18),
              color: kAccountMuted,
            ),
          ),
        ),
      );
    }

    final gap = SizedBox(height: context.fx(14));
    return Container(
      padding: EdgeInsets.all(context.fx(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: kAccountLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _passwordOpen = false),
            child: InputDecorator(
              decoration: accountInputDecoration(
                context,
                label: 'PASSWORD',
                suffix: Icon(Icons.keyboard_arrow_up_rounded,
                    size: context.fx(22), color: kAccountMuted),
              ),
              child: Text('••••••••••', style: accountValueStyle(context)),
            ),
          ),
          SizedBox(height: context.fx(12)),
          Container(
            padding: EdgeInsets.all(context.fx(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBFE),
              borderRadius: BorderRadius.circular(context.fx(12)),
              border: Border.all(color: const Color(0xFFE6F1F7)),
            ),
            child: Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: context.fx(4)),
                  field(
                    _oldPassword,
                    'OLD PASSWORD',
                    _showOld,
                    () => setState(() => _showOld = !_showOld),
                    (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
                  ),
                  gap,
                  field(
                    _newPassword,
                    'NEW PASSWORD',
                    _showNew,
                    () => setState(() => _showNew = !_showNew),
                    _passwordRule,
                  ),
                  gap,
                  field(
                    _confirmPassword,
                    'CONFIRM PASSWORD',
                    _showConfirm,
                    () => setState(() => _showConfirm = !_showConfirm),
                    (v) => v != _newPassword.text ? 'Passwords do not match' : null,
                  ),
                  SizedBox(height: context.fx(18)),
                  AccountPrimaryButton(label: 'SAVE', onPressed: _submitPassword),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Light-blue header with soft contour lines and a curved bottom edge
/// (Figma "Edit profile" background).
class _WavyHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shape = Path()
      ..lineTo(w, 0)
      ..lineTo(w, h - 34)
      ..quadraticBezierTo(w * 0.62, h - 10, w * 0.38, h - 22)
      ..quadraticBezierTo(w * 0.16, h - 32, 0, h - 14)
      ..close();
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE7F5FD), Color(0xFFCDEBFB)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(shape);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 7; i++) {
      final y = h * 0.25 + i * 16.0;
      final p = Path()..moveTo(-20, y);
      p.cubicTo(w * 0.25, y - 40, w * 0.5, y + 30, w * 0.75, y - 18);
      p.quadraticBezierTo(w * 0.9, y - 34, w + 20, y - 6);
      canvas.drawPath(p, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
