import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../ReferCode/presentation/bloc/referral_bloc.dart';
import '../../../ReferCode/presentation/bloc/referral_event.dart';
import '../../../ReferCode/presentation/bloc/referral_state.dart';
import '../../../WalletStatus/domain/entity/loyality_entity.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_bloc.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_event.dart';
import '../../../WalletStatus/presentation/bloc/loyalty_state.dart';

/// Refer & Earn and Loyalty Tier, which used to sit between the balance card
/// and the transaction list on the wallet screen.
///
/// The redesigned wallet (Figma `Wallet 1`) is only balance plus history, so
/// both moved here and the drawer opens this screen under **Rewards**. The
/// two sections are the same widgets with the same blocs, events and copy —
/// relocated, not rewritten, so referral codes still copy and the tier
/// progress still reads from [LoyaltyBloc].
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Owned here, exactly as the wallet screen owned them: the providers are
  // descendants of this element, so context.read<>() could not reach them.
  late final ReferralBloc _referralBloc;
  late final LoyaltyBloc _loyaltyBloc;

  bool _isReferralCopied = false;

  @override
  void initState() {
    super.initState();
    _referralBloc = sl<ReferralBloc>()..add(const FetchReferralEvent());
    _loyaltyBloc = sl<LoyaltyBloc>()..add(FetchUserLoyalty());
  }

  @override
  void dispose() {
    _referralBloc.close();
    _loyaltyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _referralBloc),
        BlocProvider.value(value: _loyaltyBloc),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(bottom: context.h(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.h(8)),
                      _buildReferAndEarnSection(),
                      _buildLoyaltySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        context.h(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(context.w(4)),
              child: Icon(
                Icons.arrow_back_rounded,
                size: context.w(21),
                color: AppColors.navy,
              ),
            ),
          ),
          SizedBox(width: context.w(14)),
          Text(
            'Rewards',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
        builder: (context, state) {
          if (state is LoyaltyLoading || state is LoyaltyInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: context.w(22),
                      color: Colors.amber.shade700,
                    ),
                    SizedBox(width: context.w(8)),
                    Text(
                      "Loyalty Tier",
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(16)),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }

          if (state is LoyaltyLoaded) {
            final dataState = state.dataState;
            if (dataState is DataSuccess<LoyaltyEntity>) {
              return _buildLoyaltyContent(dataState.data!);
            }
            if (dataState is DataFailed<LoyaltyEntity>) {
              return _buildLoyaltyError(
                dataState.error?.message ?? 'Failed to load',
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoyaltyContent(LoyaltyEntity loyalty) {
    final tierColor = _getColorFromHex(loyalty.tierColor);
    final progress = loyalty.progressPercentage;
    final isMaxTier =
        loyalty.nextTier == null ||
        loyalty.bookingsNeeded == null ||
        loyalty.bookingsNeeded == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.w(6)),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Icon(
                Icons.workspace_premium,
                size: context.w(20),
                color: tierColor,
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Loyalty Tier",
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    loyalty.tierLabel,
                    style: TextStyle(
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(color: tierColor.withOpacity(0.3)),
              ),
              child: Text(
                loyalty.tier.toUpperCase(),
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                  letterSpacing: context.letterSpacingWide,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(16)),
        Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to ${isMaxTier ? "Max Tier" : loyalty.nextTierLabel ?? "Next Tier"}',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: context.fs(13),
                      fontWeight: FontWeight.w700,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(8)),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: context.h(8),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                ),
              ),
              SizedBox(height: context.h(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${loyalty.completedBookings} bookings completed',
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (!isMaxTier && loyalty.bookingsNeeded != null)
                    Text(
                      '${loyalty.bookingsNeeded} more to go',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'Highest tier reached',
                      style: TextStyle(
                        fontSize: context.fs(11),
                        color: tierColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(16)),
        Text(
          'Your Benefits',
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.h(8)),
        ...loyalty.benefits.map(
          (benefit) => Padding(
            padding: EdgeInsets.only(bottom: context.h(6)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: context.h(2)),
                  child: Icon(
                    Icons.check_circle,
                    size: context.w(16),
                    color: tierColor,
                  ),
                ),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium,
              size: context.w(22),
              color: Colors.amber.shade700,
            ),
            SizedBox(width: context.w(8)),
            Text(
              "Loyalty Tier",
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(12)),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: context.w(40),
                color: Colors.red.shade300,
              ),
              SizedBox(height: context.h(8)),
              Text(
                "Failed to load loyalty data",
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: context.h(4)),
              Text(
                message,
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.h(12)),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<LoyaltyBloc>().add(FetchUserLoyalty()),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                    vertical: context.h(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
  // ==================== END LOYALTY SECTION ====================

  Widget _buildReferAndEarnSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: BlocBuilder<ReferralBloc, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading || state is ReferralInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "Refer & Earn",
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }

          if (state is ReferralSuccess && state.data != null) {
            final referral = state.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, size: context.w(22)),
                    SizedBox(width: context.w(8)),
                    Text(
                      "Refer & Earn",
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(6)),
                Text(
                  "Invite friends and earn rewards on every successful referral.",
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: context.h(12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(10),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referral.referralLink,
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w600,
                            letterSpacing: context.letterSpacingWider,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: referral.referralLink),
                          );
                          setState(() => _isReferralCopied = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Referral code copied"),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted)
                              setState(() => _isReferralCopied = false);
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _isReferralCopied ? Icons.check : Icons.copy,
                              size: context.w(18),
                            ),
                            SizedBox(width: context.w(4)),
                            Text(
                              _isReferralCopied ? "Copied" : "Copy",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: context.fs(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      label: "Total Referrals",
                      value: referral.totalReferrals.toString(),
                    ),
                    _buildStatItem(
                      label: "Total Earned",
                      value: "${referral.totalEarned}",
                    ),
                  ],
                ),
              ],
            );
          }

          if (state is ReferralFailed) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, size: context.w(22)),
                    SizedBox(width: context.w(8)),
                    Text(
                      "Refer & Earn",
                      style: TextStyle(
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: context.w(40),
                        color: Colors.red.shade300,
                      ),
                      SizedBox(height: context.h(8)),
                      Text(
                        "Failed to load referral data",
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: context.h(12)),
                      ElevatedButton.icon(
                        onPressed: () => context.read<ReferralBloc>().add(
                          const FetchReferralEvent(),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(20),
                            vertical: context.h(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        child: Column(
          children: [
            SizedBox(height: context.h(4)),
            Text(
              value,
              style: TextStyle(
                fontSize: context.fs(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
