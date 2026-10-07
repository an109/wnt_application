import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

// Shared building blocks for the account screens (Profile, Edit Profile,
// Delete Account, Add Travellers) — Figma "profile" frames, 412px wide,
// hence `context.fx`.

const Color kAccountInk = Color(0xFF111527);
const Color kAccountMuted = Color(0xFF757575);
const Color kAccountLine = Color(0xFFE3E6EB);
const Color kAccountOrange = Color(0xFFEE7330);

/// "← Title" bar used at the top of every account screen.
class AccountTopBar extends StatelessWidget {
  final String title;
  final Color color;

  const AccountTopBar({super.key, required this.title, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(48),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: EdgeInsets.all(context.fx(4)),
                child: Icon(Icons.arrow_back, size: context.fx(24), color: color),
              ),
            ),
          ),
          SizedBox(width: context.fx(12)),
          Text(
            title,
            style: TextStyle(
              fontSize: context.ffs(20),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar with the golden ring (photo, else initials).
class AccountAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool crown;

  const AccountAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    required this.size,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.take(2).map((w) => w[0]).join().toUpperCase();
    final placeholder = Container(
      color: const Color(0xFFEAF4FF),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: size * 0.5, color: AppColors.AppBlue)
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700,
                color: AppColors.AppBlue,
              ),
            ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.045),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFE0A548), Color(0xFFB8741E)]),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : placeholder,
            ),
          ),
          if (crown)
            Positioned(
              right: -size * 0.04,
              top: -size * 0.1,
              child: Transform.rotate(
                angle: 0.45,
                child: Icon(
                  FontAwesomeIcons.crown.data,
                  size: size * 0.25,
                  color: const Color(0xFFE39B3B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Blue gradient card with avatar, name, phone and email (Profile screen).
class AccountHeaderCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;

  const AccountHeaderCard({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget bubble(double s) => Container(
      width: context.fx(s),
      height: context.fx(s),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
      ),
    );
    Widget contact(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.fx(12), color: Colors.white),
        SizedBox(width: context.fx(4)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: context.ffs(11), color: Colors.white),
          ),
        ),
      ],
    );

    return Container(
      height: context.fx(86),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(12)),
        gradient: const LinearGradient(
          colors: [Color(0xFF8FD0FF), Color(0xFF5DB4F5)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(right: -context.fx(20), top: -context.fx(28), child: bubble(80)),
          Positioned(right: context.fx(30), bottom: -context.fx(40), child: bubble(72)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.fx(10)),
            child: Row(
              children: [
                AccountAvatar(name: name, imageUrl: avatarUrl, size: context.fx(68), crown: true),
                SizedBox(width: context.fx(10)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Traveller' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.ffs(18),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: context.fx(4)),
                      Row(
                        children: [
                          if (phone.isNotEmpty) ...[
                            Flexible(child: contact(Icons.call_rounded, phone)),
                            SizedBox(width: context.fx(8)),
                          ],
                          if (email.isNotEmpty)
                            Flexible(flex: 2, child: contact(Icons.mail_rounded, email)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with the light gradient header strip, a coloured icon square
/// and a title (Personal Information, Add Travellers, Delete Account…).
class AccountSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;

  const AccountSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.trailing,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final header = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.fx(12),
        vertical: context.fx(10),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5FAFF), Color(0xFFDDF0FD)],
        ),
        border: child == null
            ? null
            : const Border(bottom: BorderSide(color: kAccountLine)),
      ),
      child: Row(
        children: [
          Container(
            width: context.fx(20),
            height: context.fx(20),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(context.fx(5)),
            ),
            child: Icon(icon, size: context.fx(14), color: Colors.white),
          ),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: context.ffs(13),
                fontWeight: FontWeight.w500,
                color: kAccountInk,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: kAccountLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (child != null)
            Padding(padding: EdgeInsets.all(context.fx(12)), child: child),
        ],
      ),
    );

    return onTap == null
        ? card
        : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

InputDecoration accountInputDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  Widget? suffix,
  String? errorText,
  bool required = false,
  String? hint,
}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(context.fx(8)),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    isDense: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    label: Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(text: '*', style: TextStyle(color: Color(0xFFE5484D))),
        ],
      ),
    ),
    labelStyle: TextStyle(fontSize: context.ffs(10), color: kAccountMuted),
    floatingLabelStyle: TextStyle(fontSize: context.ffs(10), color: kAccountMuted),
    hintText: hint,
    hintStyle: TextStyle(fontSize: context.ffs(12), color: Colors.grey.shade400),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: context.fx(16), color: const Color(0xFFB0B5BD)),
    prefixIconConstraints: BoxConstraints(minWidth: context.fx(36)),
    suffixIcon: suffix,
    errorText: errorText,
    contentPadding: EdgeInsets.symmetric(
      horizontal: context.fx(12),
      vertical: context.fx(14),
    ),
    filled: true,
    fillColor: Colors.white,
    border: border(kAccountLine),
    enabledBorder: border(kAccountLine),
    focusedBorder: border(AppColors.AppBlue),
    disabledBorder: border(kAccountLine),
    errorBorder: border(const Color(0xFFE5484D)),
    focusedErrorBorder: border(const Color(0xFFE5484D)),
  );
}

TextStyle accountValueStyle(BuildContext context) => TextStyle(
  fontSize: context.ffs(12),
  fontWeight: FontWeight.w500,
  color: kAccountInk,
);

/// Read-only display of a value in the outlined-field style.
class AccountDisplayField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? suffix;

  const AccountDisplayField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: accountInputDecoration(context, label: label, icon: icon, suffix: suffix),
      child: Text(
        value.isEmpty ? '—' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: accountValueStyle(context),
      ),
    );
  }
}

/// Country-code box (flag + code + chevron) beside a phone number.
class AccountPhoneCode extends StatelessWidget {
  final String code;

  const AccountPhoneCode({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final flag = code.replaceAll('+', '') == '91' ? '🇮🇳' : '🌐';
    return Container(
      height: context.fx(46),
      padding: EdgeInsets.symmetric(horizontal: context.fx(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(8)),
        border: Border.all(color: kAccountLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: TextStyle(fontSize: context.ffs(16))),
          SizedBox(width: context.fx(6)),
          Text(code.startsWith('+') ? code : '+$code', style: accountValueStyle(context)),
          Icon(Icons.keyboard_arrow_down_rounded, size: context.fx(18), color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

/// Full-width orange button (SAVE, DELETE ACCOUNT…).
class AccountPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AccountPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(44),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccountOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAccountOrange.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.fx(12)),
          ),
        ),
        child: loading
            ? SizedBox(
                width: context.fx(20),
                height: context.fx(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: context.ffs(14),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Outlined grey button (CANCEL).
class AccountSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AccountSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.fx(44),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: kAccountMuted,
          side: const BorderSide(color: Color(0xFFBFC4CC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.fx(12)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.ffs(14),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// White bar pinned to the bottom with Cancel / primary action.
class AccountBottomActions extends StatelessWidget {
  final Widget left;
  final Widget right;

  const AccountBottomActions({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(14), context.fx(16), context.fx(14)),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: left),
            SizedBox(width: context.fx(24)),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}
