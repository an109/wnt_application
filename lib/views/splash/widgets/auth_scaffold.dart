import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import 'wander_logo.dart';

/// Dial codes offered by the phone field on the auth screens.
class AuthDial {
  const AuthDial(this.flag, this.code, this.country);

  final String flag;
  final String code;
  final String country;

  static const india = AuthDial('🇮🇳', '+91', 'India');

  static const all = <AuthDial>[
    india,
    AuthDial('🇦🇪', '+971', 'UAE'),
    AuthDial('🇺🇸', '+1', 'United States'),
    AuthDial('🇬🇧', '+44', 'United Kingdom'),
    AuthDial('🇸🇬', '+65', 'Singapore'),
    AuthDial('🇦🇺', '+61', 'Australia'),
    AuthDial('🇸🇦', '+966', 'Saudi Arabia'),
    AuthDial('🇶🇦', '+974', 'Qatar'),
  ];
}

/// The white page every auth screen sits on: optional back arrow, scrolling
/// body, and the "Thank you for choosing Wander Nova" strip pinned to the end.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.onBack,
    this.showBadge = true,
  });

  final List<Widget> children;
  final VoidCallback? onBack;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.isMobile ? double.infinity : 460,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: context.w(8)),
                          if (onBack != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: onBack,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.arrow_back,
                                  size: context.w(22),
                                  color: AppColors.authInk,
                                ),
                              ),
                            ),
                          ...children,
                          SizedBox(height: context.w(28)),
                          if (showBadge) const AuthFooterBadge(),
                          SizedBox(height: context.w(16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthFooterBadge extends StatelessWidget {
  const AuthFooterBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        WanderLogoLayers.footerBadge,
        width: context.w(210),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// The brush headline the designs use for "Hi, Traveller!", "Enter your code"
/// and "Set a new password".
///
/// The export does not name its family; Caveat Brush, slanted, is the closest
/// match. It is bundled in `assets/fonts`, so swapping it means dropping in a
/// different file and changing the family here.
// TextStyle authDisplayStyle(BuildContext context, {double size = 26}) {
//   return TextStyle(
//     fontFamily: 'CaveatBrush',
//     fontSize: context.fs(size),
//     fontWeight: FontWeight.w400,
//     fontStyle: FontStyle.italic,
//     color: AppColors.authInk,
//     height: 1.2,
//   );
// }

TextStyle authDisplayStyle(BuildContext context, {double size = 20}) {
  return GoogleFonts.merienda(
    fontSize: context.fs(size),
    fontWeight: FontWeight.w700,
    color: AppColors.authInk,
    height: 1,
  );
}

/// Notched outline field shared by every auth screen — white fill, hairline
/// border, and a small uppercase label sitting in the border gap.
InputDecoration authFieldDecoration(
  BuildContext context, {
  String? label,
  String? hintText,
  IconData? icon,
  Widget? suffix,
  bool hasError = false,
}) {
  final labelStyle = TextStyle(
    fontSize: context.fs(8),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.subhead,
  );

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.w(8)),
        borderSide: BorderSide(color: color, width: 0.8),
      );

  final idle = hasError ? AppColors.OrangeColor : AppColors.authFieldBorder;

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    hintStyle: TextStyle(
      fontSize: context.fs(10),
      fontWeight: FontWeight.w600,
      color: AppColors.authHint,
    ),
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Padding(
            padding: EdgeInsets.only(left: context.w(14), right: context.w(10)),
            child: Icon(icon, size: context.w(18), color: AppColors.authFieldIcon),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix,
    contentPadding: EdgeInsets.only(
      left: icon == null ? context.w(16) : 0,
      right: context.w(16),
      top: context.w(14),
      bottom: context.w(14),
    ),
    border: border(idle, 1),
    enabledBorder: border(idle, 1),
    focusedBorder: border(hasError ? AppColors.OrangeColor : AppColors.AppBlue, 1.4),
    errorBorder: border(AppColors.OrangeColor, 1),
    focusedErrorBorder: border(AppColors.OrangeColor, 1.4),
  );
}

/// Full-width orange action button used for LOGIN OR SIGNUP, VERIFY CODE, …
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.w(48),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.OrangeColor,
          disabledBackgroundColor: AppColors.OrangeColor.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.w(12)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: context.w(18),
                width: context.w(18),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Hairline rule with a caption in the middle: "Or Login/Signup with".
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.authFieldBorder),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(14)),
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: AppColors.authHint,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Google / Apple row — plain glyphs on white, as in the designs.
class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({
    super.key,
    required this.onGoogle,
    required this.onApple,
    this.isGoogleLoading = false,
    this.isAppleLoading = false,
    this.showApple = true,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool isGoogleLoading;
  final bool isAppleLoading;
  final bool showApple;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AuthSocialButton(
          onTap: onGoogle,
          isLoading: isGoogleLoading,
          child: Image.asset(
            'assets/images/google_icon.png',
            height: context.w(28),
            fit: BoxFit.contain,
          ),
        ),
        if (showApple) ...[
          SizedBox(width: context.w(28)),
          _AuthSocialButton(
            onTap: onApple,
            isLoading: isAppleLoading,
            child: Icon(
              Icons.apple,
              size: context.w(32),
              color: AppColors.black,
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthSocialButton extends StatelessWidget {
  const _AuthSocialButton({
    required this.child,
    required this.onTap,
    required this.isLoading,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: SizedBox(
        width: context.w(52),
        height: context.w(52),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: context.w(22),
                  height: context.w(22),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : child,
        ),
      ),
    );
  }
}

/// Country code box + phone number field, split exactly as in the designs.
class AuthPhoneRow extends StatelessWidget {
  const AuthPhoneRow({
    super.key,
    required this.dial,
    required this.controller,
    required this.onDialTap,
    this.hintText = '9876543212',
    this.hasError = false,
    this.onChanged,
  });

  final AuthDial dial;
  final TextEditingController controller;
  final VoidCallback onDialTap;
  final String hintText;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onDialTap,
          child: Container(
            height: context.w(48),
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.w(8)),
              border: Border.all(color: AppColors.authFieldBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dial.flag, style: TextStyle(fontSize: context.fs(16))),
                SizedBox(width: context.w(6)),
                Text(
                  dial.code,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.authInk,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: context.w(20),
                  color: AppColors.authFieldIcon,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            cursorColor: AppColors.AppBlue,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: context.fs(14.5),
              fontWeight: FontWeight.w500,
              color: AppColors.authInk,
            ),
            decoration: authFieldDecoration(
              context,
              hintText: hintText,
              hasError: hasError,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing the dial codes.
Future<AuthDial?> showAuthDialPicker(BuildContext context) {
  FocusScope.of(context).unfocus();

  return showModalBottomSheet<AuthDial>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.w(20))),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AuthDial.all.map((dial) {
            return ListTile(
              onTap: () => Navigator.of(sheetContext).pop(dial),
              leading: Text(dial.flag, style: TextStyle(fontSize: context.fs(20))),
              title: Text(
                dial.country,
                style: TextStyle(
                  fontSize: context.fs(14.5),
                  fontWeight: FontWeight.w500,
                  color: AppColors.authInk,
                ),
              ),
              trailing: Text(
                dial.code,
                style: TextStyle(
                  fontSize: context.fs(14.5),
                  fontWeight: FontWeight.w600,
                  color: AppColors.authSubtle,
                ),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}
