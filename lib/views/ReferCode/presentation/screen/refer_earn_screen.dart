import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../injection_container.dart';
import '../../../Dashboard/profile/widgets/account_kit.dart';
import '../../domain/entity/referral_entity.dart';
import '../bloc/referral_bloc.dart';
import '../bloc/referral_event.dart';
import '../bloc/referral_state.dart';

/// Refer & Earn — Figma "Refer & Earn". Code, link and totals come from
/// `GET /api/user/referral/`; REFER NOW opens the share sheet.
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  late final ReferralBloc _bloc = sl<ReferralBloc>()..add(const FetchReferralEvent());

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Referral code $code copied')));
  }

  void _share(ReferralEntity r) {
    final bonus = _bonusText(r);
    final lines = [
      'Plan your next trip with WanderNova — flights, hotels and holidays in one app.',
      'Use my referral code ${r.referralCode} when you sign up${bonus == null ? '' : ' and we both get rewarded'}.',
      if (r.referralLink.isNotEmpty) r.referralLink,
    ];
    Share.share(lines.join('\n'), subject: 'Join me on WanderNova');
  }

  /// "₹250" from the backend's per-friend bonus, or null when it isn't sent
  /// (older backend) or referral bonuses are switched off.
  String? _bonusText(ReferralEntity r) {
    if (r.bonusEnabled == false) return null;
    final amount = double.tryParse(r.referrerBonus ?? '');
    if (amount == null || amount <= 0) return null;
    return CurrencyConverter.format(amount, 'INR');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocBuilder<ReferralBloc, ReferralState>(
        bloc: _bloc,
        builder: (context, state) {
          final referral = state is ReferralSuccess ? state.data : null;
          return Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: referral == null || referral.referralCode.isEmpty
                ? null
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), context.fx(16)),
                      child: AccountPrimaryButton(
                        label: 'REFER NOW',
                        onPressed: () => _share(referral),
                      ),
                    ),
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), 0),
                    child: const AccountTopBar(title: 'Refer & Earn'),
                  ),
                  Expanded(child: _body(state, referral)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(ReferralState state, ReferralEntity? referral) {
    if (referral != null) {
      return RefreshIndicator(
        color: AppColors.AppBlue,
        onRefresh: () async {
          _bloc.add(const FetchReferralEvent());
          await _bloc.stream.firstWhere((s) => s is! ReferralLoading);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(28), context.fx(16), context.fx(24)),
          children: [
            _Banner(
              bonus: _bonusText(referral),
              code: referral.referralCode,
              onCopy: () => _copy(referral.referralCode),
            ),
            SizedBox(height: context.fx(24)),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFFEE7330),
                    label: 'TOTAL REFERRAL',
                    value: '${referral.totalReferrals}',
                  ),
                ),
                SizedBox(width: context.fx(16)),
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_add_alt_1_rounded,
                    iconColor: const Color(0xFF2EAD5B),
                    label: 'TOTAL EARNED',
                    value: CurrencyConverter.format(
                      double.tryParse(referral.totalEarned) ?? 0,
                      'INR',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.fx(28)),
            const _HowItWorks(),
          ],
        ),
      );
    }
    if (state is ReferralFailed) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.fx(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: context.fx(40), color: kAccountMuted),
              SizedBox(height: context.fx(12)),
              Text(
                'Couldn’t load your referral details',
                style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600),
              ),
              SizedBox(height: context.fx(16)),
              AccountPrimaryButton(
                label: 'Try again',
                onPressed: () => _bloc.add(const FetchReferralEvent()),
              ),
            ],
          ),
        ),
      );
    }
    return const AppLoadingView(message: 'Loading your referral code…');
  }
}

class _Banner extends StatelessWidget {
  final String? bonus;
  final String code;
  final VoidCallback onCopy;

  const _Banner({required this.bonus, required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: context.ffs(14), color: kAccountInk, height: 1.45);
    return Container(
      height: context.fx(176),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.fx(10)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA9DDFA), Color(0xFFF4FBFF)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Clouds along the bottom-left, behind the gift.
          Positioned(left: -context.fx(20), bottom: -context.fx(30), child: _cloud(context, 120)),
          Positioned(left: context.fx(70), bottom: -context.fx(40), child: _cloud(context, 110)),
          Positioned(left: context.fx(4), top: context.fx(16), child: _Gift(size: context.fx(150))),
          Positioned(
            right: context.fx(14),
            top: 0,
            bottom: 0,
            width: context.fx(178),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(
                        text: bonus == null
                            ? 'Earn rewards for every friend you invite to '
                            : 'Earn upto $bonus/friend you invite to ',
                      ),
                      const TextSpan(
                        text: 'Wander',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.AppBlue),
                      ),
                      const TextSpan(
                        text: 'Nova',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEE7330)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: context.fx(16)),
                _CodePill(code: code, onCopy: onCopy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloud(BuildContext context, double size) => Container(
    width: context.fx(size),
    height: context.fx(size * 0.62),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(size)),
    ),
  );
}

