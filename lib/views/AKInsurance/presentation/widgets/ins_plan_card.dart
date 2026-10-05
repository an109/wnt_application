import 'package:flutter/material.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../tokens/ins_tokens.dart';
import 'ins_common.dart';

/// Presentation-only reads of the provider's raw quote row.
///
/// The entity keeps the untouched JSON in [AkInsurancePlanEntity.raw] so the
/// plan id can be echoed back losslessly; these getters reuse it for the two
/// display-only things the Figma shows but the mapped entity has no field
/// for. Both are optional — when the provider doesn't send them the card
/// simply renders without, rather than inventing a value.
extension InsPlanView on AkInsurancePlanEntity {
  /// Whether to show the "RECOMMENDED" ribbon. True only when the provider
  /// actually flags the row.
  bool get isRecommended {
    for (final key in const [
      'isRecommended',
      'recommended',
      'IsRecommended',
      'Recommended',
      'isPopular',
      'bestSeller',
    ]) {
      final v = raw[key];
      if (v is bool && v) return true;
      if (v is num && v > 0) return true;
      if (v is String && (v.toLowerCase() == 'true' || v == '1')) return true;
    }
    return false;
  }

  /// The insurer's logo.
  ///
  /// QuotesListing and PlanDetails both send it as `providerImageURL`
  /// (e.g. `…/assets/images/Religare.jpg`); the other spellings are kept as
  /// a safety net for providers shaped differently.
  String? get logoUrl {
    for (final key in const [
      'providerImageURL',
      'providerImageUrl',
      'providerImage',
      'logo',
      'Logo',
      'logoUrl',
      'logoURL',
      'providerLogo',
      'insurerLogo',
      'image',
    ]) {
      final v = raw[key];
      if (v is String && v.trim().startsWith('http')) return v.trim();
    }
    return null;
  }

  /// What the whole party actually costs.
  ///
  /// The quote carries `premium.premiumDistributions` — one row per
  /// traveller, each with its own base/tax/total. Summing those rows gives
  /// the party total no matter how the top-level `premium.total` is meant
  /// to be read, which is why it is preferred over multiplying a headline
  /// figure by the traveller count (the previous screen's approach, and the
  /// thing that would double-charge a couple if `total` is already the
  /// party price).
  ///
  /// Falls back to [premium] when the provider sends no breakdown.
  double get partyPremium {
    final node = raw['premium'] ?? raw['Premium'];
    if (node is Map) {
      final rows = node['premiumDistributions'] ?? node['PremiumDistributions'];
      if (rows is List && rows.isNotEmpty) {
        var sum = 0.0;
        var sawTotal = false;
        for (final r in rows) {
          if (r is! Map) continue;
          final t = r['total'] ?? r['Total'];
          if (t is num) {
            sum += t.toDouble();
            sawTotal = true;
          }
        }
        if (sawTotal && sum > 0) return sum;
      }
    }
    return premium;
  }

  /// How many travellers the quoted premium covers, when the breakdown says.
  int get pricedTravellers {
    final node = raw['premium'] ?? raw['Premium'];
    if (node is Map) {
      final rows = node['premiumDistributions'] ?? node['PremiumDistributions'];
      if (rows is List && rows.isNotEmpty) return rows.length;
    }
    return 0;
  }

  /// The policy wording PDF, sent as `policyWordingURL`.
  String? get documentUrl {
    for (final key in const [
      'policyWordingURL',
      'policyWordingUrl',
      'policyWording',
      'policyDocument',
      'documentUrl',
      'brochure',
      'termsUrl',
      'pdf',
    ]) {
      final v = raw[key];
      if (v is String && v.trim().startsWith('http')) return v.trim();
    }
    return null;
  }
}

/// One plan row on the quotes list — Figma `Select plan Individual`.
class InsPlanCard extends StatelessWidget {
  final AkInsurancePlanEntity plan;
  final VoidCallback onDetails;
  final VoidCallback onSelect;

  const InsPlanCard({
    super.key,
    required this.plan,
    required this.onDetails,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(14)),
        decoration: insCard(context, border: true, shadow: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.r(12)),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(12),
                  context.h(12),
                  context.w(12),
                  context.h(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InsProviderLogo(
                          provider: plan.provider,
                          logoUrl: plan.logoUrl,
                        ),
                        SizedBox(width: context.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leave room for the ribbon on the first line.
                              Padding(
                                padding: EdgeInsets.only(
                                  right: plan.isRecommended
                                      ? context.w(90)
                                      : 0,
                                ),
                                child: Text(
                                  plan.planName,
                                  style: TextStyle(
                                    fontSize: context.fs(12),
                                    fontWeight: FontWeight.w500,
                                    color: InsTokens.navy,
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(5)),
                              if (plan.sumInsured > 0)
                                RichText(
                                  text: TextSpan(
                                    text: 'Coverage : ',
                                    style: TextStyle(
                                      fontSize: context.fs(10),
                                      fontWeight: FontWeight.w500,
                                      color: InsTokens.subGrey,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: InsTokens.coverage(
                                          plan.sumInsured,
                                          currency: _coverageCurrency,
                                        ),
                                        style: TextStyle(
                                          fontSize: context.fs(10),
                                          color: InsTokens.navy,
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onDetails,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Policy Details',
                                style: TextStyle(
                                  fontSize: context.fs(10),
                                  fontWeight: FontWeight.w600,
                                  color: InsTokens.blue,
                                ),
                              ),
                              SizedBox(width: context.w(4)),
                              Icon(Icons.chevron_right_rounded,
                                  size: context.w(19), color: InsTokens.blue),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: context.fs(10),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                                color: InsTokens.premiumLabel,
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              InsTokens.rupees(plan.premium),
                              style: TextStyle(
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w600,
                                color: InsTokens.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (plan.isRecommended)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      gradient: InsTokens.ribbon,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(context.r(8)),
                      ),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The cover amount is quoted in its own currency, which is not always the
  /// premium's — fall back to USD, which is how every rate sheet in this
  /// account expresses cover.
  String get _coverageCurrency {
    final raw = plan.raw;
    final node = raw['coverage'] ?? raw['Coverage'];
    if (node is Map) {
      final c = node['currency'] ?? node['Currency'];
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return 'USD';
  }
}
