import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../core/error/data_state.dart';
import '../../../../injection_container.dart';
import '../../../Dashboard/profile/widgets/account_kit.dart';
import '../../domain/entity/loyality_entity.dart';
import '../bloc/loyalty_bloc.dart';
import '../bloc/loyalty_event.dart';
import '../bloc/loyalty_state.dart';

/// Membership tier screen — Figma "Bronze" (opened from the drawer's tier
/// tile). Driven by `GET /api/user/loyalty/`: where the member stands, how
/// many bookings until the next tier, and what each tier unlocks.
class LoyaltyTierScreen extends StatefulWidget {
  const LoyaltyTierScreen({super.key});

  @override
  State<LoyaltyTierScreen> createState() => _LoyaltyTierScreenState();
}

class _LoyaltyTierScreenState extends State<LoyaltyTierScreen> {
  late final LoyaltyBloc _bloc = sl<LoyaltyBloc>()..add(FetchUserLoyalty());

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
            bloc: _bloc,
            builder: (context, state) {
              final data = state is LoyaltyLoaded ? state.dataState : null;
              final loyalty = data is DataSuccess<LoyaltyEntity> ? data.data : null;

              final title = loyalty?.tierLabel.isNotEmpty == true
                  ? loyalty!.tierLabel
                  : 'Membership';
              final top = Padding(
                padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(8), context.fx(16), 0),
                child: AccountTopBar(title: title),
              );