/// Gift box with confetti — drawn with shapes so it needs no image asset.
class _Gift extends StatelessWidget {
  final double size;

  const _Gift({required this.size});

  @override
  Widget build(BuildContext context) {
    final box = size * 0.56;
    Widget confetti(double l, double t, Color c, double s, {double r = 0}) => Positioned(
      left: size * l,
      top: size * t,
      child: Transform.rotate(
        angle: r,
        child: Container(
          width: size * s,
          height: size * s * 0.45,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          confetti(0.10, 0.20, const Color(0xFF3D7BE0), 0.08, r: 0.6),
          confetti(0.78, 0.12, const Color(0xFFF5B91E), 0.07, r: -0.4),
          confetti(0.86, 0.42, const Color(0xFF3D7BE0), 0.06, r: 0.9),
          confetti(0.04, 0.55, const Color(0xFFF5B91E), 0.06, r: -0.8),
          confetti(0.62, 0.02, const Color(0xFF5DB4F5), 0.08, r: 0.3),
          Positioned(
            left: (size - box) / 2,
            top: size * 0.30,
            child: Container(
              width: box,
              height: box * 0.95,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8FD0FF), Color(0xFF3FA6E6)],
                ),
                borderRadius: BorderRadius.circular(size * 0.04),
                boxShadow: const [BoxShadow(color: Color(0x332D8FD8), blurRadius: 10, offset: Offset(0, 6))],
              ),
              child: Center(
                child: Container(width: box * 0.18, color: const Color(0xFF1E5FC8)),
              ),
            ),
          ),
          // Lid, tilted open.
          Positioned(
            left: (size - box * 1.12) / 2 - size * 0.04,
            top: size * 0.18,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: box * 1.12,
                height: box * 0.26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6EC1F7), Color(0xFF3FA6E6)]),
                  borderRadius: BorderRadius.circular(size * 0.03),
                ),
                child: Center(child: Container(width: box * 0.18, color: const Color(0xFF1E5FC8))),
              ),
            ),
          ),
          Positioned(
            left: size * 0.36,
            top: size * 0.02,
            child: Icon(Icons.auto_awesome_rounded, size: size * 0.2, color: const Color(0xFFF5B91E)),
          ),
        ],
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _CodePill({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.fx(32),
      padding: EdgeInsets.only(left: context.fx(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFBDE4FA),
        borderRadius: BorderRadius.circular(context.fx(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: context.fx(100)),
            child: Text(
              code,
              style: TextStyle(
                fontSize: context.ffs(13),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: const Color(0xFFEE7330),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFEE7330),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Copy referral code',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCopy,
              child: Container(
                width: context.fx(32),
                height: context.fx(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.fx(8)),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
                ),
                child: Icon(Icons.copy_rounded, size: context.fx(15), color: AppColors.AppBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.fx(16), horizontal: context.fx(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(8)),
        border: Border.all(color: kAccountLine),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.fx(16), color: iconColor),
              SizedBox(width: context.fx(6)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.ffs(11), fontWeight: FontWeight.w500, color: kAccountInk),
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(10)),
          Text(
            value,
            style: TextStyle(fontSize: context.ffs(16), fontWeight: FontWeight.w600, color: kAccountInk),
          ),
        ],
      ),
    );
  }
}

/// Short explainer under the stats — fills the empty space in a useful way.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String text) => Padding(
      padding: EdgeInsets.only(bottom: context.fx(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.fx(22),
            height: context.fx(22),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFE6F6FD), shape: BoxShape.circle),
            child: Text(
              '$n',
              style: TextStyle(fontSize: context.ffs(11), fontWeight: FontWeight.w700, color: AppColors.AppBlue),
            ),
          ),
          SizedBox(width: context.fx(10)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: context.fx(2)),
              child: Text(text, style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted)),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(fontSize: context.ffs(14), fontWeight: FontWeight.w600, color: kAccountInk),
        ),
        SizedBox(height: context.fx(12)),
        step(1, 'Share your code or link with friends.'),
        step(2, 'They sign up on WanderNova using your code.'),
        step(3, 'Your reward is added to your wallet automatically.'),
      ],
    );
  }
}
