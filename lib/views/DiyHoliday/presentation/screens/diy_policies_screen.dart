import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../injection_container.dart';
import '../../data/diy_holiday_api.dart';
import '../../data/models/diy_models.dart';
import '../widgets/diy_common.dart';
import '../widgets/diy_trip_day_card.dart';

/// Which page of the paperwork to show.
enum DiyPolicyPage { terms, policies }

/// "Terms & Conditions" and "Policies" — Figma `Term & condition Holiday
/// cart review` and `Policies Holiday cart review`.
///
/// Both read **GET /policies/**: the same text the PDF quote and the booking
/// carry, so nothing here can promise what the paperwork does not.
class DiyPoliciesScreen extends StatefulWidget {
  final DiyPolicyPage page;

  const DiyPoliciesScreen({super.key, required this.page});

  @override
  State<DiyPoliciesScreen> createState() => _DiyPoliciesScreenState();
}

class _DiyPoliciesScreenState extends State<DiyPoliciesScreen> {
  late Future<DiyPolicies> _future = sl<DiyHolidayApi>().getPolicies();

  bool get _terms => widget.page == DiyPolicyPage.terms;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: context.w(24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          _terms ? 'Terms & Conditions' : 'Policies',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<DiyPolicies>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DiyLoading(message: 'Loading…');
          }
          if (snapshot.hasError) {
            return DiyErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = sl<DiyHolidayApi>().getPolicies();
              }),
            );
          }
          final p = snapshot.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(20),
              context.w(20),
              context.h(32),
            ),
            children: _terms ? _termsPage(p) : _policiesPage(p),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- terms

  List<Widget> _termsPage(DiyPolicies p) => [
    if (p.exclusions.isNotEmpty) ...[
      _heading('Exclusions'),
      _bullets(p.exclusions),
      SizedBox(height: context.h(20)),
    ],
    if (p.inclusions.isNotEmpty) ...[
      _heading('Always Included'),
      _bullets(p.inclusions),
      SizedBox(height: context.h(20)),
    ],
    _heading('Terms & Conditions'),
    _bullets(p.terms),
    if (p.priceNotes.isNotEmpty) ...[
      SizedBox(height: context.h(20)),
      _heading('About the price'),
      _bullets(p.priceNotes),
    ],
  ];

  // -------------------------------------------------------------- policies

  List<Widget> _policiesPage(DiyPolicies p) => [
    _heading('Package Cancellation Policy'),
    Text(
      'What you get back depends on how long before departure you cancel.',
      style: TextStyle(fontSize: context.fs(11), color: DiyTripStyle.grey),
    ),
    SizedBox(height: context.h(14)),
    _timeline(p.cancellation),
    if (p.dateChange.isNotEmpty) ...[
      SizedBox(height: context.h(24)),
      _heading('Date Change Policy'),
      SizedBox(height: context.h(8)),
      _timeline(p.dateChange),
    ],
    if (p.isProvisional) ...[
      SizedBox(height: context.h(20)),
      Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: const Color(0xFFFFD9A8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: context.w(16),
              color: DiyTripStyle.orange,
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                'Some charges are still to be confirmed. The exact fee is '
                'shared with you in writing before you book.',
                style: TextStyle(
                  fontSize: context.fs(11),
                  color: DiyTokens.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ];

  /// One dot per band, earliest first: green while it is cheapest to cancel,
  /// red once nothing comes back.
  Widget _timeline(List<DiyPolicyBand> bands) {
    Color colorOf(DiyPolicyBand b) {
      final fee = b.feePercent;
      if (fee == null) return DiyTripStyle.orange;
      if (fee >= 100) return DiyTripStyle.red;
      if (fee == 0) return DiyTripStyle.green;
      return DiyTripStyle.orange;
    }

    return Column(
      children: [
        for (var i = 0; i < bands.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: context.w(20),
                  child: Column(
                    children: [
                      Container(
                        width: context.w(12),
                        height: context.w(12),
                        margin: EdgeInsets.only(top: context.h(2)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorOf(bands[i]),
                        ),
                      ),
                      if (i < bands.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: DiyTripStyle.divider,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: context.h(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bands[i].label,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          bands[i].feePercent == null
                              ? bands[i].note
                              : '${bands[i].feePercent!.round()}% of the package'
                                    '${bands[i].note.isEmpty ? '' : ' — ${bands[i].note}'}',
                          style: TextStyle(
                            fontSize: context.fs(11),
                            color: colorOf(bands[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- pieces

  Widget _heading(String text) => Padding(
    padding: EdgeInsets.only(bottom: context.h(8)),
    child: Text(
      text,
      style: TextStyle(
        fontSize: context.fs(15),
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
  );

  Widget _bullets(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: EdgeInsets.only(bottom: context.h(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: context.h(6)),
                child: Container(
                  width: context.w(4),
                  height: context.w(4),
                  decoration: const BoxDecoration(
                    color: DiyTripStyle.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: DiyTripStyle.slate,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