              if (loyalty != null) {
                return Column(
                  children: [
                    top,
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.AppBlue,
                        onRefresh: () async {
                          _bloc.add(FetchUserLoyalty());
                          await _bloc.stream.firstWhere((s) => s is! LoyaltyLoading);
                        },
                        child: _TierBody(loyalty: loyalty),
                      ),
                    ),
                  ],
                );
              }
              if (data is DataFailed<LoyaltyEntity>) {
                return Column(
                  children: [
                    top,
                    Expanded(child: _ErrorView(onRetry: () => _bloc.add(FetchUserLoyalty()))),
                  ],
                );
              }
              return Column(
                children: [
                  top,
                  const Expanded(child: AppLoadingView(message: 'Loading your membership…')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _hex(String hex, {Color fallback = AppColors.AppBlue}) {
  final h = hex.replaceAll('#', '').trim();
  if (h.length != 6) return fallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// Tier colours from the API are metallic (Platinum is near-white), so text
/// and icons use a readable shade of the same hue.
Color _ink(String tier, String hex) {
  switch (tier) {
    case 'bronze':
      return const Color(0xFFB0662A);
    case 'silver':
      return const Color(0xFF7D8088);
    case 'gold':
      return const Color(0xFFD9A400);
    case 'platinum':
      return const Color(0xFF5B6B7F);
  }
  return _hex(hex);
}

class _TierBody extends StatelessWidget {
  final LoyaltyEntity loyalty;

  const _TierBody({required this.loyalty});

  @override
  Widget build(BuildContext context) {
    final ladder = loyalty.ladder;
    final index = ladder.indexWhere((t) => t.tier == loyalty.tier).clamp(0, ladder.length - 1);
    final current = ladder[index];
    final upcoming = ladder.sublist(index + 1);
    final isTop = upcoming.isEmpty;

    // Compare the member's tier with what lies ahead (or, at the top, with
    // the tier below) — at most three columns.
    final compared = isTop
        ? ladder.sublist((index - 2).clamp(0, index), index + 1)
        : [current, ...upcoming.take(2)];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(context.fx(16), context.fx(16), context.fx(16), context.fx(32)),
      children: [
        _StatusCard(loyalty: loyalty, ladder: ladder, index: index),
        SizedBox(height: context.fx(20)),
        _BenefitsCard(
          title: 'Your ${current.label} Benefits',
          tier: current,
          unlocked: true,
        ),
        for (final t in upcoming) ...[
          SizedBox(height: context.fx(20)),
          _BenefitsCard(title: '${t.label} Benefits', tier: t, unlocked: false),
        ],
        if (compared.length > 1) ...[
          SizedBox(height: context.fx(20)),
          _CompareTable(tiers: compared, currentTier: current.tier),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------- status

class _StatusCard extends StatelessWidget {
  final LoyaltyEntity loyalty;
  final List<LoyaltyTierInfo> ladder;
  final int index;

  const _StatusCard({required this.loyalty, required this.ladder, required this.index});

  @override
  Widget build(BuildContext context) {
    final isTop = index >= ladder.length - 1;
    // Three stops: you + the next two tiers, or (at the top) the two below + you.
    final start = isTop ? (index - 2).clamp(0, index) : index;
    final stops = ladder.sublist(start, (start + 3).clamp(0, ladder.length));
    final next = isTop ? null : ladder[index + 1];
    final needed = loyalty.bookingsNeeded ??
        (next == null ? 0 : (next.threshold - loyalty.completedBookings).clamp(0, 1 << 30));

    return Container(
      padding: EdgeInsets.all(context.fx(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: kAccountLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: context.fx(18), color: const Color(0xFFF5B91E)),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text(
                  isTop ? 'You’re at the top tier' : 'Start saving with WanderNova',
                  style: TextStyle(
                    fontSize: context.ffs(15),
                    fontWeight: FontWeight.w500,
                    color: kAccountInk,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.fx(8), vertical: context.fx(4)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7ACCF5), Color(0xFF3FA6E6)]),
                  borderRadius: BorderRadius.circular(context.fx(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: context.fx(12), color: Colors.white),
                    SizedBox(width: context.fx(4)),
                    Text(
                      'Tier Status',
                      style: TextStyle(
                        fontSize: context.ffs(10),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.fx(20)),
          _ProgressTrack(
            stops: stops,
            currentTier: loyalty.tier,
            completed: loyalty.completedBookings,
          ),
          SizedBox(height: context.fx(16)),
          const _DashedDivider(),
          SizedBox(height: context.fx(12)),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: context.fx(16), color: const Color(0xFF34C759)),
              SizedBox(width: context.fx(8)),
              Expanded(
                child: Text(
                  next == null
                      ? 'Enjoy every ${ladder[index].label} benefit — thanks for travelling with us.'
                      : needed == 0
                          ? 'Your next booking unlocks ${next.label} benefits'
                          : '$needed booking${needed == 1 ? '' : 's'} away from ${next.label} benefits',
                  style: TextStyle(fontSize: context.ffs(12), color: kAccountMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final List<LoyaltyTierInfo> stops;
  final String currentTier;
  final int completed;

  const _ProgressTrack({required this.stops, required this.currentTier, required this.completed});

  @override
  Widget build(BuildContext context) {
    final currentIdx = stops.indexWhere((s) => s.tier == currentTier);
    // Fill reaches the member's stop, plus a share of the way to the next one.
    double fill = currentIdx / (stops.length - 1).clamp(1, 99);
    if (currentIdx >= 0 && currentIdx < stops.length - 1) {
      final from = stops[currentIdx].threshold;
      final to = stops[currentIdx + 1].threshold;
      final part = to > from ? ((completed - from) / (to - from)).clamp(0.0, 1.0) : 0.0;
      fill += part / (stops.length - 1);
    }

    final dot = context.fx(22);
    return Column(
      children: [
        SizedBox(
          height: dot,
          child: LayoutBuilder(
            builder: (context, c) {
              final inset = c.maxWidth / (stops.length * 2);
              final span = c.maxWidth - inset * 2;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: context.fx(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FB),
                        borderRadius: BorderRadius.circular(context.fx(3)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: inset + span * fill,
                    child: Container(
                      height: context.fx(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7ACCF5), AppColors.AppBlue]),
                        borderRadius: BorderRadius.circular(context.fx(3)),
                      ),
                    ),
                  ),
                  for (var i = 0; i < stops.length; i++)
                    Positioned(
                      left: inset + (stops.length == 1 ? 0 : span * i / (stops.length - 1)) - dot / 2,
                      child: _StopDot(
                        size: dot,
                        color: stops[i].tier == currentTier
                            ? AppColors.AppBlue
                            : _ink(stops[i].tier, stops[i].color),
                        current: stops[i].tier == currentTier,
                        reached: i <= currentIdx,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: context.fx(8)),
        Row(
          children: [
            for (final s in stops)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      s.tier == currentTier ? 'You are here' : s.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.ffs(12),
                        fontWeight: FontWeight.w500,
                        color: s.tier == currentTier
                            ? AppColors.AppBlue
                            : _ink(s.tier, s.color),
                      ),
                    ),
                    Text(
                      s.tier == currentTier
                          ? '$completed booking${completed == 1 ? '' : 's'}'
                          : '${s.threshold} booking${s.threshold == 1 ? '' : 's'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: context.ffs(10), color: kAccountMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StopDot extends StatelessWidget {
  final double size;
  final Color color;
  final bool current;
  final bool reached;

  const _StopDot({required this.size, required this.color, required this.current, required this.reached});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: current
          ? Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : reached
              ? Icon(Icons.check_rounded, size: size * 0.55, color: color)
              : Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withValues(alpha: 0.6), color]),
                  ),
                ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 7).floor();
        return Row(
          children: [
            for (var i = 0; i < n; i++)
              Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 3),
                color: kAccountLine,
              ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------- benefits

/// Icon + tint for a benefit, picked from its wording.
(IconData, Color, Color) _benefitStyle(String benefit) {
  final b = benefit.toLowerCase();
  if (b.contains('voucher') || b.contains('discount') || b.contains('%')) {
    return (Icons.percent_rounded, const Color(0xFF2EAD5B), const Color(0xFFE6F7EC));
  }
  if (b.contains('support') || b.contains('concierge')) {
    return (Icons.headset_mic_rounded, AppColors.AppBlue, const Color(0xFFE6F6FD));
  }
  if (b.contains('gift')) {
    return (Icons.card_giftcard_rounded, const Color(0xFFE5484D), const Color(0xFFFDECEC));
  }
  if (b.contains('breakfast')) {
    return (Icons.free_breakfast_rounded, const Color(0xFFEE7330), const Color(0xFFFDEDE3));
  }
  if (b.contains('lounge')) {
    return (Icons.weekend_rounded, const Color(0xFF6E62E5), const Color(0xFFEEECFC));
  }
  if (b.contains('seat')) {
    return (Icons.event_seat_rounded, const Color(0xFF0E9AA7), const Color(0xFFE2F5F7));
  }
  if (b.contains('upgrade')) {
    return (Icons.upgrade_rounded, const Color(0xFFD9A400), const Color(0xFFFEF6DE));
  }
  if (b.contains('check-in') || b.contains('check-out')) {
    return (Icons.schedule_rounded, const Color(0xFF3D5AFE), const Color(0xFFE8EDFF));
  }
  return (Icons.star_rounded, const Color(0xFFF5B91E), const Color(0xFFFEF6DE));
}

class _BenefitsCard extends StatelessWidget {
  final String title;
  final LoyaltyTierInfo tier;
  final bool unlocked;

  const _BenefitsCard({required this.title, required this.tier, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final ink = _ink(tier.tier, tier.color);
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: kAccountLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: context.fx(20), color: ink),
              SizedBox(width: context.fx(6)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.ffs(15),
                    fontWeight: FontWeight.w500,
                    color: kAccountInk,
                  ),
                ),
              ),
              if (!unlocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: context.fx(12), color: kAccountMuted),
                    SizedBox(width: context.fx(3)),
                    Text(
                      'at ${tier.threshold} bookings',
                      style: TextStyle(fontSize: context.ffs(10), color: kAccountMuted),
                    ),
                  ],
                )
              else
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: context.ffs(11),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2EAD5B),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.fx(12)),
          Container(
            padding: EdgeInsets.all(context.fx(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(context.fx(10)),
              border: Border.all(color: const Color(0xFFEEF1F5)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tier.benefits.length; i++) ...[
                  if (i > 0) SizedBox(height: context.fx(8)),
                  _BenefitRow(text: tier.benefits[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final (icon, color, tint) = _benefitStyle(text);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.fx(10), vertical: context.fx(9)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(8)),
        border: Border.all(color: tint),
      ),
      child: Row(
        children: [
          Container(
            width: context.fx(24),
            height: context.fx(24),
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(context.fx(6))),
            child: Icon(icon, size: context.fx(15), color: color),
          ),
          SizedBox(width: context.fx(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: context.ffs(12.5), color: kAccountInk),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- comparison

class _CompareTable extends StatelessWidget {
  final List<LoyaltyTierInfo> tiers;
  final String currentTier;

  const _CompareTable({required this.tiers, required this.currentTier});

  @override
  Widget build(BuildContext context) {
    // Every benefit any compared tier offers, in first-seen order.
    final rows = <String>[];
    for (final t in tiers) {
      for (final b in t.benefits) {
        if (!rows.contains(b)) rows.add(b);
      }
    }
    final colW = context.fx(64);

    Widget headerCell(LoyaltyTierInfo t) => SizedBox(
      width: colW,
      child: Text(
        t.tier == currentTier ? '${t.label}\n(You)' : t.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: context.ffs(12),
          fontWeight: FontWeight.w600,
          color: _ink(t.tier, t.color),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: kAccountLine),
      ),
      child: Column(
        children: [
          Text(
            'Benefits you can’t let go of',
            style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w500, color: kAccountInk),
          ),
          SizedBox(height: context.fx(2)),
          Text(
            'See what each tier unlocks',
            style: TextStyle(fontSize: context.ffs(11), color: kAccountMuted),
          ),
          SizedBox(height: context.fx(8)),
          const _StarsRule(),
          SizedBox(height: context.fx(12)),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.fx(10)),
              border: Border.all(color: kAccountLine),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(12)),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFD7EEFE), Color(0xFFF5FAFF)]),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Key Benefits',
                          style: TextStyle(
                            fontSize: context.ffs(12),
                            fontWeight: FontWeight.w600,
                            color: kAccountInk,
                          ),
                        ),
                      ),
                      for (final t in tiers) headerCell(t),
                    ],
                  ),
                ),
                for (var r = 0; r < rows.length; r++)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(10)),
                    decoration: BoxDecoration(
                      border: r == 0 ? null : const Border(top: BorderSide(color: kAccountLine)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rows[r],
                            style: TextStyle(fontSize: context.ffs(11.5), color: kAccountInk),
                          ),
                        ),
                        for (final t in tiers)
                          SizedBox(
                            width: colW,
                            child: Icon(
                              t.benefits.contains(rows[r])
                                  ? Icons.check_circle_rounded
                                  : Icons.remove_rounded,
                              size: context.fx(16),
                              color: t.benefits.contains(rows[r])
                                  ? const Color(0xFF2EAD5B)
                                  : const Color(0xFFC5CAD1),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.fx(12)),
          const _StarsRule(),
        ],
      ),
    );
  }
}

class _StarsRule extends StatelessWidget {
  const _StarsRule();

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF5B91E);
    Widget line(Alignment from) => Expanded(
      child: Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: from, end: -from, colors: [gold.withValues(alpha: 0), gold]),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.fx(40)),
      child: Row(
        children: [
          line(Alignment.centerLeft),
          for (final s in const [7.0, 10.0, 7.0]) Icon(Icons.star_rounded, size: context.fx(s), color: gold),
          line(Alignment.centerRight),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.fx(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: context.fx(40), color: kAccountMuted),
            SizedBox(height: context.fx(12)),
            Text(
              'Couldn’t load your membership',
              style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: context.fx(16)),
            AccountPrimaryButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
